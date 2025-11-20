#!/usr/bin/env bun
/**
 * Example: CI Pipeline Notifications with Thread Conversations
 *
 * This example shows how to use thread-based notifications
 * to track a CI pipeline build from start to finish.
 *
 * Usage:
 *   export TELEGRAM_BOT_TOKEN="your_token"
 *   export TELEGRAM_CHAT_ID="your_chat_id"
 *   bun scripts/notify/example-ci-pipeline.ts
 */

import TelegramNotifier from "./telegram.ts";
import type { NotificationConfig } from "./types.ts";

async function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function simulateCIPipeline() {
  const config: NotificationConfig = {
    botToken: process.env.TELEGRAM_BOT_TOKEN!,
    chatId: process.env.TELEGRAM_CHAT_ID!,
  };

  if (!config.botToken || !config.chatId) {
    console.error("Error: TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID are required");
    process.exit(1);
  }

  const notifier = new TelegramNotifier(config);

  const buildNumber = Date.now().toString().slice(-4);
  const branch = "main";
  const commit = "a1b2c3d";

  console.log("Starting simulated CI pipeline...\n");

  // Start new thread for this build
  await notifier.startNewThread();

  // 1. Build started
  console.log("📢 Sending build start notification...");
  await notifier.send({
    title: `Build #${buildNumber} Started`,
    body: `
**Branch**: \`${branch}\`
**Commit**: \`${commit}\`
**Triggered by**: CI Pipeline

Starting build process...
    `.trim(),
    type: "info",
  });

  await sleep(2000);

  // 2. Running tests (continues thread)
  console.log("🧪 Sending test start update...");
  await notifier.send({
    body: `
**Stage**: Running Tests

- Unit tests: in progress
- Integration tests: pending
- E2E tests: pending
    `.trim(),
    type: "info",
  });

  await sleep(2000);

  // 3. Tests progress
  console.log("📊 Sending test progress...");
  await notifier.send({
    body: `
**Stage**: Running Tests

- Unit tests: ✅ 150/150 passed
- Integration tests: in progress
- E2E tests: pending
    `.trim(),
    type: "info",
  });

  await sleep(2000);

  // 4. All tests passed
  console.log("✅ Sending test completion...");
  await notifier.send({
    body: `
**Stage**: Tests Completed

- Unit tests: ✅ 150/150 passed
- Integration tests: ✅ 45/45 passed
- E2E tests: ✅ 12/12 passed
- Code coverage: 87.5%
    `.trim(),
    type: "success",
  });

  await sleep(2000);

  // 5. Building artifacts
  console.log("🔨 Sending build stage update...");
  await notifier.send({
    body: `
**Stage**: Building Artifacts

- Compiling TypeScript
- Bundling assets
- Generating sourcemaps
    `.trim(),
    type: "info",
  });

  await sleep(2000);

  // 6. Final success
  console.log("🎉 Sending final success...");
  await notifier.send({
    title: `Build #${buildNumber} Successful`,
    body: `
**Duration**: 2m 15s
**Status**: All stages completed successfully

✅ Tests passed (207/207)
✅ Build artifacts generated
✅ Ready for deployment

[View Build Details](#)
    `.trim(),
    type: "success",
  });

  console.log("\n✅ Pipeline simulation complete!");
  console.log("Check your Telegram for the thread conversation.");
}

// Run if executed directly
if (import.meta.main) {
  simulateCIPipeline().catch((error) => {
    console.error("Pipeline failed:", error);
    process.exit(1);
  });
}

export default simulateCIPipeline;
