#!/usr/bin/env node
/**
 * weixin-mcp listener — two-phase WeChat replies.
 *
 * Phase 1: on new message → immediately send 收到[用户原话] (no Agent)
 * Phase 2: watch ~/.weixin-mcp/outbox/<id>.txt → send answer as 2nd message
 *
 * Pending questions: ~/.weixin-mcp/inbox/<id>.json
 */
import fs from "node:fs";
import path from "node:path";
import os from "node:os";
import crypto from "node:crypto";

const HOME = path.join(os.homedir(), ".weixin-mcp");
const ACCOUNTS_DIR = path.join(HOME, "accounts");
const INBOX_DIR = path.join(HOME, "inbox");
const OUTBOX_DIR = path.join(HOME, "outbox");
const LOG_FILE = path.join(HOME, "listener.log");
const BASE_URL = "https://ilinkai.weixin.qq.com";
const CHANNEL_VERSION = "1.0.2";

function log(msg) {
  const line = `[${new Date().toLocaleString()}] ${msg}\n`;
  fs.appendFileSync(LOG_FILE, line);
  process.stdout.write(line);
}

function loadAccount() {
  const files = fs
    .readdirSync(ACCOUNTS_DIR)
    .filter((f) => f.endsWith(".json") && !f.includes("sync") && !f.includes("cursor"));
  if (!files.length) throw new Error("No account. Run QR login first.");
  const accountId = process.env.WEIXIN_ACCOUNT_ID ?? files[0].replace(".json", "");
  const data = JSON.parse(fs.readFileSync(path.join(ACCOUNTS_DIR, `${accountId}.json`), "utf-8"));
  if (!data.token) throw new Error(`No token for ${accountId}`);
  return { ...data, accountId };
}

function cursorPath(accountId) {
  return path.join(ACCOUNTS_DIR, `${accountId}.cursor.json`);
}

function loadCursor(accountId) {
  try {
    return JSON.parse(fs.readFileSync(cursorPath(accountId), "utf-8")).cursor ?? "";
  } catch {
    return "";
  }
}

function saveCursor(accountId, cursor) {
  fs.writeFileSync(cursorPath(accountId), JSON.stringify({ cursor }));
}

function clientId() {
  return `weixin-mcp-${crypto.randomUUID().replace(/-/g, "").slice(0, 16)}`;
}

async function weixinRequest(endpoint, body, token, baseUrl = BASE_URL) {
  const base = baseUrl.endsWith("/") ? baseUrl : `${baseUrl}/`;
  const url = new URL(endpoint, base).toString();
  const bodyStr = JSON.stringify(body);
  const res = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Content-Length": String(Buffer.byteLength(bodyStr, "utf-8")),
      AuthorizationType: "ilink_bot_token",
      Authorization: `Bearer ${token}`,
      "X-WECHAT-UIN": crypto.randomBytes(4).toString("base64"),
    },
    body: bodyStr,
  });
  if (!res.ok) throw new Error(`Weixin API ${res.status}: ${await res.text()}`);
  return res.json();
}

async function sendText(to, text, token, baseUrl, contextToken) {
  return weixinRequest(
    "ilink/bot/sendmessage",
    {
      msg: {
        from_user_id: "",
        to_user_id: to,
        client_id: clientId(),
        message_type: 2,
        message_state: 2,
        item_list: [{ type: 1, text_item: { text } }],
        ...(contextToken ? { context_token: contextToken } : {}),
      },
      base_info: { channel_version: CHANNEL_VERSION },
    },
    token,
    baseUrl,
  );
}

async function getUpdates(token, baseUrl, cursor = "") {
  return weixinRequest(
    "ilink/bot/getupdates",
    { get_updates_buf: cursor, base_info: { channel_version: CHANNEL_VERSION } },
    token,
    baseUrl,
  );
}

function extractIncomingText(msg) {
  if (Number(msg.message_type) !== 1) return null;
  const parts = [];
  for (const item of msg.item_list ?? []) {
    if (item.type === 1 && item.text_item?.text) parts.push(item.text_item.text);
  }
  return parts.join(" ").trim() || null;
}

function ensureDirs() {
  for (const d of [INBOX_DIR, OUTBOX_DIR]) fs.mkdirSync(d, { recursive: true });
}

async function handleIncoming(msg, account) {
  const from = String(msg.from_user_id ?? "");
  const text = extractIncomingText(msg);
  if (!from || !text) return;

  const id = `${Date.now()}-${crypto.randomBytes(3).toString("hex")}`;
  const contextToken = msg.context_token ?? "";

  // Phase 1 — immediate ACK (no Agent)
  const ack = `收到[${text}]`;
  log(`ACK → ${from.slice(0, 20)}: ${ack}`);
  await sendText(from, ack, account.token, account.baseUrl ?? BASE_URL, contextToken);

  const pending = {
    id,
    from,
    text,
    contextToken,
    ackAt: new Date().toISOString(),
    answered: false,
  };
  fs.writeFileSync(path.join(INBOX_DIR, `${id}.json`), JSON.stringify(pending, null, 2));
  log(`inbox ← ${id}: ${text}`);
}

async function drainOutbox(account) {
  if (!fs.existsSync(OUTBOX_DIR)) return;
  for (const file of fs.readdirSync(OUTBOX_DIR).filter((f) => f.endsWith(".txt"))) {
    const id = file.replace(/\.txt$/, "");
    const inboxPath = path.join(INBOX_DIR, `${id}.json`);
    if (!fs.existsSync(inboxPath)) {
      fs.unlinkSync(path.join(OUTBOX_DIR, file));
      continue;
    }
    const pending = JSON.parse(fs.readFileSync(inboxPath, "utf-8"));
    if (pending.answered) {
      fs.unlinkSync(path.join(OUTBOX_DIR, file));
      continue;
    }
    const answer = fs.readFileSync(path.join(OUTBOX_DIR, file), "utf-8").trim();
    if (!answer) continue;

    log(`reply → ${pending.from.slice(0, 20)}: ${answer.slice(0, 60)}…`);
    await sendText(
      pending.from,
      answer,
      account.token,
      account.baseUrl ?? BASE_URL,
      pending.contextToken,
    );
    pending.answered = true;
    pending.answeredAt = new Date().toISOString();
    fs.writeFileSync(inboxPath, JSON.stringify(pending, null, 2));
    fs.unlinkSync(path.join(OUTBOX_DIR, file));
  }
}

async function pollOnce(account) {
  let cursor = loadCursor(account.accountId);
  const resp = await getUpdates(account.token, account.baseUrl ?? BASE_URL, cursor);
  if (resp.get_updates_buf) {
    cursor = resp.get_updates_buf;
    saveCursor(account.accountId, cursor);
  }
  for (const msg of resp.msgs ?? []) {
    await handleIncoming(msg, account);
  }
}

async function main() {
  ensureDirs();
  const account = loadAccount();
  log(`listener started (account ${account.accountId})`);
  while (true) {
    try {
      await pollOnce(account);
      await drainOutbox(account);
    } catch (err) {
      log(`error: ${err instanceof Error ? err.message : String(err)}`);
      await new Promise((r) => setTimeout(r, 3000));
    }
  }
}

main().catch((err) => {
  log(`fatal: ${err instanceof Error ? err.message : String(err)}`);
  process.exit(1);
});
