-- `function` — function skeleton with mirrored end label.
return {
  s("function", fmt([[
function {ret} {name}({args});
  {body}
endfunction : {name2}
]], {
    ret = i(1, "void"),
    name = i(2),
    args = i(3),
    body = i(0),
    name2 = rep(2),
  })),
}
