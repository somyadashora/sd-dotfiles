-- `tenum` — typedef enum (state/type definition).
return {
  s("tenum", fmt([[
typedef enum logic [{width}:0] {{
  {states}
}} {name};
]], {
    width = i(1, "1"),
    states = i(2, "IDLE, RUN, DONE"),
    name = i(3, "state_e"),
  })),
}
