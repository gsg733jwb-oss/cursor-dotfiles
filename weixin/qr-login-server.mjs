#!/usr/bin/env node
/**
 * Browser QR login for weixin-mcp (ClawBot).
 * Usage: node ~/.weixin-mcp/qr-login-server.mjs
 * Open http://localhost:8765 and scan with WeChat.
 */
import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import os from "node:os";
import crypto from "node:crypto";
import QRCode from "qrcode";

const PORT = Number(process.env.QR_LOGIN_PORT || 8765);
const BASE_URL = "https://ilinkai.weixin.qq.com";
const BOT_TYPE = "3";
const ACCOUNTS_DIR = path.join(os.homedir(), ".weixin-mcp", "accounts");

let state = {
  phase: "loading",
  message: "正在获取二维码…",
  qrcodeUrl: "",
  accountId: "",
  userId: "",
};

async function fetchQRCode() {
  const base = BASE_URL.endsWith("/") ? BASE_URL : `${BASE_URL}/`;
  const url = `${base}ilink/bot/get_bot_qrcode?bot_type=${BOT_TYPE}`;
  const res = await fetch(url);
  if (!res.ok) throw new Error(`QR fetch failed: ${res.status}`);
  return res.json();
}

async function pollStatus(qrcodeToken) {
  const base = BASE_URL.endsWith("/") ? BASE_URL : `${BASE_URL}/`;
  const url = `${base}ilink/bot/get_qrcode_status?qrcode=${encodeURIComponent(qrcodeToken)}`;
  const res = await fetch(url, {
    headers: { "iLink-App-ClientVersion": "1" },
  });
  if (!res.ok) throw new Error(`Status poll failed: ${res.status}`);
  return res.json();
}

function findAccountByUserId(userId) {
  if (!fs.existsSync(ACCOUNTS_DIR)) return null;
  const files = fs
    .readdirSync(ACCOUNTS_DIR)
    .filter((f) => f.endsWith(".json") && !f.includes("sync") && !f.includes("cursor"));
  for (const file of files) {
    try {
      const data = JSON.parse(fs.readFileSync(path.join(ACCOUNTS_DIR, file), "utf-8"));
      if (data.userId === userId) return file.replace(".json", "");
    } catch {
      /* skip */
    }
  }
  return null;
}

function saveAccount(accountId, token, baseUrl, userId) {
  fs.mkdirSync(ACCOUNTS_DIR, { recursive: true });
  let finalAccountId = accountId;
  if (userId) {
    const existingId = findAccountByUserId(userId);
    if (existingId && existingId !== accountId) finalAccountId = existingId;
  }
  const filePath = path.join(ACCOUNTS_DIR, `${finalAccountId}.json`);
  const existing = fs.existsSync(filePath)
    ? JSON.parse(fs.readFileSync(filePath, "utf-8"))
    : {};
  fs.writeFileSync(
    filePath,
    JSON.stringify(
      {
        ...existing,
        token,
        baseUrl,
        ...(userId ? { userId } : {}),
        savedAt: new Date().toISOString(),
      },
      null,
      2,
    ),
  );
  return { finalAccountId, filePath };
}

let currentQrcodeToken = "";
let currentQrPng = null;
let qrRefreshCount = 0;
let pollTimer = null;
let pollAttempts = 0;

async function refreshQR() {
  state.phase = "waiting";
  state.message = "请用微信扫描下方二维码";
  const { qrcode, qrcode_img_content: qrcodeUrl } = await fetchQRCode();
  currentQrcodeToken = qrcode;
  state.qrcodeUrl = qrcodeUrl;
  currentQrPng = await QRCode.toBuffer(qrcodeUrl, { width: 280, margin: 1, type: "png" });
  qrVersion++;
}

async function pollLoop() {
  if (!currentQrcodeToken || state.phase === "done" || state.phase === "error") return;
  pollAttempts++;
  if (pollAttempts > 90) {
    state.phase = "error";
    state.message = "等待扫码超时，请关闭页面后重新运行登录命令。";
    return;
  }
  try {
    const status = await pollStatus(currentQrcodeToken);
    if (status.status === "scaned") {
      state.phase = "scanned";
      state.message = "已扫码，请在手机上确认登录…";
    } else if (status.status === "confirmed") {
      const token = status.bot_token;
      if (!token) throw new Error("No token in confirmed response");
      const baseUrl = status.baseurl ?? BASE_URL;
      const userId = status.ilink_user_id ?? status.ilink_bot_id;
      const accountId =
        status.ilink_bot_id?.replace("@", "-").replace(".", "-") ??
        `${crypto.randomBytes(6).toString("hex")}-im-bot`;
      const { finalAccountId, filePath } = saveAccount(accountId, token, baseUrl, userId ?? undefined);
      state.phase = "done";
      state.accountId = finalAccountId;
      state.userId = userId ?? "";
      state.message = `登录成功！账号已保存到 ${filePath}`;
      if (pollTimer) clearInterval(pollTimer);
      return;
    } else if (status.status === "expired") {
      qrRefreshCount++;
      if (qrRefreshCount > 3) {
        state.phase = "error";
        state.message = "二维码已过期 3 次，请关闭页面后重新运行。";
        if (pollTimer) clearInterval(pollTimer);
        return;
      }
      state.message = `二维码已过期，正在刷新… (${qrRefreshCount}/3)`;
      await refreshQR();
    }
  } catch (err) {
    state.phase = "error";
    state.message = `轮询失败: ${err.message}`;
    if (pollTimer) clearInterval(pollTimer);
  }
}

