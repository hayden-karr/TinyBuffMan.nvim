local M = {}

local noop_keys = {
    "i",
    "I",
    "a",
    "A",
    "o",
    "O",
    "s",
    "S",
    "c",
    "C",
    "r",
    "u",
    "U",
    "d",
}

function M.noop(bufnr)
    for _, key in ipairs(noop_keys) do
        vim.api.nvim_buf_set_keymap(bufnr, "n", key, "", { silent = true })
    end
end

function M.defaults(bufnr)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "q", "<Cmd>lua require('tbm.ui').toggle()<CR>", { silent = true })
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<ESC>", "<Cmd>lua require('tbm.ui').toggle()<CR>", { silent = true })
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<CR>", "<Cmd>lua require('tbm.ui').select_menu_item()<CR>", {})
    vim.api.nvim_buf_set_keymap(bufnr, "n", "d", "<Cmd>lua require('tbm.ui').delete_menu_item()<CR>", {})
end

return M
