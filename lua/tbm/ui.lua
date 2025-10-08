local Config = require("tbm.config")
local BufferUtils = require("tbm.utils.buffers")
local Keymaps = require("tbm.utils.keymaps")
local Autocmds = require("tbm.utils.autocmds")
local _, Devicons = pcall(require, "nvim-web-devicons")

local TBM_NS_ID = vim.api.nvim_create_namespace("tbm.nvim")

local TBM_WIN_ID = nil
local TBM_BUF_ID = nil
local PREVIOUS_BUF_ID = nil

local DIAGNOSTICS_LABELS = { "Error", "Warn", "Info", "Hint" }

local function get_diagnostics(bufnr)
    local count = vim.diagnostic.count(bufnr)
    local diags = {}
    local config = Config.get()
    local icon_map = { "error", "warn", "info", "hint" }

    for k, v in pairs(count) do
        local label = DIAGNOSTICS_LABELS[k]
        local defined_sign = vim.fn.sign_getdefined("DiagnosticSign" .. label)
        local sign_icon = config.icons[icon_map[k]] or (#defined_sign ~= 0 and defined_sign[1].text) or " "

        table.insert(diags, { tostring(v) .. sign_icon, "DiagnosticSign" .. label })
    end
    return diags
end

local has_devicons = Devicons ~= nil

local get_buffer_icon = function(buffer)
    if not has_devicons then
        return "", "Normal"
    end
    local icon, icon_hl = Devicons.get_icon(buffer.name, buffer.extension, { default = true })
    return icon, icon_hl
end

local function close_window()
    if TBM_WIN_ID == nil or not vim.api.nvim_win_is_valid(TBM_WIN_ID) then
        return
    end
    vim.api.nvim_win_close(TBM_WIN_ID, true)
    TBM_WIN_ID = nil
    TBM_BUF_ID = nil
    PREVIOUS_BUF_ID = nil
end

local function create_window(content_width)
    local tbm_config = Config.get()
    local bufnr = vim.api.nvim_create_buf(false, false)

    local max_width = vim.api.nvim_win_get_width(0)
    local max_height = vim.api.nvim_win_get_height(0)
    local buffer_lines = BufferUtils.get_lines_buffer_names()
    local width = math.min(max_width, content_width)
    local height = math.max(1, math.min(max_height, buffer_lines))

    TBM_WIN_ID = vim.api.nvim_open_win(bufnr, true, {
        title = tbm_config.title,
        title_pos = tbm_config.title_pos,
        relative = tbm_config.relative,
        border = tbm_config.border,
        width = tbm_config.width or width,
        height = tbm_config.height or height,
        row = math.floor(((vim.o.lines - (tbm_config.height or height)) / 2) - 1),
        col = math.floor((vim.o.columns - (tbm_config.width or width)) / 2),
        style = tbm_config.style,
    })

    vim.wo[TBM_WIN_ID].winhighlight = "NormalFloat:TBMBorder"

    return {
        bufnr = bufnr,
        win_id = TBM_WIN_ID,
    }
end

local M = {}

function M.select_menu_item()
    local selected_line_number = vim.api.nvim_win_get_cursor(0)[1]
    local selected_buffer = BufferUtils.get_buffer_by_index(selected_line_number)
    if selected_buffer == nil then
        return
    end
    close_window()
    local ok, err = pcall(vim.api.nvim_set_current_buf, selected_buffer.number)
    if not ok then
        vim.notify("Failed to switch to buffer: " .. tostring(err), vim.log.levels.ERROR)
    end
end

function M.delete_menu_item()
    if TBM_BUF_ID == nil or not vim.api.nvim_buf_is_valid(TBM_BUF_ID) then
        return
    end

    local selected_line_number = vim.api.nvim_win_get_cursor(0)[1]
    local selected_buffer = BufferUtils.get_buffer_by_index(selected_line_number)

    if selected_buffer == nil then
        return
    end

    local buffer_to_delete = selected_buffer.number
    local was_previous_buffer = PREVIOUS_BUF_ID and buffer_to_delete == PREVIOUS_BUF_ID

    local function delete_buffer()
        close_window()

        if was_previous_buffer then
            local buffers = BufferUtils.get_buffers_as_table()
            local next_buf = nil

            -- Sort by last_used to get the most recently used buffer
            table.sort(buffers, function(a, b)
                return a.last_used > b.last_used
            end)

            -- Find the most recently used buffer that isn't the one being deleted
            for _, buf in ipairs(buffers) do
                if buf.number ~= buffer_to_delete then
                    next_buf = buf.number
                    break
                end
            end

            if next_buf then
                local ok = pcall(vim.api.nvim_set_current_buf, next_buf)
                if not ok then
                    vim.cmd("enew")
                end
            else
                vim.cmd("enew")
            end
        end

        local ok, err = pcall(vim.api.nvim_buf_delete, buffer_to_delete, { force = true })
        if not ok then
            vim.notify("Failed to delete buffer: " .. tostring(err), vim.log.levels.ERROR)
            return
        end

        vim.schedule(function()
            M.toggle()
        end)
    end

    local should_confirm = Config.get().confirm_delete and vim.bo[buffer_to_delete].modified

    if should_confirm then
        vim.api.nvim_clear_autocmds({ group = "TBMMenu", buffer = TBM_BUF_ID })

        vim.ui.select({ "Yes", "No" }, {
            prompt = "Buffer is modified. Delete anyway?",
        }, function(choice)
            if choice == "Yes" then
                delete_buffer()
            else
                close_window()
            end
        end)
    else
        delete_buffer()
    end
end

---Add highlight to the buffer icon
---@param idx number
---@param buffer table
---@return nil
local _cached_hl_groups = {}

local add_ft_icon_highlight = function(idx, buffer)
    if TBM_BUF_ID == nil then
        return
    end

    local _, icon_hl_group = get_buffer_icon(buffer)

    if not _cached_hl_groups[icon_hl_group] then
        local icon_hl = vim.api.nvim_get_hl(0, { name = icon_hl_group })
        if icon_hl.fg then
            local hl_group = "TBMIcon" .. icon_hl_group
            vim.api.nvim_set_hl(0, hl_group, { fg = icon_hl.fg })
            _cached_hl_groups[icon_hl_group] = hl_group
        end
    end

    if _cached_hl_groups[icon_hl_group] then
        vim.api.nvim_buf_set_extmark(TBM_BUF_ID, TBM_NS_ID, idx - 1, 2, {
            end_col = 3,
            hl_group = _cached_hl_groups[icon_hl_group],
        })
    end
end

---Colors the buffer name if it is modified
---@param idx number
---@param buffer table
local add_modified_highlight = function(idx, buffer)
    if TBM_BUF_ID == nil then
        return
    end
    if not buffer.is_modified then
        return
    end
    local hl_name = "TBMModified"
    local hl = vim.api.nvim_get_hl(0, { name = hl_name, create = false })
    local fg = hl.fg or 0xffff00
    vim.api.nvim_set_hl(0, hl_name, { fg = fg })

    -- Get the icon for this buffer
    local icon, _ = get_buffer_icon(buffer)

    -- Build the exact prefix: "  " + icon + " "
    local prefix = "  " .. icon .. " "

    -- Get the BYTE length of the prefix (handles multi-byte UTF-8 correctly)
    local start_col = #prefix

    -- Highlight from where the buffer name actually starts to end of line
    vim.api.nvim_buf_set_extmark(TBM_BUF_ID, TBM_NS_ID, idx - 1, start_col, {
        hl_group = hl_name,
        end_line = idx, -- Next line (exclusive)
        end_col = 0, -- Column 0 of next line = end of current line
    })
end

local add_diagnostics_icons = function(idx, buffer, cached_diags)
    if TBM_BUF_ID == nil then
        return 0
    end
    local diags = cached_diags or {}
    local count = 0
    for _, diagnostic in ipairs(diags) do
        vim.api.nvim_buf_set_extmark(TBM_BUF_ID, TBM_NS_ID, idx - 1, 0, {
            virt_text = { { diagnostic[1], diagnostic[2] } },
        })
        count = count + 1
    end
    return count
end

function M.toggle()
    if TBM_WIN_ID ~= nil and vim.api.nvim_win_is_valid(TBM_WIN_ID) then
        close_window()
        return
    end

    PREVIOUS_BUF_ID = vim.api.nvim_get_current_buf()

    local valid_buffers = BufferUtils.get_buffers_as_table()

    -- Width calculation
    local longest_name_width = 0
    for _, buffer in ipairs(valid_buffers) do
        local name_width = vim.fn.strwidth(buffer.name)
        if name_width > longest_name_width then
            longest_name_width = name_width
        end
    end

    -- Add the fixed overhead (line numbers, icon, spacing, padding)
    local line_number_width = #tostring(#valid_buffers) + 1
    local icon_and_spacing = 5
    local diagnostic_space = 15
    local padding = 5

    local total_width = line_number_width + icon_and_spacing + longest_name_width + diagnostic_space + padding

    -- Create window using the helper function
    local win_info = create_window(total_width)
    TBM_WIN_ID = win_info.win_id
    TBM_BUF_ID = win_info.bufnr

    local contents = {}
    local cursor_line = 1

    for idx, buffer in ipairs(valid_buffers) do
        local icon, _ = get_buffer_icon(buffer)
        contents[idx] = string.format("  %s %s", icon, buffer.name)

        if buffer.number == PREVIOUS_BUF_ID then
            cursor_line = idx
        end
    end

    vim.wo[TBM_WIN_ID].number = true
    vim.api.nvim_buf_set_name(TBM_BUF_ID, "tbm-menu")
    vim.api.nvim_buf_set_lines(TBM_BUF_ID, 0, #contents, false, contents)
    vim.bo[TBM_BUF_ID].buftype = "nofile"
    vim.bo[TBM_BUF_ID].bufhidden = "delete"

    for idx, buffer in ipairs(valid_buffers) do
        add_ft_icon_highlight(idx, buffer)
        add_modified_highlight(idx, buffer)
        if Config.get().diagnostics then
            local diags = get_diagnostics(buffer.number)
            add_diagnostics_icons(idx, buffer, diags)
        end
    end

    vim.api.nvim_win_set_cursor(TBM_WIN_ID, { cursor_line, 0 })

    Keymaps.noop(TBM_BUF_ID)
    Keymaps.defaults(TBM_BUF_ID)
    Autocmds.defaults(TBM_BUF_ID)
end

return M
