# ai/ — portable AI coding skills

Version-controlled skills shared with AI coding agents (Claude Code, Codex,
Gemini, and successors). They live here as the single source of truth and are
installed **per-project** by `nvim/scripts/init-ai` (aliased `init-ai`) — nothing
is installed globally into `~/.claude`.

## Skills

| Skill           | Scope                                                          |
|-----------------|---------------------------------------------------------------|
| `sd-rtl-coding` | Synthesizable SystemVerilog **coding** contract (allowed/banned constructs, reset/clock discipline, FSM/latch rules). Project-agnostic; installed as-is. |
| `sd-rtl-style`  | SystemVerilog **naming/style** conventions. A **template** — each project customizes it (snake_case vs camelCase, suffixes, prefixes). |

The split is deliberate: coding correctness is universal, but naming style
varies per project, so they are separate skills.

## Install into a project

Run at the project root:

```bash
init-ai                # install both skills under ./.claude/skills/
init-ai -d path/to/proj
init-ai --force        # overwrite existing skill files (re-pull latest)
init-ai --regen-only   # refresh sd-rtl-coding only; keep customized sd-rtl-style
```

`init-ai` copies the skills into `<project>/.claude/skills/`, which Claude Code
auto-discovers. For other tools it creates an `AGENTS.md` pointing at the skills
**only if one does not already exist** — if `AGENTS.md` or `CLAUDE.md` is already
present, it is never edited; `init-ai` prints a reference block to paste in
yourself.

After installing, **customize `sd-rtl-style/SKILL.md`** to this project's naming
convention.
</content>
