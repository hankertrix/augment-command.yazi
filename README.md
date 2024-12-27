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
- [What about the commands are augmented?][augment-section]
- [Augmented commands](#augmented-commands)
- [New commands](#new-commands)
- [Usage](#usage)
- [Licence](#licence)

## Requirements

- [Yazi](https://github.com/sxyazi/yazi) v0.4.2+
- [`7z` or `7zz` command][7z-link]
- [`file` command][file-command-link]

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

| Configuration                       | Values                                | Default   | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| ----------------------------------- | ------------------------------------- | --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `prompt`                            | `true` or `false`                     | `false`   | Create a prompt to choose between hovered and selected items when both exist. If this option is disabled, selected items will only be operated on when the hovered item is selected, otherwise the hovered item will be the default item that is operated on.                                                                                                                                                                                                                                                       |
| `default_item_group_for_prompt`     | `hovered`, `selected` or `none`       | `hovered` | The default item group to operate on when the prompt is submitted without any value. This only takes effect if `prompt` is set to `true`, otherwise this option doesn't do anything. `hovered` means the hovered item is operated on, `selected` means the selected items are operated on, and `none` just cancels the operation.                                                                                                                                                                                   |
| `smart_enter`                       | `true` or `false`                     | `true`    | Use one command to open files or enter a directory. With this option set, the `enter` and `open` commands will both call the `enter` command when a directory is hovered and call the `open` command when a regular file is hovered. You can also enable this behaviour by passing the `--smart` flag to the `enter` or `open` commands.                                                                                                                                                                            |
| `smart_paste`                       | `true` or `false`                     | `false`   | Paste items into a directory without entering it. The behaviour is exactly the same as the [smart paste tip on Yazi's documentation](https://yazi-rs.github.io/docs/tips#smart-paste). Setting this option to `false` will use the default `paste` behaviour. You can also enable this behaviour by passing the `--smart` flag to the `paste` command.                                                                                                                                                              |
| `smart_tab_create`                  | `true` or `false`                     | `false`   | Create tabs in the directory that is being hovered instead of the current directory. The behaviour is exactly the same as the [smart tab tip on Yazi's documentation](https://yazi-rs.github.io/docs/tips#smart-tab). Setting this option to `false` will use the default `tab_create` behaviour, which means you need to pass the `--current` flag to the command. You can also enable this behaviour by passing the `--smart` flag to the `tab_create` command.                                                   |
| `smart_tab_switch`                  | `true` or `false`                     | `false`   | If the tab that is being switched to does not exist yet, setting this option to `true` will create all the tabs in between the current number of open tabs, and the tab that is being switched to. The behaviour is exactly the same as the [smart switch tip on Yazi's documentation](https://yazi-rs.github.io/docs/tips#smart-switch). Setting this option to `false` will use the default `tab_switch` behaviour. You can also enable this behaviour by passing the `--smart` flag to the `tab_switch` command. |
| `open_file_after_creation`          | `true` or `false`                     | `false`   | This option determines whether the plugin will open a file after it has been created. Setting this option to `true` will cause the plugin to open the created file. You can also enable this behaviour by passing the `--open` flag to the `create` command.                                                                                                                                                                                                                                                        |
| `enter_directory_after_creation`    | `true` or `false`                     | `false`   | This option determines whether the plugin will enter a directory after it has been created. Setting this option to `true` will cause the plugin to enter the created directory. You can also enable this behaviour by passing the `--enter` flag to the `create` command.                                                                                                                                                                                                                                           |
| `use_default_create_behaviour`      | `true` or `false`                     | `false`   | This option determines whether the plugin will use the behaviour of Yazi's `create` command. Setting this option to `true` will use the behaviour of Yazi's `create` command. You can also enable this behaviour by passing the `--default-behaviour` flag to the `create` command.                                                                                                                                                                                                                                 |
| `enter_archives`                    | `true` or `false`                     | `true`    | Automatically extract and enter archive files. This option requires the [`7z` or `7zz` command][7z-link] to be present.                                                                                                                                                                                                                                                                                                                                                                                             |
| `extract_retries`                   | An integer, like `1`, `3`, `10`, etc. | `3`       | This option determines how many times the plugin will retry opening an encrypted or password-protected archive when a wrong password is given. This value plus 1 is the total number of times the plugin will try opening an encrypted or password-protected archive.                                                                                                                                                                                                                                               |
| `recursively_extract_archives`      | `true` or `false`                     | `true`    | This option determines whether the plugin will extract all archives inside an archive file recursively. If this option is set to `false`, archive files inside an archive will not be extracted, and you will have to manually extract them yourself.                                                                                                                                                                                                                                                               |
| `must_have_hovered_item`            | `true` or `false`                     | `true`    | This option stops the plugin from executing any commands when there is no hovered item.                                                                                                                                                                                                                                                                                                                                                                                                                             |
| `skip_single_subdirectory_on_enter` | `true` or `false`                     | `true`    | Skip directories when there is only one subdirectory and no other files when entering directories. This behaviour can be turned off by passing the `--no-skip` flag to the `enter` or `open` commands.                                                                                                                                                                                                                                                                                                              |
| `skip_single_subdirectory_on_leave` | `true` or `false`                     | `true`    | Skip directories when there is only one subdirectory and no other files when leaving directories. This behaviour can be turned off by passing the `--no-skip` flag to the `leave` command.                                                                                                                                                                                                                                                                                                                          |
| `wraparound_file_navigation`        | `true` or `false`                     | `false`   | Wrap around from the bottom to the top or from the top to the bottom when using the `arrow` or `parent_arrow` command to navigate.                                                                                                                                                                                                                                                                                                                                                                                  |

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
    recursively_extract_archives = true,
    must_have_hovered_item = true,
    skip_single_subdirectory_on_enter = true,
    skip_single_subdirectory_on_leave = true,
    wraparound_file_navigation = false,
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
    wraparound_file_navigation = true,
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

- The `open` command is augmented as stated in
  [this section above][augment-section].

  Videos:

  - When `prompt` is set to `false`:

    [open-behaviour-video]

  - When `prompt` is set to `true`:

    [open-prompt-video]

- When `smart_enter` is set to `true`,
  it calls the `enter` command when the hovered item is a directory.
- `--smart` flag to use one command to `open` files and `enter` directories.
  This flag will cause the `open` command to call the `enter` command when
  the hovered item is a directory even when `smart_enter` is set to `false`.
  This allows you to set a key to use this behaviour
  with the `open` command instead of using it for
  every `open` command.

  Video:

  [smart-enter-video]

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
  [`7z` or `7zz` command][7z-link]
  to be present to extract the archives.

  Video:

  [open-auto-extract-archives-video]

- If the extracted archive file contains other archive
  files in it, those archives will be automatically
  extracted, keeping the directory structure
  of the archive if the archive doesn't
  only contain a single archive file.
  This feature requires the
  [`file` command][file-command-link]
  to detect the mime type of the extracted file,
  and to check whether it is an archive file or not.
  This makes extracting binaries from
  compressed tarballs much easier, as there's no need
  to press a key twice to decompress and extract
  the compressed tarballs.
  You can disable this feature by setting
  `recursively_extract_archives` to `false`
  in the configuration.

  Video:

  [open-recursively-extract-archives-video]

### Enter (`enter`)

- When `smart_enter` is set to `true`,
  it calls the `open` command when the hovered item is a file.
- `--smart` flag to use one command to `enter` directories and `open` files.
  This flag will cause the `enter` command to call the `open` command when
  the selected items or the hovered item is a file,
  even when `smart_enter` is set to `false`.
  This allows you to set a key to use this behaviour
  with the `enter` command instead of using it for
  every `enter` command.

  Video:

  [smart-enter-video]

- Automatically skips directories that
  contain only one subdirectory when entering directories.
  This can be turned off by setting
  `skip_single_subdirectory_on_enter` to `false` in the configuration.

  Video:

  [enter-skip-single-subdirectory-video]

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

  Video:

  [leave-skip-single-subdirectory-video]

- `--no-skip` flag. It stops the plugin
  from skipping directories that contain only one subdirectory,
  even when `skip_single_subdirectory_on_leave` is set to `true`.
  This allows you to set a key to navigate out of directories
  without skipping the directories that contain only one subdirectory.

### Rename (`rename`)

- The `rename` command is augmented as stated in
  [this section above][augment-section].

  Videos:

  - When `prompt` is set to `false`:

    [rename-behaviour-video]

  - When `prompt` is set to `true`:

    [rename-prompt-video]

### Remove (`remove`)

- The `remove` command is augmented as stated in
  [this section above][augment-section].

  Videos:

  - When `prompt` is set to `false`:

    [remove-behaviour-video]

  - When `prompt` is set to `true`:

    [rename-prompt-video]

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
  If you are using the latest version of Yazi from the main branch,
  the `confirm` component is now exposed to plugin developers and
  the plugin will use the `confirm` component instead.
  However, the separator in the `confirm` component will be the text colour
  instead of your configured border colour for the `confirm` component as
  the `list` part of the `confirm` component has not been exposed to plugin
  developers, so the separator is made using text.
- The rationale for this behaviour is that creating a path without
  a file extension usually means you intend to create a directory instead
  of a file, as files usually have file extensions.

  Video:

  [create-behaviour-video]

- When `open_file_after_creation` is set to `true`, the `create` command
  will `open` the created file. This behaviour can also be enabled by
  passing the `--open` flag to the `create` command.

  Video:

  [create-and-open-files-video]

  Likewise, when `enter_directory_after_creation` is set to `true`,
  the `create` command will `enter` the created directory.
  This behaviour can also be enabled by passing the `--enter` flag
  to the `create` command.

  Video:

  [create-and-open-directories-video]

  To enable both behaviours with flags, just pass both the `--open` flag
  and the `--enter` flag to the `create` command.

  Video:

  [create-and-open-files-and-directories-video]

- If you would like to use the behaviour of Yazi's `create` command,
  probably because you would like to automatically open and enter the created
  file and directory respectively, you can either set
  `use_default_create_behaviour` to `true`,
  or pass the `--default-behaviour` flag to the `create` command.

  Video:

  [create-default-behaviour-video]

### Shell (`shell`)

- This command runs the shell command given with the augment stated in
  [this section above][augment-section]. You should
  only use this command if you need the plugin to determine a suitable
  item group for the command to operate on. Otherwise, you should just
  use the default `shell` command provided by Yazi.

  Videos:

  - When `prompt` is set to `false`:

    [shell-behaviour-video]

  - When `prompt` is set to `true`:

    [shell-prompt-video]

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

  Video:

  [shell-exit-if-directory-video]

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

  Video:

  [smart-paste-video]

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

  Video:

  [smart-tab-create-video]

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

  Video:

  [smart-tab-create-video]

### Arrow (`arrow`)

- When `wraparound_file_navigation` is set to `true`,
  the arrow command will wrap around from the bottom to the top or
  from the top to the bottom when navigating.

  Video:

  [wraparound-arrow-video]

  Otherwise, it'll behave like the default `arrow` command.

## New commands

### Parent arrow (`parent_arrow`)

- This command behaves like the `arrow` command,
  but in the parent directory.
  It allows you to navigate in the parent directory
  without leaving the current directory.

  Video:

  [parent-arrow-video]

- When `wraparound_file_navigation` is set to `true`,
  this command will also wrap around from the bottom to the top or
  from top to the bottom when navigating in the parent directory.

  Video:

  [wraparound-parent-arrow-video]

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
  [this section above][augment-section].

  Videos:

  - When `prompt` is set to `false`:

    [editor-behaviour-video]

  - When `prompt` is set to `true`:

    [editor-prompt-video]

### Pager (`pager`)

- The `pager` command opens the default pager set by the
  `$PAGER` environment variable.
- The command is also augmented as stated in
  [this section above][augment-section].
- The `pager` command will also skip opening directories, as the pager
  cannot open directories and will error out.
  Hence, the command will not do anything when the hovered item
  is a directory, or if **all** the selected items are directories.
  This makes the pager command less annoying as it will not
  try to open a directory and then immediately fail with an error,
  causing a flash and causing Yazi to send a notification.

  Videos:

  - When `prompt` is set to `false`:

    [pager-behaviour-video]

  - When `prompt` is set to `true`:

    [pager-prompt-video]

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
[Yazi's default `keymap.toml` file][yazi-keymap-toml].

Essentially, all you need to do to use this plugin
is to wrap a Yazi command in single quotes,
like `'enter'`,
then add `plugin augment-command --args=`
in front of it, which results in
`plugin augment-command --args='enter'`.

### Full configuration example

For a full configuration example,
you can take a look at [my `keymap.toml` file][my-keymap-toml].

## [Licence]

This plugin is licenced under the [GNU AGPL v3 licence][Licence].
You can view the full licence in the [`LICENSE`][Licence] file.

<!-- Regular links -->

[augment-section]: #what-about-the-commands-are-augmented
[7z-link]: https://www.7-zip.org/
[file-command-link]: https://www.darwinsys.com/file/
[my-keymap-toml]: https://github.com/hankertrix/Dotfiles/blob/main/.config/yazi/keymap.toml
[yazi-keymap-toml]: https://github.com/sxyazi/yazi/blob/main/yazi-config/preset/keymap-default.toml
[Licence]: LICENSE

<!-- Videos -->

<!-- Open command -->

[open-behaviour-video]: https://github.com/user-attachments/assets/5636ffc0-fe24-4da3-9f0e-98de9cd74096
[open-prompt-video]: https://github.com/user-attachments/assets/6bad5a20-e5d3-491d-9c7c-0f5962b77c1c
[open-auto-extract-archives-video]: https://github.com/user-attachments/assets/aeb3368b-4f7d-431e-9f7a-69a443af7153
[open-recursively-extract-archives-video]: https://github.com/user-attachments/assets/44228646-3e82-41e4-a445-f93ab5649309

<!-- Enter command -->

[smart-enter-video]: https://github.com/user-attachments/assets/d3507110-1385-4029-bf64-da3225446d72
[enter-skip-single-subdirectory-video]: https://github.com/user-attachments/assets/2cdb9289-ef41-454f-817b-81beb8a8d030

<!-- Leave command -->

[leave-skip-single-subdirectory-video]: https://github.com/user-attachments/assets/49acdddb-4d04-4624-8d29-057ada33fd01

<!-- Rename command -->

[rename-behaviour-video]: https://github.com/user-attachments/assets/ba6c79e0-9062-43ae-a76b-2782f28a9a18
[rename-prompt-video]: https://github.com/user-attachments/assets/4d42653e-9595-4322-b0c9-451b112dc596

<!-- Remove command -->

[remove-behaviour-video]: https://github.com/user-attachments/assets/cc0617b1-fedf-45d3-b894-00524ba31434
[remove-prompt-video]: https://github.com/user-attachments/assets/d23283fd-5068-429d-b06d-72b0c6a3bb36

<!-- Create command -->

[create-and-open-directories-video]: https://github.com/user-attachments/assets/52b244db-50a8-4adc-912f-239e01a10cc6
[create-and-open-files-video]: https://github.com/user-attachments/assets/8f2306ea-b795-4da4-9867-9a5ed34f7e12
[create-and-open-files-and-directories-video]: https://github.com/user-attachments/assets/ed14e451-a8ca-4622-949f-1469e1d17643
[create-behaviour-video]: https://github.com/user-attachments/assets/8604d1cc-423b-46e8-b464-ef3380435a28
[create-default-behaviour-video]: https://github.com/user-attachments/assets/8c59f579-8f32-443c-8ae1-edd8d18e5ba0

<!-- Shell command -->

[shell-behaviour-video]: https://github.com/user-attachments/assets/5d898205-e5ca-487e-b731-4624ca0123ee
[shell-prompt-video]: https://github.com/user-attachments/assets/d1790105-1e40-4639-bf65-d395a488ae94
[shell-exit-if-directory-video]: https://github.com/user-attachments/assets/a992300a-2eed-40a1-97e4-d4efef57f7f0

<!-- Paste command -->

[smart-paste-video]: https://github.com/user-attachments/assets/9796fbf1-6807-4f74-a0eb-a36c6306c761

<!-- Tab create command -->

[smart-tab-create-video]: https://github.com/user-attachments/assets/2738598c-ccdf-49e4-9d57-90a6378f6155

<!-- Tab switch command -->

[smart-tab-switch-video]: https://github.com/user-attachments/assets/78240347-7d5e-4b45-85df-8446cfb61edf

<!-- Arrow command -->

[wraparound-arrow-video]: https://github.com/user-attachments/assets/28d96bb3-276d-41c8-aa17-eebd7fde9390

<!-- Parent arrow command -->

[parent-arrow-video]: https://github.com/user-attachments/assets/d58a841d-0c05-4555-bf1b-f4d539b9d9c9
[wraparound-parent-arrow-video]: https://github.com/user-attachments/assets/72dcd01a-63f0-4193-9a23-cefa61142d73

<!-- Editor command -->

[editor-behaviour-video]: https://github.com/user-attachments/assets/af057282-8f75-4662-8b4b-29e594cf4163
[editor-prompt-video]: https://github.com/user-attachments/assets/6c12380c-36fb-4a57-bd82-8452fdcad7e6

<!-- Pager command -->

[pager-behaviour-video]: https://github.com/user-attachments/assets/d18aec12-8be3-483a-a24a-2929ad8fc6c2
[pager-prompt-video]: https://github.com/user-attachments/assets/ac3cd3b3-2624-4ea2-b22d-5ab6a49a98c6
