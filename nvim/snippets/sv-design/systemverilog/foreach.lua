-- `foreach` — foreach loop over an array.
return {
  s("foreach", fmt([[
foreach ({arr}[{idx}]) begin
  {body}
end
]], {
    arr = i(1, "array"),
    idx = i(2, "i"),
    body = i(0),
  })),
}
