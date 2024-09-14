# Neovim Updater Plugin

This plugin allows you to easily update Neovim from source,
with fully customizable options to define where the source is cloned,
which branch is tracked, and the desired build type.

## 📦 Installation and Setup (with lazy.nvim)

To use the plugin with [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "rootiest/nvim-updater.nvim",
  config = function()
    require("nvim_updater").setup({
      source_dir = "~/.local/src/neovim",  -- Custom target directory
      build_type = "RelWithDebInfo",       -- Set the desired build type
      branch = "master",                   -- Track nightly branch
    })
  end,

  -- Optionally, you can customize your own keymaps
  keys = {
    {
      "<Leader>cuU",
      function()
        require('nvim_updater').update_neovim()
      end,
      desc = "Custom Update Neovim"
    },
    {
      "<Leader>cuD",
      function()
        require('nvim_updater').update_neovim({ build_type = 'Debug' })
      end,
      desc = "Debug Build Neovim"
    },
  }
}
```

---

### ✨ Features

- Clone, build, and install Neovim **from the source**.
- Customizable **source path**, **build type**
  (`Debug`, `Release`, `RelWithDebInfo`), and **branch**.
- Provides default keybindings for quick actions or
  lets you define your own custom keymaps.
- Integrates with **lualine** and statusline plugins via a
  dedicated buffer **filetype** for customization.

---

## ⚙️ Configuration

The `setup` function accepts an optional table to configure the plugin’s behavior.

### Available Options

- **`source_dir`**: Path to where the Neovim source is cloned. Default is `~/.local/src/neovim`.
- **`build_type`**: The build type to use, e.g.,
  `Release`, `Debug`, or `RelWithDebInfo`. Default is `RelWithDebInfo`.
- **`branch`**: The branch to track when cloning Neovim. Default is `master`.
- **`keys`**: (table|nil) Define custom keymaps. When `nil`, sets default keymaps.

### Example Setup

```lua
require("nvim_updater").setup({
  source_dir = "~/projects/neovim",  -- Custom source directory
  build_type = "Release",            -- Use Release mode for building
  branch = "master",                 -- Default to the 'master' branch
})
```

---

## ⌨️ Default Keybindings

If you do not specify your own custom keymaps,
the plugin provides the following default keymaps:

- **`<Leader>uU`**: Update Neovim using the default configuration.
- **`<Leader>uD`**: Update Neovim using a `Debug` build.
- **`<Leader>uR`**: Update Neovim using a `Release` build type.

You can override these keybindings by providing a table of
custom **key mappings** in the plugin’s setup
(as demonstrated in the installation example).

---

## 🔧 Exposed Commands

### Commands

- **`:UpdateNeovim`**: Updates Neovim from the source, using the default
  or custom options you’ve set (e.g., source directory, build type, and branch).
  If the source does not exist at the specified path,
  the repository is cloned and built.

#### Example

```vim
:UpdateNeovim
```

This command pulls the latest changes from the source
and builds Neovim based on your configuration.

---

## 📂 Filetype Integration

The plugin assigns a custom **filetype** to the terminal buffer
used to run shell commands for updating Neovim.

### Filetype: `neovim_updater_term`

You can easily integrate with statusline plugins like **lualine** by referencing
this **filetype** and applying custom conditions.
For example, you may want to hide certain lualine components when
this filetype is active in your terminal buffers.

#### Example Lualine Configuration

```lua
require("lualine").setup {
  sections = {
    lualine_a = { "mode" },
    lualine_b = { "branch" },
    lualine_c = {
      { -- Hide filename when using the updater
        "filename",
        cond = function()
          return vim.bo.filetype ~= "neovim_updater_term"
        end,
      },
      { -- Neovim Updater
        function()
          return "Neovim Updating.."
        end,
        icon = "󰅢 ",
        -- Use the lualine_a highlight for emphasis
        color = "lualine_a_terminal",
        -- Use bubble separators
        separator = { left = "", right = "" },
        -- Show only when using the updater
        cond = function()
          return vim.bo.filetype == "neovim_updater_term"
        end,
      },
  },
  -- Other lualine components
}
```

This configuration hides the file name in lualine when
the `neovim_updater_term` filetype is detected and
shows the `Neovim Updating` component instead.

In this way we can avoid a messy "filename" being displayed
when using the updater and instead display a customized
"Neovim Updating" message.

The condition can also be applied to any other components you
wish to hide when using the updater.

---

## ⚠️ Compatibility

- **Platform:** The plugin is primarily developed for Linux environments.
  Although it may work on macOS or other platforms,
  `sudo make install` is hardcoded and assumes a Linux-based setup.
- **Neovim Version:** This plugin requires **Neovim 0.10+** to operate correctly,
  as it depends on specific Lua API features.

---

## 🛠️ Contributing

If you find any issues or have suggestions for improvement,
feel free to open a GitHub issue or send a pull request.
We welcome contributions!

### Filing an Issue

Be sure to include the following information when reporting bugs:

1. The output of `nvim --version`.
2. Error messages from Neovim (if any).
3. Steps to reproduce the issue.

### PR Submission Guidelines

1. Fork the repository.
2. Create a new branch for your feature or fix.
3. Make your changes, add or update tests, and confirm everything works.
4. Submit a **pull request** with a clear description of the changes made.

---

## 📜 License

This repository is licensed under the [MIT License](LICENSE).
You are free to use, modify, and distribute this project in your own work.
