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
    -- Try to find git root
    local git_root = vim.fn.systemlist("git -C " .. vim.fn.fnamemodify(item, ":h") .. " rev-parse --show-toplevel")[1]

    if git_root and vim.v.shell_error == 0 then
        -- Make relative to git root
        if vim.startswith(item, git_root) then
            return item:sub(#git_root + 2)
        end
    end

    -- Fall back to cwd-relative
    local cwd = vim.fn.getcwd()
    if vim.startswith(item, cwd) then
        return item:sub(#cwd + 2)
    end

    -- Last resort: just the filename
    return vim.fn.fnamemodify(item, ":t")
end
return M
