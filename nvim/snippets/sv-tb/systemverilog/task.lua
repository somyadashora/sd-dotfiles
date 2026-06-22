-- `task` — task skeleton with mirrored end label.
return {
  s("task", fmt([[
task {name}({args});
  {body}
endtask : {name2}
]], {
    name = i(1),
    args = i(2),
    body = i(0),
    name2 = rep(1),
  })),
}
