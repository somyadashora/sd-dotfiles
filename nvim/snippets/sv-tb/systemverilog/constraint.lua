-- `constraint` — constraint block ({{ }} are escaped literal braces in fmt).
return {
  s("constraint", fmt([[
constraint {name} {{
  {body}
}}
]], {
    name = i(1, "c"),
    body = i(0),
  })),
}
