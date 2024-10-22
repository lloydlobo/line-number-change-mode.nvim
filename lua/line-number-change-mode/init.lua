local api = vim.api

local M = {}

---@alias ModeName "n" | "i" | "v" | "V" | "R" | "c" See `|:map!|` or `|:map|`
---@alias ModeEntry table<ModeName, vim.api.keyset.highlight>

---@class Config
---@field mode? ModeEntry Mapping of vim mode short-name with highlight options.
---@field debug? boolean Notify on every mode change (default: false).

-- Color palette (from Catppuccin Mocha).
local palette = {
    mantle = "#181825",
    blue = "#89b4fa",
    green = "#a6e3a1",
    maroon = "#eba0ac",
    mauve = "#cba6f7",
}

-- Default configuration.
local defaults = {
    mode = {
        n = { bg = palette.blue, fg = palette.mantle, bold = true },
        i = { bg = palette.green, fg = palette.mantle, bold = true },
        v = { bg = palette.mauve, fg = palette.mantle, bold = true },
        V = { bg = palette.mauve, fg = palette.mantle, bold = true },
        R = { bg = palette.maroon, fg = palette.mantle, bold = true },
    },
    debug = false,
}

-- Module state.
local state = {
    options = {},
}

---Set highlight for the current mode.
---@param mode ModeName
local function set_hl_for_mode(mode)
    if state.options.mode and state.options.mode[mode] then
        api.nvim_set_hl(0, "CursorLineNr", state.options.mode[mode])
        -- Force redraw for command mode to ensure color updates.
        if mode == "c" then
            vim.cmd.redraw()
        end
    end
end

---Setup the plugin.
---@param opts? Config
function M.setup(opts)
    opts = opts or {}
    vim.validate({
        ["opts.mode"] = { opts.mode, "table", true },
        ["opts.debug"] = { opts.debug, "boolean", true },
    })
    -- Merge options with defaults.
    state.options = vim.tbl_deep_extend("force", defaults, opts)

    -- Set up autocommand for mode changes.
    local group = api.nvim_create_augroup("LineNumberChangeMode", { clear = true })
    api.nvim_create_autocmd("ModeChanged", {
        group = group,
        callback = function()
            local new_mode = vim.v.event.new_mode
            if state.options.debug then
                local message = "line-number-change-mode.nvim: new_mode '" .. new_mode .. "'"
                vim.notify(message, vim.log.levels.DEBUG)
            end
            set_hl_for_mode(new_mode)
        end,
    })

    -- Set initial highlight.
    set_hl_for_mode(api.nvim_get_mode().mode)
end

return M
