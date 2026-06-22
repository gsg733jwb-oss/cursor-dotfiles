#!/usr/bin/env node
/**
 * 微信消息监听器：轮询 weixin-mcp，仅有新消息时才启动 Cursor Agent。
 * Agent 只生成回复文本，由本脚本通过 weixin-mcp 发送（避免 headless Agent 无法调 MCP）。
 */
import { spawn, execFile } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { promisify } from "node:util";
import os from "node:os";

const execFileAsync = promisify(execFile);

const HOME = os.homedir();
const DATA_DIR = path.join(HOME, ".weixin-mcp");
const LOG_FILE = path.join(DATA_DIR, "watcher.log");
const LOCK_FILE = path.join(DATA_DIR, "watcher-agent.lock");
const CONFIG_FILE = path.join(DATA_DIR, "watcher.config.json");

const DEFAULT_CONFIG = {
  pollIntervalSec: 5,
  replyMode: "agent", // "agent" | "echo"
  defaultRecipient: "o9cq80wMQuHgYT-RF5ZP",
};

function loadConfig() {
  try {
    return { ...DEFAULT_CONFIG, ...JSON.parse(fs.readFileSync(CONFIG_FILE, "utf-8")) };
  } catch {
    return { ...DEFAULT_CONFIG };
  }
}

function log(...args) {
  const line = `[${new Date().toISOString()}] ${args.join(" ")}\n`;
  fs.mkdirSync(DATA_DIR, { recursive: true });
  fs.appendFileSync(LOG_FILE, line);
  process.stdout.write(line);
}

async function runWeixinPoll() {
  const { stdout } = await execFileAsync("npx", ["-y", "weixin-mcp", "poll"], {
    cwd: HOME,
    env: process.env,
    maxBuffer: 2 * 1024 * 1024,
    shell: process.platform === "win32",
  });
  return stdout.trim();
}

function parseMessages(output) {
  if (!output || /No new messages\.?/i.test(output)) return [];
  const messages = [];
  for (const line of output.split(/\r?\n/)) {
    const m = line.match(/^←\s+([^:]+):\s*(.+)$/);
    if (m) messages.push({ from: m[1].trim(), text: m[2].trim() });
  }
  return messages;
}

function findVersionedAgent() {
  const isWin = process.platform === "win32";
  const versionsDir = isWin
    ? path.join(process.env.LOCALAPPDATA || "", "cursor-agent", "versions")
    : path.join(HOME, ".local", "share", "cursor-agent", "versions");
  if (!fs.existsSync(versionsDir)) return null;
  const binName = isWin ? "cursor-agent.cmd" : "cursor-agent";
  const versions = fs
    .readdirSync(versionsDir)
    .filter((name) => fs.existsSync(path.join(versionsDir, name, binName)))
    .sort()
    .reverse();
  if (versions.length === 0) return null;
  return path.join(versionsDir, versions[0], binName);
}

async function commandExists(cmd) {
  try {
    if (cmd.includes(path.sep) || cmd.includes("/")) return fs.existsSync(cmd);
    const which = process.platform === "win32" ? "where" : "which";
    await execFileAsync(which, [cmd], { shell: process.platform === "win32" });
    return true;
  } catch {
    return false;
  }
}

async function resolveAgentCommand() {
  const isWin = process.platform === "win32";
  const candidates = [
    findVersionedAgent(),
    isWin ? path.join(process.env.LOCALAPPDATA || "", "cursor-agent", "agent.cmd") : null,
    path.join(HOME, ".local", "bin", "agent"),
    path.join(HOME, ".local", "bin", "cursor-agent"),
    "agent",
    "cursor-agent",
  ].filter(Boolean);
  for (const cmd of candidates) {
    if (await commandExists(cmd)) return cmd;
  }
  return null;
}

function buildAgentPrompt(msg) {
  return [
    "用户刚才在微信发来一条消息，监听器已自动回复「收到[用户原话]」。",
    "你的任务：只输出【回答正文】发回微信。",
    "",
    "严格要求：",
    "1. 不要写「收到[」、不要重复用户原话",
    "2. 只输出针对问题的答案，纯文本",
    "3. 不要 markdown、不要代码块、不要解释你在做什么",
    "4. 答案要完整、用户可直接阅读",
    "",
    `用户微信消息：${msg.text}`,
    "",
    "请只输出回答正文：",
  ].join("\n");
}

