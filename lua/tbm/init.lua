local Config = require("tbm.config")

local M = {}

---Setup TinyBuffMan plugin
---@param config TBMConfig|nil User configuration
M.setup = function(config)
    Config.setup(config)
end

return M
