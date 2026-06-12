# augment-command.yazi

A [Yazi][yazi-link] plugin that enhances Yazi's default commands. This plugin is
inspired by the [Yazi tips page][yazi-tips-page], the
[bypass.yazi](https://github.com/Rolv-Apneseth/bypass.yazi) plugin and the
[fast-enter.yazi](https://github.com/ourongxing/fast-enter.yazi) plugin.

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
  - [Tab create (`tab-create`)](#tab-create-tab-create)
  - [Tab switch (`tab-switch`)](#tab-switch-tab-switch)
  - [Quit (`quit`)](#quit-quit)
  - [Arrow (`arrow`)](#arrow-arrow)
- [New commands](#new-commands)
  - [Parent arrow (`parent-arrow`)](#parent-arrow-parent-arrow)
  - [First file (`first-file`)](#first-file-first-file)
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

- [Yazi][yazi-link] v26.5.6+
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
| `wraparound_file_navigation`        | `true` or `false`                                         | `true`    | Wrap around from the bottom to the top or from the top to the bottom when using the `arrow` or `parent-arrow` command to navigate.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| `protected_directories`             | `string[]`                                                | `{}`      | A list of **absolute** paths to directories that are excluded from forced deletion. Basically, if an item is in one of the directories in `protected_directories`, the confirmation prompt will appear even when the `--force` flag is passed. This option also causes a prompt to appear when using the `--remove` flag for the `extract` and `archive` commands.                                                                                                                                                                                                                                                                                                                                                                                                                                                                |

If you would like to use the default configuration, which is shown below, you
don't need to add anything to your `~/.config/yazi/init.lua` file on Linux and
macOS, or your `%AppData%\yazi\config\init.lua` file on Windows.

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
    wraparound_file_navigation = true,
    protected_directories = {},
})
```

However, if you would like to configure the plugin, you can add your desired
configuration options to your `~/.config/yazi/init.lua` file on Linux and macOS,
or your `%AppData%\yazi\config\init.lua` file on Windows. You can leave out
configuration options that you would like to be left as default. An example
configuration is shown below:

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
    wraparound_file_navigation = false,
    protected_directories = {"/bin/", "/usr/bin/"},
})
```

## What about the commands are augmented?

All commands that can operate on multiple files and directories, like `open`,
`rename`, `remove` and `shell`, as well as the new commands `extract`,
`archive`, `editor` and `pager`, now determine an item group to operate on. By
default, the command will operate on the hovered item, unless the hovered item
is also selected, then it will operate on the selected items.

- When `must_have_hovered_item` is set to `true`, having no hovered item means
  the plugin will cancel the operation.
- When `must_have_hovered_item` is set to `false` and there are selected items,
  the selected items will be operated on.
- With `prompt` is set to `true`, the plugin will always prompt you to choose an
  item group when there are both selected items and a hovered item.

## Augmented commands

### Open (`open`)

- The `open` command is augmented as stated in [this section
  above][augment-section].

  Videos:
  - When `prompt` is set to `true`:

    [open-prompt-video]

  - When `prompt` is set to `false`:

    [open-behaviour-video]

- When `smart_enter` is set to `true`, it calls the `enter` command when the
  hovered item is a directory.
- `--smart` flag to use one command to `open` files and `enter` directories.
  This flag will cause the `open` command to call the `enter` command when the
  hovered item is a directory even when `smart_enter` is set to `false`. This
  allows you to set a key to use this behaviour with the `open` command instead
  of using it for every `open` command.

  Video:

  [smart-enter-video]

- `--no-skip` flag, which only applies when `smart_enter` is used as it is
  passed to the `enter` command. More details about this flag can be found at
  the documentation for the [enter command](#enter-enter).
- Automatically extracts and enters archive files, with support for skipping
  directories that contain only one subdirectory in the extracted archive. This
  can be disabled by setting `enter_archives` to `false` in the configuration.
  This feature requires the [`7z` or `7zz` command][7z-link] to be present to
  extract the archives.

  Video:

  [open-auto-extract-archives-video]

- The `open` command makes use of the `extract` command, so recursively
  extracting archives is also supported. For more information, look at the
  section about the [`extract` command](#extract-extract).

  Video:

  [open-recursively-extract-archives-video]

### Extract (`extract`)

- Technically this is a new command, as Yazi does not provide an `extract`
  command. However, Yazi does provide a built-in plugin called `extract`, so
  this command is included in the
  [augmented commands section](#augmented-commands) instead of the
  [new commands section](#new-commands).
- This command requires the [`7z` or `7zz` command][7z-link] to be present to
  extract the archives, as well as the [`file` command][file-command-link] to
  check if a file is an archive or not.
- You are not meant to use this command directly. However, you can do so if you
  like, as the extract command is also augmented as stated in [this section
  above][augment-section].

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
  which is used for the `extract` opener. This way, you can use the features
  that come with the augmented `extract` command, like recursively extracting
  archives, with the `open` command. This is the intended way to use this
  command, as the `open` command is meant to be the command that opens
  everything, so it is a bit counterintuitive to have to use a separate key to
  extract archives.

  To replace the built-in `extract` plugin, copy the [`extract` openers
  section][yazi-yazi-toml-extract-openers] in [Yazi's default
  `yazi.toml`][yazi-yazi-toml] into your `yazi.toml`, which is located at
  `~/.config/yazi/yazi.toml` for Linux and macOS, and
  `%AppData%\yazi\config\yazi.toml` file on Windows. Make sure that the
  `extract` openers are under the `opener` key in your `yazi.toml`. Then replace
  `extract` with `augmented-extract`, and you will be using the plugin's
  `extract` command instead of Yazi's built-in `extract` plugin.

  Here is an example configuration:

  ```toml
  # ~/.config/yazi/yazi.toml for Linux and macOS
  # %AppData%\yazi\config\yazi.toml for Windows

  [opener]
  extract = [
      { run = "ya pub augmented-extract --list %s", desc = "Extract here" },
  ]
  ```

  Alternatively, another way to do it is:

  ```toml
  # ~/.config/yazi/yazi.toml for Linux and macOS
  # %AppData%\yazi\config\yazi.toml for Windows

  [[opener.extract]]
  run = "ya pub augmented-extract --list %s"
  desc = "Extract here"
  ```

- The `extract` command supports recursively extracting archives, which means if
  the extracted archive file contains other archive files in it, those archives
  will be automatically extracted, keeping the directory structure of the
  archive if the archive doesn't only contain a single archive file. This
  feature requires the [`file` command][file-command-link] to detect the mime
  type of the extracted file, and to check whether it is an archive file or not.
  This makes extracting binaries from compressed tarballs much easier, as
  there's no need to press a key twice to decompress and extract the compressed
  tarballs. You can disable this feature by setting
  `recursively_extract_archives` to `false` in the configuration.

  Video:

  [extract-recursively-extract-archives-video]

- The `extract` command also supports extracting encrypted archives, and will
  prompt you for a password when it encounters an encrypted archive. You can
  configure the number of times the plugin prompts you for a password by setting
  the `extract_retries` configuration option. The default value is `3`, which
  means the plugin will prompt you `3` more times for the correct password after
  the initial password attempt before giving up and showing an error.

  Video:

  [extract-encrypted-archive-video]

- The `preserve_file_permissions` configuration option applies to the `extract`
  command, and requires the [`tar` command][gnu-tar-link] to be present, as
  [`7z`][7z-link] does not support preserving file permissions. The plugin will
  show a warning if the `preserve_file_permissions` option is set to `true` but
  [`tar`][gnu-tar-link] is not installed.

  For macOS users, it is highly recommended to install and use [GNU `tar`, or
  `gtar`][gnu-tar-link] instead of the [Apple provided `tar`
  command][apple-tar-link]. You can install it using the [`brew`][brew-link]
  command below:

  ```sh
  brew install gnu-tar
  ```

  The plugin will automatically use [GNU `tar`][gnu-tar-link] if it finds the
  [`gtar` command][gnu-tar-link] instead of the [Apple provided `tar`
  command][apple-tar-link].

  Setting the `preserve_file_permissions` configuration option to `true` will
  preserve the file permissions of the files contained in a `tar` archive or
  tarball.

  This has considerable security implications, as executables extracted from all
  `tar` archives can be immediately executed on your system, possibly
  compromising your system if you extract a malicious `tar` archive. Hence, this
  option is set to `false` by default, and should be left as such. This option
  is provided for your convenience, but do seriously consider if such
  convenience is worth the risk of extracting a malicious `tar` archive that
  executes malware on your system.

- `--reveal` flag to automatically hover the files that have been extracted.

  Video:

  [extract-reveal-extracted-item-video]

- `--remove` flag to automatically remove the archive after the files have been
  extracted.

  Video:

  [extract-remove-extracted-archive-video]

- When the item being removed by the `--remove` flag is in the list of
  `protected_directories`, the plugin prompts for confirmation instead of
  immediately removing the item even when the `--force` flag is passed.

  Video:

  [extract-remove-protected-extracted-archive-video]

### Enter (`enter`)

- When `smart_enter` is set to `true`, it calls the `open` command when the
  hovered item is a file.
- `--smart` flag to use one command to `enter` directories and `open` files.
  This flag will cause the `enter` command to call the `open` command when the
  selected items or the hovered item is a file, even when `smart_enter` is set
  to `false`. This allows you to set a key to use this behaviour with the
  `enter` command instead of using it for every `enter` command.

  Video:

  [smart-enter-video]

- Automatically skips directories that contain only one subdirectory when
  entering directories. This can be turned off by setting
  `skip_single_subdirectory_on_enter` to `false` in the configuration.

  Video:

  [enter-skip-single-subdirectory-video]

- `--no-skip` flag. It stops the plugin from skipping directories that contain
  only one subdirectory when entering directories, even when
  `skip_single_subdirectory_on_enter` is set to `true`. This allows you to set a
  key to navigate into directories without skipping the directories that contain
  only one subdirectory.

### Leave (`leave`)

- Automatically skips directories that contain only one subdirectory when
  leaving directories. This can be turned off by setting
  `skip_single_subdirectory_on_leave` to `false` in the configuration.

  Video:

  [leave-skip-single-subdirectory-video]

- `--no-skip` flag. It stops the plugin from skipping directories that contain
  only one subdirectory, even when `skip_single_subdirectory_on_leave` is set to
  `true`. This allows you to set a key to navigate out of directories without
  skipping the directories that contain only one subdirectory.

### Rename (`rename`)

- The `rename` command is augmented as stated in [this section
  above][augment-section].

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

- The `remove` command is augmented as stated in [this section
  above][augment-section].

  Videos:
  - When `must_have_hovered_item` is `true`:

    [remove-must-have-hovered-item-video]

  - When `must_have_hovered_item` is `false`:

    [remove-hovered-item-optional-video]

  - When `prompt` is set to `true`:

    [remove-prompt-video]

  - When `prompt` is set to `false`:

    [remove-behaviour-video]

- When removing an item that is in the list of `protected_directories`, the
  plugin prompts for confirmation instead of immediately removing the item even
  when the `--force` flag was passed.

  Video:

  [remove-protected-directory-video]

### Copy (`copy`)

- The `copy` command is augmented as stated in [this section
  above][augment-section].

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

- You should use Yazi's default `create` command instead of this augmented
  `create` command if you don't want the paths without file extensions to be
  created as directories by default, and you don't care about automatically
  opening and entering the created file and directory respectively.
- The `create` command has a different behaviour from Yazi's `create` command.
  When the path given to the command doesn't have a file extension, the `create`
  command will create a directory instead of a file, unlike Yazi's `create`
  command. Other that this major difference, the `create` command functions
  identically to Yazi's `create` command, which means that you can use a
  trailing `/` on Linux and macOS, or `\` on Windows to create a directory. It
  will also recursively create directories to ensure that the path given exists.
  It also supports all the options supported by Yazi's `create` command, so you
  can pass them to the command and expect the same behaviour.
- The rationale for this behaviour is that creating a path without a file
  extension usually means you intend to create a directory instead of a file, as
  files usually have file extensions.

  Video:

  [create-behaviour-video]

- When `open_file_after_creation` is set to `true`, the `create` command will
  `open` the created file. This behaviour can also be enabled by passing the
  `--open` flag to the `create` command.

  Video:

  [create-and-open-files-video]

  Likewise, when `enter_directory_after_creation` is set to `true`, the `create`
  command will `enter` the created directory. This behaviour can also be enabled
  by passing the `--enter` flag to the `create` command.

  Video:

  [create-and-enter-directories-video]

  To enable both behaviours with flags, just pass both the `--open` flag and the
  `--enter` flag to the `create` command.

  Video:

  [create-and-open-files-and-directories-video]

- If you would like to use the behaviour of Yazi's `create` command, probably
  because you would like to automatically open and enter the created file and
  directory respectively, you can either set `use_default_create_behaviour` to
  `true`, or pass the `--default-behaviour` flag to the `create` command.

  Video:

  [create-default-behaviour-video]

### Shell (`shell`)

- This command runs the shell command given with the augment stated in [this
  section above][augment-section]. You should only use this command if you need
  the plugin to determine a suitable item group for the command to operate on.
  Otherwise, you should just use the default `shell` command provided by Yazi.

  Videos:
  - When `must_have_hovered_item` is `true`:

    [shell-must-have-hovered-item-video]

  - When `must_have_hovered_item` is `false`:

    [shell-hovered-item-optional-video]

  - When `prompt` is set to `true`:

    [shell-prompt-video]

  - When `prompt` is set to `false`:

    [shell-behaviour-video]

- To use this command, the syntax is exactly the same as the default `shell`
  command provided by Yazi. You just provide the command you want and provide
  any Yazi shell variable that **provides the file path**, which is [documented
  here][yazi-shell-variables]. The plugin will automatically replace the shell
  variable you give with the file paths for the item group before executing the
  command.

- There is no need to quote the shell variable on Linux and macOS, as it is
  expanded by the plugin instead of the shell, and the paths are already quoted
  using the `ya.quote` function before execution, so quoting is entirely
  unnecessary and may result in unexpected behaviour.

- `--exit-if-dir` flag to stop the shell command given from executing if the
  item group consists only of directories. For example, if the item group is the
  hovered item, then the shell command will not be executed if the hovered item
  is a directory. If the item group is the selected items group, then the shell
  command will not be executed if **all** the selected items are directories.
  This behaviour comes from it being used in the `pager` command. The `pager`
  command is essentially:

  ```toml
  # ~/.config/yazi/keymap.toml on Linux and macOS
  # %AppData%\yazi\config\keymap.toml on Windows

  [[mgr.prepend_keymap]]
  on = "i"
  run = "plugin augment-command.shell -- '$PAGER %s' --block --exit-if-dir"
  desc = "Open the pager"
  ```

  It is also used in the `editor` command, since you usually wouldn't use your
  text editor to open directories, especially if you are already using a
  terminal file manager like [Yazi][yazi-link]. The `editor` command is
  essentially:

  ```toml
  # ~/.config/yazi/keymap.toml on Linux and macOS
  # %AppData%\yazi\config\keymap.toml on Windows

  [[mgr.prepend_keymap]]
  on = "o"
  run = "plugin augment-command.shell -- '$EDITOR %s' --block --exit-if-dir"
  desc = "Open the editor"
  ```

  Video:

  [shell-exit-if-directory-video]

#### Passing arguments to the `shell` command

Ideally, you will want to avoid using backslashes to escape the shell command
arguments, so here are a few ways to do it:

1. Shell arguments that don't have special shell variables on Linux and macOS,
   like `$SHELL`, or don't have special shell characters like `>`, `|` or
   spaces, need not be quoted with double quotes `"` or single quotes `'`
   respectively. For example:

   ```toml
   # ~/.config/yazi/keymap.toml on Linux and macOS
   # %AppData%\yazi\config\keymap.toml on Windows
   [[mgr.prepend_keymap]]
   on = "i"
   run = "plugin augment-command.shell -- --block 'bat -p --pager less %s'"
   desc = "Open with bat"
   ```

2. If the arguments to the `shell` command have special shell variables on Linux
   and macOS, like `$SHELL`, or special shell characters like `>`, `|`, or
   spaces, use `--` to denote the end of the flags and options passed to the
   `shell` command. For example:

   ```toml
   # ~/.config/yazi/keymap.toml on Linux and macOS
   # %AppData%\yazi\config\keymap.toml on Windows
   [[mgr.prepend_keymap]]
   on = "<C-s>"
   run = 'plugin augment-command.shell -- --block -- sh -c "$SHELL"'
   desc = "Open a shell inside of a shell here"
   ```

   ```toml
   # ~/.config/yazi/keymap.toml on Linux and macOS
   # %AppData%\yazi\config\keymap.toml on Windows
   [[mgr.prepend_keymap]]
   on = "<C-s>"
   run = "plugin augment-command.shell -- --block -- sh -c 'echo hello'"
   desc = "Open a shell and say hello inside the opened shell"
   ```

3. If the arguments passed to the `shell` command themselves contain arguments
   that have special shell variables on Linux and macOS, like `$SHELL`, or
   special shell characters like `>`, `|`, or spaces, use the triple single
   quote `'''` delimiter for the `run` string.

   ```toml
   # ~/.config/yazi/keymap.toml on Linux and macOS
   # %AppData%\yazi\config\keymap.toml on Windows
   [[mgr.prepend_keymap]]
   on = "<C-s>"
   run = '''plugin augment-command.shell -- --block -- sh -c 'sh -c "$SHELL"''''
   desc = "Open a shell inside of a shell inside of a shell here"
   ```

   ```toml
   # ~/.config/yazi/keymap.toml on Linux and macOS
   # %AppData%\yazi\config\keymap.toml on Windows
   [[mgr.prepend_keymap]]
   on = "<C-s>"
   run = '''plugin augment-command.shell --
       --block -- sh -c "$SHELL -c 'echo hello'"
   '''
   desc = "Open a shell inside of a shell and say hello inside the opened shell"
   ```

   A more legitimate use case for this would be something like [Yazi's tip to
   email files using Mozilla Thunderbird][thunderbird-tip]:

   ```toml
   # ~/.config/yazi/keymap.toml on Linux and macOS
   # %AppData%\yazi\config\keymap.toml on Windows
   [[mgr.prepend_keymap]]
   on = "<C-e>"
   run = '''plugin augment-command.shell --
       paths=$(for p in %s; do echo "$p"; done | paste -s -d,)
       thunderbird -compose "attachment='$paths'"
   '''
   desc = "Email files using Mozilla Thunderbird"
   ```

If the above few methods to avoid using backslashes within your shell command to
escape the quotes are still insufficient for your use case, it is probably more
appropriate to write a shell script in a separate file and execute that instead
of writing the shell command inline in your `keymap.toml` file.

### Paste (`paste`)

- When `smart_paste` is set to `true`, the `paste` command will paste items into
  the hovered directory without entering it. If the hovered item is not a
  directory, the command pastes in the current directory instead. Otherwise,
  when `smart_paste` is set to `false`, the `paste` command will behave like the
  default `paste` command.
- `--smart` flag to enable pasting in the hovered directory without entering the
  directory. This flag will cause the `paste` command to paste items into the
  hovered directory even when `smart_paste` is set to `false`. This allows you
  to set a key to use this behaviour with the `paste` command instead of using
  it for every `paste` command.

  Video:

  [smart-paste-video]

### Tab create (`tab-create`)

- When `smart_tab_create` is set to `true`, the `tab_create` command will create
  a tab in the hovered directory instead of the current directory like the
  default key binds. If the hovered item is not a directory, then the command
  just creates a new tab in the current directory instead. Otherwise, when
  `smart_tab_create` is set to `false`, the `tab_create` command will behave
  like the default key bind to create a tab, which is `tab_create --current`.
- `--smart` flag to enable creating a tab in the hovered directory. This flag
  will cause the `tab_create` command to create a tab in the hovered directory
  even when `smart_tab_create` is set to `false`. This allows you to set a
  specific key to use this behaviour with the `tab_create` command instead of
  using it for every `tab_create` command.

  Video:

  [smart-tab-create-video]

### Tab switch (`tab-switch`)

- When `smart_tab_switch` is set to `true`, the `tab_switch` command will ensure
  that the tab that is being switched to exist. It does this by automatically
  creating all the tabs required for the desired tab to exist. For example, if
  you are switching to tab 5 (`tab_switch 4`), and you only have two tabs
  currently open (tabs 1 and 2), the plugin will create tabs 3, 4 and 5 and then
  switch to tab 5. The tabs are created using the current directory. The
  `smart_tab_create` configuration option does not affect the behaviour of this
  command. Otherwise, when `smart_tab_switch` is set to `false`, the
  `tab_switch` command will behave like the default `tab_switch` command, and
  simply switch to the tab if it exists, and do nothing if it doesn't exist.
- `--smart` flag to automatically create the required tabs for the desired tab
  to exist. This flag will cause the `tab_switch` command to automatically
  create the required tabs even when `smart_tab_switch` is set to `false`. This
  allows you to set a specific key to use this behaviour with the `tab_switch`
  command instead of using it for every `tab_switch` command.

  Video:

  [smart-tab-switch-video]

### Quit (`quit`)

- You should use Yazi's default `quit` command instead of this augmented command
  if you don't want to have a prompt when quitting Yazi with multiple tabs open.
  This command has a visual side effect of showing a confirmation prompt for a
  split second before closing Yazi when quitting Yazi with only 1 tab open,
  which can be annoying. This confirmation prompt is due to the plugin still
  running for a bit after the `quit` command is emitted, causing Yazi to prompt
  you for confirmation as there are tasks still running. However, once the
  plugin has stopped running, which is a split second after the `quit` command
  is emitted, Yazi will exit. You can observe this visual effect in the video
  demonstration below.
- When `confirm_on_quit` is set to `true`, the plugin will prompt you for
  confirmation when there is more than 1 tab open. Otherwise, it will
  immediately quit Yazi, just like the default `quit` command.
- `--confirm` flag to get the plugin to prompt you for confirmation when
  quitting with multiple tabs open. This flag will cause the `quit` command to
  prompt you for confirmation when quitting with multiple tabs open even when
  `confirm_on_quit` is set to `false`. This allows you to set a specific key to
  use this behaviour with the `quit` command instead of using it for every
  `quit` command.

  Video:

  [quit-with-confirmation-video]

### Arrow (`arrow`)

- When `smooth_scrolling` is set to `true`, the arrow command will smoothly
  scroll through the file list.

  Video:

  [smooth-arrow-video]

- When `wraparound_file_navigation` is set to `true`, the arrow command will
  wrap around from the bottom to the top or from the top to the bottom when
  navigating.

  Video:

  [wraparound-arrow-video]

- When both `smooth_scrolling` and `wraparound_file_navigation` are set to
  `true`, the command will smoothly scroll the wraparound transition as well.

  Video:

  [smooth-wraparound-arrow-video]

- Otherwise, it'll behave like the default `arrow 1` command.
- `--no-wrap` flag to prevent the `arrow` command from wrapping around, even
  when `wraparound_file_navigation` is set to `true`.

## New commands

### Parent arrow (`parent-arrow`)

- This command behaves like the `arrow` command, but in the parent directory. It
  allows you to navigate in the parent directory without leaving the current
  directory.

  Video:

  [parent-arrow-video]

- When `smooth_scrolling` is set to `true`, this command will smoothly scroll
  through the parent directories.

  Video:

  [smooth-parent-arrow-video]

- When `wraparound_file_navigation` is set to `true`, this command will also
  wrap around from the bottom to the top or from top to the bottom when
  navigating in the parent directory.

  Video:

  [wraparound-parent-arrow-video]

- When both `smooth_scrolling` and `wraparound_file_navigation` are set to
  `true`, the command will smoothly scroll the wraparound transition as well.

  Video:

  [smooth-wraparound-parent-arrow-video]

- You can also replicate this using this series of commands below, but it
  doesn't work as well, and doesn't support wraparound navigation or smooth
  scrolling:

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

- `--no-wrap` flag to prevent the `parent-arrow` command from wrapping around,
  even when `wraparound_file_navigation` is set to `true`.

### First file (`first-file`)

- This command just moves the cursor to the first file in the current directory,
  regardless of the current cursor position.
- It is useful for quickly getting to the first file in the current directory
  when `sort_dir_first` is set to `true`, which is the case by default.

  Video:

  [first-file-video]

- It also works with smooth scrolling, so when `smooth_scrolling` is set to
  `true`, the command will smoothly scroll the cursor to the first file.

  Video:

  [smooth-first-file-video]

- Alternatively, if you just want to get to a file in the current directory, you
  can use the built-in `G` key bind that calls `arrow bot` to get to the last
  item in the current directory, which would be a file if `sort_dir_first` is
  set to `true`, which is the case by default.

### Archive (`archive`)

- The `archive` command adds the selected or hovered items to an archive, with
  the plugin prompting for an archive name. The archive file extension given
  will be used to determine the type of archive to create.
- When the archive name given has no file extension, the `.zip` file extension
  will be automatically added by default to create a `zip` archive.
- When the item group is determined to be the hovered item, the `archive`
  command will create a `.zip` archive with the name of the hovered item if no
  archive name is given and the input is confirmed by using the `<Enter>` key.
- The `archive` command will also prompt for an overwrite confirmation, if the
  archive being created already exists, just like the `create` command.
- This command is also augmented as stated in [this section
  above][augment-section].

  Videos:
  - When `must_have_hovered_item` is `true`:

    [archive-must-have-hovered-item-video]

  - When `must_have_hovered_item` is `false`:

    [archive-hovered-item-optional-video]

  - When `prompt` is set to `true`:

    [archive-prompt-video]

  - When `prompt` is set to `false`:

    [archive-behaviour-video]

- `--force` flag to always overwrite the existing archive without showing the
  confirmation prompt.
- `--encrypt` flag to encrypt the archive with the given password, which applies
  even when `encrypt_archives` is set to `false`.
- `--encrypt-headers` flag to encrypt the archive headers, which applies even
  when `encrypt_archive_headers` is set to `false`. Note that this option only
  works with `7z` archives, other types of archives like `zip` archives do not
  support header encryption. The plugin will show a warning if the archive type
  does not support header encryption and the flag is passed, but will continue
  with the creation of the encrypted archive. This option has no effect if
  either `encrypt_archives` is set to `false` or the `--encrypt` flag isn't
  given.

  Video:

  [archive-encrypt-files-video]

- `--reveal` flag to automatically hover the archive file that is created, which
  applies even when `reveal_created_archive` is set to `false`.

  Video:

  [archive-reveal-created-archive-video]

- `--remove` flag to automatically remove the files that are added to the
  archive, which applies even when `remove_archived_files` is set to `false`.

  Video:

  [archive-remove-archived-files-video]

- When the item being removed by the `--remove` flag is in the list of
  `protected_directories`, the plugin prompts for confirmation instead of
  immediately removing the item even when the `--force` flag is passed.

  Video:

  [archive-remove-protected-archived-files-video]

### Emit (`emit`)

- The `emit` command allows you to emit any Yazi command by typing the command
  into an input prompt. The syntax of the command is exactly the same as the
  commands in the `keymap.toml` file. For example, if the input is `arrow next`,
  then that will be the command that is emitted by the plugin.

  Video:

  [emit-yazi-command-video]

- `--plugin` flag to emit a plugin command. This flag essentially just emits
  Yazi's `plugin` command with the input passed as the first argument. For
  example, if the input is `augment-command.parent-arrow -- 1`, then the full
  command being emitted by the plugin is
  `plugin augment-command.parent-arrow -- 1`.

  Video:

  [emit-plugin-command-video]

- `--augmented` flag to emit an augmented command. This flag is a shortcut for
  emitting a command from this plugin. For example, if the command given is
  `parent-arrow -- 1`, the full command emitted by the plugin is
  `plugin augment-command.parent-arrow -- 1`.

  Video:

  [emit-augmented-command-video]

- If `--augmented` flag is passed together with the `--plugin` flag, the
  `--augmented` flag will take precedence over the `--plugin` flag, and the
  command emitted will be from this plugin instead of being a `plugin` command.
  In any case, you should not be passing both the `--plugin` and `--augmented`
  flags.

### Editor (`editor`)

- The `editor` command opens the default editor set by the `$EDITOR` environment
  variable.
- When the file being edited is owned by the root user on Unix systems, like
  Linux and macOS, the `editor` command will automatically call `sudo -e` to
  edit the file instead of using the `$EDITOR` environment variable.
- The command is also augmented as stated in [this section
  above][augment-section].

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

- The `pager` command opens the default pager set by the `$PAGER` environment
  variable.
- The command is also augmented as stated in [this section
  above][augment-section].
- The `pager` command will also skip opening directories, as the pager cannot
  open directories and will error out. Hence, the command will not do anything
  when the hovered item is a directory, or if **all** the selected items are
  directories. This makes the pager command less annoying as it will not try to
  open a directory and then immediately fail with an error, causing a flash and
  causing Yazi to send a notification.

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

Add the commands that you would like to use to your `keymap.toml` file, located
at `~/.config/yazi/keymap.toml` on Linux and macOS and at
`%AppData%\yazi\config\keymap.toml` on Windows, in this format:

```toml
# ~/.config/yazi/keymap.toml on Linux and macOS
# %AppData%\yazi\config\keymap.toml on Windows

[[mgr.prepend_keymap]]
on = "key"
run = "plugin augment-command.command -- arguments --flags --options=42"
desc = "Description"
```

For example, to use the augmented `enter` command:

```toml
# ~/.config/yazi/keymap.toml on Linux and macOS
# %AppData%\yazi\config\keymap.toml on Windows

[[mgr.prepend_keymap]]
on = "l"
run = "plugin augment-command.enter"
desc = "Enter a directory and skip directories with only a single subdirectory"
```

All the default arguments, flags and options provided by Yazi are also
supported, for example:

```toml
# ~/.config/yazi/keymap.toml on Linux and macOS
# %AppData%\yazi\config\keymap.toml on Windows

[[mgr.prepend_keymap]]
on = "k"
run = "plugin augment-command.arrow -- -1"
desc = "Move the cursor up"

[[mgr.prepend_keymap]]
on = "r"
run = "plugin augment-command.rename -- --cursor=before_ext"
desc = "Rename a file or directory"

[[mgr.prepend_keymap]]
on = "D"
run = "plugin augment-command.remove -- --permanently"
desc = "Permanently delete the files"

[[mgr.prepend_keymap]]
on = ["g", "j"]
run = "plugin augment-command.parent-arrow -- 1"
desc = "Move the cursor down in the parent directory"
```

For the default descriptions of the commands, you can refer to [Yazi's default
`keymap.toml` file][yazi-keymap-toml].

Essentially, all you need to do to use this plugin is to add
`plugin augment-command.`, in front of a Yazi command, such as `enter`, which
results in `plugin augment-command.enter'`.

### Using the `extract` command as an opener

This is the intended way to use the `extract` command instead of binding the
`extract` command to a key in your `keymap.toml` file. Look at the
[`extract` command section](#extract-extract) for details on how to do so.

### Configuring the plugin's prompts

If you would like to use the plugin's default prompts, you can skip this section
entirely. Otherwise, read on.

The plugin's prompts can be configured using the `th` object for built-in
commands like `create`.

New commands, or new features in existing commands introduced by the plugin,
like `archive` or `quit`, can be configured using the `th.augment_command`
object instead.

You **must** call the plugin's `setup` function **after** configuring the
plugin's prompts, otherwise, the prompts will remain as the default prompts.

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

This method of configuration is to be forward compatible with future versions of
Yazi, [as mentioned here](https://github.com/yazi-rs/plugins/issues/44).

#### Input prompts

For `input` prompts, like the prompt for the `archive` command, there are 3
configuration options:

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

- `create`: The prompt shown when creating a file.
- `delete`: The prompt shown when deleting a file in a protected directory.

Below is an example of configuring the `archive` command, which is provided by
the plugin:

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

- `extract_password`: The prompt to enter the password when extracting an
  encrypted archive.

- `archive`: The prompt for the archive name.

- `archive_password`: The prompts to enter the archive password when creating an
  encrypted archive. Note that the title for this prompt,
  `archive_password_title`, should be a list of two strings, like this:

- `emit`: The prompt shown when emitting a Yazi or plugin command.

  ```lua
  th.augment_command = th.augment_command or {}
  th.archive_password_title = {
      "Archive password:",
      "Confirm archive password:",
  }
  ```

#### Confirmation prompts

For `confirm` prompts, like the prompt for the `quit` command, there are 4
configuration options:

- `title`
- `body`
- `origin`
- `offset`

These options are documented in [Yazi's documentation][confirm-configuration].

The configuration for the `confirm` prompt is very similar to that of the
`input` prompt, just with one more option called `content`. The `content` option
can take either a `string`, or a list of `strings`.

For example, to configure the `overwrite` part of the `create` and `archive`
commands, which is built-in:

```lua
th.overwrite_title = "Overwrite file?"
th.overwrite_body = "Will overwrite the following file:"
th.overwrite_origin = "center"
th.overwrite_offset = {
    x = 0,
    y = 0,
    w = 50,
    h = 15,
}
```

This way of configuring the `confirm` prompt applies to the following:

- `overwrite`: The overwrite prompt when creating a file with the same name as
  an existing file.

Below is an example of configuring the `quit` command, which is provided by the
plugin:

```lua
th.augment_command = th.augment_command or {}
th.augment_command.quit_title = "Quit?"
th.augment_command.quit_body = {
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

For a full configuration example, you can have a look at [my `keymap.toml`
file][my-keymap-toml] and [my `yazi.toml` file][my-yazi-toml].

## [Licence]

This plugin is licensed under the [GNU AGPL v3 licence][Licence]. You can view
the full licence in the [`LICENSE`][Licence] file.

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
[yazi-yazi-toml-extract-openers]:
  https://github.com/sxyazi/yazi/blob/main/yazi-config/preset/yazi-default.toml#L50-L53
[yazi-yazi-toml]:
  https://github.com/sxyazi/yazi/blob/main/yazi-config/preset/yazi-default.toml
[yazi-shell-variables]:
  https://yazi-rs.github.io/docs/configuration/keymap/#mgr.shell
[thunderbird-tip]: https://yazi-rs.github.io/docs/tips/#email-selected-files
[input-configuration]: https://yazi-rs.github.io/docs/configuration/yazi#input
[confirm-configuration]:
  https://yazi-rs.github.io/docs/configuration/yazi#confirm
[yazi-keymap-toml]:
  https://github.com/sxyazi/yazi/blob/main/yazi-config/preset/keymap-default.toml
[my-keymap-toml]:
  https://github.com/hankertrix/Dotfiles/blob/main/tilde/dot_config/yazi/keymap.toml.tmpl
[my-yazi-toml]:
  https://github.com/hankertrix/Dotfiles/blob/main/tilde/dot_config/yazi/yazi.toml
[Licence]: LICENSE

<!-- Videos -->

<!-- Open command -->

[open-prompt-video]:
  https://github.com/user-attachments/assets/a19b6203-c4f9-4add-9974-6eb20c3f27c8
[open-behaviour-video]:
  https://github.com/user-attachments/assets/c2b43cf8-f6f4-4234-a3c7-2a2df2f3f0eb
[open-auto-extract-archives-video]:
  https://github.com/user-attachments/assets/5e42848a-b88c-4447-8bdd-6a407d8122d9
[open-recursively-extract-archives-video]:
  https://github.com/user-attachments/assets/579c1f62-5f22-4479-99c4-add80207427e

<!-- Extract command -->

[extract-must-have-hovered-item-video]:
  https://github.com/user-attachments/assets/829b2823-9caa-4a33-8c4c-6b62e2c4932a
[extract-hovered-item-optional-video]:
  https://github.com/user-attachments/assets/a1e9a69b-8ce4-4918-8fe4-c0dfa8dd4f03
[extract-prompt-video]:
  https://github.com/user-attachments/assets/2980fac3-8b84-42de-b1b7-3f461520c5ab
[extract-behaviour-video]:
  https://github.com/user-attachments/assets/d3328f55-2267-4299-9c40-0ee406c8a083
[extract-recursively-extract-archives-video]:
  https://github.com/user-attachments/assets/54fae0b3-332f-4c0a-8d37-ddfc34142d7f
[extract-encrypted-archive-video]:
  https://github.com/user-attachments/assets/43514e09-a501-4676-8954-4841690548bc
[extract-reveal-extracted-item-video]:
  https://github.com/user-attachments/assets/1925b178-1342-4c6d-a082-0c2a59506708
[extract-remove-extracted-archive-video]:
  https://github.com/user-attachments/assets/a28a327c-42a4-46f7-9195-1781301d4f9c
[extract-remove-protected-extracted-archive-video]:
  https://github.com/user-attachments/assets/47bd15cd-433b-4c36-9f0c-881a008e8abb

<!-- Enter command -->

[smart-enter-video]:
  https://github.com/user-attachments/assets/d5498a22-2914-4a7a-9663-f40faecff3e6
[enter-skip-single-subdirectory-video]:
  https://github.com/user-attachments/assets/0d5e0f05-9719-476d-9628-88e710c69173

<!-- Leave command -->

[leave-skip-single-subdirectory-video]:
  https://github.com/user-attachments/assets/30020de8-76a5-4c83-adeb-103985a68b29

<!-- Rename command -->

[rename-must-have-hovered-item-video]:
  https://github.com/user-attachments/assets/f07bd2c3-e66b-47bc-9970-1518a1a7ec72
[rename-hovered-item-optional-video]:
  https://github.com/user-attachments/assets/5127184d-4535-4dfb-96b6-9517119c0aad
[rename-prompt-video]:
  https://github.com/user-attachments/assets/c45c81f1-b808-493d-ab31-9958a6515333
[rename-behaviour-video]:
  https://github.com/user-attachments/assets/4f79d651-caf6-45cf-88f2-0807863285b5

<!-- Remove command -->

[remove-must-have-hovered-item-video]:
  https://github.com/user-attachments/assets/9224bd37-c8da-4d83-b34f-d5bd6ab85e6c
[remove-hovered-item-optional-video]:
  https://github.com/user-attachments/assets/0b26d634-53a6-4d1a-b08f-843ba5761552
[remove-prompt-video]:
  https://github.com/user-attachments/assets/de7157b8-957c-44f9-bd6f-85536b617977
[remove-behaviour-video]:
  https://github.com/user-attachments/assets/dd605e23-bbf6-4a0d-8515-207ff7854828
[remove-protected-directory-video]:
  https://github.com/user-attachments/assets/c9718beb-7b82-424c-beb7-67d8cc4685f6

<!-- Copy command -->

[copy-must-have-hovered-item-video]:
  https://github.com/user-attachments/assets/fe1639ff-4692-4aef-be41-0140d354e602
[copy-hovered-item-optional-video]:
  https://github.com/user-attachments/assets/706d64b2-e2dc-4448-b920-b5c866d76637
[copy-prompt-video]:
  https://github.com/user-attachments/assets/d040f80a-9453-4df4-bb6d-855b98eb9ae3
[copy-behaviour-video]:
  https://github.com/user-attachments/assets/92c18001-3aeb-4bda-a61f-56910ad766a6

<!-- Create command -->

[create-and-enter-directories-video]:
  https://github.com/user-attachments/assets/517de112-e193-4f1c-a53c-576552fa20aa
[create-and-open-files-video]:
  https://github.com/user-attachments/assets/c8304411-ee1e-4e19-8559-d93dc19c718c
[create-and-open-files-and-directories-video]:
  https://github.com/user-attachments/assets/eee148e5-5a6c-4844-b3f7-26d038ee0493
[create-behaviour-video]:
  https://github.com/user-attachments/assets/fba2d75e-0a5a-4f1a-8d36-cbeb573ec3f5
[create-default-behaviour-video]:
  https://github.com/user-attachments/assets/1f9f472d-2b2a-4b08-b258-5c48e78f58ed

<!-- Shell command -->

[shell-must-have-hovered-item-video]:
  https://github.com/user-attachments/assets/a9700aa4-5620-45ca-96fa-36cb315745ac
[shell-hovered-item-optional-video]:
  https://github.com/user-attachments/assets/23d31818-2d26-4d9a-b231-e089f81b3b14
[shell-prompt-video]:
  https://github.com/user-attachments/assets/a9f5308e-7a55-4501-be08-5bf0f2ee194b
[shell-behaviour-video]:
  https://github.com/user-attachments/assets/61a2cac9-c9ca-4d3d-b878-aa3e1697a496
[shell-exit-if-directory-video]:
  https://github.com/user-attachments/assets/5a425c86-fd88-4c98-ad2a-3e26ff3d9fe5

<!-- Paste command -->

[smart-paste-video]:
  https://github.com/user-attachments/assets/740e11b9-5d08-4a9b-8ab9-57497c2c9823

<!-- Tab create command -->

[smart-tab-create-video]:
  https://github.com/user-attachments/assets/8a9c5a20-6a0d-4c08-8700-8de1635cc128

<!-- Tab switch command -->

[smart-tab-switch-video]:
  https://github.com/user-attachments/assets/0de97bae-8c27-4b3b-804b-e7809e9cfc65

<!-- Quit command -->

[quit-with-confirmation-video]:
  https://github.com/user-attachments/assets/4eff8168-c483-484c-b5af-b19e5e73ad16

<!-- Arrow command -->

[smooth-arrow-video]:
  https://github.com/user-attachments/assets/c0cd6a04-dc90-4259-a5a6-738862345da0
[wraparound-arrow-video]:
  https://github.com/user-attachments/assets/8658a1ad-3924-4da6-bb75-2d64c7455026
[smooth-wraparound-arrow-video]:
  https://github.com/user-attachments/assets/491f37c2-9860-460f-ad73-78ea3b4ed69e

<!-- Parent arrow command -->

[parent-arrow-video]:
  https://github.com/user-attachments/assets/9c3fff42-0eaa-458e-a2bb-7a33534e806e
[smooth-parent-arrow-video]:
  https://github.com/user-attachments/assets/01fbb557-a5f9-489c-b33f-437bcb690990
[wraparound-parent-arrow-video]:
  https://github.com/user-attachments/assets/1d2989b2-ac02-41f6-b743-4b5c00a8e154
[smooth-wraparound-parent-arrow-video]:
  https://github.com/user-attachments/assets/f146ed1b-3af1-4d7f-ab29-4faae24a6d89

<!-- First file command -->

[first-file-video]:
  https://github.com/user-attachments/assets/90e48209-4c81-4103-ad8b-90677dbd4f5a
[smooth-first-file-video]:
  https://github.com/user-attachments/assets/1fb58097-2509-4db9-b786-9b8dfcf68206

<!-- Archive command -->

[archive-must-have-hovered-item-video]:
  https://github.com/user-attachments/assets/d0c918a8-bad0-4753-9112-a498b41e3a1b
[archive-hovered-item-optional-video]:
  https://github.com/user-attachments/assets/f49e7873-6749-4cda-bb27-065be9fc3ca5
[archive-prompt-video]:
  https://github.com/user-attachments/assets/8737fdad-a07f-46e2-bfcf-fc3a31de7a56
[archive-behaviour-video]:
  https://github.com/user-attachments/assets/8072fb6a-f3f4-434a-8c4c-9463e2a3407c
[archive-encrypt-files-video]:
  https://github.com/user-attachments/assets/180f1bc3-b426-4ed2-8211-9f6219c52bac
[archive-reveal-created-archive-video]:
  https://github.com/user-attachments/assets/703c011f-7e1f-415a-aa9f-36e8e165c327
[archive-remove-archived-files-video]:
  https://github.com/user-attachments/assets/e91c6560-7787-40e4-835f-4ddea2dfaccc
[archive-remove-protected-archived-files-video]:
  https://github.com/user-attachments/assets/0fb99276-d11b-4f1b-9d6f-c71dfb467590

<!-- Emit command -->

[emit-yazi-command-video]:
  https://github.com/user-attachments/assets/371ea916-7494-44f1-b5b1-8c84f6aa64b1
[emit-plugin-command-video]:
  https://github.com/user-attachments/assets/ed429335-a864-4e8c-8fe2-c955a66d5966
[emit-augmented-command-video]:
  https://github.com/user-attachments/assets/0d32d51e-cc75-4928-ae47-896ad25e1cc2

<!-- Editor command -->

[editor-must-have-hovered-item-video]:
  https://github.com/user-attachments/assets/ebd0649a-c466-4fbe-8146-65e83a88606a
[editor-hovered-item-optional-video]:
  https://github.com/user-attachments/assets/b9522045-5272-4bf4-81a8-4620b9c464e6
[editor-prompt-video]:
  https://github.com/user-attachments/assets/15651e22-230f-4d34-8fa8-b4d0d3614d17
[editor-behaviour-video]:
  https://github.com/user-attachments/assets/36597333-c652-4cd5-ae6f-d4b5ad542a0e

<!-- Pager command -->

[pager-must-have-hovered-item-video]:
  https://github.com/user-attachments/assets/123bd6af-de61-4a8a-b1aa-104a06ef403c
[pager-hovered-item-optional-video]:
  https://github.com/user-attachments/assets/9b6ff9b2-3c46-417a-be54-7460bbefccbc
[pager-prompt-video]:
  https://github.com/user-attachments/assets/9251ecb0-d912-4f95-ac99-cc418ad20daa
[pager-behaviour-video]:
  https://github.com/user-attachments/assets/229e5585-ea43-4424-92d5-4bc305438207
