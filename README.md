# Neovim Updater Plugin

This plugin updates Neovim from source with customizable options.

## Installation and Setup with lazy.nvim

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
   "rootiest/nvim-updater.nvim",
   config = function()
     require("nvim_updater").setup({
       source_dir = "~/.local/src/neovim",  -- Custom target directory
       build_type = "RelWithDebInfo",  -- Set the desired build type
       -- If you don't provide the `keys` field,
       --  default keymaps will be set (see below)
     })
   end,

   -- Optionally, you can completely customize your own keymaps
   keys = {
     {
      "<Leader>cuU",
      ":UpdateNeovim<CR>",
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

### Defaults

- If no `source_dir` is provided, it defaults to `~/.local/src/neovim`.
- If no `build_type` is specified, it defaults to `RelWithDebInfo`.
- If no `keys` are provided, the plugin sets [default keymaps](#️-default-keybindings)

---

## ⚙️ Configuration

The `setup` function accepts an optional table to configure the plugin's behavior:

### Available Options

- **source_dir**: (string) Path to the directory where Neovim
  source is cloned and built. Default: `~/.local/src/neovim`.
- **build_type**: (string) Specify the build type for Neovim,
  such as `Release`, `Debug`, or `RelWithDebInfo`. Default: `RelWithDebInfo`.
- **keys**: (nil or table) If `nil`, the plugin sets default keymaps.
  If you provide your own keymaps, defaults are disabled.

Example setup with custom `source_dir` and `build_type`:

```lua
require("nvim_updater").setup({
  source_dir = "~/projects/neovim",  -- Custom source directory
  build_type = "Release",            -- Use Release mode to build
})
```

---

## ⌨️ Default Keybindings

If you do not provide any custom `keys` or disable the `keys` field in the plugin
config, the following default key maps are created:

- **`<Leader>uU`**: Update Neovim using the default configuration.
- **`<Leader>uD`**: Update Neovim using a `Debug` build type.
- **`<Leader>uR`**: Update Neovim using a `Release` build type.

If you'd prefer to use your own keymaps,
customize it with the `keys` field in lazy.nvim
as shown in the installation section.

---

## 🔧 Commands

**_Exposed Commands:_**

- `:UpdateNeovim`: This command updates Neovim from the source using default
  or user-set options (specifying the source directory and build type).

### Example

```vim
:UpdateNeovim
```

This will either clone the Neovim source (if it doesn’t exist at the path)
or pull the latest changes and then build it according to the configured build type.

---

## 🌍 Compatibility

- **Platform:** The plugin is designed for Linux.
  While it may work on macOS or other platforms,
  `sudo make install` is hardcoded and assumes a Linux environment setup.
- **Neovim Version:** Ensure you are using Neovim 0.09+ to
  avoid compatibility issues with the required Lua APIs.

---

## 🛠️ Contributing

If you run into any issues or have suggestions for improvements,
feel free to open a GitHub issue.
Contributions are welcome in the form of pull requests.

### Filing an Issue

When reporting a bug, make sure to include:

1. Neovim version (`nvim --version`)
2. Error messages/log (if any)
3. Steps to reproduce, if applicable.

### Submitting a PR

1. Fork the repository.
2. Create a feature branch for your changes.
3. Add new functionality or fix bugs and ensure tests (if applicable) pass.
4. Submit a pull request describing changes clearly.

---

## 📜 License

This repository is licensed under the [MIT License](LICENSE).
Feel free to use this in your own projects!
