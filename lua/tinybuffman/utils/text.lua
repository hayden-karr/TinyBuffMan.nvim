local M = {}

---Extract base path from file path
---@param file_path string Full file path
---@return string|nil Base path
M.get_base_path_from_file_path = function(file_path)
  local base_path = file_path:match("(.*/)")
  return base_path
end

---Extract file name from file path
---@param file_path string Full file path
---@return string|nil File name
M.get_file_name_from_file_path = function(file_path)
  local file_name = file_path:match("([^/]+)$")
  return file_name
end

---Get normalized relative path
---@param item string Full path
---@return string Relative path
M.get_normalized_path = function(item)
  local relative_path = vim.fn.fnamemodify(item, ":.")
  return relative_path
end

return M
