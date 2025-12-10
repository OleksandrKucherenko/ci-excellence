#!/usr/bin/env bun
/**
 * Telegram notification utility with thread support
 *
 * Supports:
 * - Thread-based conversations (reply to previous messages)
 * - Message formatting (Markdown, HTML)
 * - Notification types with emojis
 * - Persistent thread context via file storage
 *
 * Usage:
 *   bun scripts/notify/telegram.ts --title "Build Started" --body "Running tests..."
 *   bun scripts/notify/telegram.ts --body "Tests passed" --type success --thread
 */

import type {
  NotificationConfig,
  MessageOptions,
  TelegramResponse,
  ThreadContext,
  NotificationType,
} from "./types.ts";
import { join } from "path";
import { mkdir, exists, readFile, writeFile } from "fs/promises";

export class TelegramNotifier {
  private config: NotificationConfig;
  private baseUrl: string;
  private threadContextPath: string;

  constructor(config: NotificationConfig) {
    this.config = config;
    this.baseUrl = `https://api.telegram.org/bot${config.botToken}`;
    this.threadContextPath = join(
      process.env.HOME || "/tmp",
      ".cache/ci-notify/thread-context.json"
    );
  }

  /**
   * Send a notification message
   */
  async send(options: MessageOptions): Promise<number | null> {
    const text = this.formatMessage(options);
    const replyToMessageId =
      options.replyToMessageId || (await this.getLastMessageId());

    const payload: Record<string, any> = {
      chat_id: this.config.chatId,
      text,
      parse_mode: options.parseMode || "Markdown",
      disable_web_page_preview: options.disablePreview ?? true,
    };

    // Add thread support
    if (this.config.threadId) {
      payload.message_thread_id = this.config.threadId;
    }

    // Add reply for conversation threading
    if (replyToMessageId) {
      payload.reply_to_message_id = replyToMessageId;
    }

    try {
      const response = await fetch(`${this.baseUrl}/sendMessage`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });

      // Check if response is OK
      if (!response.ok) {
        const text = await response.text();
        console.error(
          `HTTP error ${response.status}: ${response.statusText}\nResponse: ${text}`
        );
        return null;
      }

      // Try to parse JSON
      const contentType = response.headers.get("content-type");
      if (!contentType?.includes("application/json")) {
        const text = await response.text();
        console.error(
          `Unexpected content type: ${contentType}\nResponse: ${text}`
        );
        return null;
      }

      const data = (await response.json()) as TelegramResponse;

      if (!data.ok) {
        console.error(
          `Telegram API error: ${data.description} (code: ${data.error_code})`
        );
        return null;
      }

      const messageId = data.result?.message_id;
      if (messageId) {
        await this.saveMessageId(messageId);
      }

      return messageId || null;
    } catch (error) {
      console.error("Failed to send notification:", error);
      return null;
    }
  }

  /**
   * Start a new thread (clear previous context)
   */
  async startNewThread(): Promise<void> {
    await this.clearThreadContext();
  }

  /**
   * Format message with title and type emoji
   */
  private formatMessage(options: MessageOptions): string {
    const emoji = this.getTypeEmoji(options.type || "info");
    const parts: string[] = [];

    if (options.title) {
      parts.push(`${emoji} *${options.title}*`);
      parts.push("");
    }

    parts.push(options.body);

    return parts.join("\n");
  }

  /**
   * Get emoji for notification type
   */
  private getTypeEmoji(type: NotificationType): string {
    const emojis: Record<NotificationType, string> = {
      info: "ℹ️",
      success: "✅",
      warning: "⚠️",
      failure: "❌",
    };
    return emojis[type] || emojis.info;
  }

  /**
   * Get last message ID for threading
   */
  private async getLastMessageId(): Promise<number | undefined> {
    try {
      const contextExists = await exists(this.threadContextPath);
      if (!contextExists) {
        return undefined;
      }

      const content = await readFile(this.threadContextPath, "utf-8");
      const context = JSON.parse(content) as ThreadContext;
      return context.lastMessageId;
    } catch {
      return undefined;
    }
  }

  /**
   * Save message ID for threading
   */
  private async saveMessageId(messageId: number): Promise<void> {
    try {
      const dir = join(process.env.HOME || "/tmp", ".cache/ci-notify");
      await mkdir(dir, { recursive: true });

      const context: ThreadContext = {
        lastMessageId: messageId,
        threadId: this.config.threadId,
      };

      await writeFile(
        this.threadContextPath,
        JSON.stringify(context, null, 2),
        "utf-8"
      );
    } catch (error) {
      console.warn("Failed to save thread context:", error);
    }
  }

  /**
   * Clear thread context (start fresh)
   */
  private async clearThreadContext(): Promise<void> {
    try {
      const contextExists = await exists(this.threadContextPath);
      if (contextExists) {
        await Bun.write(this.threadContextPath, JSON.stringify({}, null, 2));
      }
    } catch (error) {
      console.warn("Failed to clear thread context:", error);
    }
  }
}

