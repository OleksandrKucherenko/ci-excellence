/**
 * Notification types and interfaces
 */

export type NotificationType = "info" | "success" | "warning" | "failure";

export interface NotificationConfig {
  botToken: string;
  chatId: string;
  threadId?: number; // For topic/thread support
}

export interface MessageOptions {
  title?: string;
  body: string;
  type?: NotificationType;
  parseMode?: "Markdown" | "HTML" | "MarkdownV2";
  disablePreview?: boolean;
  replyToMessageId?: number; // For threading/replies
}

export interface TelegramResponse {
  ok: boolean;
  result?: {
    message_id: number;
    chat: {
      id: number;
      type: string;
    };
    date: number;
    text?: string;
  };
  description?: string;
  error_code?: number;
}

export interface ThreadContext {
  threadId?: number;
  lastMessageId?: number;
}
