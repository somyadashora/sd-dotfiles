-- `tstruct` — typedef packed struct.
return {
  s("tstruct", fmt([[
typedef struct packed {{
  {fields}
}} {name};
]], {
    fields = i(1, "logic [7:0] data;"),
    name = i(2, "my_struct_t"),
  })),
}
