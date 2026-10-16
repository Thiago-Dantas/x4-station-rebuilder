# Workflow: Project setup (Phase 0)

Status: **in progress** (started 2026-10-15)

Goal: project skeleton (CLAUDE.md, docs/, tasks/) and a first roadmap for the mod, using what the sibling project `..\x4-station-designer\` already learned about X4.

## Steps
- [x] Inspect the workspace: empty git repo on `main`, no commits, remote `github.com/Thiago-Dantas/x4-station-rebuilder` (private)
- [x] Set repo-local `user.email` = dant12@gmail.com (the global config holds a work email)
- [x] Read the designer's CLAUDE.md, docs and roadmap for reusable knowledge (paths, archives, plan format, plan APIs, working rules)
- [x] Check the game's script schema (`libraries/common.xsd`, extracted by the designer) for hooks the mod needs: build events, dock events, workforce actions (results in [docs/x4-modding.md](../docs/x4-modding.md))
- [x] Write `CLAUDE.md`
- [x] Write `docs/goals.md`, `docs/decisions.md`, `docs/x4-modding.md`
- [x] Write `tasks/roadmap.md` and `tasks/workflow-phase1-research.md`
- [x] `.gitignore` (extracted game files never get committed)
- [x] User review of the roadmap and the open decisions: OD-1 … OD-7 decided (D-4 … D-10); new open questions OD-8 (build storage full), OD-9 (workforce leave rate)
- [x] `LICENSE` (MIT, copied from the designer, D-10)
- [ ] First commit (when the user asks)

## Sub-agents
None.
