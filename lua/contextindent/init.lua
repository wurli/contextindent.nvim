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
        vim.validate({ pattern = { config.pattern, "string" } })
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
---@param expr string the function to evaluate
---@return any
local safe_eval = function(expr)
    local ok, res = pcall(vim.api.nvim_eval, expr)
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

    local curr_parser_name = parser:language_for_range({ vim.v.lnum, 0, vim.v.lnum, 1 }):lang()
    local curr_ft
    if curr_parser_name == 'c_sharp' then
        curr_ft = 'cs'
    elseif curr_parser_name == 'powershell' then
        curr_ft = 'ps1'
    else
        curr_ft = curr_parser_name
    end

    if curr_ft == "" or curr_ft == vim.bo.filetype then
        if buf_indentexpr == "" then
            if vim.bo.cindent then
                return vim.fn.cindent(vim.v.lnum)
            elseif vim.bo.autoindent and vim.bo.smartindent then
                return vim.fn.indent(vim.v.lnum)
            end
        end
        return safe_eval(buf_indentexpr) or -1
    end

    ---@as string
    local curr_indentexpr = vim.filetype.get_option(curr_ft, "indentexpr")

    local indent = -1

    local buf_shiftwidth = vim.bo.shiftwidth
    local buf_cindent = vim.bo.cindent
    local buf_autoindent = vim.bo.autoindent
    local buf_smartindent = vim.bo.smartindent

    vim.bo.shiftwidth = vim.filetype.get_option(curr_ft, "shiftwidth")

    if curr_indentexpr == "" or type(curr_indentexpr) ~= "string" then
        --NOTE: cindent is not stable in context code, but generally ok
        if vim.filetype.get_option(curr_ft, "cindent") then
            vim.bo.cindent = true
            vim.bo.cinoptions = vim.filetype.get_option(curr_ft, "cinoptions")
            vim.bo.cinwords = vim.filetype.get_option(curr_ft, "cinwords")
            vim.bo.cinkeys = vim.filetype.get_option(curr_ft, "cinkeys")
            vim.bo.cinscopedecls = vim.filetype.get_option(curr_ft, "cinscopedecls")
            indent = vim.fn.cindent(vim.v.lnum)
        elseif vim.filetype.get_option(curr_ft, "autoindent") and vim.filetype.get_option(curr_ft, "smartindent") then
            vim.bo.autoindent = true
            vim.bo.smartindent = true
            indent = vim.fn.indent(vim.v.lnum)
        end
    else
        indent = safe_eval(curr_indentexpr) or -1
    end

    -- finally restore buf options
    vim.bo.shiftwidth = buf_shiftwidth
    vim.bo.cindent = buf_cindent
    vim.bo.smartindent = buf_smartindent
    vim.bo.autoindent = buf_autoindent

    return indent
end

return M

