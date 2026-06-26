-- Filetype detection for languages Neovim doesn't map out of the box.

vim.filetype.add({
  extension = {
    -- EDA constraint / command files are all Tcl dialects, so mapping them to
    -- the `tcl` filetype gives them tcl syntax + indent AND the tcl treesitter
    -- parser (installed in plugins/treesitter.lua).
    ["do"] = "tcl", -- ModelSim / QuestaSim simulator macro scripts
    sdc    = "tcl", -- Synopsys Design Constraints (timing)
    xdc    = "tcl", -- Xilinx / Vivado Design Constraints
    upf    = "tcl", -- Unified Power Format (low-power intent)

    -- SystemRDL register description language. No treesitter grammar or bundled
    -- Vim syntax exists yet, so this only gives the buffer a meaningful filetype
    -- (for the statusline / a future PeakRDL LSP); highlighting stays plain.
    rdl    = "systemrdl",
  },
})
