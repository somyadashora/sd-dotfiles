;; extends

; aerial's bundled SystemVerilog query lists modules/instances/interfaces/
; packages/generate/class/function/task but NOT procedural always blocks, so a
; named `always_comb begin : my_logic` never shows in the outline (:AerialToggle
; / <leader>oo). Add it here.
;
; ";; extends" MERGES this with the bundled aerial query rather than replacing it
; (aerial loads via vim.treesitter.query.get(lang,"aerial"), same mechanism as
; the context query). Kind matters: aerial's default `filter_kind` only shows
; Class/Constructor/Enum/Function/Interface/Module/Method/Struct — a kind outside
; that set is captured but hidden, so always blocks are tagged "Function".
;
; The block label is the `: my_logic` after begin. The leading "." anchor pins
; @name to the FIRST identifier (the opening label), so a closing `end : my_logic`
; label can't produce a duplicate outline entry. Path always_construct ->
; statement -> statement_item -> seq_block is from the gmlarumbe grammar.
(always_construct
  (statement
    (statement_item
      (seq_block
        . (simple_identifier) @name)))
  (#set! "kind" "Function")) @type
