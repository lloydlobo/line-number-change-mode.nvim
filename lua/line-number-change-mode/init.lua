--- Mode short-name (map command prefix: "n", "i", "v", "x", …) or "!" for |:map!|,
--- or empty string for |:map|. "ia", "ca" or "!a" for abbreviation in Insert mode,
--- Cmdline mode, or both, respectively. See also |nvim_set_keymap()|
---
--- @alias M.ModeKind
---
--- | "R"
--- | "V"
--- | "c"
--- | "i"
--- | "n"
--- | "v"

--- @alias M.Mode table<M.ModeKind, vim.api.keyset.highlight>

--- @class M.Config
--- @field debug boolean
--- @field mode M.Mode

local M = {}

---@param opts? M.Config
function M.setup(opts)
   opts = opts or {}
   local va = vim.api
   local group = va.nvim_create_augroup("LineNumberChangeMode", {
      clear = true,
   })

   local function set_hl_for_mode(mode)
      if opts.mode[mode] ~= nil then
         va.nvim_set_hl(0, "CursorLineNr", opts.mode[mode])

         -- The statuscolumn may not repaint when switching to command mode so
         -- we force a redraw here to make sure the color updates
         if (mode == "c") then
            vim.cmd.redraw()
         end
      end
   end

   set_hl_for_mode(va.nvim_get_mode().mode)

   va.nvim_create_autocmd("ModeChanged", {
      group = group,
      desc = "Notify on every mode change",
      callback = function()
         local new_mode = vim.v.event.new_mode

         if opts.debug then
            vim.notify(new_mode, vim.log.levels.DEBUG)
         end

         set_hl_for_mode(new_mode)
      end,
   })
end

return M
