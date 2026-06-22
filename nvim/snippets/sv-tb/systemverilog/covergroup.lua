-- `covergroup` — covergroup with mirrored end label.
return {
  s("covergroup", fmt([[
covergroup {name}();
  {body}
endgroup : {name2}
]], {
    name = i(1, "cg"),
    body = i(0),
    name2 = rep(1),
  })),
}