/**
 * CLI Entry Point
 */
async function main() {
  const args = process.argv.slice(2);

  // Parse CLI arguments
  const getArg = (flag: string): string | undefined => {
    const index = args.indexOf(flag);
    return index !== -1 && args[index + 1] ? args[index + 1] : undefined;
  };

  const hasFlag = (flag: string): boolean => args.includes(flag);

  // Get configuration from environment
  const botToken = process.env.TELEGRAM_BOT_TOKEN || getArg("--token");
  const chatId = process.env.TELEGRAM_CHAT_ID || getArg("--chat-id");

  if (!botToken || !chatId) {
    console.error(`
Usage: bun scripts/notify/telegram.ts [OPTIONS]

Required (via env or args):
  --token, TELEGRAM_BOT_TOKEN      Telegram bot token
  --chat-id, TELEGRAM_CHAT_ID      Telegram chat ID

Options:
  --title <text>                    Message title
  --body <text>                     Message body (required)
  --type <type>                     Notification type: info|success|warning|failure
  --thread                          Continue previous thread (reply to last message)
  --new-thread                      Start a new thread (clear context)
  --parse-mode <mode>               Parse mode: Markdown|HTML|MarkdownV2
  --help                            Show this help

Examples:
  # Start a new build notification thread
  bun scripts/notify/telegram.ts \\
    --title "Build #123 Started" \\
    --body "Running CI pipeline..." \\
    --type info

  # Continue the thread with updates
  bun scripts/notify/telegram.ts \\
    --body "Tests: 50% complete" \\
    --thread

  bun scripts/notify/telegram.ts \\
    --body "Tests completed ✅" \\
    --type success \\
    --thread

  # Start a fresh thread
  bun scripts/notify/telegram.ts \\
    --new-thread \\
    --title "Build #124 Started" \\
    --body "New build started"
`);
    process.exit(1);
  }

  if (hasFlag("--help")) {
    console.log("See usage above");
    process.exit(0);
  }

  const body = getArg("--body");
  if (!body) {
    console.error("Error: --body is required");
    process.exit(1);
  }

  const config: NotificationConfig = {
    botToken,
    chatId,
  };

  const notifier = new TelegramNotifier(config);

  // Start new thread if requested
  if (hasFlag("--new-thread")) {
    await notifier.startNewThread();
  }

  const options: MessageOptions = {
    title: getArg("--title"),
    body,
    type: (getArg("--type") as NotificationType) || "info",
    parseMode: (getArg("--parse-mode") as any) || "Markdown",
  };

  // Send notification
  const messageId = await notifier.send(options);

  if (messageId) {
    console.log(`Message sent successfully (ID: ${messageId})`);
    process.exit(0);
  } else {
    console.error("Failed to send message");
    process.exit(1);
  }
}

// Run CLI if executed directly
if (import.meta.main) {
  main();
}

export default TelegramNotifier;
