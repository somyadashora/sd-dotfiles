-- Version / build-id for SD-NVIM.
--
-- ~/.config/nvim is symlinked into the dotfiles repo (see install.sh), so a real
-- git checkout is present at runtime — we derive everything from `git` at the
-- config dir rather than baking a version file. The query runs once, lazily
-- (first M.info() call, off the startup path), and is cached.
--
-- Surfaced two ways for bug reports:
--   • the dashboard footer shows the one-line M.summary()
--   • :SDVersion echoes version + build id + nvim version (copy this into reports)
--
-- `git describe --tags --always --dirty` is the single source of truth:
--   v1.2.0                    exact tag, clean tree
--   v1.2.0-4-g806b334         4 commits past the tag (short hash baked in)
--   v1.2.0-4-g806b334-dirty   …with uncommitted local changes
--   806b334(-dirty)           no tags yet — falls back to the short hash

local M = {}
local cache

local function git(...)
  local dir = vim.fn.stdpath("config")
  local out = vim.fn.systemlist({ "git", "-C", dir, ... })
  if vim.v.shell_error ~= 0 or not out[1] or out[1] == "" then
    return nil
  end
  return vim.trim(out[1])
end

-- Cached { version, build, dirty }. version/build are "unknown" if git is absent
-- or the config dir isn't a checkout (e.g. files copied rather than symlinked).
function M.info()
  if cache then
    return cache
  end
  local version = git("describe", "--tags", "--always", "--dirty") or "unknown"
  local build = git("rev-parse", "--short", "HEAD") or "unknown"
  cache = {
    version = version,
    build = build,
    dirty = version:match("%-dirty$") ~= nil,
  }
  return cache
end

-- One-liner for the dashboard footer. When there's no tag the describe output IS
-- the hash, so we drop the redundant "build" half.
function M.summary()
  local i = M.info()
  if i.version == i.build or i.version == i.build .. "-dirty" then
    return "SD-NVIM build " .. i.version
  end
  return string.format("SD-NVIM %s · build %s", i.version, i.build)
end

-- :SDVersion — print the full identity for a bug report. Always registered (this
-- module is required from somya.core); the git query is still deferred to here.
vim.api.nvim_create_user_command("SDVersion", function()
  local i = M.info()
  local v = vim.version()
  local lines = {
    { "SD-NVIM " .. i.version, "Title" },
    { "  build id : " .. i.build .. (i.dirty and "  (local changes)" or ""), "Comment" },
    { string.format("  neovim   : %d.%d.%d", v.major, v.minor, v.patch), "Comment" },
  }
  vim.api.nvim_echo(lines, true, {})
end, { desc = "Show SD-NVIM version + build id (for bug reports)" })

return M
