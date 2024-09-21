# Neovim Updater Plugin

This plugin allows you to easily update Neovim from source,
with fully customizable options to define where the source is cloned,
which branch is tracked, and the desired build type.

All without leaving Neovim.

## Demo

https://github.com/rootiest/nvim-updater.nvim/raw/refs/heads/main/.img/nvim_updater.webm

## 🔧 Prerequisites

- A Linux system (macOS and Windows are not supported by this plugin)
- [Neovim 0.10+](https://neovim.io/)
  (earlier versions may work, but could encounter issues)
- [Build prerequisites](https://github.com/neovim/neovim/blob/master/BUILD.md#build-prerequisites)
  for your platform

> It is recommended to uninstall any distro-provided neovim packages after
> installing from source (with this plugin or manually) to prevent those
> distro-packaged updates from overwriting the locally-built neovim binary.

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
      ":RemoveNeovimSource<CR>",
      desc = "Remove Neovim Source Directory",
    },
  }
}
```

Minimal example with defaults:

```lua
  {
    "rootiest/nvim-updater.nvim",
    opts = {},
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
  dedicated buffer **filetype** for customization and
  a status component.
- Integrates with `DiffView` and `Telescope` plugins

---

## ⚙️Configuration

The `setup` function accepts an optional table to configure the plugin’s behavior.

### Available Options

- **`source_dir`**: Path to where the Neovim source is cloned. Default is `~/.local/src/neovim`.
- **`build_type`**: The build type to use, e.g.,
  `Release`, `Debug`, or `RelWithDebInfo`. Default is `RelWithDebInfo`.
- **`branch`**: The branch to track when cloning Neovim. Default is `master`.
- **`verbose`**: (boolean) Enable verbose output. Default is `false`.
- **`check_for_updates`**: (boolean) Enable automatic update checks. Default is `false`.
- **`update_interval`**: (number) Update interval in seconds. Default is `6 hours`.
- **`default_keymaps`**: (boolean) Enable default keymaps. Default is `true`.

### Example Setup

```lua
require("nvim_updater").setup({
  source_dir = "~/projects/neovim",  -- Custom source directory
  build_type = "Release",            -- Use Release mode for building
  branch = "master",                 -- Default to the 'master' branch
  verbose = false,                   -- Disable verbose output
  check_for_updates = false,         -- Disable automatic update checks
  update_interval = (60 * 60) * 6,   -- 6 hours default update interval
  default_keymaps = true,            -- Enable default keymaps
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

- **`:UpdateNeovim`**: Updates Neovim from the source, using the default
  or custom options you’ve set (e.g., source directory, build type, and branch).
  If the source does not exist at the specified path,
  the repository is cloned and built.

  ```vim
  :UpdateNeovim
  ```

This command pulls the latest changes from the source
and builds Neovim based on your configuration.

- **`:RemoveNeovimSource`**: Removes the source directory.

  ```vim
  :RemoveNeovimSource
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

![lualine_up2date](./.img/lualine_up2date.png)

![lualine_updates](./.img/lualine_updates.png)

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

### Command Line

After installing the plugin, you can run the following command:

```sh
NVIMUPDATER_HEADLESS=1 nvim "+UpdateNeovim"
```

This command will open Neovim directly to the updater.

- If the update completes successfully, Neovim will be closed.
- If the update fails, the window will be kept open.

You can also alias this command to a shortcut like `nvimup`:

**bash/zsh**:

```bash
alias nvimup='NVIMUPDATER_HEADLESS=1 nvim "+UpdateNeovim"'
```

**fish**:

```fish
alias --save nvimup='NVIMUPDATER_HEADLESS=1 nvim "+UpdateNeovim"'
```

This will allow you to simply run `nvimup` from anywhere in your terminal.

### Desktop Shortcut

You can also create a desktop shortcut for this command like so:

**nvimup.desktop**:

```desktop
[Desktop Entry]
Name=Neovim Updater
Exec=env NVIMUPDATER_HEADLESS=1 nvim "+UpdateNeovim"
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
Exec=env NVIMUPDATER_HEADLESS=1 kitty nvim "+UpdateNeovim"
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
