-- `fsm` — two-process FSM skeleton (state register + next-state/output comb).
return {
  s("fsm", fmt([[
typedef enum logic [{width}:0] {{
  {states}
}} {st_t};

{st_t2} state, next;

// State register
always_ff @(posedge {clk} or negedge {rst}) begin
  if (!{rst2})
    state <= {reset_state};
  else
    state <= next;
end

// Next-state / output logic
always_comb begin
  next = state;
  unique case (state)
    {body}
    default : next = {reset_state2};
  endcase
end
]], {
    width = i(1, "1"),
    states = i(2, "IDLE, RUN, DONE"),
    st_t = i(3, "state_e"),
    st_t2 = rep(3),
    clk = i(4, "clk"),
    rst = i(5, "rst_n"),
    rst2 = rep(5),
    reset_state = i(6, "IDLE"),
    reset_state2 = rep(6),
    body = i(0),
  })),
}
