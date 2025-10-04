local text_utils = require("tbm.utils.text")

local M = {}

---@class TBMBuffer
---@field name string The display name of the buffer
---@field path string The full path to the buffer
---@field number integer The buffer number
---@field last_used integer Timestamp when buffer was last used
---@field is_modified boolean Whether the buffer has unsaved changes
---@field extension string The file extension

---Check if a buffer is valid for display
---@param buffer_number integer The buffer number to check
---@return boolean
M.is_valid_buffer = function(buffer_number)
  local buffer_name = vim.api.nvim_buf_get_name(buffer_number)
  local is_listed = vim.bo[buffer_number].buflisted == true
  local is_not_tbm_buffer = buffer_name ~= "tbm-menu"
  if is_not_tbm_buffer and is_listed then
    return true
  end
  return false
end

---Get the width of the longest buffer name
---@return integer
M.get_width_longest_buffer_name = function()
  local buffers = M.get_buffers_as_table()
  local longest_buffer_name = 0
  for _, buffer in ipairs(buffers) do
    local buffer_name_width = vim.fn.strwidth(buffer.name)
    if buffer_name_width > longest_buffer_name then
      longest_buffer_name = buffer_name_width
    end
  end
  return longest_buffer_name
end

---Get the number of valid buffers
---@return integer
M.get_lines_buffer_names = function()
  local buffers = M.get_buffers_as_table()
  return #buffers
end

---Get a buffer by its index in the buffer list
---@param buffer_index integer The 1-based index
---@return TBMBuffer|nil
M.get_buffer_by_index = function(buffer_index)
  local buffer_numbers = M.get_buffers_as_table()
  local buffer = buffer_numbers[buffer_index]
  if buffer == nil then
    return nil
  end
  local buffer_number = buffer.number
  if buffer_number == nil then
    return nil
  end
  return buffer
end

---Get all valid buffers as a table
---@return TBMBuffer[]
M.get_buffers_as_table = function()
  local buffers = {}
  local buffer_numbers = vim.api.nvim_list_bufs()
  for _, buffer_number in ipairs(buffer_numbers) do
    local is_valid_buffer = M.is_valid_buffer(buffer_number)
    if is_valid_buffer then
      local last_used = vim.fn.getbufinfo(buffer_number)[1].lastused
      local buffer_name = vim.api.nvim_buf_get_name(buffer_number)

      -- Handle unnamed buffers
      local buffer_file_name
      if buffer_name == "" then
        buffer_file_name = "[No Name]"
      else
        buffer_file_name = text_utils.get_normalized_path(buffer_name)
      end

      local is_modified = vim.bo[buffer_number].modified == true
      local extension = vim.fn.fnamemodify(buffer_name, ":e")
      local buffer = {
        name = buffer_file_name,
        path = buffer_name,
        number = buffer_number,
        last_used = last_used,
        is_modified = is_modified,
        extension = extension,
      }
      table.insert(buffers, buffer)
    end
  end

  table.sort(buffers, function(a, b)
    return a.number < b.number
  end)

  return buffers
end

return M
