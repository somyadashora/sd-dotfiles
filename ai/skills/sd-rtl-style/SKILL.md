---
name: sd-rtl-style
description: >-
  Apply this project's SystemVerilog naming and identifier conventions when
  writing, editing, or applying review comments to RTL — signal case, port
  direction suffixes, clock/reset names, type/enum suffixes, generate and
  instance prefixes. PER-PROJECT TEMPLATE: customize the rules below to match
  this project before relying on it. Coding correctness lives in sd-rtl-coding.
---

# sd-rtl-style — SystemVerilog naming & style conventions

> **PER-PROJECT TEMPLATE — EDIT THIS FILE.**
> Naming conventions differ per project (snake_case vs camelCase, suffix sets,
> prefixes). The rules below are sensible **defaults** (lowRISC / OpenTitan
> style). Adjust them to match THIS project's house style, then delete this
> banner. If the project already documents a convention, that document wins —
> reconcile this file with it.

This skill covers **naming and identifier style only**. Synthesizable coding
rules (allowed/banned constructs, reset scheme, FSM/latch rules) live in the
separate `sd-rtl-coding` skill — apply both together.

## How to use this skill

- When **writing new RTL**, name identifiers per the conventions below.
- When **applying review comments**, change only what the comment asks; do not
  rename untouched signals or restyle unrelated lines.
- Match the surrounding file's existing convention when it conflicts with a
  default here — consistency within a file beats this template's defaults.

## Conventions (defaults — customize)

### Case
- **Signals, ports, instances, modules, files**: `lower_snake_case`.
- **Parameters, `localparam`, type/struct/enum names**: `UpperCamelCase`.
- **Enum members / macro constants**: `UPPER_SNAKE_CASE`.

### Port direction suffixes
- Input: `_i`   ·   Output: `_o`   ·   Bidirectional: `_io`.
- Active-low: append `_n` (so an active-low input is `_ni`, active-low output
  `_no`).
- Differential pair: `_p` / `_m` (or `_n`) — be consistent.

### Clock & reset
- Clock: `clk_i` (qualify multi-clock designs, e.g. `clk_axi_i`).
- Reset: `rst_ni` (active-low, matching the sd-rtl-coding reset scheme).

### Sequential signal pairs
- Flop output / input pair: `foo_q` (registered) and `foo_d` (next value).

### Types & enums
- Type/struct suffix: `_t` (e.g. `req_t`).
- Enum type suffix: `_e` (e.g. `state_e`); members share a short prefix
  (e.g. `StIdle`, `StRun`).

### Generate & instances
- Generate block labels: `g_` / `gen_` prefix (e.g. `begin : g_lane`).
- Instance names: `u_` / `i_` prefix (e.g. `u_fifo`).

### Formatting
- Indentation, alignment, and line length are owned by the formatter (verible
  flagfile / `.verible_format`), not hand-tuned. State the project's line-length
  limit here and let the formatter enforce it.
</content>
