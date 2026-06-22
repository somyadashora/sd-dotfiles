-- `fork` — fork...join block; choose join / join_any / join_none.
return {
  s("fork", fmt([[
fork
  {body}
{join}
]], {
    body = i(1),
    join = c(2, { t("join"), t("join_any"), t("join_none") }),
  })),
}
