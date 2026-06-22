-- `beg` — begin .. end block (optional `: label`).
return {
  s("beg", fmt([[
begin {label}
end
]], {
    label = i(0, ": "),
  })),
}