async function sendWeixin(recipient, text, config) {
  const to = recipient || config.defaultRecipient;
  await execFileAsync(
    "npx",
    ["-y", "weixin-mcp", "send", to, text],
    { cwd: HOME, shell: process.platform === "win32", maxBuffer: 2 * 1024 * 1024 }
  );
}

async function sendAck(msg, config) {
  const ack = `收到[${msg.text}]`;
  await sendWeixin(msg.from, ack, config);
  log(`ACK 已发送（不经 Agent）-> ${ack.slice(0, 80)}`);
}

async function echoReply(messages, config) {
  for (const msg of messages) {
    await sendAck(msg, config);
  }
}

function extractReplyText(agentOutput) {
  let text = agentOutput.trim();
  const codeMatch = text.match(/```(?:\w*\n)?([\s\S]*?)```/);
  if (codeMatch) text = codeMatch[1].trim();
  // 去掉 Agent 误写的「收到[...]」
  text = text.replace(/^收到\[[^\]]*\]\s*/m, "").trim();
  return text;
}

function isAgentRunning() {
  try {
    const pid = Number(fs.readFileSync(LOCK_FILE, "utf-8").trim());
    if (!pid) return false;
    process.kill(pid, 0);
    return true;
  } catch {
    return false;
  }
}

async function launchAgentAndGetReply(msg) {
  const agentCmd = await resolveAgentCommand();
  if (!agentCmd) throw new Error("未找到 agent CLI");

  const args = ["-p", "-f", "--trust", "--output-format", "text", buildAgentPrompt(msg)];

  log(`启动 Agent 生成回复: ${agentCmd}`);
  const child = spawn(agentCmd, args, {
    cwd: HOME,
    env: process.env,
    stdio: ["ignore", "pipe", "pipe"],
    shell: process.platform === "win32",
  });

  fs.writeFileSync(LOCK_FILE, String(child.pid));
  let stdout = "";
  let stderr = "";
  child.stdout?.on("data", (d) => {
    stdout += d.toString();
  });
  child.stderr?.on("data", (d) => {
    stderr += d.toString();
  });

  const code = await new Promise((resolve, reject) => {
    child.on("exit", resolve);
    child.on("error", reject);
  });

  try {
    fs.unlinkSync(LOCK_FILE);
  } catch {}

  if (stderr.trim()) log("AGENT ERR:", stderr.trim().slice(0, 500));
  if (code !== 0) throw new Error(`Agent 退出码 ${code}`);

  const reply = extractReplyText(stdout);
  if (!reply) {
    throw new Error(`Agent 输出为空: ${stdout.slice(0, 200)}`);
  }
  return reply;
}

async function agentReply(messages, config) {
  for (const msg of messages) {
    // 阶段1：立即确认收到（不经 Agent，不耗 token）
    await sendAck(msg, config);

    // 阶段2：Agent 生成答案，再发第二条消息
    try {
      const answer = await launchAgentAndGetReply(msg);
      await sendWeixin(msg.from, answer, config);
      log(`ANSWER 已发送 -> ${answer.slice(0, 100).replace(/\n/g, " ")}`);
    } catch (err) {
      log(`AGENT 回答失败: ${err.message}`);
    }
  }
}

async function handleMessages(messages, config) {
  if (messages.length === 0) return;
  log(`发现 ${messages.length} 条新消息`);

  if (config.replyMode === "echo") {
    await echoReply(messages, config);
    return;
  }

  if (isAgentRunning()) {
    // Agent 忙时仍先发 ACK，答案等下轮或当前 Agent 结束后再处理
    for (const msg of messages) {
      await sendAck(msg, config);
    }
    log("Agent 忙碌，已发 ACK，答案稍后");
    return;
  }

  await agentReply(messages, config);
}

async function main() {
  const config = loadConfig();
  fs.mkdirSync(DATA_DIR, { recursive: true });
  log("微信监听器启动 v3（ACK 即时 + Agent 只答问题）");
  log(`轮询 ${config.pollIntervalSec}s，模式=${config.replyMode}`);

  const agentCmd = await resolveAgentCommand();
  if (agentCmd) log(`Agent CLI: ${agentCmd}`);
  else log("警告: 无 agent CLI，将使用 echo");

  while (true) {
    try {
      const output = await runWeixinPoll();
      await handleMessages(parseMessages(output), config);
    } catch (err) {
      log("轮询错误:", err.message);
    }
    await new Promise((r) => setTimeout(r, config.pollIntervalSec * 1000));
  }
}

main().catch((err) => {
  log("致命错误:", err.message);
  process.exit(1);
});
