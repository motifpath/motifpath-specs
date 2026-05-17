# Git Skill — Changelog

All changes to the MotifPath git workflow skill are recorded here.
Engineers should read this before re-running `install.sh`.

---

## [1.0.0] — 2026-05-17

### Added
- Initial release of the MotifPath git workflow skill
- Conventional Commits enforcement with MotifPath-specific types and scopes
- Branch naming with mandatory task codes: `type/CODE-NNN/short-description`
- Two-level protected branch model: `main` (production) and `dev` (integration)
- Hotfix flow — branches from `main` directly, automated sync back to `dev`
  via the `sync-main-to-dev` GitHub Actions workflow
- Release PR template (dev → main) with rollback plan requirement
- Task code policy — every branch must reference a backlog item
- Atomic commit discipline — flags mixed concerns
- SDD gate check — prompts spec verification before feature branch creation
- PR description template with MotifPath checklist
- Anti-pattern detection (WIP commits, direct commits to protected branches,
  missing task codes, vague messages, ignored dev sync PRs)
- Generated file commit guidance (codegen commits must be separate)
- Code review delegation — directs to tech-stack-specific review skills

