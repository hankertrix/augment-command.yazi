# augment-command.yazi

A [Yazi][yazi-link] plugin that enhances Yazi's default commands.
This plugin is inspired by the
[Yazi tips page][yazi-tips-page],
the [bypass.yazi](https://github.com/Rolv-Apneseth/bypass.yazi) plugin
and the [fast-enter.yazi](https://github.com/ourongxing/fast-enter.yazi)
plugin.

## Table of Contents

- [Requirements](#requirements)
  - [Optional dependencies](#optional-dependencies)
- [Installation](#installation)
- [Configuration](#configuration)
- [What about the commands are augmented?][augment-section]
- [Augmented commands](#augmented-commands)
  - [Open (`open`)](#open-open)
  - [Extract (`extract`)](#extract-extract)
  - [Enter (`enter`)](#enter-enter)
  - [Leave (`leave`)](#leave-leave)
  - [Rename (`rename`)](#rename-rename)
  - [Remove (`remove`)](#remove-remove)
  - [Copy (`copy`)](#copy-copy)
  - [Create (`create`)](#create-create)
  - [Shell (`shell`)](#shell-shell)
    - [Passing arguments to the `shell` command](#passing-arguments-to-the-shell-command)
  - [Paste (`paste`)](#paste-paste)
  - [Tab create (`tab_create`)](#tab-create-tab_create)
  - [Tab switch (`tab_switch`)](#tab-switch-tab_switch)
  - [Quit (`quit`)](#quit-quit)
  - [Arrow (`arrow`)](#arrow-arrow)
- [New commands](#new-commands)
  - [Parent arrow (`parent_arrow`)](#parent-arrow-parent_arrow)
  - [First file (`first_file`)](#first-file-first_file)
  - [Archive (`archive`)](#archive-archive)
  - [Emit (`emit`)](#emit-emit)
  - [Editor (`editor`)](#editor-editor)
  - [Pager (`pager`)](#pager-pager)
- [Usage](#usage)
  - [Using the `extract` command as an opener](#using-the-extract-command-as-an-opener)
  - [Configuring the plugin's prompts](#configuring-the-plugins-prompts)
    - [Input prompts](#input-prompts)
    - [Confirmation prompts](#confirmation-prompts)
  - [Full configuration example](#full-configuration-example)
- [Licence]

## Requirements

- [Yazi][yazi-link] v25.5.31+
- [`7z` or `7zz` command][7z-link]
- [`file` command][file-command-link]

### Optional dependencies

- [`tar` command][gnu-tar-link] for the `preserve_file_permissions` option

## Installation

```sh
# Add the plugin
ya pkg add hankertrix/augment-command

# Install plugin
ya pkg install

# Update plugin
ya pkg upgrade
```

## Configuration

| Configuration                       | Values                                                    | Default   | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| ----------------------------------- | --------------------------------------------------------- | --------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `prompt`                            | `true` or `false`                                         | `false`   | Create a prompt to choose between hovered and selected items when both exist. If this option is disabled, selected items will only be operated on when the hovered item is selected, otherwise the hovered item will be the default item that is operated on.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| `default_item_group_for_prompt`     | `hovered`, `selected` or `none`                           | `hovered` | The default item group to operate on when the prompt is submitted without any value. This only takes effect if `prompt` is set to `true`, otherwise this option doesn't do anything. `hovered` means the hovered item is operated on, `selected` means the selected items are operated on, and `none` just cancels the operation.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| `smart_enter`                       | `true` or `false`                                         | `true`    | Use one command to open files or enter a directory. With this option set, the `enter` and `open` commands will both call the `enter` command when a directory is hovered and call the `open` command when a regular file is hovered. You can also enable this behaviour by passing the `--smart` flag to the `enter` or `open` commands.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| `smart_paste`                       | `true` or `false`                                         | `false`   | Paste items into a directory without entering it. The behaviour is exactly the same as the [smart paste tip on Yazi's documentation][smart-paste-tip]. Setting this option to `false` will use the default `paste` behaviour. You can also enable this behaviour by passing the `--smart` flag to the `paste` command.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| `smart_tab_create`                  | `true` or `false`                                         | `false`   | Create tabs in the directory that is being hovered instead of the current directory. The behaviour is exactly the same as the [smart tab tip on Yazi's documentation][smart-tab-tip]. Setting this option to `false` will use the default `tab_create` behaviour, which means you need to pass the `--current` flag to the command. You can also enable this behaviour by passing the `--smart` flag to the `tab_create` command.                                                                                                                                                                                                                                                                                                                                                                                                 |
| `smart_tab_switch`                  | `true` or `false`                                         | `false`   | If the tab that is being switched to does not exist yet, setting this option to `true` will create all the tabs in between the current number of open tabs, and the tab that is being switched to. The behaviour is exactly the same as the [smart switch tip on Yazi's documentation][smart-switch-tip]. Setting this option to `false` will use the default `tab_switch` behaviour. You can also enable this behaviour by passing the `--smart` flag to the `tab_switch` command.                                                                                                                                                                                                                                                                                                                                               |
| `confirm_on_quit`                   | `true` or `false`                                         | `true`    | Setting this option to `true` will cause Yazi to prompt you for a confirmation before quitting when there is more than 1 tab open. Setting this option to `false` will use the default `quit` behaviour, which is to immediately quit Yazi. You can also enable this behaviour by passing the `--confirm` flag to the `quit` command.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| `open_file_after_creation`          | `true` or `false`                                         | `false`   | This option determines whether the plugin will open a file after it has been created. Setting this option to `true` will cause the plugin to open the created file. You can also enable this behaviour by passing the `--open` flag to the `create` command.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| `enter_directory_after_creation`    | `true` or `false`                                         | `false`   | This option determines whether the plugin will enter a directory after it has been created. Setting this option to `true` will cause the plugin to enter the created directory. You can also enable this behaviour by passing the `--enter` flag to the `create` command.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| `use_default_create_behaviour`      | `true` or `false`                                         | `false`   | This option determines whether the plugin will use the behaviour of Yazi's `create` command. Setting this option to `true` will use the behaviour of Yazi's `create` command. You can also enable this behaviour by passing the `--default-behaviour` flag to the `create` command.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| `enter_archives`                    | `true` or `false`                                         | `true`    | Automatically extract and enter archive files. This option requires the [`7z` or `7zz` command][7z-link] to be present.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| `extract_retries`                   | An integer, like `1`, `3`, `10`, etc.                     | `3`       | This option determines how many times the plugin will retry opening an encrypted or password-protected archive when a wrong password is given. This value plus 1 is the total number of times the plugin will try opening an encrypted or password-protected archive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| `recursively_extract_archives`      | `true` or `false`                                         | `true`    | This option determines whether the plugin will extract all archives inside an archive file recursively. If this option is set to `false`, archive files inside an archive will not be extracted, and you will have to manually extract them yourself.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| `preserve_file_permissions`         | `true` or `false`                                         | `false`   | This option determines whether to preserve the file permissions of the items in the extracted archive. Setting this option to `true` will preserve the file permissions of the extracted items. It requires the [`tar` command][gnu-tar-link] and will only work on `tar` archives, or tarballs, as [`7z`][7z-link] does not support preserving file permissions. You will receive a warning if you have this option set but [`tar`][gnu-tar-link] is not installed. Do note that there are significant security implications of setting this option to `true`, as any executable file or binary in an archive can be immediately executed after it is extracted, which can compromise your system if you extract a malicious archive. As such, the default value is `false`, and it is strongly recommended to leave it as such. |
| `encrypt_archives`                  | `true` or `false`                                         | `false`   | This option determines whether the plugin will encrypt the archives it creates. If this option is set to `true`, the plugin will prompt for the archive password when creating an archive to encrypt it with. The plugin will prompt twice for the password, and will check both of them to see if they match. If they do, the password entered is set as the archive password. Otherwise, the plugin will show an error stating the passwords do not match, and prompt for two passwords again. Cancelling either of the prompts will cancel the whole process.                                                                                                                                                                                                                                                                  |
| `encrypt_archive_headers`           | `true` or `false`                                         | `false`   | This option determines whether the plugin will encrypt the headers of the archives it creates. If this option is set to `true`, the plugin will encrypt the headers of all `7z` archives, which means the file list cannot be previewed and Yazi will not be able to preview the contents of the archive. This encryption is only available to `7z` archives, so the plugin will show a warning message when this option is used, but the selected archive file type, does not support header encryption, like a `zip` archive, but will continue with the creation of the encrypted archive. This option has no effect when the archive is not encrypted, which is when `encrypt_archives` is set to `false`.                                                                                                                    |
| `reveal_created_archive`            | `true` or `false`                                         | `true`    | This option determines whether the plugin will automatically hover over the created archive once created.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| `remove_archived_files`             | `true` or `false`                                         | `false`   | This option determines whether the plugin will automatically remove the files that were added to the created archive.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| `must_have_hovered_item`            | `true` or `false`                                         | `true`    | This option stops the plugin from executing any commands when there is no hovered item.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| `skip_single_subdirectory_on_enter` | `true` or `false`                                         | `true`    | Skip directories when there is only one subdirectory and no other files when entering directories. This behaviour can be turned off by passing the `--no-skip` flag to the `enter` or `open` commands.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| `skip_single_subdirectory_on_leave` | `true` or `false`                                         | `true`    | Skip directories when there is only one subdirectory and no other files when leaving directories. This behaviour can be turned off by passing the `--no-skip` flag to the `leave` command.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| `smooth_scrolling`                  | `true` or `false`                                         | `false`   | Self-explanatory, this option enables smooth scrolling.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| `scroll_delay`                      | A floating point number, like `0.02`, `0.05`, `0.1`, etc. | `0.02`    | The delay, in seconds, between each call of the `arrow` command to scroll through the file list. The smaller the `scroll_delay`, the faster the file list is scrolled. Avoid setting a `scroll_delay` that is more than `1` second. This is due to the plugin being asynchronous, which will result in the plugin continuing to call the `arrow` command even when the directory has changed, or when you are in a different application that doesn't block Yazi, resulting in unexpected behaviour.                                                                                                                                                                                                                                                                                                                              |
| `create_item_delay`                 | A floating point number, like `0.25`, `0.1`, `1e-2`, etc. | `0.25`    | The delay, in seconds, before calling the `reveal` command to reveal the created item. This delay is mainly to ensure a smooth experience using the plugin's `archive` and `create` commands, as the `reveal` command will create a dummy file that doesn't exist and reveal that before jumping to the created item. This delay is dependent on how fast your file system is. For the `Ext4` file system, it seems that a delay of `0.1` seconds is ideal, while a delay of `0.25` seconds for the `Btrfs` file system seems to be appropriate.                                                                                                                                                                                                                                                                                  |
| `wraparound_file_navigation`        | `true` or `false`                                         | `true`    | Wrap around from the bottom to the top or from the top to the bottom when using the `arrow` or `parent_arrow` command to navigate.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |

If you would like to use the default configuration, which is shown below,
you don't need to add anything to your `~/.config/yazi/init.lua`
file on Linux and macOS, or your `%AppData%\yazi\config\init.lua`
file on Windows.

```lua
-- ~/.config/yazi/init.lua for Linux and macOS
-- %AppData%\yazi\config\init.lua for Windows

-- Using the default configuration
require("augment-command"):setup({
    prompt = false,
    default_item_group_for_prompt = "hovered",
    smart_enter = true,
    smart_paste = false,
    smart_tab_create = false,
    smart_tab_switch = false,
    confirm_on_quit = true,
    open_file_after_creation = false,
    enter_directory_after_creation = false,
    use_default_create_behaviour = false,
    enter_archives = true,
    extract_retries = 3,
    recursively_extract_archives = true,
    preserve_file_permissions = false,
    encrypt_archives = false,
    encrypt_archive_headers = false,
    reveal_created_archive = true,
    remove_archived_files = false,
    must_have_hovered_item = true,
    skip_single_subdirectory_on_enter = true,
    skip_single_subdirectory_on_leave = true,
    smooth_scrolling = false,
    scroll_delay = 0.02,
    create_item_delay = 0.25,
    wraparound_file_navigation = true,
})
```

However, if you would like to configure the plugin, you can add
your desired configuration options to your `~/.config/yazi/init.lua` file
on Linux and macOS, or your
`%AppData%\yazi\config\init.lua` file on Windows.
You can leave out configuration options that you would
like to be left as default.
An example configuration is shown below:

```lua
-- ~/.config/yazi/init.lua for Linux and macOS
-- %AppData%\yazi\config\init.lua for Windows

-- Custom configuration
require("augment-command"):setup({
    prompt = true,
    default_item_group_for_prompt = "none",
    open_file_after_creation = true,
    enter_directory_after_creation = true,
    extract_retries = 5,
    encrypt_archives = true,
    smooth_scrolling = true,
    create_item_delay = 0.1,
    wraparound_file_navigation = false,
})
```

## What about the commands are augmented?

All commands that can operate on multiple files and directories,
like `open`, `rename`, `remove` and `shell`,
as well as the new commands `extract`, `archive`,
`editor` and `pager`,
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
- `--smart` flag to use one command to `open` files
  and `enter` directories.
  This flag will cause the `open` command to call
  the `enter` command when the hovered item is a directory
  even when `smart_enter` is set to `false`.
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

- Technically this is a new command,
  as Yazi does not provide an `extract` command.
  However, Yazi does provide a built-in plugin called `extract`,
  so this command is included in the
  [augmented commands section](#augmented-commands) instead of the
  [new commands section](#new-commands).
- This command requires the [`7z` or `7zz` command][7z-link] to
  be present to extract the archives, as well as the
  [`file` command][file-command-link] to check if a file is an archive or not.
- You are not meant to use this command directly.
  However, you can do so if you like,
  as the extract command is also augmented as stated in
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

- Instead, this command is intended to replace the
  built-in `extract` plugin, which is used for the `extract` opener.
  This way, you can use the
  features that come with the augmented `extract` command, like
  recursively extracting archives, with the `open` command.
  This is the intended way to use this command,
  as the `open` command is meant to be the command
  that opens everything, so it is a bit counterintuitive
  to have to use a separate key to extract archives.

  To replace the built-in `extract` plugin, copy the
  [`extract` openers section][yazi-yazi-toml-extract-openers]
  in [Yazi's default `yazi.toml`][yazi-yazi-toml] into your `yazi.toml`,
  which is located at `~/.config/yazi/yazi.toml` for Linux and macOS,
  and `%AppData%\yazi\config\yazi.toml` file on Windows.
  Make sure that the `extract` openers are
  under the `opener` key in your `yazi.toml`.
  Then replace `extract` with `augmented-extract`,
  and you will be using the plugin's `extract` command instead of
  Yazi's built-in `extract` plugin.

  Here is an example configuration:

  ```toml
  # ~/.config/yazi/yazi.toml for Linux and macOS
  # %AppData%\yazi\config\yazi.toml for Windows

  [opener]
  extract = [
      { run = 'ya pub augmented-extract --list "$@"', desc = "Extract here", for = "unix" },
      { run = 'ya pub augmented-extract --list %*',   desc = "Extract here", for = "windows" },
  ]
  ```

  If that exceeds your editor's line length limit,
  another way to do it is:

  ```toml
  # ~/.config/yazi/yazi.toml for Linux and macOS
  # %AppData%\yazi\config\yazi.toml for Windows

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

  [extract-encrypted-archive-video]

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

  Setting the `preserve_file_permissions` configuration
  option to `true` will preserve the file permissions
  of the files contained in a `tar` archive or tarball.

  This has considerable security implications,
  as executables extracted from
  all `tar` archives can be immediately executed on your system,
  possibly compromising your system if you extract a
  malicious `tar` archive.
  Hence, this option is set to `false` by default,
  and should be left as such.
  This option is provided for your convenience,
  but do seriously consider if such convenience
  is worth the risk of extracting a malicious `tar` archive
  that executes malware on your system.

- `--reveal` flag to automatically hover the files
  that have been extracted.

  Video:

  [extract-reveal-extracted-item-video]

- `--remove` flag to automatically remove the archive
  after the files have been extracted.

  Video:

  [extract-remove-extracted-archive-video]

### Enter (`enter`)

- When `smart_enter` is set to `true`,
  it calls the `open` command when the hovered item is a file.
- `--smart` flag to use one command to `enter`
  directories and `open` files. This flag will cause
  the `enter` command to call the `open` command when
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

### Copy (`copy`)

- The `copy` command is augmented as stated in
  [this section above][augment-section].

  Videos:

  - When `must_have_hovered_item` is `true`:

    [copy-must-have-hovered-item-video]

  - When `must_have_hovered_item` is `false`:

    [copy-hovered-item-optional-video]

  - When `prompt` is set to `true`:

    [copy-prompt-video]

  - When `prompt` is set to `false`:

    [copy-behaviour-video]

### Create (`create`)

- You should use Yazi's default `create` command instead
  of this augmented `create` command if you
  don't want the paths without file extensions to be created
  as directories by default, and you don't care about automatically
  opening and entering the created file and directory respectively.
- The `create` command has a different behaviour from
  Yazi's `create` command.
  When the path given to the command doesn't have a file extension,
  the `create` command will create a directory instead of a file,
  unlike Yazi's `create` command. Other that this major difference,
  the `create` command functions identically
  to Yazi's `create` command,
  which means that you can use a trailing `/` on Linux and macOS,
  or `\` on Windows to create a directory. It will also recursively
  create directories to ensure that the path given exists.
  It also supports all the options supported
  by Yazi's `create` command,
  so you can pass them to the command and expect the same behaviour.
- The rationale for this behaviour is that creating a path without
  a file extension usually means you intend to
  create a directory instead of a file,
  as files usually have file extensions.

  Video:

  [create-behaviour-video]

- When `open_file_after_creation` is set to `true`,
  the `create` command will `open` the created file.
  This behaviour can also be enabled by
  passing the `--open` flag to the `create` command.

  Video:

  [create-and-open-files-video]

  Likewise, when `enter_directory_after_creation` is set to `true`,
  the `create` command will `enter` the created directory.
  This behaviour can also be enabled by passing the `--enter` flag
  to the `create` command.

  Video:

  [create-and-enter-directories-video]

  To enable both behaviours with flags, just pass both the
  `--open` flag and the `--enter` flag to the `create` command.

  Video:

  [create-and-open-files-and-directories-video]

- If you would like to use the behaviour of Yazi's `create` command,
  probably because you would like to automatically open
  and enter the created file and directory respectively,
  you can either set
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
  `shell` command provided by Yazi. You just provide
  the command you want and provide any Yazi shell variable,
  which is documented [here][yazi-shell-variables].
  The plugin will automatically replace the shell variable you give
  with the file paths for the item group before executing the command.

- There is no need to quote the shell variable on Linux and macOS,
  as it is expanded by the plugin instead of the shell,
  and the paths are already quoted using the `ya.quote` function
  before execution, so quoting is entirely unnecessary
  and may result in unexpected behaviour.

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
  # %AppData%\yazi\config\keymap.toml on Windows

  [[mgr.prepend_keymap]]
  on = "i"
  run = "plugin augment-command -- shell '$PAGER $@' --block --exit-if-dir"
  desc = "Open the pager"
  ```

  It is also used in the `editor` command,
  since you usually wouldn't use
  your text editor to open directories,
  especially if you are already using
  a terminal file manager like [Yazi][yazi-link].
  The `editor` command is essentially:

  ```toml
  # ~/.config/yazi/keymap.toml on Linux and macOS
  # %AppData%\yazi\config\keymap.toml on Windows

  [[mgr.prepend_keymap]]
  on = "o"
  run = "plugin augment-command -- shell '$EDITOR $@' --block --exit-if-dir"
  desc = "Open the editor"
  ```

  Video:

  [shell-exit-if-directory-video]

#### Passing arguments to the `shell` command

Ideally, you will want to avoid using backslashes to escape
the shell command arguments, so here are a few ways to do it:

1. Shell arguments that don't have special shell variables
   on Linux and macOS, like `$SHELL`, or don't have
   special shell characters like `>`, `|` or spaces,
   need not be quoted with double quotes `"`
   or single quotes `'` respectively.
   For example:

   ```toml
   # ~/.config/yazi/keymap.toml on Linux and macOS
   # %AppData%\yazi\config\keymap.toml on Windows
   [[mgr.prepend_keymap]]
   on = "i"
   run = "plugin augment-command -- shell --block 'bat -p --pager less $@'"
   desc = "Open with bat"
   ```

   Even though the `$@` argument above is considered
   a shell variable in Linux and macOS,
   the plugin automatically replaces it with the full path
   of the items in the item group,
   so it does not need to be quoted with
   double quotes `"`, as it is expanded by the plugin,
   and not meant to be expanded by the shell.

2. If the arguments to the `shell` command have special
   shell variables on Linux and macOS, like `$SHELL`,
   or special shell characters like `>`, `|`, or spaces,
   use `--` to denote the end of the flags and options
   passed to the `shell` command.
   For example:

   ```toml
   # ~/.config/yazi/keymap.toml on Linux and macOS
   # %AppData%\yazi\config\keymap.toml on Windows
   [[mgr.prepend_keymap]]
   on = "<C-s>"
   run = 'plugin augment-command -- shell --block -- sh -c "$SHELL"'
   desc = "Open a shell inside of a shell here"
   ```

   ```toml
   # ~/.config/yazi/keymap.toml on Linux and macOS
   # %AppData%\yazi\config\keymap.toml on Windows
   [[mgr.prepend_keymap]]
   on = "<C-s>"
   run = "plugin augment-command -- shell --block -- sh -c 'echo hello'"
   desc = "Open a shell and say hello inside the opened shell"
   ```

3. If the arguments passed to the `shell` command themselves
   contain arguments that have special shell variables on
   Linux and macOS, like `$SHELL`, or special shell characters
   like `>`, `|`, or spaces, use the triple single quote
   `'''` delimiter for the `run` string.

   ```toml
   # ~/.config/yazi/keymap.toml on Linux and macOS
   # %AppData%\yazi\config\keymap.toml on Windows
   [[mgr.prepend_keymap]]
   on = "<C-s>"
   run = '''plugin augment-command -- shell --block -- sh -c 'sh -c "$SHELL"''''
   desc = "Open a shell inside of a shell inside of a shell here"
   ```

   ```toml
   # ~/.config/yazi/keymap.toml on Linux and macOS
   # %AppData%\yazi\config\keymap.toml on Windows
   [[mgr.prepend_keymap]]
   on = "<C-s>"
   run = '''plugin augment-command --
       shell --block -- sh -c "$SHELL -c 'echo hello'"
   '''
   desc = "Open a shell inside of a shell and say hello inside the opened shell"
   ```

   A more legitimate use case for this would be something like
   [Yazi's tip to email files using Mozilla Thunderbird][thunderbird-tip]:

   ```toml
   # ~/.config/yazi/keymap.toml on Linux and macOS
   # %AppData%\yazi\config\keymap.toml on Windows
   [[mgr.prepend_keymap]]
   on = "<C-e>"
   run = '''plugin augment-command --
       shell --
           paths=$(for p in $@; do echo "$p"; done | paste -s -d,)
           thunderbird -compose "attachment='$paths'"
   '''
   desc = "Email files using Mozilla Thunderbird"
   ```

   Once again, the `$@` variable above does not need to be quoted
   in double quotes `"` as it is expanded by the plugin
   instead of the shell.

If the above few methods to avoid using backslashes
within your shell command to escape the quotes are
still insufficient for your use case,
it is probably more appropriate to write a shell script
in a separate file and execute that instead of
writing the shell command inline
in your `keymap.toml` file.

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
  into the hovered directory even
  when `smart_paste` is set to `false`.
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

### Quit (`quit`)

- You should use Yazi's default `quit` command instead of this
  augmented command if you don't want to have a prompt
  when quitting Yazi with multiple tabs open.
  This command has a visual side effect of showing a
  confirmation prompt for a split second before closing Yazi
  when quitting Yazi with only 1 tab open,
  which can be annoying.
  This confirmation prompt is due to the plugin still running
  for a bit after the `quit` command is emitted,
  causing Yazi to prompt you for
  confirmation as there are tasks still running.
  However, once the plugin has stopped running,
  which is a split second after the `quit` command is emitted,
  Yazi will exit.
  You can observe this visual effect in the video demonstration below.
- When `confirm_on_quit` is set to `true`,
  the plugin will prompt you for
  confirmation when there is more than 1 tab open.
  Otherwise, it will immediately quit Yazi,
  just like the default `quit` command.
- `--confirm` flag to get the plugin to prompt you
  for confirmation when quitting with multiple tabs open.
  This flag will cause the `quit` command to
  prompt you for confirmation when quitting with multiple tabs open
  even when `confirm_on_quit` is set to `false`.
  This allows you to set a specific key to use this behaviour with the
  `quit` command instead of using it for every `quit` command.

  Video:

  [quit-with-confirmation-video]

### Arrow (`arrow`)

- When `smooth_scrolling` is set to `true`, the arrow command will
  smoothly scroll through the file list.

  Video:

  [smooth-arrow-video]

- When `wraparound_file_navigation` is set to `true`,
  the arrow command will wrap around from the bottom to the top or
  from the top to the bottom when navigating.

  Video:

  [wraparound-arrow-video]

- When both `smooth_scrolling` and `wraparound_file_navigation`
  are set to `true`,
  the command will smoothly scroll the wraparound transition as well.

  Video:

  [smooth-wraparound-arrow-video]

- Otherwise, it'll behave like the default `arrow 1` command.
- `--no-wrap` flag to prevent the `arrow` command
  from wrapping around,
  even when `wraparound_file_navigation` is set to `true`.

## New commands

### Parent arrow (`parent_arrow`)

- This command behaves like the `arrow` command,
  but in the parent directory.
  It allows you to navigate in the parent directory
  without leaving the current directory.

  Video:

  [parent-arrow-video]

- When `smooth_scrolling` is set to `true`, this command will
  smoothly scroll through the parent directories.

  Video:

  [smooth-parent-arrow-video]

- When `wraparound_file_navigation` is set to `true`,
  this command will also wrap around from the bottom to the top or
  from top to the bottom when navigating in the parent directory.

  Video:

  [wraparound-parent-arrow-video]

- When both `smooth_scrolling` and `wraparound_file_navigation`
  are set to `true`,
  the command will smoothly scroll the wraparound transition as well.

  Video:

  [smooth-wraparound-parent-arrow-video]

- You can also replicate this using this series of commands below,
  but it doesn't work as well,
  and doesn't support wraparound navigation or smooth scrolling:

  ```toml
  # ~/.config/yazi/keymap.toml on Linux and macOS
  # %AppData%\yazi\config\keymap.toml on Windows

  # Use K to move up in the parent directory
  [[mgr.prepend_keymap]]
  on = "K"
  run = ["leave", "arrow -1", "enter"]
  desc = "Move up in the parent directory"


  # Use J to move down in the parent directory
  [[mgr.prepend_keymap]]
  on = "J"
  run = ["leave", "arrow 1", "enter"]
  desc = "Move down in the parent directory"
  ```

- `--no-wrap` flag to prevent the `parent_arrow` command from
  wrapping around,
  even when `wraparound_file_navigation` is set to `true`.

### First file (`first_file`)

- This command just moves the cursor to the first file
  in the current directory, regardless of the current cursor position.
- It is useful for quickly getting to the first file
  in the current directory when `sort_dir_first` is set to `true`,
  which is the case by default.

  Video:

  [first-file-video]

- It also works with smooth scrolling, so when `smooth_scrolling`
  is set to `true`, the command will smoothly scroll the cursor
  to the first file.

  Video:

  [smooth-first-file-video]

- Alternatively, if you just want to get to a file
  in the current directory, you can use the built-in `G` key bind
  that calls `arrow bot` to get to the last item
  in the current directory, which would be a file
  if `sort_dir_first` is set to `true`,
  which is the case by default.

### Archive (`archive`)

- The `archive` command adds the selected or hovered items
  to an archive, with the plugin prompting for an archive name.
  The archive file extension given will be used to determine
  the type of archive to create.
- When the archive name given has no file extension, the `.zip`
  file extension will be automatically added by default
  to create a `zip` archive.
- When the item group is determined to be the hovered item,
  the `archive` command will create a `.zip` archive with the
  name of the hovered item if no archive name is given
  and the input is confirmed by using the `<Enter>` key.
- The `archive` command will also prompt for an overwrite confirmation,
  if the archive being created already exists,
  just like the `create` command.
- This command is also augmented as stated in
  [this section above][augment-section].

  Videos:

  - When `must_have_hovered_item` is `true`:

    [archive-must-have-hovered-item-video]

  - When `must_have_hovered_item` is `false`:

    [archive-hovered-item-optional-video]

  - When `prompt` is set to `true`:

    [archive-prompt-video]

  - When `prompt` is set to `false`:

    [archive-behaviour-video]

- `--force` flag to always overwrite the existing archive
  without showing the confirmation prompt.
- `--encrypt` flag to encrypt the archive with the given password,
  which applies even when `encrypt_archives` is set to `false`.
- `--encrypt-headers` flag to encrypt the archive headers,
  which applies even when `encrypt_archive_headers`
  is set to `false`.
  Note that this option only works with `7z` archives,
  other types of archives like `zip` archives
  do not support header encryption.
  The plugin will show a warning if the archive type
  does not support header encryption and the flag is passed,
  but will continue with the creation of the encrypted archive.
  This option has no effect if either `encrypt_archives`
  is set to `false` or the `--encrypt` flag isn't given.

  Video:

  [archive-encrypt-files-video]

- `--reveal` flag to automatically hover the archive file
  that is created, which applies even when
  `reveal_created_archive` is set to `false`.

  Video:

  [archive-reveal-created-archive-video]

- `--remove` flag to automatically remove the files
  that are added to the archive, which applies even when
  `remove_archived_files` is set to `false`.

  Video:

  [archive-remove-archived-files-video]

### Emit (`emit`)

- The `emit` command allows you to emit any Yazi command
  by typing the command into an input prompt.
  The syntax of the command is exactly the same as
  the commands in the `keymap.toml` file.
  For example, if the input is `arrow next`,
  then that will be the command that is emitted by the plugin.

  Video:

  [emit-yazi-command-video]

- `--plugin` flag to emit a plugin command.
  This flag essentially just emits Yazi's `plugin` command
  with the input passed as the first argument.
  For example, if the input is `augment-command -- parent_arrow 1`,
  then the full command being emitted by the plugin is
  `plugin augment-command -- parent_arrow 1`.

  Video:

  [emit-plugin-command-video]

- `--augmented` flag to emit an augmented command.
  This flag is a shortcut for emitting a command from this plugin.
  For example, if the command given is `parent_arrow 1`,
  the full command emitted by the plugin is
  `plugin augment-command -- parent_arrow 1`.

  Video:

  [emit-augmented-command-video]

- If `--augmented` flag is passed together with the `--plugin` flag,
  the `--augmented` flag will take precedence over the `--plugin` flag,
  and the command emitted will be from this plugin
  instead of being a `plugin` command.
  In any case, you should not be passing
  both the `--plugin` and `--augmented` flags.

### Editor (`editor`)

- The `editor` command opens the default editor set by the
  `$EDITOR` environment variable.
- When the file being edited is owned by the root user on Unix systems,
  like Linux and macOS, the `editor` command will automatically call
  `sudo -e` to edit the file instead of using the `$EDITOR`
  environment variable.
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
and at `%AppData%\yazi\config\keymap.toml`
on Windows, in this format:

```toml
# ~/.config/yazi/keymap.toml on Linux and macOS
# %AppData%\yazi\config\keymap.toml on Windows

[[mgr.prepend_keymap]]
on = "key"
run = "plugin augment-command -- command arguments --flags --options=42"
desc = "Description"
```

For example, to use the augmented `enter` command:

```toml
# ~/.config/yazi/keymap.toml on Linux and macOS
# %AppData%\yazi\config\keymap.toml on Windows

[[mgr.prepend_keymap]]
on = "l"
run = "plugin augment-command -- enter"
desc = "Enter a directory and skip directories with only a single subdirectory"
```

All the default arguments, flags and options provided by Yazi
are also supported, for example:

```toml
# ~/.config/yazi/keymap.toml on Linux and macOS
# %AppData%\yazi\config\keymap.toml on Windows

[[mgr.prepend_keymap]]
on = "k"
run = "plugin augment-command -- arrow -1"
desc = "Move the cursor up"

[[mgr.prepend_keymap]]
on = "r"
run = "plugin augment-command -- rename --cursor=before_ext"
desc = "Rename a file or directory"

[[mgr.prepend_keymap]]
on = "D"
run = "plugin augment-command -- remove --permanently"
desc = "Permanently delete the files"

[[mgr.prepend_keymap]]
on = ["g", "j"]
run = "plugin augment-command -- parent_arrow 1"
desc = "Move the cursor down in the parent directory"
```

For the default descriptions of the commands, you can refer to
[Yazi's default `keymap.toml` file][yazi-keymap-toml].

Essentially, all you need to do to use this plugin
is to add `plugin augment-command --`, with a space at the end,
in front of a Yazi command, such as `enter`,
which results in `plugin augment-command -- enter'`.

### Using the `extract` command as an opener

This is the intended way to use the `extract` command instead of binding
the `extract` command to a key in your `keymap.toml` file.
Look at the [`extract` command section](#extract-extract)
for details on how to do so.

### Configuring the plugin's prompts

If you would like to use the plugin's default prompts,
you can skip this section entirely. Otherwise, read on.

The plugin's prompts can be configured using the `th`
object for built-in commands like `create`.

New commands, or new features in existing commands introduced by the plugin,
like `archive` or `quit`, can be configured
using the `th.augment_command` object instead.

You **must** call the plugin's `setup` function after
configuring the plugin's prompts, otherwise,
the prompts will remain as the default prompts.

For example:

```lua
-- Prompt configurations for the plugin
th.create_title = { "Create:", "Create (dir):" }
th.augment_command = th.augment_command or {}
th.augment_command.archive_title = "Archive name:"
th.augment_command.quit_title = "Quit?"

-- Call the plugin's setup function
require("augment-command"):setup()
```

This method of configuration is to be forward compatible
with future versions of Yazi, as mentioned
[here](https://github.com/yazi-rs/plugins/issues/44).

#### Input prompts

For `input` prompts, like the prompt for the `archive` command,
there are 3 configuration options:

- `title`
- `origin`
- `offset`

These options are documented in [Yazi's documentation][input-configuration].

For example, to configure the `create` command, which is built-in:

```lua
th.create_title = { "Create:", "Create (dir):" }
th.create_origin = "top-center"
th.create_offset = {
    x = 0,
    y = 2,
    w = 50,
    h = 3,
}
```

This way of configuring the `input` prompt applies to the following:

- `create`

Below is an example of configuring the `archive` command,
which is provided by the plugin:

```lua
th.augment_command = th.augment_command or {}
th.augment_command.archive_title = "Archive name:"
th.augment_command.archive_origin = "top-center"
th.augment_command.archive_offset = {
    x = 0,
    y = 2,
    w = 50,
    h = 3,
}
```

This way of configuring the `input` prompt applies to the following:

- `item_group`: The prompt to select an item group.

- `extract_password`:
  The prompt to enter the password when extracting an encrypted archive.

- `archive`: The prompt for the archive name.

- `archive_password`:
  The prompts to enter the archive password when
  creating an encrypted archive.
  Note that the title for this prompt, `archive_password_title`,
  should be a list of two strings, like this:

  ```lua
  th.augment_command = th.augment_command or {}
  th.archive_password_title = {
      "Archive password:",
      "Confirm archive password:",
  }
  ```

#### Confirmation prompts

For `confirm` prompts, like the prompt for the `quit` command,
there are 4 configuration options:

- `title`
- `content`
- `origin`
- `offset`

These options are documented in [Yazi's documentation][confirm-configuration].

The configuration for the `confirm` prompt is very
similar to that of the `input` prompt,
just with one more option called `content`.
The `content` option can take either a `string`, or a list of `strings`.

For example, to configure the `overwrite` part
of the `create` and `archive` commands, which is built-in:

```lua
th.overwrite_title = "Overwrite file?"
th.overwrite_content = "Will overwrite the following file:"
th.overwrite_origin = "center"
th.overwrite_offset = {
    x = 0,
    y = 0,
    w = 50,
    h = 15,
}
```

This way of configuring the `confirm` prompt applies to the following:

- `overwrite`:
  The overwrite prompt when creating a file with
  the same name as an existing file.

Below is an example of configuring the `quit` command,
which is provided by the plugin:

```lua
th.augment_command = th.augment_command or {}
th.augment_command.quit_title = "Quit?"
th.augment_command.quit_content = {
    "There are multiple tabs open.",
    "Are you sure you want to quit?",
}
th.augment_command.quit_origin = "center"
th.augment_command.quit_offset = {
    x = 0,
    y = 0,
    w = 50,
    h = 15,
}
```

This way of configuring the `confirm` prompt applies to the following:

- `quit`: The quit prompt when quitting with multiple tabs open.

### Full configuration example

For a full configuration example,
you can have a look at [my `keymap.toml` file][my-keymap-toml]
and [my `yazi.toml` file][my-yazi-toml].

## [Licence]

This plugin is licensed under the [GNU AGPL v3 licence][Licence].
You can view the full licence in the [`LICENSE`][Licence] file.

<!-- Regular links -->

[yazi-link]: https://github.com/sxyazi/yazi
[yazi-tips-page]: https://yazi-rs.github.io/docs/tips
[smart-paste-tip]: https://yazi-rs.github.io/docs/tips#smart-paste
[smart-tab-tip]: https://yazi-rs.github.io/docs/tips#smart-tab
[smart-switch-tip]: https://yazi-rs.github.io/docs/tips#smart-switch
[augment-section]: #what-about-the-commands-are-augmented
[7z-link]: https://www.7-zip.org/
[file-command-link]: https://www.darwinsys.com/file/
[gnu-tar-link]: https://www.gnu.org/software/tar/
[apple-tar-link]: https://ss64.com/mac/tar.html
[brew-link]: https://brew.sh/
[yazi-yazi-toml-extract-openers]: https://github.com/sxyazi/yazi/blob/main/yazi-config/preset/yazi-default.toml#L50-L53
[yazi-yazi-toml]: https://github.com/sxyazi/yazi/blob/main/yazi-config/preset/yazi-default.toml
[yazi-shell-variables]: https://yazi-rs.github.io/docs/configuration/keymap/#mgr.shell
[thunderbird-tip]: https://yazi-rs.github.io/docs/tips/#email-selected-files
[input-configuration]: https://yazi-rs.github.io/docs/configuration/yazi#input
[confirm-configuration]: https://yazi-rs.github.io/docs/configuration/yazi#confirm
[yazi-keymap-toml]: https://github.com/sxyazi/yazi/blob/main/yazi-config/preset/keymap-default.toml
[my-keymap-toml]: https://github.com/hankertrix/Dotfiles/blob/main/tilde/dot_config/yazi/keymap.toml.tmpl
[my-yazi-toml]: https://github.com/hankertrix/Dotfiles/blob/main/tilde/dot_config/yazi/yazi.toml
[Licence]: LICENSE

<!-- Videos -->

<!-- Open command -->

[open-prompt-video]: https://github.com/user-attachments/assets/1d483b04-a74d-42d2-a94d-2e7b4923d62d
[open-behaviour-video]: https://github.com/user-attachments/assets/78a02383-52ee-4268-9d8a-24790d15fb9e
[open-auto-extract-archives-video]: https://github.com/user-attachments/assets/e720fef7-da81-455b-8c82-b338577a0aa2
[open-recursively-extract-archives-video]: https://github.com/user-attachments/assets/614b4358-0c56-41de-a97c-c514693e0da1

<!-- Extract command -->

[extract-must-have-hovered-item-video]: https://github.com/user-attachments/assets/86014955-9997-47e2-82fb-8de938044d31
[extract-hovered-item-optional-video]: https://github.com/user-attachments/assets/509597c2-9df6-4199-900d-ad7f092a12b4
[extract-prompt-video]: https://github.com/user-attachments/assets/85a85efe-cc25-45d2-9414-aa4935196cb4
[extract-behaviour-video]: https://github.com/user-attachments/assets/db06f14e-7e9e-47a0-a6b3-a22f468be24d
[extract-recursively-extract-archives-video]: https://github.com/user-attachments/assets/cd57721c-4461-42d2-8756-0928ac6bba34
[extract-encrypted-archive-video]: https://github.com/user-attachments/assets/98341d53-9218-4817-960c-e0811f5505cd
[extract-reveal-extracted-item-video]: https://github.com/user-attachments/assets/4ae1f884-5f12-4133-8757-18a1081be0e4
[extract-remove-extracted-archive-video]: https://github.com/user-attachments/assets/2dd8467f-68a4-4560-b45e-4d2e2c635016

<!-- Enter command -->

[smart-enter-video]: https://github.com/user-attachments/assets/63f11df6-46a7-416a-bb11-fe72ce094a95
[enter-skip-single-subdirectory-video]: https://github.com/user-attachments/assets/33b3a3de-bb42-4bbd-ac61-b292fb2d6f6a

<!-- Leave command -->

[leave-skip-single-subdirectory-video]: https://github.com/user-attachments/assets/b842328f-9d5d-4ddb-b21d-88903f59858e

<!-- Rename command -->

[rename-must-have-hovered-item-video]: https://github.com/user-attachments/assets/afe0c9c6-9b0b-4077-8f0a-76feb33c5824
[rename-hovered-item-optional-video]: https://github.com/user-attachments/assets/62cb647b-0519-4d1d-8d99-55b2c8eb6258
[rename-prompt-video]: https://github.com/user-attachments/assets/48bf39cc-72db-4648-91d8-9c612fb144f7
[rename-behaviour-video]: https://github.com/user-attachments/assets/4276eebb-87ae-4442-a0e8-01ef32f52137

<!-- Remove command -->

[remove-must-have-hovered-item-video]: https://github.com/user-attachments/assets/62422c9e-d81b-4789-8cf4-08178a7c2a0a
[remove-hovered-item-optional-video]: https://github.com/user-attachments/assets/079a0ad4-f496-4d41-9374-d1cd13bd5aa7
[remove-prompt-video]: https://github.com/user-attachments/assets/1dfffc05-99b8-4b1d-8a3e-b895e315b947
[remove-behaviour-video]: https://github.com/user-attachments/assets/0aa35c6d-9897-45ed-8d60-fff4a9d1cb80

<!-- Copy command -->

[copy-must-have-hovered-item-video]: https://github.com/user-attachments/assets/ebbfa383-1771-4515-a30b-5f97142be249
[copy-hovered-item-optional-video]: https://github.com/user-attachments/assets/44f62540-3778-42f2-bd1e-5b90e356198c
[copy-prompt-video]: https://github.com/user-attachments/assets/2cd1421f-991f-4c66-85e5-283b541f7ff6
[copy-behaviour-video]: https://github.com/user-attachments/assets/abf9e1a9-969f-4ac2-8e72-088b770ae902

<!-- Create command -->

[create-and-enter-directories-video]: https://github.com/user-attachments/assets/8355ebe5-9870-4dd8-b40b-3048c7636dc2
[create-and-open-files-video]: https://github.com/user-attachments/assets/5ca0833b-f112-4469-a382-4e64c432731b
[create-and-open-files-and-directories-video]: https://github.com/user-attachments/assets/4739a197-4b7e-461b-b257-1d6aa070bcd5
[create-behaviour-video]: https://github.com/user-attachments/assets/158a429b-b217-4f3d-8f27-f0a3ea2e1cdc
[create-default-behaviour-video]: https://github.com/user-attachments/assets/0a5e88af-eade-46dd-b76b-f80d6a87b8d4

<!-- Shell command -->

[shell-must-have-hovered-item-video]: https://github.com/user-attachments/assets/52f9ecf1-877f-4377-921a-f954771a0496
[shell-hovered-item-optional-video]: https://github.com/user-attachments/assets/c15adf88-dc08-4555-99d8-1968a804bf03
[shell-prompt-video]: https://github.com/user-attachments/assets/90f3f1b7-1de5-494a-aca2-0810ef1218eb
[shell-behaviour-video]: https://github.com/user-attachments/assets/9837752d-ec91-4af8-a22e-28b821508e22
[shell-exit-if-directory-video]: https://github.com/user-attachments/assets/96b874dc-d97b-4ca8-a306-f8f243579142

<!-- Paste command -->

[smart-paste-video]: https://github.com/user-attachments/assets/d78e370b-1447-4dd7-8c1f-af56cd9eab6d

<!-- Tab create command -->

[smart-tab-create-video]: https://github.com/user-attachments/assets/16c50c24-70bc-47b7-9a1b-889c36ef6c70

<!-- Tab switch command -->

[smart-tab-switch-video]: https://github.com/user-attachments/assets/1bec33d2-6d2a-421e-95e0-80d8e427cfa6

<!-- Quit command -->

[quit-with-confirmation-video]: https://github.com/user-attachments/assets/6ef5c012-77c1-4147-8032-4a9be7da6145

<!-- Arrow command -->

[smooth-arrow-video]: https://github.com/user-attachments/assets/c670a888-d168-4166-990c-d3a19b886dc3
[wraparound-arrow-video]: https://github.com/user-attachments/assets/91b4f5c1-6ab7-4b58-96b1-194078e3e52e
[smooth-wraparound-arrow-video]: https://github.com/user-attachments/assets/07bdd6d8-686e-49db-9073-874cefff6f8d

<!-- Parent arrow command -->

[parent-arrow-video]: https://github.com/user-attachments/assets/67b4c0b5-5b94-4574-a7c1-0dda8e18b7b4
[smooth-parent-arrow-video]: https://github.com/user-attachments/assets/1b7ac44c-f7bc-4847-aa8a-897380aed54e
[wraparound-parent-arrow-video]: https://github.com/user-attachments/assets/ce35b55f-98dc-485d-a5e4-005ebe3ea169
[smooth-wraparound-parent-arrow-video]: https://github.com/user-attachments/assets/5256f0c5-b96b-4f4c-ac1d-f4a3f087cc57

<!-- First file command -->

[first-file-video]: https://github.com/user-attachments/assets/4b4a1e6d-b013-47b5-919f-90279977fd98
[smooth-first-file-video]: https://github.com/user-attachments/assets/f4c9c191-fa9f-428e-87e2-9bf654e60f72

<!-- Archive command -->

[archive-must-have-hovered-item-video]: https://github.com/user-attachments/assets/a49929b3-3b0d-4a50-b5d6-9dae7c119e7e
[archive-hovered-item-optional-video]: https://github.com/user-attachments/assets/b1dfd41a-1125-4fc4-9fe7-dc5a0378b70b
[archive-prompt-video]: https://github.com/user-attachments/assets/f247f71c-e846-4bff-a2cc-13fc645a2472
[archive-behaviour-video]: https://github.com/user-attachments/assets/531b04e9-4fe6-4a39-9a7e-4b16deae87c6
[archive-encrypt-files-video]: https://github.com/user-attachments/assets/8330a9db-ff74-4f37-8b21-113c7010e353
[archive-reveal-created-archive-video]: https://github.com/user-attachments/assets/8ae784bc-e64e-4fd1-9ebc-93f759f5a3d7
[archive-remove-archived-files-video]: https://github.com/user-attachments/assets/be37cb9d-8f1e-4548-98c0-33bcbd288b59

<!-- Emit command -->

[emit-yazi-command-video]: https://github.com/user-attachments/assets/2f2a6231-b888-4041-be40-6d0adf6b1c8f
[emit-plugin-command-video]: https://github.com/user-attachments/assets/a6f93fb1-3a86-4580-8f17-b75fd7ce6650
[emit-augmented-command-video]: https://github.com/user-attachments/assets/68e64f0e-e9f4-4e1d-ae3e-0c339b89763c

<!-- Editor command -->

[editor-must-have-hovered-item-video]: https://github.com/user-attachments/assets/cefa765e-8ba1-407e-a144-b098641dde25
[editor-hovered-item-optional-video]: https://github.com/user-attachments/assets/76cce397-b159-4967-8429-fc6d8d0944e0
[editor-prompt-video]: https://github.com/user-attachments/assets/e6a9aef0-d31c-40e6-ac40-d091f8b67b25
[editor-behaviour-video]: https://github.com/user-attachments/assets/21e8a73c-4a82-4f57-96c1-e3208ea073ab

<!-- Pager command -->

[pager-must-have-hovered-item-video]: https://github.com/user-attachments/assets/09e5200f-3d68-4718-a34a-27dbd66f8fca
[pager-hovered-item-optional-video]: https://github.com/user-attachments/assets/95b30bce-ef3f-4051-af7a-6f217dc1a828
[pager-prompt-video]: https://github.com/user-attachments/assets/ab44b3ab-2938-405a-8a86-294bb23f652f
[pager-behaviour-video]: https://github.com/user-attachments/assets/05085f86-a256-4ee8-a086-dc9cb9cddc9a
