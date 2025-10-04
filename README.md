<div align="center">

![Bafa Logo](logo.svg)

# bafa.nvim

![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua)
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/mistweaverco/bafa.nvim?style=for-the-badge)](https://github.com/mistweaverco/bafa.nvim/releases/latest)

[Requirements](#requirements) • [Install](#install) • [Usage](#usage)

<p></p>

A minimal BufExplorer alternative for lazy people for your favorite editor.

Bafa is swahili for "buffer".

It allows you to quickly switch between buffers and delete them.

<p></p>

![demo](demo.png)

<p></p>

</div>

## Requirements

- [Neovim](https://github.com/neovim/neovim) (tested with 0.9.0)

> [!TIP]
> For having fancy icons, you need to install a patched font.
> You can find some patched fonts in the [Nerd Fonts](https://www.nerdfonts.com/) website.
> Also you should consider installing [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons)
> for having the correct icons based on the ft in the buffer list.

## Install

Via [lazy.nvim](https://github.com/folke/lazy.nvim):

### Simple configuration

```lua
require('lazy').setup({
  -- Buffer management
  { 'mistweaverco/bafa.nvim' },
})
```

### Advanced configuration

```lua
require('lazy').setup({
  -- Buffer management
  {
    'mistweaverco/bafa.nvim',
    opts = {
      width = 60,
      height = 10,
      title = "Bafa",
      title_pos = "center",
      relative = "editor",
      border = "rounded",
      style = "minimal",
      diagnostics = true,
    }
  },
})

```

## Usage

### `require('bafa.ui').toggle()`

Opens up a floating window with your buffers.

Press enter to select a buffer or press `d` to delete a buffer.
