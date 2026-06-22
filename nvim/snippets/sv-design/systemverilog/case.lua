-- `case` — case statement.
return {
  s("case", fmt([[
case ({sel})

  default : {def};
endcase
]], {
    sel = i(1, "/* switch */"),
    def = i(0, "/* default */"),
  })),
}
