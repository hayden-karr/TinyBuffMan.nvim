local Config = require("bafa.config")

local M = {}

---Setup Bafa plugin
---@param config BafaConfig|nil User configuration
M.setup = function(config)
  Config.setup(config)
end

return M
