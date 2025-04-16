local M = {}

---@class ContextIndentConfig
---Can be used to restrict filetypes which |indentexpr| is set for. See
---|autocmd-pattern| for more information.
---@field pattern? string

---@type ContextIndentConfig
local config = { pattern = "*" }

---@param opts? ContextIndentConfig
M.setup = function(opts)
    config = vim.tbl_extend("force", config, opts or {})

    if vim.fn.has("nvim-0.11") == 1 then
        vim.validate("pattern", config.pattern, "string")
    else
        vim.validate({ pattern = { config.pattern, "string" }, })
    end

    vim.api.nvim_create_autocmd("BufRead", {
        pattern = config.pattern,
        group = vim.api.nvim_create_augroup("contextindent", {}),
        callback = function()
            local template = 'v:lua.require("contextindent").context_indent("%s")'
            vim.bo.indentexpr = template:format(vim.bo.indentexpr)
        end
    })
end

---Evaluate a vimscript function safely
---@param x string the function to evaluate
---@return any
local safe_eval = function(x)
    local fn_name = x:gsub("%(%)$", "")
    if fn_name == "" then return end
    local ok, res = pcall(function() return vim.fn[fn_name]() end)
    return ok and res or nil
end

---Indent according to the language of the current cursor position, which is
---determined using treesitter. This is nice because it applies the correct
---indentation, e.g. in markdown code blocks.
---
---@param buf_indentexpr string The 'original' |indentexpr| for the current buffer
---@return number
M.context_indent = function(buf_indentexpr)
    local parser_exists, parser = pcall(vim.treesitter.get_parser)

    if not parser_exists then
        -- -1 means 'fall back to autoindent'; see :help indentexpr
        return safe_eval(buf_indentexpr) or -1
    end

    local curr_ft = parser:language_for_range({ vim.v.lnum, 0, vim.v.lnum, 1 }):lang()

    if curr_ft == "" or curr_ft == vim.bo.filetype then
        return safe_eval(buf_indentexpr) or -1
    end

    ---@as string
    local curr_indentexpr = vim.filetype.get_option(curr_ft, "indentexpr")

    if curr_indentexpr == "" or type(curr_indentexpr) ~= "string" then
        return -1
    end

    local buf_shiftwidth = vim.bo.shiftwidth
    vim.bo.shiftwidth    = vim.filetype.get_option(curr_ft, "shiftwidth")
    local indent         = safe_eval(curr_indentexpr)
    vim.bo.shiftwidth    = buf_shiftwidth

    return indent or -1
end

return M

