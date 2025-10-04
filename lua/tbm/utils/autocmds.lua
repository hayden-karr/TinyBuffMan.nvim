local M = {}

function M.defaults(bufnr)
  local augroup = vim.api.nvim_create_augroup("TBMMenu", { clear = true })

  vim.api.nvim_create_autocmd("BufModifiedSet", {
    group = augroup,
    buffer = bufnr,
    callback = function()
      vim.bo[bufnr].modified = false
    end,
  })

  vim.api.nvim_create_autocmd("BufLeave", {
    group = augroup,
    buffer = bufnr,
    nested = true,
    once = true,
    callback = function()
      require("tbm.ui").toggle()
    end,
  })
end

return M
