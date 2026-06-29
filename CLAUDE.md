# CLAUDE.md — Sunsets AI

This file contains permanent engineering rules for every Claude session working in this repository.
Read this file, then read `docs/PROJECT_STATUS.md`, before touching any other file.

---

## Before Any Work

1. Read `docs/PROJECT_STATUS.md` to understand the current milestone and the next approved task.
2. Read the relevant documentation in `docs/` for the area you are about to change.
3. Do not begin work that is not part of the current approved milestone.
4. Stop after each milestone and wait for explicit human approval before proceeding.

---

## Milestone Discipline

- Work on **one approved milestone at a time**.
- Keep changes **small and independently testable**.
- After completing a milestone, update `docs/PROJECT_STATUS.md` and stop.
- Do not speculatively implement future milestones.
- Never bundle milestone work together into a single large change.

---

## iOS and Apple Platform Rules

- Do **not** use private iOS APIs.
- Do **not** use screen scraping, overlay windows, or Accessibility API abuse to read conversation content.
- Do **not** monitor the pasteboard or keystrokes in the background.
- Do **not** send messages automatically — all text insertion requires explicit user action.
- Do **not** modify signing, bundle identifiers, entitlements, App Groups, or provisioning profiles without prior explanation and written approval from Nox.
- Always use `textDocumentProxy.insertText()` for text insertion; never simulate key events.
- The keyboard extension must not exceed iOS memory limits (~50 MB soft cap for keyboard extensions).

---

## Security Rules

- **Never** expose API keys, secrets, or tokens in iOS application code, Swift files, plists, or committed files.
- All Anthropic API calls must be made from the backend; the iOS app must never call the Anthropic API directly.
- Minimize personal data stored in the App Group cache.
- Do not log customer messages or full conversation content.
- Do not store complete conversation history by default.

---

## Git Rules

- Do **not** run destructive Git commands (`git reset --hard`, `git push --force`, `git clean -fd`, etc.) without explicit instruction.
- Do not create branches, merge, or tag without explicit instruction.
- Do not commit on behalf of the user unless explicitly asked.

---

## File and Configuration Rules

- The App Group identifier is `group.com.zircondata.sunsetsai`. Do not change it without approval.
- The main application bundle identifier is `com.zircondata.sunsetsproperties`. Do not change it without approval.
- The keyboard extension bundle identifier is `com.zircondata.sunsetsproperties.keyboard`. Do not change it without approval.
- Do not modify `*.xcodeproj`, `*.xcworkspace`, entitlements files, or `Info.plist` signing fields without prior explanation and approval.
- Do not add, remove, or upgrade Swift Package Manager dependencies without explaining the reason first.

---

## Documentation Rules

- Update `docs/PROJECT_STATUS.md` after completing each milestone.
- Record every significant architectural decision in `docs/DECISIONS.md`.
- If a decision from any doc file is changed, update that file immediately.

---

## What Claude Must Never Do

| Rule | Reason |
|------|--------|
| Send messages automatically | Privacy, user autonomy |
| Read clipboard in background | iOS policy, user trust |
| Use private APIs | App Store rejection |
| Embed API keys in app | Security |
| Modify Apple Developer settings | Cannot be undone without human intervention |
| Work across multiple milestones at once | Prevents untestable large diffs |
| Skip human approval between milestones | Engineering discipline |

---

## Reference

- Product specification: `docs/PRODUCT_SPEC.md`
- Architecture: `docs/ARCHITECTURE.md`
- Property schema: `docs/PROPERTY_SCHEMA.md`
- Milestones: `docs/MILESTONES.md`
- Current status: `docs/PROJECT_STATUS.md`
- Decisions log: `docs/DECISIONS.md`
- API contracts: `docs/API_CONTRACTS.md`
- Security: `docs/SECURITY_AND_PRIVACY.md`
- Testing: `docs/TESTING.md`
