# Neovim Updater Plugin

![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua)
[![nvim-updater.nvim](https://dotfyle.com/plugins/rootiest/nvim-updater.nvim/shield?style=for-the-badge)](https://dotfyle.com/plugins/rootiest/nvim-updater.nvim)

This plugin allows you to easily update Neovim from source,
with fully customizable options to define where the source is cloned,
which branch is tracked, and the desired build type.

All without leaving Neovim.

## Demo

[nvim-updater.webm](https://github.com/user-attachments/assets/dcf5dba0-837d-4ac5-9fb6-ef5a1bd2ae4a)

The above video shows an example of the update workflow with the Neovim Updater plugin.

## 🔧 Prerequisites

- A Linux system (macOS and Windows are not supported by this plugin)
- [Neovim 0.10+](https://neovim.io/)
  (earlier versions may work, but could encounter issues)
- [Build prerequisites](https://github.com/neovim/neovim/blob/master/BUILD.md#build-prerequisites)
  for your platform

> It is recommended to uninstall any distro-provided neovim packages after
> installing from source (with this plugin or manually) to prevent those
> distro-packaged updates from overwriting the locally-built neovim binary.

### 📌 Optional Dependencies

These plugins are not required but can be used to extend functionality.

- [diffview.nvim](https://github.com/sindrets/diffview.nvim)
  This plugin can be used to show new commits in DiffView.
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
  This plugin can be used to show new commits in Telescope.

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
      check_for_updates = true,            -- Enable automatic update checks
      default_keymaps = false,             -- Disable default keymaps
    })
  end,
  keys = { -- Custom keymappings
    { -- Custom Update Neovim
      "<Leader>cuU",
      function()
        require('nvim_updater').update_neovim()
      end,
      desc = "Custom Update Neovim"
    },
    { -- Debug Build Neovim
      "<Leader>cuD",
      function()
        require('nvim_updater').update_neovim({ build_type = 'Debug' })
      end,
      desc = "Debug Build Neovim"
    },
    { -- Remove Neovim Source
      "<Leader>cRN",
      ":NVUpdateRemoveSource<CR>",
      desc = "Remove Neovim Source Directory",
    },
  }
}
```

Minimal example with defaults in [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
  {
    "rootiest/nvim-updater.nvim",
    opts = {},
  }
```

Example with [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  "rootiest/nvim-updater.nvim",
  config = function()
    require("nvim_updater").setup({
      source_dir = "~/.local/src/neovim",  -- Custom target directory
      build_type = "RelWithDebInfo",       -- Set the desired build type
      branch = "master",                   -- Track nightly branch
      check_for_updates = true,            -- Enable automatic update checks
      default_keymaps = false,             -- Disable default keymaps
    })
  end,
  keys = { -- Custom keymappings
    { -- Custom Update Neovim
      "<Leader>cuU",
      function()
        require('nvim_updater').update_neovim()
      end,
      desc = "Custom Update Neovim"
    },
    { -- Debug Build Neovim
      "<Leader>cuD",
      function()
        require('nvim_updater').update_neovim({ build_type = 'Debug' })
      end,
      desc = "Debug Build Neovim"
    },
    { -- Remove Neovim Source
      "<Leader>cRN",
      ":NVUpdateRemoveSource<CR>",
      desc = "Remove Neovim Source Directory",
    },
  }
}
```

Example with [vim-plug](https://github.com/junegunn/vim-plug):

```lua
Plug "rootiest/nvim-updater.nvim"

lua << EOF
require("nvim_updater").setup({
  source_dir = "~/.local/src/neovim",  -- Custom target directory
  build_type = "RelWithDebInfo",       -- Set the desired build type
  branch = "master",                   -- Track nightly branch
  check_for_updates = true,            -- Enable automatic update checks
  default_keymaps = false,             -- Disable default keymaps
})

-- Custom keybindings
vim.api.nvim_set_keymap("n", "<Leader>cuU",
  ":lua require('nvim_updater').update_neovim()<CR>",
  { noremap = true, silent = true, desc = "Custom Update Neovim" })

vim.api.nvim_set_keymap("n", "<Leader>cuD",
  ":lua require('nvim_updater').update_neovim({ build_type = 'Debug' })<CR>",
  { noremap = true, silent = true, desc = "Debug Build Neovim" })

vim.api.nvim_set_keymap("n", "<Leader>cRN",
  ":NVUpdateRemoveSource<CR>",
  { noremap = true, silent = true, desc = "Remove Neovim Source Directory" })
EOF
```

---

### ✨ Features

- Clone, build, and install Neovim **from the source**.
- Customizable **source path**, **build type**
  (`Debug`, `Release`, `RelWithDebInfo`), and **branch**.
- Provides default keybindings for quick actions or
  define your own custom keymaps.
- Integrates with **lualine** and statusline plugins via a
  dedicated buffer **filetype** for customization and
  a status component.
- Integrates with `DiffView` and `Telescope` plugins

---

## ⚙️Configuration

The `setup` function accepts an optional table to configure the plugin’s behavior.

### Available Options

- **`source_dir`**: Path to where the Neovim source is cloned.  
  Default is `vim.fn.expand("~/.local/src/neovim")`.

  The source directory path can be any valid path Neovim can write to.

- **`build_type`**: The build type to use.  
  Default is `"RelWithDebInfo"`.

  Possible values are:  
   `"Release"` - No debugging symbols.  
   `"Debug"` - All debugging symbols.  
   `"RelWithDebInfo"` - Release with common debugging symbols.

- **`branch`**: The branch to track when cloning Neovim.  
  Default is `"master"` (nightly).

  The branch can be used to track the Neovim version.

  Possible values are:  
   `"master"` - Neovim nightly  
   `"release-0.10"` - Neovim 0.10  
   `"release-0.9"` - Neovim 0.9  
   etc..

- **`verbose`**: (boolean) Enable verbose output.  
  Default is `false`.

  When set to `false`, `INFO` and `DEBUG` notifications
  from the plugin are suppressed.

  Possible values are:  
   `true` - Enable verbose output.  
   `false` - Disable verbose output.

- **`check_for_updates`**: (boolean) Enable automatic update checks.  
  Default is `false`.

  When set to `false`, the plugin will not check for updates automatically.

  Possible values are:  
   `true` - Enable automatic update checks.  
   `false` - Disable automatic update checks.

- **`update_interval`**: (number) Update interval in seconds.  
  Default is `(60 * 60 * 6)` (6 hours).

  The update interval is the time between checks for new commits in the
  neovim source repository.

  Possible values are:  
   `number` - Update interval in seconds.

- **`default_keymaps`**: (boolean) Enable default keymaps.  
  Default is `false`.

  When set to `true`, the plugin provides a set of default keymaps.

  Possible values are:  
   `true` - Enable default keymaps.  
   `false` - Disable default keymaps.

### Example Setup

Default configuration:

```lua
require("nvim_updater").setup({
  source_dir = "~/.local/src/neovim",  -- Default source directory
  build_type = "RelWithDebInfo",       -- Default build mode
  branch = "master",                   -- Represents "nightly"
  check_for_updates = false,           -- Disable automatic update checks
  update_interval = (60 * 60) * 6,     -- 6 hours default update interval
  verbose = false,                     -- Disable verbose output
  default_keymaps = false,              -- Disable default keymaps
})
```

---

## ⌨️ Default Keybindings

If you do not specify your own custom keymaps,
the plugin provides the following default keymaps:

- **`<Leader>uU`**: Update Neovim using the default configuration.
- **`<Leader>uD`**: Update Neovim using a `Debug` build.
- **`<Leader>uR`**: Update Neovim using a `Release` build type.
- **`<Leader>uC`**: Remove Neovim source directory.
- **`<Leader>un`**: Show new updates available

You can override these keybindings by providing a table of
custom **key mappings** in the plugin’s setup
(as demonstrated in the installation example).

---

## 🔧 Exposed Commands

### Commands

- **`:NVUpdateNeovim`**: Updates Neovim from the source, using the default
  or custom options you’ve set (e.g., source directory, build type, and branch).
  If the source does not exist at the specified path,
  the repository is cloned and built.

  ```vim
  :NVUpdateNeovim
  ```

This command pulls the latest changes from the source
and builds Neovim based on your configuration.

- **`:NVUpdateRemoveSource`**: Removes the source directory.

  ```vim
  :NVUpdateRemoveSource
  ```

This command is useful if you want to clean up your source directory
after you’ve built and installed Neovim.

- **`:NVUpdateShowNewCommits`**: Shows new updates available.

  ```vim
  :NVUpdateShowNewCommits
  ```

  This command allows you to check for new updates and show the changes
  in a floating terminal.

- **`:NVUpdateShowNewCommitsInDiffView`**: Shows new updates available in
  the [DiffView](https://github.com/sindrets/diffview.nvim) plugin.

  ```vim
  :NVUpdateShowNewCommitsInDiffView
  ```

  This command allows you to check for new updates and show the changes
  in the [DiffView](https://github.com/sindrets/diffview.nvim) plugin.

- **`:NVUpdateShowNewCommitsInTelescope`**: Shows new updates available in
  the [Telescope](https://github.com/nvim-telescope/telescope.nvim) plugin.

  ```vim
  :NVUpdateShowNewCommitsInTelescope
  ```

  This command allows you to check for new updates and show the changes
  in the [Telescope](https://github.com/nvim-telescope/telescope.nvim) plugin.

### Lua Functions

The plugin exposes several Lua functions.

The following functions are available in the `nvim_updater` namespace:

#### Update Neovim from source

```lua
require("nvim_updater").update_neovim( [options] )
```

Available `[options]`:

- **`source_dir`**: Path to where the Neovim source is cloned. Default is `~/.local/src/neovim`.
- **`build_type`**: The build type to use, e.g.,
  `Release`, `Debug`, or `RelWithDebInfo`. Default is `RelWithDebInfo`.
- **`branch`**: The branch to track when cloning Neovim. Default is `master`.

#### Remove Neovim source

```lua
require("nvim_updater").remove_source_dir( [options] )
```

Available `[options]`:

- **`source_dir`**: Path to where the Neovim source is cloned.
  Default is `~/.local/src/neovim`.

#### Show new commits

```lua
 require("nvim_updater.utils").show_new_commits( [options] )
```

This function opens a floating terminal with the new commits/changes on
the remote repository vs the local src directory.

Available `[options]`:

- `isupdate`: Whether to prompt for updating after showing the changes.
  Default is `false`

#### Show new commits in DiffView

```lua
 require("nvim_updater.utils").show_new_commits_in_diffview()
```

This function opens [DiffView](https://github.com/sindrets/diffview.nvim)
with the new commits/changes on the remote repository vs the local src directory.

#### Show new commits in Telescope

```lua
 require("nvim_updater.utils").show_new_commits_in_telescope()
```

This function opens [Telescope](https://github.com/nvim-telescope/telescope.nvim)
with the new commits/changes on the remote repository vs the local src directory.

#### Open floating terminal

```lua
require("nvim_updater.utils").open_floating_terminal( [options] )
```

This is a helper function for opening a floating terminal that is used by the
updater to display the terminal output.

Available `[options]`:

- **`cmd`**: Command to run in the terminal.
- **`filetype`**: Filetype to assign to the terminal buffer.

#### Setup

```lua
require("nvim_updater").setup( [options] )
```

See [Configuration](⚙️Configuration) for setup `[options]`.

---

## 📂 Integrations

There are several features that allow the plugin to better integrate with other plugins.

### Filetype: `neovim_updater_term`

The plugin assigns a custom **filetype** to the terminal buffer
used to run shell commands for updating Neovim.

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
          return not string.find(vim.bo.filetype, "neovim_updater_term")
        end,
      },
      { -- Neovim Updater
        function()
          local ft = vim.bo.filetype
          if ft == "neovim_updater_term.updating" then
            return "Neovim Updating.."
          elseif ft == "neovim_updater_term.cloning" then
            return "Neovim Source Cloning.."
          elseif ft == "neovim_updater_term.changes" then
            return "Neovim Source Changelog"
          end
        end,
        icon = "󰅢 ",
        color = "lualine_a_terminal",
        separator = { left = "", right = "" },
        padding = { left = 0, right = 0 },
        cond = function()
          return string.find(vim.bo.filetype, "neovim_updater_term") ~= nil
        end,
      },
  },
  -- Other lualine components
}
```

This configuration hides the file name in lualine when
the `neovim_updater_term` root filetype is detected and
shows the `nvim-updater` component instead.

In this way we can avoid a messy "filename" being displayed
when using the updater and instead display a customized
"Neovim Updating" message.

The condition can also be applied to any other components you
wish to hide when using the updater.

We can also take advantage of the "sub-filetype" to determine
the mode of the updater plugin.

The plugin exposes the following sub-filetypes:

- `neovim_updater_term.updating` - Neovim is updating
- `neovim_updater_term.changes` - Showing Neovim source changes
- `neovim_updater_term.cloning` - Neovim source directory is cloning

### 🪄 Statusline Integration

The plugin exposes a function `nvim_updater.get_statusline()`

This function returns a table of values that can be used to
populate your statusline component.

The table is **not** updated when the function is called.
This prevents blocking or caching from negatively impacting your status component.

Instead, set the `check_for_updates` option to `true` and configure a
`update_interval` in the plugin setup options. The plugin will then
periodically check for updates and update the statusline component
automatically at that interval.

Alternatively, set `check_for_updates` to `false` and manually
call `nvim_updater.utils.get_commit_count()` when you'd like to
refresh the updates.

Here is an example adding a component to the lualine statusline:

```lua
require("lualine").setup {
  sections = {
    lualine_x = {
      { -- Neovim Updater Status
        function()
          return require("nvim_updater").get_statusline().icon_text
        end,
        color = function()
          return require("nvim_updater").get_statusline().color
        end,
        on_click = function()
          require("nvim_updater").show_new_commits(true)
        end,
      },
    },
  },
}
```

This will produce statusline components like this:

![Lualine up-to-date](https://github.com/user-attachments/assets/9e57c41b-cb1c-419a-828c-4399919af980)

![Lualine has-updates](https://github.com/user-attachments/assets/7b0cb567-23ad-4b83-8aae-2a0e0eedf724)

Clicking on the component will open the changelog in a floating terminal.

The `get_statusline()` function provides the following values:

- count: The number of new commits
- text: The text of the status
- icon: An icon representing the update status
- icon_text: The icon and text of the status
- icon_count: The icon and count of the status
- color: A highlight group representing the update status

### Diff Integrations

The plugin exposes a couple additional functions that provide better
integration with other plugins.

#### DiffView Integration

The plugin exposes a function `nvim_updater.show_new_commits_in_diffview()`

This function opens the changelog in
the [DiffView](https://github.com/sindrets/diffview.nvim) plugin.

If the plugin is not installed/available, the function will produce an error
notification and then fallback to opening the changelog in a floating terminal.

#### Telescope Integration

The plugin exposes a function `nvim_updater.show_new_commits_in_telescope()`

This function opens the changelog in
the [Telescope](https://github.com/nvim-telescope/telescope.nvim) plugin.

If the plugin is not installed/available, the function will produce an error
notification and then fallback to opening the changelog in a floating terminal.

---

## 🧰 External Use

You can also use this plugin to update Neovim directly from
the command line or from the desktop.

This is achieved by the use of an environment variable.

The `NVIMUPDATER_HEADLESS` environment variable can be set
to enable headless mode. In this mode, Neovim will be exited
immediately after the update completes.

> [!WARNING]
> Lazy-loading the plugin may prevent headless
> operation from functioning properly.

If you receive an error with external calls:

```vim
E492: Not an editor command: NVUpdateNeovim
```

This generally indicates the plugin was not loaded at startup.

### Command Line

After installing the plugin, you can run the following command:

```sh
NVIMUPDATER_HEADLESS=1 nvim "+NVUpdateNeovim"
```

This command will open Neovim directly to the updater.

- If the update completes successfully, Neovim will be closed.
- If the update fails, the window will be kept open.

You can also alias this command to a shortcut like `nvimup`:

**bash/zsh**:

```bash
alias nvimup='NVIMUPDATER_HEADLESS=1 nvim "+NVUpdateNeovim"'
```

**fish**:

```fish
alias --save nvimup='NVIMUPDATER_HEADLESS=1 nvim "+NVUpdateNeovim"'
```

This will allow you to simply run `nvimup` from anywhere in your terminal.

### Desktop Shortcut

You can also create a desktop shortcut for this command like so:

**nvimup.desktop**:

```desktop
[Desktop Entry]
Name=Neovim Updater
Exec=env NVIMUPDATER_HEADLESS=1 nvim "+NVUpdateNeovim"
Terminal=true
Type=Application
Icon=nvim
```

Place this file in your `~/.local/share/applications` directory.

You will then have a shortcut available in your system's application menu
for updating Neovim called  
`Neovim Updater`. This shortcut will open the updater in your
default terminal emulator.

To use a specific terminal emulator instead of the default,
you can modify the desktop file like so:

**kitty-nvimup.desktop**:

```desktop
[Desktop Entry]
Name=Neovim Updater (kitty)
Exec=env NVIMUPDATER_HEADLESS=1 kitty nvim "+NVUpdateNeovim"
Terminal=false
Type=Application
Icon=nvim
```

This example uses the `kitty` terminal emulator.

You can substitute `kitty` with any terminal emulator of your choice.

---

## ⚠️ Compatibility

- **Platform:** The plugin is primarily developed for Linux environments.
  Although it may work on macOS or other platforms,
  `sudo make install` is hard-coded and assumes a Linux-based setup.
- **Neovim Version:** This plugin requires **Neovim 0.10+** to operate correctly,
  as it depends on specific Lua API features.

---

## 🛠️ Contributing

If you find any issues or have suggestions for improvement,
feel free to open a GitHub issue or send a pull request.
We welcome contributions!

### 🐛 Filing an Issue

Be sure to include the following information when reporting bugs:

1. The output of `nvim --version`.
2. Error messages from Neovim (if any).
3. Steps to reproduce the issue.

### 🚀 PR Submission Guidelines

1. Fork the repository.
2. Create a new branch for your feature or fix.
3. Make your changes, add or update tests, and confirm everything works.
4. Submit a **pull request** with a clear description of the changes made.

---

## 📜 License

This repository is licensed under the [MIT License](LICENSE).  
You are free to use, modify, and distribute this project in your own work.
