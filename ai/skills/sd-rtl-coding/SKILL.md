---
name: sd-rtl-coding
description: >-
  Apply when writing, editing, or applying review comments to synthesizable
  SystemVerilog (.sv/.svh/.v) RTL. Enforces a portable, lint-clean IEEE
  1800-2017 coding subset — allowed vs banned constructs, reset/clock
  discipline, FSM and latch rules. Covers coding correctness ONLY, not signal
  naming (see the sd-rtl-style skill for naming conventions).
---

# sd-rtl-coding — synthesizable SystemVerilog coding contract

A binding coding contract for **synthesizable** SystemVerilog. It governs *how*
RTL is written, not *what the signals are called* — naming/style lives in the
separate `sd-rtl-style` skill. Apply both together on RTL work.

## How to use this skill

- When **writing new RTL**, conform to every rule below.
- When **applying review comments**, change only what the comment asks. Do not
  make unrelated edits, do not reformat untouched lines, and do not "fix" things
  the comment did not mention.
- New or modified code must satisfy this contract even if surrounding legacy
  code does not. Do not propagate existing violations.
- If a review comment would require violating this contract, **stop and flag the
  conflict** instead of silently breaking a rule.
- These rules apply to synthesizable RTL only. Testbench/verification code is out
  of scope (and may use the constructs banned below).

## 1. Allowed (synthesizable subset, IEEE 1800-2017)

- `logic` for every signal — the single 4-state type for RTL.
- `always_ff @(posedge clk or negedge rst_ni)` for sequential logic.
- `always_comb` for combinational logic.
- `always_latch` **only** with an inline comment justifying why a latch (not a
  flop) is correct here — and never on a clock-crossing path.
- Packed `struct` / `union` for bundling related signals across module ports.
- `enum logic [...]` for state encodings; state the scheme (binary / one-hot) in
  a comment.
- `parameter` (overridable) and `localparam` (derived/internal) for compile-time
  constants.
- `function automatic` for combinational helpers (never a non-`automatic`
  function in synthesizable code).
- Generate blocks with **named** labels: `for (genvar i...) begin : g_name`.
- SystemVerilog Assertions: `assert property`, `cover property`, `assume
  property` (concurrent), with a clocking and disable-on-reset.
- `import` of a package into a leaf module is allowed.

## 2. Banned in synthesizable code

- `wire` and four-state net declarations — use `logic`.
- `reg` — use `logic`.
- `interface` **ports on leaf IP modules**. Leaf IP must use packed structs to
  stay tool-portable. (Top-level subsystem wrappers MAY use interfaces.)
- `force` / `release`.
- `disable fork`.
- `event` data type.
- `class` / `virtual class` (verification only).
- `mailbox`, `semaphore` (verification only).
- `$random`, `$urandom`, `$urandom_range` inside RTL (use the testbench's
  constrained-random layer, never RTL).
- Non-blocking assignment (`<=`) inside `always_comb` (`<=` belongs only in
  `always_ff`).
- Blocking assignment (`=`) to a flopped signal (`=` belongs only in
  `always_comb`).
- Implicit nets — set `` `default_nettype none `` at the top of every file (and
  `` `default_nettype wire `` is not restored mid-design).
- `casex` / `casez` — use `case ... inside` or `unique case`.
- Bare `case` without a `unique` or `priority` qualifier.
- Multiple-driver nets.
- Driving one output/signal from more than one `always_*` block.
- `defparam`.
- Behavioural delays (`#5`, `#1ns`, …) outside testbenches.

## 3. Design discipline (coding, not naming)

- **Reset scheme**: asynchronous-assert, synchronous-deassert, **active-low**
  reset. Never synchronous-active-high. Keep logic off the reset path (no gating
  the reset with data).
- **One clock per `always_ff`.** No multi-clock sequential blocks.
- **FSMs**: next-state logic in `always_comb`, state register in `always_ff`.
  Default-assign `next_state = state;` before the case.
- **No inferred latches**: in every `always_comb`, assign a default value to all
  outputs at the top (or assign on every path).
- **Width discipline**: match assignment widths; no unintended truncation or
  zero/sign-extension. Make width changes explicit.
- **CDC**: cross only through documented synchronizers (e.g. 2-flop for single
  bits, gray-coded/handshake for buses). Never let combinational logic cross a
  clock domain unsynchronized.
- **No combinational loops.**
- **Parameterize, don't hardcode**: use `parameter`/`localparam` for widths and
  constants; no magic numbers in expressions.
</content>
