# augment-command.yazi

A [Yazi](https://github.com/sxyazi/yazi)
plugin that enhances Yazi's default commands.
This plugin is inspired by the
[Yazi tips page](https://yazi-rs.github.io/docs/tips),
the [bypass.yazi](https://github.com/Rolv-Apneseth/bypass.yazi) plugin
and the [fast-enter.yazi](https://github.com/ourongxing/fast-enter.yazi)
plugin.

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [What about the commands are augmented?](#what-about-the-commands-are-augmented)
- [Augmented commands](#augmented-commands)
- [New commands](#new-commands)
- [Usage](#usage)
- [Licence](#licence)

## Requirements

- [Yazi](https://github.com/sxyazi/yazi) v0.4.2+
- [`7z` or `7zz` command](https://github.com/p7zip-project/p7zip)
- [`file` command](https://www.darwinsys.com/file/)

## Installation

```sh
# Add the plugin
ya pack -a hankertrix/augment-command

# Install plugin
ya pack -i

# Update plugin
ya pack -u
```

## Configuration

| Configuration                       | Values                                | Default   | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| ----------------------------------- | ------------------------------------- | --------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `prompt`                            | `true` or `false`                     | `false`   | Create a prompt to choose between hovered and selected items when both exist. If this option is disabled, selected items will only be operated on when the hovered item is selected, otherwise the hovered item will be the default item that is operated on.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| `default_item_group_for_prompt`     | `hovered`, `selected` or `none`       | `hovered` | The default item group to operate on when the prompt is submitted without any value. This only takes effect if `prompt` is set to `true`, otherwise this option doesn't do anything. `hovered` means the hovered item is operated on, `selected` means the selected items are operated on, and `none` just cancels the operation.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| `smart_enter`                       | `true` or `false`                     | `true`    | Use one command to open files or enter a directory. With this option set, the `enter` and `open` commands will both call the `enter` command when a directory is hovered and call the `open` command when a regular file is hovered. You can also enable this behaviour by passing the `--smart` flag to the `enter` or `open` commands.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| `smart_paste`                       | `true` or `false`                     | `false`   | Paste items into a directory without entering it. The behaviour is exactly the same as the [smart paste tip on Yazi's documentation](https://yazi-rs.github.io/docs/tips#smart-paste). Setting this option to `false` will use the default `paste` behaviour. You can also enable this behaviour by passing the `--smart` flag to the `paste` command.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| `smart_tab_create`                  | `true` or `false`                     | `false`   | Create tabs in the directory that is being hovered instead of the current directory. The behaviour is exactly the same as the [smart tab tip on Yazi's documentation](https://yazi-rs.github.io/docs/tips#smart-tab). Setting this option to `false` will use the default `tab_create` behaviour, which means you need to pass the `--current` flag to the command. You can also enable this behaviour by passing the `--smart` flag to the `tab_create` command.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| `smart_tab_switch`                  | `true` or `false`                     | `false`   | If the tab that is being switched to does not exist yet, setting this option to `true` will create all the tabs in between the current number of open tabs, and the tab that is being switched to. The behaviour is exactly the same as [this tip](https://github.com/sxyazi/yazi/issues/918#issuecomment-2058157773). Setting this option to `false` will use the default `tab_switch` behaviour. You can also enable this behaviour by passing the `--smart` flag to the `tab_switch` command.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| `open_file_after_creation`          | `true` or `false`                     | `false`   | This option determines whether the plugin will open a file after it has been created. Setting this option to `true` will cause the plugin to open the created file. You can also enable this behaviour by passing the `--open` flag to the `create` command.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| `enter_directory_after_creation`    | `true` or `false`                     | `false`   | This option determines whether the plugin will enter a directory after it has been created. Setting this option to `true` will cause the plugin enter the created directory. You can also enable this behaviour by passing the `--enter` flag to the `create` command.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| `use_default_create_behaviour`      | `true` or `false`                     | `false`   | This option determines whether the plugin will use the behaviour of Yazi's `create` command. Setting this option to `true` will use the behaviour of Yazi's `create` command. You can also enable this behaviour by passing the `--default-behaviour` flag to the `create` command.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| `enter_archives`                    | `true` or `false`                     | `true`    | Automatically extract and enter archive files. This option requires the [7z or 7zz command](https://github.com/p7zip-project/p7zip) to be present.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| `extract_retries`                   | An integer, like `1`, `3`, `10`, etc. | `3`       | This option determines how many times the plugin will retry opening an encrypted or password-protected archive when a wrong password is given. This value plus 1 is the total number of times the plugin will try opening an encrypted or password-protected archive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| `extract_archives_recursively`      | `true` or `false`                     | `true`    | This option determines whether the plugin will extract all archives inside an archive file recursively. If this option is set to `false`, archive files inside an archive will not be extracted, and you will have to manually extract them yourself.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| `must_have_hovered_item`            | `true` or `false`                     | `true`    | This option stops the plugin from executing any commands when there is no hovered item.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| `skip_single_subdirectory_on_enter` | `true` or `false`                     | `true`    | Skip directories when there is only one subdirectory and no other files when entering directories. This behaviour can be turned off by passing the `--no-skip` flag to the `enter` or `open` commands.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| `skip_single_subdirectory_on_leave` | `true` or `false`                     | `true`    | Skip directories when there is only one subdirectory and no other files when leaving directories. This behaviour can be turned off by passing the `--no-skip` flag to the `leave` command.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| `ignore_hidden_items`               | `true` or `false`                     | `false`   | Ignore hidden items when determining whether a directory only has one subdirectory and no other items. Setting this option to `false` will mean that hidden items in a directory will stop the plugin from skipping the single subdirectory.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| `wraparound_file_navigation`        | `true` or `false`                     | `false`   | Wrap around from the bottom to the top or from the top to the bottom when using the `arrow` or `parent_arrow` command to navigate.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| `sort_directories_first`            | `true` or `false`                     | `true`    | This option tells the plugin if you have sorted directories first in your [`yazi.toml` file](https://yazi-rs.github.io/docs/configuration/yazi#manager.sort_dir_first), located at `~/.config/yazi/yazi.toml` on Linux and macOS or `C:\Users\USERNAME\AppData\Roaming\yazi\config\yazi.toml` on Windows, where `USERNAME` is your Windows username. If you have set [`sort_dir_first`](https://yazi-rs.github.io/docs/configuration/yazi#manager.sort_dir_first) to `true` in your [`yazi.toml` file](https://yazi-rs.github.io/docs/configuration/yazi#manager.sort_dir_first), set this option to `true` as well. If you have set [`sort_dir_first`](https://yazi-rs.github.io/docs/configuration/yazi#manager.sort_dir_first) to `false` instead, set this option to `false` as well. This option only affects the `parent_arrow` command with `wraparound_file_navigation` set to `true`. If the [`sort_dir_first`](https://yazi-rs.github.io/docs/configuration/yazi#manager.sort_dir_first) setting doesn't match the plugin's `sort_directories_first` setting, i.e. Yazi's `sort_dir_first` is `true` but the plugin's `sort_directories_first` is `false`, or Yazi's `sort_dir_first` is `false` but the plugin's `sort_directories_first` is `true`, the wraparound functionality of the `parent_arrow` command will not work properly and may act erratically. The default value of `sort_directories_first` follows Yazi's [`sort_dir_first`](https://yazi-rs.github.io/docs/configuration/yazi#manager.sort_dir_first) default value, which is `true`. |

If you would like to use the default configuration, which is shown below,
you don't need to add anything to your `~/.config/yazi/init.lua`
file on Linux and macOS, or your
`C:\Users\USERNAME\AppData\Roaming\yazi\config\init.lua`
file on Windows, where `USERNAME` is your Windows username.

```lua
-- ~/.config/yazi/init.lua for Linux and macOS
-- C:\Users\USERNAME\AppData\Roaming\yazi\config\init.lua for Windows

-- Using the default configuration
require("augment-command"):setup({
    prompt = false,
    default_item_group_for_prompt = "hovered",
    smart_enter = true,
    smart_paste = false,
    smart_tab_create = false,
    smart_tab_switch = false,
    open_file_after_creation = false,
    enter_directory_after_creation = false,
    use_default_create_behaviour = false,
    enter_archives = true,
    extract_retries = 3,
    extract_archives_recursively = true,
    must_have_hovered_item = true,
    skip_single_subdirectory_on_enter = true,
    skip_single_subdirectory_on_leave = true,
    ignore_hidden_items = false,
    wraparound_file_navigation = false,
    sort_directories_first = true,
})
```

However, if you would like to configure the plugin, you can add
your desired configuration options to your `~/.config/yazi/init.lua` file
on Linux and macOS, or your
`C:\Users\USERNAME\AppData\Roaming\yazi\config\init.lua`
file on Windows, where `USERNAME` is your Windows username.
You can leave out configuration options that you would
like to be left as default.
An example configuration is shown below:

```lua
-- ~/.config/yazi/init.lua for Linux and macOS
-- C:\Users\USERNAME\AppData\Roaming\yazi\config\init.lua for Windows

-- Custom configuration
require("augment-command"):setup({
    prompt = true,
    default_item_group_for_prompt = "none",
    open_file_after_creation = true,
    enter_directory_after_creation = true,
    extract_retries = 5,
    ignore_hidden_items = true,
    wraparound_file_navigation = true,
    sort_directories_first = false,
})
```

## What about the commands are augmented?

All commands that can operate on multiple files and directories,
like `open`, `rename`, `remove` and `shell`,
as well as the new commands `editor` and `pager`,
now determine an item group to operate on.
By default, the command will operate on the hovered item,
unless the hovered item is also selected,
then it will operate on the selected items.

- When `must_have_hovered_item` is set to `true`,
  having no hovered item means the plugin will cancel the operation.
- When `must_have_hovered_item` is set to `false` and
  there are selected items, the selected items will be operated on.
- With `prompt` is set to `true`,
  the plugin will always prompt you to
  choose an item group when there are
  both selected items and a hovered item.

## Augmented commands

### Open (`open`)

- When `smart_enter` is set to `true`,
  it calls the `enter` command when the hovered item is a directory.
- `--smart` flag to use one command to `open` files and `enter` directories.
  This flag will cause the `open` command to call the `enter` command when
  the hovered item is a directory even when `smart_enter` is set to `false`.
  This allows you to set a key to use this behaviour
  with the `open` command instead of using it for
  every `open` command.
- `--no-skip` flag, which only applies
  when `smart_enter` is used as it is passed to the `enter` command.
  More details about this flag can be found at the documentation
  for the [enter command](#enter-enter).
- Automatically extracts and enters archive files,
  with support for skipping directories
  that contain only one subdirectory in the extracted archive.
  This can be disabled by setting `enter_archives` to `false`
  in the configuration.
  This feature requires the
  [`7z` or `7zz` command](https://github.com/p7zip-project/p7zip)
  to be present to extract the archives.
- If the extracted archive file contains other archive
  files in it, those archives will be automatically
  extracted, keeping the directory structure
  of the archive if the archive doesn't
  only contain a single archive file.
  This feature requires the
  [`file` command](https://www.darwinsys.com/file/)
  to detect the mime type of the extracted file,
  and to check whether it is an archive file or not.
  This makes extracting binaries from
  compressed tarballs much easier, as there's no need
  to press a key twice to decompress and extract
  the compressed tarballs.
  You can disable this feature by setting
  `extract_archives_recursively` to `false`
  in the configuration.

### Enter (`enter`)

- When `smart_enter` is set to `true`,
  it calls the `open` command when the hovered item is a file.
- Automatically skips directories that
  contain only one subdirectory when entering directories.
  This can be turned off by setting
  `skip_single_subdirectory_on_enter` to `false` in the configuration.
- `--smart` flag to use one command to `enter` directories and `open` files.
  This flag will cause the `enter` command to call the `open` command when
  the selected items or the hovered item is a file,
  even when `smart_enter` is set to `false`.
  This allows you to set a key to use this behaviour
  with the `enter` command instead of using it for
  every `enter` command.
- `--no-skip` flag. It stops the plugin from skipping directories
  that contain only one subdirectory when entering directories,
  even when `skip_single_subdirectory_on_enter` is set to `true`.
  This allows you to set a key to navigate into directories
  without skipping the directories that contain only one subdirectory.

### Leave (`leave`)

- Automatically skips directories that
  contain only one subdirectory when leaving directories.
  This can be turned off by
  setting `skip_single_subdirectory_on_leave` to `false`
  in the configuration.
- `--no-skip` flag. It stops the plugin
  from skipping directories that contain only one subdirectory,
  even when `skip_single_subdirectory_on_leave` is set to `true`.
  This allows you to set a key to navigate out of directories
  without skipping the directories that contain only one subdirectory.

### Rename (`rename`)

- The `rename` command is augmented as stated in
  [this section above](#what-about-the-commands-are-augmented).

### Remove (`remove`)

- The `remove` command is augmented as stated in
  [this section above](#what-about-the-commands-are-augmented).

### Create (`create`)

- You should use Yazi's default `create` command instead of this augmented
  `create` command if you don't want the paths without file extensions to
  be created as directories by default, and you don't care about automatically
  opening and entering the created file and directory respectively.
- The `create` command has a different behaviour from Yazi's `create` command.
  When the path given to the command doesn't have a file extension,
  the `create` command will create a directory instead of a file,
  unlike Yazi's `create` command. Other that this major difference,
  the `create` command functions identically to Yazi's `create` command,
  which means that you can use a trailing `/` on Linux and macOS,
  or `\` on Windows to create a directory. It will also recursively
  create directories to ensure that the path given exists.
  It also supports all the options supported by Yazi's `create` command,
  so you can pass them to the command and expect the same behaviour.
  However, due to the
  [`confirm` component](https://github.com/sxyazi/yazi/issues/2082)
  currently not being exposed to plugin developers, it uses Yazi's input
  component to prompt for a confirmation, like in Yazi v0.3.0 and below.
  This is not ideal, but it shouldn't happen that often and
  hopefully wouldn't be too annoying.
- The rationale for this behaviour is that creating a path without
  a file extension usually means you intend to create a directory instead
  of a file, as files usually have file extensions.
- When `open_file_after_creation` is set to `true`, the `create` command
  will `open` the created file. This behaviour can also be enabled by
  passing the `--open` flag to the `create` command.
  Likewise, when `enter_directory_after_creation` is set to `true`,
  the `create` command will `enter` the created directory.
  This behaviour can also be enabled by passing the `--enter` flag
  to the `create` command.
  To enable both behaviours with flags, just pass both the `--open` flag
  and the `--enter` flag to the `create` command.
- If you would like to use the behaviour of Yazi's `create` command,
  probably because you would like to automatically open and enter the created
  file and directory respectively, you can either set
  `use_default_create_behaviour` to `true`,
  or pass the `--default-behaviour` flag to the `create` command.

### Shell (`shell`)

- This command runs the shell command given with the augment stated in
  [this section above](#what-about-the-commands-are-augmented). You should
  only use this command if you need the plugin to determine a suitable
  item group for the command to operate on. Otherwise, you should just
  use the default `shell` command provided by Yazi.
- To use this command, the syntax is exactly the same as the default
  `shell` command provided by Yazi. You just provide the command you want and
  provide any Yazi shell variable, which is documented
  [here](https://yazi-rs.github.io/docs/configuration/keymap/#manager.shell).
  The plugin will automatically replace the shell variable you give
  with the file paths for the item group before executing the command.
- You will also need to escape the quotes when giving the shell command
  if you use the same quotes to quote the given arguments to the plugin.
  For example, if you pass the arguments to the plugin with double quotes,
  i.e. `--args="shell"`, you will have to escape the double quotes with a
  backslash character, like shown below:

  ```toml
  # ~/.config/yazi/keymap.toml on Linux and macOS
  # C:\Users\USERNAME\AppData\Roaming\yazi\config\keymap.toml on Windows

  [[manager.prepend_keymap]]
  on = [ "o" ]
  run = 'plugin augment-command --args="shell \"$EDITOR $@\" --block"'
  desc = "Open the editor"
  ```

- Alternatively, you can use the triple single quote `'''` delimiter
  for the run string and avoid the escaping the shell command altogether,
  like the two examples below:

  ```toml
  # ~/.config/yazi/keymap.toml on Linux and macOS
  # C:\Users\USERNAME\AppData\Roaming\yazi\config\keymap.toml on Windows

  [[manager.prepend_keymap]]
  on = [ "o" ]
  run = '''plugin augment-command --args='shell "$EDITOR $@" --block''''
  desc = "Open the editor"

  [[manager.prepend_keymap]]
  on = [ "i" ]
  run = '''plugin augment-command --args="shell '$PAGER $@' --block"'''
  desc = "Open the pager"
  ```

- `--exit-if-dir` flag to stop the shell command given
  from executing if the item group consists only of directories.
  For example, if the item group is the hovered item, then
  the shell command will not be executed if the hovered item
  is a directory. If the item group is the selected items group,
  then the shell command will not be executed if **all**
  the selected items are directories. This behaviour comes
  from it being used in the `pager` command.
  The `pager` command is essentially:

  ```toml
  # ~/.config/yazi/keymap.toml on Linux and macOS
  # C:\Users\USERNAME\AppData\Roaming\yazi\config\keymap.toml on Windows

  [[manager.prepend_keymap]]
  on = [ "i" ]
  run = '''plugin augment-command --args="shell '$PAGER $@' --block --exit-if-dir"'''
  desc = "Open the pager"
  ```

### Paste (`paste`)

- When `smart_paste` is set to `true`,
  the `paste` command will paste items
  into the hovered directory without entering it.
  If the hovered item is not a directory,
  the command pastes in the current directory instead.
  Otherwise, when `smart_paste` is set to `false`,
  the `paste` command will behave like the default
  `paste` command.
- `--smart` flag to enable pasting in the hovered directory
  without entering the directory.
  This flag will cause the `paste` command to paste items
  into the hovered directory even when `smart_paste` is set to `false`.
  This allows you to set a key to use this behaviour
  with the `paste` command instead of using it for
  every `paste` command.

### Tab create (`tab_create`)

- When `smart_tab_create` is set to `true`,
  the `tab_create` command will create a tab
  in the hovered directory instead of the
  current directory like the default key binds.
  If the hovered item is not a directory,
  then the command just creates a new tab in
  the current directory instead.
  Otherwise, when `smart_tab_create` is set to
  `false`, the `tab_create` command will behave
  like the default key bind to create a tab,
  which is `tab_create --current`.
- `--smart` flag to enable creating a tab
  in the hovered directory.
  This flag will cause the `tab_create` command
  to create a tab in the hovered directory even
  when `smart_tab_create` is set to `false`.
  This allows you to set a specific key to use this
  behaviour with the `tab_create` command instead
  of using it for every `tab_create` command.

### Tab switch (`tab_switch`)

- When `smart_tab_switch` is set to `true`,
  the `tab_switch` command will ensure that
  the tab that is being switched to exist.
  It does this by automatically creating
  all the tabs required for the desired
  tab to exist.
  For example, if you are switching to
  tab 5 (`tab_switch 4`), and you only have
  two tabs currently open (tabs 1 and 2),
  the plugin will create tabs 3, 4 and 5
  and then switch to tab 5.
  The tabs are created using the current
  directory. The `smart_tab_create`
  configuration option does not affect
  the behaviour of this command.
  Otherwise, when `smart_tab_switch` is
  set to `false`, the `tab_switch` command
  will behave like the default `tab_switch`
  command, and simply switch to the tab
  if it exists, and do nothing if it doesn't
  exist.
- `--smart` flag to automatically create
  the required tabs for the desired tab
  to exist.
  This flag will cause the `tab_switch`
  command to automatically create the
  required tabs even when `smart_tab_switch`
  is set to `false`.
  This allows you to set a specific key to use this
  behaviour with the `tab_switch` command instead
  of using it for every `tab_switch` command.

### Arrow (`arrow`)

- When `wraparound_file_navigation` is set to `true`,
  the arrow command will wrap around from the bottom to the top or
  from the top to the bottom when navigating.
  Otherwise, it'll behave like the default `arrow` command.

## New commands

### Parent arrow (`parent_arrow`)

- This command behaves like the `arrow` command,
  but in the parent directory.
  It allows you to navigate in the parent directory
  without leaving the current directory.
- When `wraparound_file_navigation` is set to `true`,
  this command will also wrap around from the bottom to the top or
  from top to the bottom when navigating in the parent directory.
  For this feature to work properly, the
  [`sort_dir_first`](https://yazi-rs.github.io/docs/configuration/yazi#manager.sort_dir_first)
  option in your `~/.config/yazi/yazi.toml` file on Linux and macOS,
  or your `C:\Users\USERNAME\AppData\Roaming\yazi\config\yazi.toml`
  file on Windows, where `USERNAME` is your Windows username,
  has to match the plugin's `sort_directories_first` option,
  i.e. if you have set the
  [`sort_dir_first`](https://yazi-rs.github.io/docs/configuration/yazi#manager.sort_dir_first)
  to `true` in your `~/.config/yazi/yazi.toml` file on Linux and macOS,
  or your `C:\Users\USERNAME\AppData\Roaming\yazi\config\yazi.toml`
  on Windows, like so:

  ```toml
  # ~/.config/yazi/yazi.toml on Linux and macOS
  # C:\Users\USERNAME\AppData\Roaming\yazi\config\yazi.toml on Windows

  [manager]
  sort_dir_first = true
  ```

  Then `sort_directories_first` should be set to `true`
  as well in your `~/.config/yazi/init.lua` file on Linux and macOS,
  or your `C:\Users\USERNAME\AppData\Roaming\yazi\config\yazi.toml`
  file on Windows, where `USERNAME` is your Windows username, like so:

  ```lua
  -- ~/.config/yazi/init.lua on Linux and macOS
  -- C:\Users\USERNAME\AppData\Roaming\yazi\config\init.lua on Windows

  require("augment-command"):setup({
      sort_directories_first = true
  })
  ```

  If your `~/.config/yazi/yazi.toml` file on Linux and macOS, or your
  `C:\Users\USERNAME\AppData\Roaming\yazi\config\yazi.toml` file on Windows,
  where `USERNAME` is your Windows username, has
  [`sort_dir_first`](https://yazi-rs.github.io/docs/configuration/yazi#manager.sort_dir_first)
  set to `false`, like so:

  ```toml
  # ~/.config/yazi/yazi.toml on Linux and macOS
  # C:\Users\USERNAME\AppData\Roaming\yazi\config\yazi.toml on Windows

  [manager]
  sort_dir_first = false
  ```

  Then `sort_directories_first` should be set to `false`
  as well in your `~/.config/yazi/init.lua` file on Linux and macOS,
  or your `C:\Users\USERNAME\AppData\Roaming\yazi\config\yazi.toml`
  file on Windows, where `USERNAME` is your Windows username, like so:

  ```lua
  -- ~/.config/yazi/init.lua on Linux and macOS
  -- C:\Users\USERNAME\AppData\Roaming\yazi\config\init.lua on Windows

  require("augment-command"):setup({
      sort_directories_first = false
  })
  ```

  The default value of `sort_directories_first` follows Yazi's
  [`sort_dir_first`](https://yazi-rs.github.io/docs/configuration/yazi#manager.sort_dir_first)
  default value, which is `true`.

- You can also replicate this using this series of commands below,
  but it doesn't work as well,
  and doesn't support wraparound navigation:

  ```toml
  # ~/.config/yazi/keymap.toml on Linux and macOS
  # C:\Users\USERNAME\AppData\Roaming\yazi\config\keymap.toml on Windows

  # Use K to move up in the parent directory
  [[manager.prepend_keymap]]
  on   = [ "K" ]
  run  = [ "leave", "arrow -1", "enter" ]
  desc = "Move up in the parent directory"


  # Use J to move down in the parent directory
  [[manager.prepend_keymap]]
  on   = [ "J" ]
  run  = [ "leave", "arrow 1", "enter" ]
  desc = "Move down in the parent directory"
  ```

### Editor (`editor`)

- The `editor` command opens the default editor set by the
  `$EDITOR` environment variable.
- The command is also augmented as stated in
  [this section above](#what-about-the-commands-are-augmented).

### Pager (`pager`)

- The `pager` command opens the default pager set by the
  `$PAGER` environment variable.
- The command is also augmented as stated in
  [this section above](#what-about-the-commands-are-augmented).
- The `pager` command will also skip opening directories, as the pager
  cannot open directories and will error out.
  Hence, the command will not do anything when the hovered item
  is a directory, or if **all** the selected items are directories.
  This makes the pager command less annoying as it will not
  try to open a directory and then immediately fail with an error,
  causing a flash and causing Yazi to send a notification.

## Usage

Add the commands that you would like to use to your `keymap.toml` file,
located at `~/.config/yazi/keymap.toml` on Linux and macOS
and at `C:\Users\USERNAME\AppData\Roaming\yazi\config\keymap.toml`
on Windows, in this format:

```toml
# ~/.config/yazi/keymap.toml on Linux and macOS
# C:\Users\USERNAME\AppData\Roaming\yazi\config\keymap.toml on Windows

[[manager.prepend_keymap]]
on = [ "key" ]
run = "plugin augment-command --args='command arguments --flags --options=42'"
desc = "Description"
```

For example, to use the augmented `enter` command:

```toml
# ~/.config/yazi/keymap.toml on Linux and macOS
# C:\Users\USERNAME\AppData\Roaming\yazi\config\keymap.toml on Windows

[[manager.prepend_keymap]]
on = [ "l" ]
run = "plugin augment-command --args='enter'"
desc = "Enter a directory and skip directories with only a single subdirectory"
```

All the default arguments, flags and options provided by Yazi
are also supported, for example:

```toml
# ~/.config/yazi/keymap.toml on Linux and macOS
# C:\Users\USERNAME\AppData\Roaming\yazi\config\keymap.toml on Windows

[[manager.prepend_keymap]]
on   = [ "k" ]
run  = "plugin augment-command --args='arrow -1'"
desc = "Move cursor up"

[[manager.prepend_keymap]]
on = [ "r" ]
run = "plugin augment-command --args='rename --cursor=before_ext'"
desc = "Rename a file or directory"

[[manager.prepend_keymap]]
on = [ "D" ]
run = "plugin augment-command --args='remove --permanently'"
desc = "Permanently delete the files"
```

For the default descriptions of the commands, you can refer to
[Yazi's default `keymap.toml` file](https://github.com/sxyazi/yazi/blob/main/yazi-config/preset/keymap-default.toml).

Essentially, all you need to do to use this plugin
is to wrap a Yazi command in single quotes,
like `'enter'`,
then add `plugin augment-command --args=`
in front of it, which results in
`plugin augment-command --args='enter'`.

### Full configuration example

For a full configuration example,
you can take a look at
[my `keymap.toml` file](https://github.com/hankertrix/Dotfiles/blob/main/.config/yazi/keymap.toml).

## [Licence](LICENSE)

This plugin is licenced under the [GNU AGPL v3 licence](LICENSE).
You can view the full licence in the [`LICENSE`](LICENSE) file.
