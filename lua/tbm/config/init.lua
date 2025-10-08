local M = {}

---@class TBMConfig
---@field title string Window title
---@field title_pos "left"|"center"|"right" Title position
---@field relative "editor"|"win"|"cursor" Window positioning
---@field border "none"|"single"|"double"|"rounded"|"solid"|"shadow" Border style
---@field style "minimal"|nil Window style
---@field diagnostics boolean Show diagnostics
---@field width integer|nil Window width (auto if nil)
---@field height integer|nil Window height (auto if nil)
---@field confirm_delete boolean Confirm before deleting modified buffers
---@field icons table Diagnostic icons configuration

---@type TBMConfig
M.defaults = {
    title = "Buffers",
    title_pos = "center",
    relative = "editor",
    border = "rounded",
    style = "minimal",
    diagnostics = true,
    confirm_delete = true,
    icons = {
        error = " ",
        warn = " ",
        info = " ",
        hint = " ",
    },
}

M.options = M.defaults

---Setup configuration
---@param config TBMConfig|nil User configuration
M.setup = function(config)
    M.options = vim.tbl_deep_extend("force", M.defaults, config or {})
end

---Update configuration
---@param config TBMConfig|nil Configuration updates
M.set = function(config)
    M.options = vim.tbl_deep_extend("force", M.options, config or {})
end

---Get current configuration
---@return TBMConfig
M.get = function()
    return M.options
end

return M
