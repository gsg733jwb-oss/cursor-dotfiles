import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { exec } from "node:child_process";

const BASE_URL = "https://ilinkai.weixin.qq.com";
const BOT_TYPE = "3";
const PORT = 8765;
const DATA_DIR =
  process.env.WEIXIN_MCP_DIR?.trim() ||
  path.join(process.env.USERPROFILE || process.env.HOME, ".weixin-mcp");
const ACCOUNTS_DIR = DATA_DIR.endsWith("accounts")
  ? DATA_DIR
  : path.join(DATA_DIR, "accounts");

let state = {
  qrcodeToken: "",
  qrcodeUrl: "",
  status: "waiting",
  message: "请用微信扫描二维码",
  qrRefreshCount: 0,
};

async function fetchQRCode() {
  const url = `${BASE_URL}/ilink/bot/get_bot_qrcode?bot_type=${BOT_TYPE}`;
  const res = await fetch(url);
  if (!res.ok) throw new Error(`QR fetch failed: ${res.status}`);
  return res.json();
}

async function pollStatus(qrcodeVal) {
  const url = `${BASE_URL}/ilink/bot/get_qrcode_status?qrcode=${encodeURIComponent(qrcodeVal)}`;
  const res = await fetch(url, { headers: { "iLink-App-ClientVersion": "1" } });
  if (!res.ok) throw new Error(`Status poll failed: ${res.status}`);
  return res.json();
}

function findAccountByUserId(userId) {
  if (!fs.existsSync(ACCOUNTS_DIR)) return null;
  for (const file of fs.readdirSync(ACCOUNTS_DIR)) {
    if (!file.endsWith(".json") || file.includes("sync") || file.includes("cursor")) continue;
    try {
      const data = JSON.parse(fs.readFileSync(path.join(ACCOUNTS_DIR, file), "utf-8"));
      if (data.userId === userId) return file.replace(".json", "");
    } catch {}
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
  const existing = fs.existsSync(filePath) ? JSON.parse(fs.readFileSync(filePath, "utf-8")) : {};
  fs.writeFileSync(
    filePath,
    JSON.stringify({ ...existing, token, baseUrl, ...(userId ? { userId } : {}), savedAt: new Date().toISOString() }, null, 2)
  );
  return { finalAccountId, filePath, userId };
}

function htmlPage() {
  const qrImg = `https://api.qrserver.com/v1/create-qr-code/?size=360x360&margin=10&data=${encodeURIComponent(state.qrcodeUrl)}`;
  const statusColor =
    state.status === "confirmed" ? "#22c55e" : state.status === "scaned" ? "#3b82f6" : state.status === "expired" ? "#f59e0b" : "#64748b";
  return `<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <meta http-equiv="refresh" content="2" />
  <title>微信 ClawBot 扫码登录</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      min-height: 100vh; display: flex; align-items: center; justify-content: center;
      background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      color: #f8fafc; padding: 24px;
    }
    .card {
      background: #fff; color: #0f172a; border-radius: 20px; padding: 40px 48px;
      text-align: center; box-shadow: 0 25px 50px rgba(0,0,0,.35); max-width: 480px; width: 100%;
    }
    h1 { font-size: 22px; margin-bottom: 8px; }
    .sub { color: #64748b; font-size: 14px; margin-bottom: 28px; }
    .qr-wrap {
      display: inline-block; padding: 16px; border: 2px solid #e2e8f0; border-radius: 16px;
      background: #fff; margin-bottom: 24px;
    }
    .qr-wrap img { display: block; width: 360px; height: 360px; }
    .status {
      font-size: 16px; font-weight: 600; color: ${statusColor}; margin-bottom: 8px;
    }
    .hint { font-size: 13px; color: #94a3b8; line-height: 1.6; }
    .success { color: #22c55e; font-size: 18px; font-weight: 700; }
  </style>
</head>
<body>
  <div class="card">
    <h1>微信 ClawBot 扫码登录</h1>
    <p class="sub">weixin-mcp · 官方接口</p>
    ${
      state.status === "confirmed"
        ? `<p class="success">✅ 登录成功！可以关闭此页面。</p><p class="hint" style="margin-top:12px">请在 Cursor 中 Reload Window 后使用 Agent 模式。</p>`
        : `<div class="qr-wrap"><img src="${qrImg}" alt="微信登录二维码" /></div>
           <p class="status">${state.message}</p>
           <p class="hint">打开微信 → 扫一扫<br/>或搜索小程序「ClawBot」</p>`
    }
  </div>
</body>
</html>`;
}

async function refreshQR() {
  const data = await fetchQRCode();
  state.qrcodeToken = data.qrcode;
  state.qrcodeUrl = data.qrcode_img_content;
  state.status = "waiting";
  state.message = "请用微信扫描二维码";
}

async function pollLoop() {
  let attempts = 0;
  await refreshQR();

  while (attempts < 120) {
    await new Promise((r) => setTimeout(r, 2000));
    attempts++;
    try {
      const result = await pollStatus(state.qrcodeToken);
      if (result.status === "scaned") {
        state.status = "scaned";
        state.message = "✓ 已扫码，请在手机上确认登录…";
      } else if (result.status === "confirmed") {
        const token = result.bot_token;
        if (!token) throw new Error("No token");
        const baseUrl = result.baseurl ?? BASE_URL;
        const userId = result.ilink_user_id ?? result.ilink_bot_id;
        const accountId =
          result.ilink_bot_id?.replace("@", "-").replace(".", "-") ?? crypto.randomBytes(6).toString("hex") + "-im-bot";
        const saved = saveAccount(accountId, token, baseUrl, userId ?? undefined);
        state.status = "confirmed";
        state.message = `登录成功！账号: ${saved.finalAccountId}`;
        console.log(`\n✅ 登录成功! 账号: ${saved.finalAccountId}`);
        console.log(`   凭证已保存: ${saved.filePath}`);
        return;
      } else if (result.status === "expired") {
        state.qrRefreshCount++;
        if (state.qrRefreshCount > 5) {
          state.status = "expired";
          state.message = "二维码多次过期，请刷新页面重试";
          return;
        }
        await refreshQR();
        state.message = "二维码已刷新，请重新扫描";
      }
    } catch (err) {
      console.error("Poll error:", err.message);
    }
  }
  state.status = "expired";
  state.message = "等待超时，请刷新页面重试";
}

const server = http.createServer((req, res) => {
  if (req.url === "/" || req.url === "/index.html") {
    res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
    res.end(htmlPage());
  } else if (req.url === "/api/status") {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify(state));
  } else {
    res.writeHead(404);
    res.end("Not found");
  }
});

server.listen(PORT, () => {
  const url = `http://localhost:${PORT}`;
  console.log(`\n🌐 二维码页面: ${url}`);
  console.log("   正在后台轮询扫码状态…\n");
  exec(`start ${url}`);
  pollLoop().catch((err) => {
    console.error("Error:", err);
    process.exit(1);
  });
});
