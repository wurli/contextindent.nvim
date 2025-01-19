# contextindent.nvim

A tiny Neovim plugin which adds context-aware indenting (i.e. using `=`/`==`).
In practice this means that if you're editing a file with treesitter language
injections - think a markdown file with a python code chunk, or a HTML file with
embedded javascript - the python/javascript portions of the files will be
indented according to your indent settings for those languages; not according to
your settings you have for markdown/HTML files.

**Note**: this plugin relies on treesitter for language detection.

## Installation

Using lazy.nvim:

``` lua
{
    "wurli/contextindent.nvim",
    -- This is the only config option; you can use it to restrict the files
    -- which this plugin will affect (see :help autocommand-pattern).
    opts = { pattern = "*" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
}
```

## Implementation

This plugin works by overriding `indentexpr` whenever a new buffer is entered.
The new indentexpr will in most cases fall back to the normal behaviour, but if
treesitter detects that the language for the region the cursor is currently in
is *not* the same as that of the buffer, it will use the indentexpr for the
current region.

