# CI Script Layout

- Naming: `ci-{NN}-{purpose}.sh` where `NN` is 01–90. Prefer steps of 10; use +5 to keep paired actions (publish/verify/rollback, apply/deprecate) adjacent.
- Reports live in `scripts/ci/reports/` (pipeline summaries) to keep operational scripts focused on execution.
- Setup/build/test/notification use 10/20/30... ordering; maintenance uses 10–90 with +5 for paired deprecations.

Release ranges (space reserved for future growth):
- GitHub release (10–40): version selection, changelog/notes, asset upload, verification, rollback (45 left open for another GH release step).
- GitHub package (50–60): documentation build/publish sit here; 60 stays open for future GitHub package publish/deprecate scripts.
- Production release (65–90): npm and Docker publish/verify/rollback; keep new registries in this block.

When adding scripts, pick the next free slot in the right block, leave gaps for future related steps, and keep paired actions within +5 where possible.
