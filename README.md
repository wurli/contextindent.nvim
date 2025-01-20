# contextindent.nvim

A tiny Neovim plugin which adds context-aware indenting (i.e. using `=`/`==`).
In practice this means that if you're editing a file with treesitter language
injections - think a markdown file with a python code chunk, or a HTML file with
embedded javascript - the python/javascript portions of the files will be
indented according to your indent settings for those languages; not according to
the settings you use for markdown/HTML.

![demo](https://github.com/user-attachments/assets/fcc3dd6e-8690-4f31-b858-b7481ccf0b66)

This plugin has a much more noticeable effect for files when treesitter
indentation is *disabled*, since unlike vim syntax rules, treesitter indentation
is already context-aware. That said, treesitter alone won't adjust the indent
width based on language, so this plugin will still add some value even if you
have treesitter indentation enabled all the time.

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