const HTML = `<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>微信 ClawBot 扫码登录</title>
  <style>
    * { box-sizing: border-box; }
    body {
      margin: 0; min-height: 100vh; display: flex; align-items: center; justify-content: center;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      background: #0b141a; color: #e9edef;
    }
    .card {
      width: min(420px, 92vw); padding: 32px 28px; border-radius: 16px;
      background: #111b21; box-shadow: 0 12px 40px rgba(0,0,0,.35); text-align: center;
    }
    h1 { margin: 0 0 8px; font-size: 1.35rem; font-weight: 600; }
    .hint { margin: 0 0 24px; color: #8696a0; font-size: 0.95rem; line-height: 1.5; }
    #qr-wrap {
      min-height: 280px; display: flex; align-items: center; justify-content: center;
      background: #fff; border-radius: 12px; padding: 16px; margin-bottom: 20px;
    }
    #qr-wrap img { width: 280px; height: 280px; display: block; }
    .status { font-size: 1rem; line-height: 1.6; min-height: 3em; }
    .status.done { color: #25d366; }
    .status.error { color: #ea4335; }
    .status.scanned { color: #53bdeb; }
    .footer { margin-top: 16px; color: #667781; font-size: 0.8rem; }
  </style>
</head>
<body>
  <div class="card">
    <h1>微信 ClawBot 登录</h1>
    <p class="hint">请使用微信扫描下方二维码完成 ClawBot 绑定（非个人微信号登录）</p>
    <div id="qr-wrap"><img src="/qr.png" alt="微信登录二维码" width="280" height="280" /></div>
    <div id="status" class="status">正在获取二维码…</div>
    <p class="footer">登录完成后可关闭此页面 · 验证: npx weixin-mcp status</p>
  </div>
  <script>
    const statusEl = document.getElementById("status");
    const qrImg = document.querySelector("#qr-wrap img");
    let qrVersion = 0;

    async function tick() {
      try {
        const res = await fetch("/api/state");
        const data = await res.json();
        statusEl.textContent = data.message || "";
        statusEl.className = "status " + (data.phase || "");
        if (data.qrVersion && data.qrVersion !== qrVersion) {
          qrVersion = data.qrVersion;
          qrImg.src = "/qr.png?v=" + qrVersion;
        }
        if (data.phase === "done" || data.phase === "error") clearInterval(timer);
      } catch (e) {
        statusEl.textContent = "无法连接本地服务";
        statusEl.className = "status error";
      }
    }
    const timer = setInterval(tick, 1500);
    tick();
  </script>
</body>
</html>`;

let qrVersion = 0;

const server = http.createServer((req, res) => {
  const url = new URL(req.url || "/", `http://127.0.0.1:${PORT}`);
  if (url.pathname === "/" || url.pathname === "/index.html") {
    res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
    res.end(HTML);
    return;
  }
  if (url.pathname === "/qr.png") {
    if (!currentQrPng) {
      res.writeHead(503);
      res.end("QR not ready");
      return;
    }
    res.writeHead(200, { "Content-Type": "image/png", "Cache-Control": "no-store" });
    res.end(currentQrPng);
    return;
  }
  if (url.pathname === "/api/state") {
    res.writeHead(200, { "Content-Type": "application/json; charset=utf-8" });
    res.end(JSON.stringify({ ...state, qrVersion }));
    return;
  }
  res.writeHead(404);
  res.end("Not found");
});

async function main() {
  try {
    await refreshQR();
    pollTimer = setInterval(pollLoop, 2000);
    server.listen(PORT, "127.0.0.1", () => {
      const url = `http://localhost:${PORT}`;
      console.log(`\n🔐 微信扫码登录页面已启动: ${url}`);
      console.log("   用浏览器打开上述地址，微信扫码后确认即可。\n");
    });
  } catch (err) {
    console.error("启动失败:", err);
    process.exit(1);
  }
}

main();
