local M = {}

-- Color palette (from Catppuccin Mocha).
-- NOTE: should lazily load this
local palette = {
    mantle = "#181825",
    blue = "#89b4fa",
    green = "#a6e3a1",
    maroon = "#eba0ac",
    mauve = "#cba6f7",
}

--- @alias ModeName "n" | "i" | "no" | "t" | "v" | "V" | "R" See `|:map!|` or `|:map|`
--- @alias ModeEntry table<ModeName, vim.api.keyset.highlight>

--- @class (exact) Opts
--- @field enable boolean Toggle the plugin.
--- @field mode ModeEntry Mapping of vim mode short-name with highlight options.
--- @field ignoremode ModeName[] List of modes that are not drawn.
--- @field debug boolean Notify on every mode change (default: false).
local defaults = {
    enable = true,
    mode = {
        R = { bg = palette.maroon, fg = palette.mantle, bold = true },
        V = { bg = palette.mauve, fg = palette.mantle, bold = true },
        i = { bg = palette.green, fg = palette.mantle, bold = true },
        n = { bg = palette.blue, fg = palette.mantle, bold = true },
        no = {}, -- { bg = palette.mantle, fg = palette.green, bold = true },
        v = { bg = palette.mauve, fg = palette.mantle, bold = true },
    },
    ignoremode = {},
    debug = false,
}

--- Module state.
--- @class (exact) State
--- @field options Opts
local state = {
    --- Initialize in setup for lazy loading.
    --- @diagnostic disable-next-line: missing-fields
    options = {},
}

--- Set highlight for the current mode.
--- @param mode ModeName
local function set_hl_for_mode(mode)
    local api = vim.api
    local options = state.options
    local entries = options.mode
    if entries and entries[mode] then
        if #options.ignoremode > 0 and vim.tbl_contains(options.ignoremode, mode) then
            api.nvim_set_hl(0, "CursorLineNr", {})
        else
            api.nvim_set_hl(0, "CursorLineNr", entries[mode])
        end
        -- Force redraw for command mode to ensure color updates.
        if mode == "c" then
            vim.cmd.redraw()
        end
    end
end

--- Setup the plugin.
--- @param opts? Opts
function M.setup(opts)
    opts = opts or {}
    M._validate(opts)
    state.options = vim.tbl_deep_extend("force", {}, defaults, opts)
    if not state.options.enable then
        return -- NOTE: Does it reload if user toggles enable without reload|sourcing?
    end

    -- Set up autocommand for mode changes.
    local api = vim.api
    local group = api.nvim_create_augroup("LineNumberChangeMode", { clear = true })
    api.nvim_create_autocmd("ModeChanged", {
        group = group,
        callback = function()
            local new_mode = vim.v.event.new_mode
            if state.options.debug then
                vim.notify("line-number-change-mode.nvim: new_mode '" .. new_mode .. "'", vim.log.levels.DEBUG)
            end
            set_hl_for_mode(new_mode)
        end,
    })

    -- Set initial highlight.
    set_hl_for_mode(api.nvim_get_mode().mode)
end

--- @param opts Opts
--- @private
function M._validate(opts)
    if vim.tbl_count(opts) > vim.tbl_count(defaults) then
        vim.notify("[line-number-change-mode.nvim]: Invalid options length found during setup", vim.log.levels.ERROR)
    end
    vim.validate({
        ["opts.debug"] = { opts.debug, "boolean", true },
        ["opts.enable"] = { opts.enable, "boolean", true }, -- true -> (optional)
        ["opts.ignoremode"] = { opts.ignoremode, "table", true },
        ["opts.mode"] = { opts.mode, "table", true },
    })
    -- stylua: ignore
    if opts.mode ~= nil then
        local diagnostics = {} --- @type string[]
        local expected = vim.tbl_keys(defaults.mode) --- @type ModeName[]
        local actual = vim.tbl_keys(opts.mode) --- @type ModeName[]|string[]
        for i = 1, #actual do
            local value = actual[i]
            if not vim.list_contains(expected, value) then table.insert(diagnostics, value) end
        end
        local is_valid = vim.tbl_count(diagnostics) == 0
        if not is_valid then
            vim.notify("line-number-change-mode.nvim: Found invalid mode(s) in opts: '" .. table.concat(diagnostics, " ") .. "'", vim.log.levels.ERROR)
        end
    end
end

return M

