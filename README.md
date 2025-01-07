# augment-command.yazi

A [Yazi][yazi-link] plugin that enhances Yazi's default commands.
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

### Optional dependencies

- [`tar` command][gnu-tar-link] for the `preserve_file_permissions` option

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

| Configuration                       | Values                                | Default   | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| ----------------------------------- | ------------------------------------- | --------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `prompt`                            | `true` or `false`                     | `false`   | Create a prompt to choose between hovered and selected items when both exist. If this option is disabled, selected items will only be operated on when the hovered item is selected, otherwise the hovered item will be the default item that is operated on.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| `default_item_group_for_prompt`     | `hovered`, `selected` or `none`       | `hovered` | The default item group to operate on when the prompt is submitted without any value. This only takes effect if `prompt` is set to `true`, otherwise this option doesn't do anything. `hovered` means the hovered item is operated on, `selected` means the selected items are operated on, and `none` just cancels the operation.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| `smart_enter`                       | `true` or `false`                     | `true`    | Use one command to open files or enter a directory. With this option set, the `enter` and `open` commands will both call the `enter` command when a directory is hovered and call the `open` command when a regular file is hovered. You can also enable this behaviour by passing the `--smart` flag to the `enter` or `open` commands.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| `smart_paste`                       | `true` or `false`                     | `false`   | Paste items into a directory without entering it. The behaviour is exactly the same as the [smart paste tip on Yazi's documentation][smart-paste-tip]. Setting this option to `false` will use the default `paste` behaviour. You can also enable this behaviour by passing the `--smart` flag to the `paste` command.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| `smart_tab_create`                  | `true` or `false`                     | `false`   | Create tabs in the directory that is being hovered instead of the current directory. The behaviour is exactly the same as the [smart tab tip on Yazi's documentation][smart-tab-tip]. Setting this option to `false` will use the default `tab_create` behaviour, which means you need to pass the `--current` flag to the command. You can also enable this behaviour by passing the `--smart` flag to the `tab_create` command.                                                                                                                                                                                                                                                                                                                                                                                                 |
| `smart_tab_switch`                  | `true` or `false`                     | `false`   | If the tab that is being switched to does not exist yet, setting this option to `true` will create all the tabs in between the current number of open tabs, and the tab that is being switched to. The behaviour is exactly the same as the [smart switch tip on Yazi's documentation][smart-switch-tip]. Setting this option to `false` will use the default `tab_switch` behaviour. You can also enable this behaviour by passing the `--smart` flag to the `tab_switch` command.                                                                                                                                                                                                                                                                                                                                               |
| `open_file_after_creation`          | `true` or `false`                     | `false`   | This option determines whether the plugin will open a file after it has been created. Setting this option to `true` will cause the plugin to open the created file. You can also enable this behaviour by passing the `--open` flag to the `create` command.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| `enter_directory_after_creation`    | `true` or `false`                     | `false`   | This option determines whether the plugin will enter a directory after it has been created. Setting this option to `true` will cause the plugin to enter the created directory. You can also enable this behaviour by passing the `--enter` flag to the `create` command.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| `use_default_create_behaviour`      | `true` or `false`                     | `false`   | This option determines whether the plugin will use the behaviour of Yazi's `create` command. Setting this option to `true` will use the behaviour of Yazi's `create` command. You can also enable this behaviour by passing the `--default-behaviour` flag to the `create` command.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| `enter_archives`                    | `true` or `false`                     | `true`    | Automatically extract and enter archive files. This option requires the [`7z` or `7zz` command][7z-link] to be present.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| `extract_retries`                   | An integer, like `1`, `3`, `10`, etc. | `3`       | This option determines how many times the plugin will retry opening an encrypted or password-protected archive when a wrong password is given. This value plus 1 is the total number of times the plugin will try opening an encrypted or password-protected archive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| `recursively_extract_archives`      | `true` or `false`                     | `true`    | This option determines whether the plugin will extract all archives inside an archive file recursively. If this option is set to `false`, archive files inside an archive will not be extracted, and you will have to manually extract them yourself.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| `preserve_file_permissions`         | `true` or `false`                     | `false`   | This option determines whether to preserve the file permissions of the items in the extracted archive. Setting this option to `true` will preserve the file permissions of the extracted items. It requires the [`tar` command][gnu-tar-link] and will only work on `tar` archives, or tarballs, as [`7z`][7z-link] does not support preserving file permissions. You will receive a warning if you have this option set but [`tar`][gnu-tar-link] is not installed. Do note that there are significant security implications of setting this option to `true`, as any executable file or binary in an archive can be immediately executed after it is extracted, which can compromise your system if you extract a malicious archive. As such, the default value is `false`, and it is strongly recommended to leave it as such. |
| `must_have_hovered_item`            | `true` or `false`                     | `true`    | This option stops the plugin from executing any commands when there is no hovered item.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| `skip_single_subdirectory_on_enter` | `true` or `false`                     | `true`    | Skip directories when there is only one subdirectory and no other files when entering directories. This behaviour can be turned off by passing the `--no-skip` flag to the `enter` or `open` commands.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| `skip_single_subdirectory_on_leave` | `true` or `false`                     | `true`    | Skip directories when there is only one subdirectory and no other files when leaving directories. This behaviour can be turned off by passing the `--no-skip` flag to the `leave` command.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| `wraparound_file_navigation`        | `true` or `false`                     | `false`   | Wrap around from the bottom to the top or from the top to the bottom when using the `arrow` or `parent_arrow` command to navigate.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |

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
    preserve_file_permissions = false,
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
as well as the new commands `extract`, `editor` and `pager`,
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

  - When `prompt` is set to `true`:

    [open-prompt-video]

  - When `prompt` is set to `false`:

    [open-behaviour-video]

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

- The `open` command makes use of the `extract` command,
  so recursively extracting archives is also supported.
  For more information, look at the section about the
  [`extract` command](#extract-extract).

  Video:

  [open-recursively-extract-archives-video]

### Extract (`extract`)

- Technically this is a new command, as Yazi does not provide an `extract`
  command. However, Yazi does provide a built-in plugin called `extract`,
  so this command is included in the
  [augmented commands section](#augmented-commands) instead of the
  [new commands section](#new-commands).
- This command requires the [`7z` or `7zz` command][7z-link] to
  be present to extract the archives, as well as the
  [`file` command][file-command-link] to check if a file is an archive or not.
- You are not meant to use this command directly. However, you can do so
  if you like, as the extract command is also augmented as stated in
  [this section above][augment-section].

  Videos:

  - When `must_have_hovered_item` is `true`:

    [extract-must-have-hovered-item-video]

  - When `must_have_hovered_item` is `false`:

    [extract-hovered-item-optional-video]

  - When `prompt` is set to `true`:

    [extract-prompt-video]

  - When `prompt` is set to `false`:

    [extract-behaviour-video]

- Instead, this command is intended to replace the built-in `extract` plugin,
  which is used for the `extract` opener. This way, you can use the
  features that come with the augmented `extract` command, like
  recursively extracting archives, with the `open` command.
  This is the intended way to use this command, as the `open` command is
  meant to be the command that opens everything, so it is a bit
  counterintuitive to have to use a special key bind to extract archives.

  To replace the built-in `extract` plugin, copy the
  [`extract` openers section][yazi-yazi-toml-extract-openers]
  in [Yazi's default `yazi.toml`][yazi-yazi-toml] into your `yazi.toml`,
  which is located at `~/.config/yazi/yazi.toml` for Linux and macOS, and
  `C:\Users\USERNAME\AppData\Roaming\yazi\config\yazi.toml`
  file on Windows, where `USERNAME` is your Windows username.
  Make sure that the `extract` openers are under the `opener` key in your
  `yazi.toml`. Then replace `extract` with `augmented-extract`,
  and you will be using the plugin's `extract` command instead of
  Yazi's built-in `extract` plugin.

  Here is an example configuration:

  ```toml
  # ~/.config/yazi/yazi.toml for Linux and macOS
  # C:\Users\USERNAME\AppData\Roaming\yazi\config\yazi.toml for Windows

  [opener]
  extract = [
      { run = 'ya pub augmented-extract --list "$@"', desc = "Extract here", for = "unix" },
      { run = 'ya pub augmented-extract --list %*',   desc = "Extract here", for = "windows" },
  ]
  ```

  If that exceeds your editor's line length limit, another way to do it is:

  ```toml
  # ~/.config/yazi/yazi.toml for Linux and macOS
  # C:\Users\USERNAME\AppData\Roaming\yazi\config\yazi.toml for Windows

  [[opener.extract]]
  run = 'ya pub augmented-extract --list "$@"'
  desc = "Extract here"
  for = "unix"

  [[opener.extract]]
  run = 'ya pub augmented-extract --list %*'
  desc = "Extract here"
  for = "windows"
  ```

- The `extract` command supports recursively extracting archives,
  which means if the extracted archive file contains other archive
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

  [extract-recursively-extract-archives-video]

- The `extract` command also supports extracting encrypted archives,
  and will prompt you for a password when it encounters an encrypted
  archive. You can configure the number of times the plugin prompts
  you for a password by setting the `extract_retries` configuration
  option. The default value is `3`, which means the plugin will
  prompt you `3` more times for the correct password after the
  initial password attempt before giving up and showing an error.

  Video:

  [extract-encrypted-archive]

- The `preserve_file_permissions` configuration option applies to
  the `extract` command, and requires the [`tar` command][gnu-tar-link]
  to be present, as [`7z`][7z-link] does not support preserving
  file permissions. The plugin will show a warning if the
  `preserve_file_permissions` option is set to `true` but
  [`tar`][gnu-tar-link] is not installed.

  For macOS users, it is highly recommended to install and use
  [GNU `tar`, or `gtar`][gnu-tar-link] instead of the
  [Apple provided `tar` command][apple-tar-link].
  You can install it using the [`brew`][brew-link] command below:

  ```sh
  brew install gnu-tar
  ```

  The plugin will automatically use [GNU `tar`][gnu-tar-link]
  if it finds the [`gtar` command][gnu-tar-link] instead
  of the [Apple provided `tar` command][apple-tar-link].

  Setting the `preserve_file_permissions` configuration option to `true`
  will preserve the file permissions of the files contained in a `tar`
  archive or tarball.

  This has considerable security implications, as executables extracted from
  all `tar` archives can be immediately executed on your system, possibly
  compromising your system if you extract a malicious `tar` archive.
  Hence, this option is set to `false` by default, and should be left as such.
  This option is provided for your convenience, but do seriously consider
  if such convenience is worth the risk of extracting a malicious `tar`
  archive that executes malware on your system.

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

  - When `must_have_hovered_item` is `true`:

    [rename-must-have-hovered-item-video]

  - When `must_have_hovered_item` is `false`:

    [rename-hovered-item-optional-video]

  - When `prompt` is set to `true`:

    [rename-prompt-video]

  - When `prompt` is set to `false`:

    [rename-behaviour-video]

### Remove (`remove`)

- The `remove` command is augmented as stated in
  [this section above][augment-section].

  Videos:

  - When `must_have_hovered_item` is `true`:

    [remove-must-have-hovered-item-video]

  - When `must_have_hovered_item` is `false`:

    [remove-hovered-item-optional-video]

  - When `prompt` is set to `true`:

    [remove-prompt-video]

  - When `prompt` is set to `false`:

    [remove-behaviour-video]

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

  [create-and-enter-directories-video]

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

  - When `must_have_hovered_item` is `true`:

    [shell-must-have-hovered-item-video]

  - When `must_have_hovered_item` is `false`:

    [shell-hovered-item-optional-video]

  - When `prompt` is set to `true`:

    [shell-prompt-video]

  - When `prompt` is set to `false`:

    [shell-behaviour-video]

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

  It is also used in the `editor` command, since you usually wouldn't use
  your text editor to open directories, especially if you are already using
  a terminal file manager like [Yazi][yazi-link].
  The `editor` command is essentially:

  ```toml
  # ~/.config/yazi/keymap.toml on Linux and macOS
  # C:\Users\USERNAME\AppData\Roaming\yazi\config\keymap.toml on Windows

  [[manager.prepend_keymap]]
  on = [ "i" ]
  run = '''plugin augment-command --args="shell '$EDITOR $@' --block --exit-if-dir"'''
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

  [smart-tab-switch-video]

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

  - When `must_have_hovered_item` is `true`:

    [editor-must-have-hovered-item-video]

  - When `must_have_hovered_item` is `false`:

    [editor-hovered-item-optional-video]

  - When `prompt` is set to `true`:

    [editor-prompt-video]

  - When `prompt` is set to `false`:

    [editor-behaviour-video]

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

  - When `must_have_hovered_item` is `true`:

    [pager-must-have-hovered-item-video]

  - When `must_have_hovered_item` is `false`:

    [pager-hovered-item-optional-video]

  - When `prompt` is set to `true`:

    [pager-prompt-video]

  - When `prompt` is set to `false`:

    [pager-behaviour-video]

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

### Using the `extract` command as an opener

This is the intended way to use the `extract` command instead of binding
the `extract` command to a key in your `keymap.toml` file.
Look at the [`extract` command section](#extract-extract)
for details on how to do so.

### Full configuration example

For a full configuration example,
you can take a look at [my `keymap.toml` file][my-keymap-toml]
and [my `yazi.toml` file][my-yazi-toml].

## [Licence]

This plugin is licenced under the [GNU AGPL v3 licence][Licence].
You can view the full licence in the [`LICENSE`][Licence] file.

<!-- Regular links -->

[yazi-link]: https://github.com/sxyazi/yazi
[smart-paste-tip]: https://yazi-rs.github.io/docs/tips#smart-paste
[smart-tab-tip]: https://yazi-rs.github.io/docs/tips#smart-tab
[smart-switch-tip]: https://yazi-rs.github.io/docs/tips#smart-switch
[augment-section]: #what-about-the-commands-are-augmented
[7z-link]: https://www.7-zip.org/
[file-command-link]: https://www.darwinsys.com/file/
[gnu-tar-link]: https://www.gnu.org/software/tar/
[apple-tar-link]: https://ss64.com/mac/tar.html
[brew-link]: https://brew.sh/
[yazi-yazi-toml-extract-openers]: https://github.com/sxyazi/yazi/blob/main/yazi-config/preset/yazi-default.toml#L51-L54
[yazi-yazi-toml]: https://github.com/sxyazi/yazi/blob/main/yazi-config/preset/yazi-default.toml
[yazi-keymap-toml]: https://github.com/sxyazi/yazi/blob/main/yazi-config/preset/keymap-default.toml
[my-keymap-toml]: https://github.com/hankertrix/Dotfiles/blob/main/.config/yazi/keymap.toml
[my-yazi-toml]: https://github.com/hankertrix/Dotfiles/blob/main/.config/yazi/yazi.toml
[Licence]: LICENSE

<!-- Videos -->

<!-- Open command -->

[open-prompt-video]: https://github.com/user-attachments/assets/82ddc67d-0b79-4487-8d29-6fd1eb754a8e
[open-behaviour-video]: https://github.com/user-attachments/assets/3f8eec80-ae39-4071-b7ed-e9e9367f10fe
[open-auto-extract-archives-video]: https://github.com/user-attachments/assets/35b356ed-9c3f-4093-ab59-f85ae64de757
[open-recursively-extract-archives-video]: https://github.com/user-attachments/assets/dd1a5bd4-c7af-4d0a-9bf5-b087ee5a06f0

<!-- Extract command -->

[extract-must-have-hovered-item-video]: https://github.com/user-attachments/assets/7c0516ff-01fd-48c2-ba27-4449ffede933
[extract-hovered-item-optional-video]: https://github.com/user-attachments/assets/07ef7d25-3284-4d93-9485-c8635519c57e
[extract-prompt-video]: https://github.com/user-attachments/assets/be2cabc3-b47d-4aac-ac45-0f26957c606b
[extract-behaviour-video]: https://github.com/user-attachments/assets/6ea90612-da8f-45ad-8310-9b38c9e5a6f9
[extract-recursively-extract-archives-video]: https://github.com/user-attachments/assets/bbf7f670-f86d-4aa4-85c7-35b41170924e
[extract-encrypted-archive]: https://github.com/user-attachments/assets/58645691-3559-44ad-918e-8c2cd127252f

<!-- Enter command -->

[smart-enter-video]: https://github.com/user-attachments/assets/a00da3f5-305a-4615-b55c-483a06dd56d7
[enter-skip-single-subdirectory-video]: https://github.com/user-attachments/assets/25ca5fb5-68f9-45fe-bf32-369e9335505d

<!-- Leave command -->

[leave-skip-single-subdirectory-video]: https://github.com/user-attachments/assets/4740fdae-2cd9-463d-b67b-7cdfd8d8b9a1

<!-- Rename command -->

[rename-must-have-hovered-item-video]: https://github.com/user-attachments/assets/fd88a198-3de3-4d2b-8bcf-8d68142c965f
[rename-hovered-item-optional-video]: https://github.com/user-attachments/assets/324dcd94-6f83-49a2-9390-5f41da520689
[rename-prompt-video]: https://github.com/user-attachments/assets/5aba29ae-8b16-4b92-a99c-ff7f0ec925fa
[rename-behaviour-video]: https://github.com/user-attachments/assets/280db6dd-10e4-4255-8c12-e13d23105e90

<!-- Remove command -->

[remove-must-have-hovered-item-video]: https://github.com/user-attachments/assets/18649ff1-ef0d-409a-8f01-29431dcc8f2e
[remove-hovered-item-optional-video]: https://github.com/user-attachments/assets/6e9f5ca0-9b9f-47f8-8499-2b2c1db9f47c
[remove-prompt-video]: https://github.com/user-attachments/assets/3f94c6f8-2ffd-4970-a5a4-5ac6b3a621c0
[remove-behaviour-video]: https://github.com/user-attachments/assets/37d3c059-84ff-4475-908b-2c167b23c488

<!-- Create command -->

[create-and-enter-directories-video]: https://github.com/user-attachments/assets/a102f918-8d99-491f-a6e3-fd8151f16f96
[create-and-open-files-video]: https://github.com/user-attachments/assets/14341b9b-a048-4ea2-9322-e963293b6813
[create-and-open-files-and-directories-video]: https://github.com/user-attachments/assets/dd05d84a-716b-4c4b-8e77-429bbfb4ea43
[create-behaviour-video]: https://github.com/user-attachments/assets/2ee90aa4-1d2f-484c-86c6-2e65cd895080
[create-default-behaviour-video]: https://github.com/user-attachments/assets/5e9305c0-e56c-4fc3-b36b-e86c43571b06

<!-- Shell command -->

[shell-must-have-hovered-item-video]: https://github.com/user-attachments/assets/43404049-1a4c-458c-b33f-c221dddf15c6
[shell-hovered-item-optional-video]: https://github.com/user-attachments/assets/b399450a-eec4-43d5-a75d-91c4f04a9d59
[shell-prompt-video]: https://github.com/user-attachments/assets/e83eb468-96fd-463f-a96a-54ac9ee2295f
[shell-behaviour-video]: https://github.com/user-attachments/assets/caa32923-9c3e-4ea4-a1b6-e0a2c7968e9d
[shell-exit-if-directory-video]: https://github.com/user-attachments/assets/a0feab97-b7fc-4d58-8611-60ccf5e794d5

<!-- Paste command -->

[smart-paste-video]: https://github.com/user-attachments/assets/d48c12a7-f652-4df7-90a5-271cbfa97683

<!-- Tab create command -->

[smart-tab-create-video]: https://github.com/user-attachments/assets/2921df3d-b51d-4dbb-a42f-80e021feaaf6

<!-- Tab switch command -->

[smart-tab-switch-video]: https://github.com/user-attachments/assets/1afb540d-47a9-4625-ae59-95d5cd91aa35

<!-- Arrow command -->

[wraparound-arrow-video]: https://github.com/user-attachments/assets/41ea1fb0-a526-4549-95a2-547c3c4b0498

<!-- Parent arrow command -->

[parent-arrow-video]: https://github.com/user-attachments/assets/f4dc492a-566b-4645-82e1-301713cff11f
[wraparound-parent-arrow-video]: https://github.com/user-attachments/assets/d19872f8-2851-47e6-8485-4e8e5be66871

<!-- Editor command -->

[editor-must-have-hovered-item-video]: https://github.com/user-attachments/assets/c2811b90-e164-4a6d-9f3d-aefe8aec1d95
[editor-hovered-item-optional-video]: https://github.com/user-attachments/assets/adad538a-fbe8-4ad3-8f6d-5600618a0673
[editor-prompt-video]: https://github.com/user-attachments/assets/cccb8a3c-6afa-49a6-8808-04b0f235b391
[editor-behaviour-video]: https://github.com/user-attachments/assets/b6821220-8530-4fd1-a40f-53d191a3fe1b

<!-- Pager command -->

[pager-must-have-hovered-item-video]: https://github.com/user-attachments/assets/22a5211a-89cc-4c36-aadb-eb9e6ab1d578
[pager-hovered-item-optional-video]: https://github.com/user-attachments/assets/6eaed3c9-91f4-4414-8d26-5eaf955a2861
[pager-prompt-video]: https://github.com/user-attachments/assets/1ee621f4-704e-4cc3-a2ff-ba06e4eaf5a3
[pager-behaviour-video]: https://github.com/user-attachments/assets/9ed0d520-4e73-44c3-82f7-18378994e0f4
