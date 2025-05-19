#!/usr/bin/env python3

import argparse
import asyncio
import os
import shutil
import subprocess
from collections.abc import Coroutine
from pathlib import Path
from typing import cast, final, override

# Get the script directory
PYTHON_SCRIPT_DIRECTORY: Path = Path(__file__).parent

# The path to the directory for the demonstration
DEMONSTRATION_DIRECTORY: str = os.path.join(
	PYTHON_SCRIPT_DIRECTORY, "demonstration"
)

# The path to the VHS tapes directory
VHS_TAPES_DIRECTORY: Path = Path(DEMONSTRATION_DIRECTORY, "vhs_tapes")

# The folder with the subdirectory
FOLDER_WITH_SUBDIRECTORY: str = "folder_with_subdirectory"

# The empty folder
EMPTY_FOLDER: str = "empty_folder"

# Lorem ipsum text
DEMONSTRATION_TEXT: str = """
Lorem ipsum dolor sit amet, consectetur adipiscing elit,
sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris
nisi ut aliquip ex ea commodo consequat.
Duis aute irure dolor in reprehenderit in voluptate velit esse cillum
dolore eu fugiat nulla pariatur.
Excepteur sint occaecat cupidatat non proident,
sunt in culpa qui officia deserunt mollit anim id est laborum.
""".strip()

# The file name of the first file
FIRST_FILE_NAME: str = "file_1.txt"

# The plugin file name
PLUGIN_FILE_NAME: str = os.path.join(PYTHON_SCRIPT_DIRECTORY, "main.lua")

# The keymap TOML file name
KEYMAP_TOML_FILE_NAME: str = os.path.join(
	PYTHON_SCRIPT_DIRECTORY, "../../", "keymap.toml"
)

# The set of archive file extensions
ARCHIVE_FILE_EXTENSIONS: set[str] = {".zip", ".7z"}

# The plugin command template
PLUGIN_COMMAND_TEMPLATE = "plugin augment-command -- {}"

# The default key to use for a command
DEFAULT_KEY = "e"

# The default text file content
DEFAULT_TEXT_FILE_CONTENT = "Hello, world!"

# The settings for all demos
CONFIG: str = "\n".join(
	[
		"Set FontSize 20",
		'Set FontFamily "Maple Mono NF CN"',
		'Set Theme "BlulocoDark"',
		"Set Padding 20",
		"Set Margin 0",
	]
)

# The normal typing speed for all demos
NORMAL_TYPING_SPEED: str = "Set TypingSpeed 150ms"

# The typing speed for set up and clean up
FAST_TYPING_SPEED: str = "Set TypingSpeed 0.1ms"

# A long sleep time for some actions
LONG_SLEEP_TIME: str = "Sleep 2s"

# A sleep time for most actions
SLEEP_TIME: str = "Sleep 1s"

# A shorter sleep time for some actions
SHORT_SLEEP_TIME: str = "Sleep 500ms"

# A very short sleep time for some actions
VERY_SHORT_SLEEP_TIME: str = "Sleep 250ms"

# The command to change the working directory for all VHS tapes
CHANGE_TO_WORKING_DIRECTORY: str = f'Type "cd {DEMONSTRATION_DIRECTORY}" Enter'

# The command to clear the screen
CLEAR_SCREEN: str = "Type 'clear' Enter"

# The command to apply the configuration
APPLY_CONFIG_COMMAND: str = "Type 'chezmoi apply --force' Enter Wait"


# Function to create the argument parser and parse the command line arguments
def get_command_line_arguments() -> argparse.Namespace:
	"""
	Function to create the argument parser to parse
	the command line arguments and return the arguments.
	"""

	# Create the command line argument parser
	parser: argparse.ArgumentParser = argparse.ArgumentParser()

	# Add the arguments
	_ = parser.add_argument(
		"-s",
		"--search-term",
		type=str,
		default=None,
		help="The substring to search for in the video title.",
	)

	# Parse the arguments
	args = parser.parse_args()

	# Return the arguments
	return args


@final
class Script:
	"A class to represent a script for a VHS tape"

	__slots__ = ("setup", "clean_up", "required_programs")

	def __init__(
		self,
		*,
		setup: str | list[str] = "",
		clean_up: str | list[str] = "",
		required_programs: list[str] | None = None,
	):
		"Initialise the script for a VHS tape"

		# Save all the given variables
		self.setup: str = setup if isinstance(setup, str) else "\n".join(setup)
		self.clean_up: str = (
			clean_up if isinstance(clean_up, str) else "\n".join(clean_up)
		)
		self.required_programs: list[str] = (
			required_programs if required_programs is not None else []
		)


@final
class VHSTape:
	"A class to represent a VHS tape"

	__slots__ = (
		"name",
		"file_name",
		"files_and_directories",
		"setup",
		"clean_up",
		"required_programs",
		"shell_body",
		"yazi_body",
		"skip_quitting_yazi",
		"editor",
	)

	def __init__(
		self,
		*,
		name: str,
		files_and_directories: list[str] | None = None,
		scripts: list[Script] | None = None,
		shell_body: list[str] | None = None,
		yazi_body: list[str],
		skip_quitting_yazi: bool = False,
		editor: str | None = None,
	):
		"Initialise the VHS tape"

		# Save all the given variables
		self.name: str = name
		self.file_name: str = name.lower().replace(" ", "_")
		self.files_and_directories: list[str] = (
			files_and_directories if files_and_directories is not None else []
		)
		self.shell_body: list[str] = shell_body if shell_body else []
		self.yazi_body: list[str] = yazi_body
		self.skip_quitting_yazi: bool = skip_quitting_yazi
		self.editor: str | None = editor

		# Set the setup script to an empty list if it is not given
		scripts = scripts if scripts else []

		# Initialise the setup scripts
		self.setup: list[str] = []

		# Initialise the clean up scripts
		self.clean_up: list[str] = []

		# Initialise the required programs
		self.required_programs: set[str] = set()

		# Iterate over the scripts
		for script in scripts:
			#

			# Add the setup script
			self.setup.append(script.setup)

			# Add the clean up script
			self.clean_up.append(script.clean_up)

			# Add the required programs
			self.required_programs.update(script.required_programs)

		# Add yazi and clear to the required programs
		# as they are required for all demos
		self.required_programs.update(
			[
				"yazi",
				"clear",
			]
		)

		# Add the editor to the required programs if it is given
		if self.editor:
			self.required_programs.add(self.editor)

	@override
	def __str__(self) -> str:
		"Return the VHS tape as a string"

		# The files and directories to clean up
		files_and_directories_to_clean_up: set[str] = set()

		# Iterate over the files and directories
		for item in self.files_and_directories:
			#

			# Add the item with the trailing slashes removed
			files_and_directories_to_clean_up.add(item.strip("/"))

			# The path object for the item
			path_object = Path(item)

			# Get the file name and the file extension
			file_name, file_extension = path_object.stem, path_object.suffix

			# If the file extension is an archive file extension
			if file_extension in ARCHIVE_FILE_EXTENSIONS:
				#

				# Add the item without the file extension
				files_and_directories_to_clean_up.add(file_name)

		# If the list of files and directories to clean up is not empty
		if files_and_directories_to_clean_up:
			#

			# Append the rm command to the required programs
			self.required_programs.add("rm")

		# fmt: off

		# The list of lines
		lines: list[str] = [

			# The output file for the VHS tape
			f"Output ../videos/{self.file_name}.mp4",

			# The required programs for the VHS tape
			"\n".join(
				[f'Require "{program}"' for program in self.required_programs]
			),

			# Configuration for the VHS tape
			CONFIG,

			# The set up for the VHS tape
			"Hide",
			FAST_TYPING_SPEED,
			CHANGE_TO_WORKING_DIRECTORY,
			"\n".join(self.setup),
			CLEAR_SCREEN,

			# Set the normal typing speed
			NORMAL_TYPING_SPEED,

			# Show the output
			"Show",

			# The shell body of the VHS tape
			"\n".join(self.shell_body),

			# Open the Yazi program
			'Type "{}" Enter'.format(
				f"EDITOR={self.editor} yazi" if self.editor else "yazi"
			),
			SLEEP_TIME,

			# The yazi body of the VHS tape
			"\n".join(self.yazi_body),
		]

		# fmt: on

		# If quitting yazi is not skipped
		if not self.skip_quitting_yazi:
			#

			# The commands to quit yazi
			quit_yazi_commands = [
				SLEEP_TIME,
				'Type "q"',
				SHORT_SLEEP_TIME,
			]

			# Add the commands to the VHS tape
			lines.extend(quit_yazi_commands)

		# If there are clean up commands,
		# or there are files and directories to clean up
		if self.clean_up or files_and_directories_to_clean_up:
			#

			# Set the clean up section
			clean_up_section = [
				"Hide",
				FAST_TYPING_SPEED,
				"\n".join(self.clean_up),
				(
					"Type 'rm -rf {}' Enter".format(
						" ".join(files_and_directories_to_clean_up)
					)
					if files_and_directories_to_clean_up
					else ""
				),
			]

			# Add the clean up section to the lines
			lines.extend(clean_up_section)

		# The vhs tape
		vhs_tape = "\n".join(lines).format(*self.files_and_directories).strip()

		# Return the vhs tape
		return vhs_tape

	def to_string(self) -> str:
		"Return the VHS tape as a string"
		return self.__str__()

	def get_file_path(self) -> str:
		"Return the file name for the VHS tape"
		return f"./vhs_tapes/{self.file_name}.tape"

	def write_to_file(self) -> None:
		"Write the VHS tape to a tape file"

		# Open the file for writing
		with open(self.get_file_path(), "w") as file:
			#

			# Write the VHS tape to the file
			_ = file.write(self.to_string())

	@staticmethod
	def edit_plugin_config(
		config_option: str,
		value: int | float | str | bool,
		original_value: int | float | str | None = None,
	) -> Script:
		"""
		Return a script object that contains the
		setup commands, the clean up commands, and the required programs
		to edit the plugin configuration.
		"""

		# Initialise the stringified value
		stringified_value: str = str(value)

		# Initialise the stringified original value
		stringified_original_value: str = str(original_value)

		# If the value given is a boolean
		if isinstance(value, bool):
			#

			# Lower case the stringified value
			stringified_value = stringified_value.lower()

			# Set the stringified original value to the inverse of the value
			stringified_original_value = str(not value).lower()

		# Otherwise, if the original value is not given, throw an error
		elif original_value is None:
			raise ValueError("Original value not given for non-boolean value")

		# The template for the set command
		sed_command_template = (
			r"sed -i 's/\({} = \)\w\+,/\1{},/' " + PLUGIN_FILE_NAME
		)

		# The command to edit the configuration
		edit_config_command = rf"Type `{sed_command_template}` Enter".format(
			config_option, stringified_value
		)

		# The setup commands
		setup_commands = [edit_config_command, APPLY_CONFIG_COMMAND]

		# The clean up command to undo the edit to the init.lua file
		clean_up_edit_config_command = (
			rf"Type `{sed_command_template}` Enter".format(
				config_option, stringified_original_value
			)
		)

		# The clean up commands
		clean_up_commands = [clean_up_edit_config_command, APPLY_CONFIG_COMMAND]

		# Return the script object
		return Script(
			setup=setup_commands,
			clean_up=clean_up_commands,
			required_programs=["sed"],
		)

	@staticmethod
	def toggle_between_two_items(number_of_times: int) -> str:
		"Return a command to quickly toggle the selection between two items"
		return "\n".join(
			[
				"Ctrl+n",
				VERY_SHORT_SLEEP_TIME,
				"Ctrl+p",
				VERY_SHORT_SLEEP_TIME,
			]
			* number_of_times
		)

	@staticmethod
	def create_nested_archive(
		number_of_nested_archives: int,
		archive_file_name: str = "demo.zip",
		nested_archive_file_name: str = "nested",
		text_file_name: str = "demo.txt",
		text_file_content: str = DEFAULT_TEXT_FILE_CONTENT,
	) -> Script:
		"""
		Returns a script object that contains the
		setup commands, the clean up commands, and the required programs
		to create the nested archive for the demo.
		"""

		# The list of the nested archive names
		nested_archive_names_list = [
			f"{nested_archive_file_name}-{number + 1}.zip"
			for number in range(number_of_nested_archives)
		]

		# Create the commands to create the nested archives
		nested_archive_commands = "\n".join(
			[
				f'Type "7z a {archive_name} {text_file_name}" Enter'
				for archive_name in nested_archive_names_list
			]
		)

		# Join the list of nested archive names with a space
		nested_archive_names = " ".join(nested_archive_names_list)

		# The command to create the archive
		create_archive_command = 'Type "7z a {} {}" Enter'.format(
			archive_file_name,
			nested_archive_names,
		)

		# The command to remove all of the extra archives and the file
		clean_up_commands = 'Type "rm {} {}" Enter'.format(
			text_file_name,
			nested_archive_names,
		)

		# The command to create the nested archive
		create_nested_archive_command = [
			"Type `echo '{}' > {}` Enter".format(
				text_file_content, text_file_name
			),
			nested_archive_commands,
			create_archive_command,
			clean_up_commands,
		]

		# Return the script object
		return Script(
			setup=create_nested_archive_command,
			required_programs=["echo", "7z", "rm"],
		)

	@staticmethod
	def create_multiple_nested_archives(
		number_of_archives: int, number_of_nested_archives: int
	) -> Script:
		"""
		Returns a script object that contains the
		setup commands, the clean up commands, and the required programs
		to create multiple nested archives for the demo.
		"""

		# Initialise the scripts for the setup
		setup_scripts: list[str] = []

		# Initialise the required programs
		required_programs: list[str] = []

		# Iterate over the number of archives to create
		for number in range(number_of_archives):
			#

			# Create the nested archive
			nested_archive = VHSTape.create_nested_archive(
				number_of_nested_archives, "{" + str(number) + "}"
			)

			# If it is the first iteration,
			# set the required programs
			if number == 0:
				required_programs = nested_archive.required_programs

			# Add the setup script
			setup_scripts.append(nested_archive.setup)

		# Return the script object
		return Script(
			setup=setup_scripts,
			required_programs=required_programs,
		)

	@staticmethod
	def create_encrypted_archive(
		archive_file_name: str = "demo.7z",
		archive_password: str = "password",
		encrypt_headers: bool = False,
		text_file_name: str = "demo.txt",
		text_file_content: str = DEFAULT_TEXT_FILE_CONTENT,
	) -> Script:
		"""
		Returns a script object that contains the
		setup commands, the clean up commands, and the required programs
		to create an encrypted archive.
		"""

		# The commands to create the encrypted archive
		create_encrypted_archive_commands = [
			"Type `echo '{}' > {}` Enter".format(
				text_file_content, text_file_name
			),
			"Type '7z a {} -p{} {} {}' Enter".format(
				"-mhe=on" if encrypt_headers else "",
				archive_password,
				archive_file_name,
				text_file_name,
			),
			f"Type `rm {text_file_name}` Enter",
		]

		# Return the script object
		return Script(
			setup=create_encrypted_archive_commands,
			required_programs=["echo", "7z", "rm"],
		)

	@staticmethod
	def create_keymap_toml(contents: str) -> Script:
		"""
		Returns a script object that contains the
		setup commands, the clean up commands, and the required programs
		to create the keymap.toml file for the demo.
		"""

		# Make the contents work with the VHS file format
		fixed_contents = (
			contents.strip()
			.replace('"', '\\"')
			.replace("\n", "` Enter\nType `")
			.strip()
		)

		# The command to create the keymap.toml file
		create_keymap_toml_command = "\n".join(
			[
				f"Type `mv '{KEYMAP_TOML_FILE_NAME}' "
				+ f"'{KEYMAP_TOML_FILE_NAME}.bak'` Enter",
				f'Type `echo "{fixed_contents}" > {KEYMAP_TOML_FILE_NAME}` '
				+ "Enter",
				APPLY_CONFIG_COMMAND,
			]
		)

		# The command to clean up the keymap.toml file
		clean_up_keymap_toml_command = "\n".join(
			[
				f"Type 'rm {KEYMAP_TOML_FILE_NAME}' Enter",
				f"Type `mv '{KEYMAP_TOML_FILE_NAME}.bak' "
				+ f"'{KEYMAP_TOML_FILE_NAME}'` Enter",
				APPLY_CONFIG_COMMAND,
			]
		)

		# Return the script object
		return Script(
			setup=create_keymap_toml_command,
			clean_up=clean_up_keymap_toml_command,
			required_programs=["mv", "echo", "rm"],
		)

	@staticmethod
	def create_keymap_toml_keybind(key: str | int, command: str) -> str:
		"Create a key bind in the keymap.toml file"

		# The single keybind
		keybind = "\n".join(
			[
				"[[manager.prepend_keymap]]",
				f'on = [ "{key}" ]',
				f"run = '{PLUGIN_COMMAND_TEMPLATE}'".format(command),
			]
		)

		# Return the key bind
		return keybind

	@staticmethod
	def create_keymap_toml_with_keymap(
		keymap: dict[str | int, str],
	) -> Script:
		"""
		Create a keymap.toml file with the given keymaps.

		The keymap argument is a dictionary with the key
		being the dictionary, and the value being the plugin command.

		For example:
		```python
		{
		    "e": "extract",
		    1: "tab_switch 1",
		    ...
		}
		```
		"""

		# The keybinds in the keymap.toml file
		keybinds: list[str] = []

		# Iterate over the keymap
		for key, command in keymap.items():
			#

			# Create the keybind for the key
			keybind = VHSTape.create_keymap_toml_keybind(key, command)

			# Add the keybind to the list
			keybinds.append(keybind)

		# Combine all the keybinds into a single string
		keybinds_str = "\n".join(keybinds)

		# Create and return the keymap.toml file
		return VHSTape.create_keymap_toml(keybinds_str)

	@staticmethod
	def create_shell_keymap_toml(
		key: str, shell_command: str, flags: list[str]
	) -> Script:
		"Create the keymap.toml file for the shell command demo"

		# Get the flags standardised for the shell command
		standardised_flags = [
			f"--{flag.replace(' ', '-').replace('_', '-').strip()}"
			for flag in flags
		]

		# The shell command as an argument
		shell_command = 'shell "{}" {}'.format(
			shell_command,
			" ".join(standardised_flags),
		)

		# The contents of the keymap.toml file
		contents = VHSTape.create_keymap_toml_keybind(key, shell_command)

		# Return the script to create and clean up the keymap.toml file
		return VHSTape.create_keymap_toml(contents)

	@staticmethod
	def create_tab_switch_keymap_toml() -> Script:
		"Create the keymap.toml file for the tab switch demo"

		# Create the dictionary for the keybinds
		# by iterating from 1 to 9
		keymap: dict[int | str, str] = {
			number: f"tab_switch {number}" for number in range(1, 10)
		}

		# Return the script to create and clean up the keymap.toml file
		return VHSTape.create_keymap_toml_with_keymap(keymap)

	@staticmethod
	def copy_text_to_clipboard(text: str = "Hello, world!") -> Script:
		"Copy the given text to the clipboard."

		# The command to copy the given text to the clipboard
		command = f"Copy '{text}'"

		# Return the scrip to copy the given text to the clipboard
		return Script(setup=[command])

	@staticmethod
	def press_key_repeatedly(
		key: str,
		number_of_times: int,
		delay_in_ms: int = 250,
	) -> str:
		"Return the command to cycle through the tabs"
		return 'Type@{}ms "{}"'.format(delay_in_ms, key * number_of_times)


# The dictionary containing the tapes for all demos
VHS_TAPES: list[VHSTape] = [
	VHSTape(
		name="Open prompt",
		scripts=[
			VHSTape.edit_plugin_config("prompt", True),
		],
		yazi_body=[
			f'Type "/{FIRST_FILE_NAME}" Enter',
			"Space@300ms 3",
			'Type "l"',
			SLEEP_TIME,
			'Type "h"',
			SLEEP_TIME,
			"Enter",
			'Space Type "pb"',
			LONG_SLEEP_TIME,
			"Ctrl+c",
			SHORT_SLEEP_TIME,
			'Type ":q!" Enter',
			SLEEP_TIME,
			'Type "l"',
			SLEEP_TIME,
			'Type "s"',
			SLEEP_TIME,
			"Enter",
			'Space Type "pb"',
			VHSTape.toggle_between_two_items(3),
			SHORT_SLEEP_TIME,
			"Ctrl+c",
			SHORT_SLEEP_TIME,
			'Type ":q!" Enter',
			SLEEP_TIME,
			'Type "l"',
			SLEEP_TIME,
			"Enter",
			'Space Type "pb"',
			LONG_SLEEP_TIME,
			"Ctrl+c",
			SHORT_SLEEP_TIME,
			'Type ":q!" Enter',
		],
	),
	VHSTape(
		name="Open behaviour",
		yazi_body=[
			f'Type "/{FIRST_FILE_NAME}" Enter',
			"Space@300ms 3",
			'Type "l"',
			SLEEP_TIME,
			'Space Type "pb"',
			LONG_SLEEP_TIME,
			"Ctrl+c",
			SHORT_SLEEP_TIME,
			'Type ":q!" Enter',
			SLEEP_TIME,
			'Type "k"',
			SHORT_SLEEP_TIME,
			'Type "l"',
			'Space Type "pb"',
			VHSTape.toggle_between_two_items(3),
			SHORT_SLEEP_TIME,
			"Ctrl+c",
			SHORT_SLEEP_TIME,
			'Type ":q!" Enter',
		],
	),
	VHSTape(
		name="Open auto extract archives",
		files_and_directories=["demo.zip"],
		scripts=[
			VHSTape.edit_plugin_config("recursively_extract_archives", False),
			VHSTape.create_nested_archive(4, "{0}"),
		],
		yazi_body=[
			'Type "/{0}" Enter',
			SLEEP_TIME,
			'Type "l"',
			SLEEP_TIME,
			'Type "h"',
		],
	),
	VHSTape(
		name="Open recursively extract archives",
		files_and_directories=["demo.zip"],
		scripts=[
			VHSTape.create_nested_archive(4, "{0}"),
		],
		shell_body=[
			"Type `7z l {0}` Enter",
			LONG_SLEEP_TIME,
		],
		yazi_body=[
			'Type "/{0}" Enter',
			SLEEP_TIME,
			'Type "l"',
			SLEEP_TIME,
			'Type "h"',
		],
	),
	VHSTape(
		name="Extract must have hovered item",
		files_and_directories=[
			"demo-1.zip",
			"demo-2.zip",
			"demo-3.zip",
			"demo-4.zip",
			"demo-1",
		],
		scripts=[
			VHSTape.edit_plugin_config("recursively_extract_archives", False),
			VHSTape.create_keymap_toml_with_keymap({DEFAULT_KEY: "extract"}),
			VHSTape.create_multiple_nested_archives(4, 4),
		],
		yazi_body=[
			'Type "/{0}" Enter',
			SLEEP_TIME,
			'Type "j"',
			"Space@300ms 3",
			SLEEP_TIME,
			f'Type "/{EMPTY_FOLDER}" Enter',
			SLEEP_TIME,
			'Type "l"',
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			LONG_SLEEP_TIME,
			'Type "h"',
			SLEEP_TIME,
			'Type "/{0}" Enter',
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			'Type "gg"',
			SLEEP_TIME,
			'Type "/{4}" Enter',
		],
	),
	VHSTape(
		name="Extract hovered item optional",
		files_and_directories=[
			"demo-1.zip",
			"demo-2.zip",
			"demo-3.zip",
			"demo-4.zip",
			"demo-2",
			"demo-3",
			"demo-4",
			"demo-1",
		],
		scripts=[
			VHSTape.edit_plugin_config("recursively_extract_archives", False),
			VHSTape.edit_plugin_config("must_have_hovered_item", False),
			VHSTape.create_keymap_toml_with_keymap({DEFAULT_KEY: "extract"}),
			VHSTape.create_multiple_nested_archives(4, 4),
		],
		yazi_body=[
			'Type "/{0}" Enter',
			SLEEP_TIME,
			'Type "j"',
			"Space@300ms 3",
			SLEEP_TIME,
			f'Type "/{EMPTY_FOLDER}" Enter',
			SLEEP_TIME,
			'Type "l"',
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			'Type "h"',
			SLEEP_TIME,
			'Type "gg"',
			SLEEP_TIME,
			'Type "/{4}" Enter',
			SLEEP_TIME,
			'Type "j"',
			SLEEP_TIME,
			'Type "j"',
			SLEEP_TIME,
			'Type "/{0}" Enter',
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			'Type "gg"',
			SLEEP_TIME,
			'Type "/{7}" Enter',
		],
	),
	VHSTape(
		name="Extract prompt",
		files_and_directories=[
			"demo-1.zip",
			"demo-2.zip",
			"demo-3.zip",
			"demo-4.zip",
			"demo-1",
			"demo-4",
			"demo-4_1",
		],
		scripts=[
			VHSTape.edit_plugin_config("recursively_extract_archives", False),
			VHSTape.edit_plugin_config("prompt", True),
			VHSTape.create_keymap_toml_with_keymap({DEFAULT_KEY: "extract"}),
			VHSTape.create_multiple_nested_archives(4, 4),
		],
		yazi_body=[
			'Type "/{0}" Enter',
			SLEEP_TIME,
			"Space@300ms 3",
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			'Type "h"',
			SLEEP_TIME,
			"Enter",
			SLEEP_TIME,
			'Type "gg"',
			SLEEP_TIME,
			'Type "/{5}" Enter',
			SLEEP_TIME,
			'Type "/{3}" Enter',
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			'Type "s"',
			SLEEP_TIME,
			"Enter",
			SLEEP_TIME,
			'Type "gg"',
			SLEEP_TIME,
			'Type "/{4}" Enter',
			SLEEP_TIME,
			'Type "j"',
			SLEEP_TIME,
			'Type "j"',
			SLEEP_TIME,
			'Type "/{3}" Enter',
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			"Enter",
			SLEEP_TIME,
			'Type "gg"',
			SLEEP_TIME,
			'Type "/{6}" Enter',
		],
	),
	VHSTape(
		name="Extract behaviour",
		files_and_directories=[
			"demo-1.zip",
			"demo-2.zip",
			"demo-3.zip",
			"demo-4.zip",
			"demo-5.zip",
			"demo-4",
			"demo-1",
		],
		scripts=[
			VHSTape.edit_plugin_config("recursively_extract_archives", False),
			VHSTape.create_keymap_toml_with_keymap({DEFAULT_KEY: "extract"}),
			VHSTape.create_multiple_nested_archives(5, 4),
		],
		yazi_body=[
			'Type "/{0}" Enter',
			SLEEP_TIME,
			"Space@300ms 3",
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			'Type "gg"',
			SLEEP_TIME,
			'Type "/{5}" Enter',
			SLEEP_TIME,
			'Type "/{0}" Enter',
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			'Type "gg"',
			SLEEP_TIME,
			'Type "/{6}" Enter',
			SLEEP_TIME,
			'Type "j"',
			SLEEP_TIME,
			'Type "j"',
		],
	),
	VHSTape(
		name="Extract recursively extract archives",
		files_and_directories=["demo.zip", "demo"],
		scripts=[
			VHSTape.create_keymap_toml_with_keymap({DEFAULT_KEY: "extract"}),
			VHSTape.create_nested_archive(4, "{0}"),
		],
		shell_body=[
			"Type `7z l {0}` Enter",
			LONG_SLEEP_TIME,
		],
		yazi_body=[
			'Type "/{0}" Enter',
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			'Type "gg"',
			SLEEP_TIME,
			'Type "/{1}" Enter',
			SLEEP_TIME,
			'Type "l"',
		],
	),
	VHSTape(
		name="Extract encrypted archive",
		files_and_directories=["demo.7z", "demo.txt"],
		scripts=[
			VHSTape.create_keymap_toml_with_keymap({DEFAULT_KEY: "extract"}),
			VHSTape.create_encrypted_archive(
				archive_file_name="{0}",
				archive_password="{0}",
			),
		],
		yazi_body=[
			'Type "/{0}" Enter',
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			'Type "password" Enter',
			SLEEP_TIME,
			'Type "wrong password" Enter',
			SLEEP_TIME,
			'Type "still wrong password" Enter',
			SLEEP_TIME,
			'Type "LET ME IN!1!1!1!" Enter',
			SLEEP_TIME,
			'Type "w"',
			SLEEP_TIME,
			"Enter",
			SLEEP_TIME,
			'Type "q"',
			SLEEP_TIME,
			'Type "x"',
			SLEEP_TIME,
			"Ctrl+c",
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			'Type "{0}" Enter',
			SLEEP_TIME,
			'Type "/{1}" Enter',
		],
	),
	VHSTape(
		name="Extract reveal extracted item",
		files_and_directories=[
			"demo.zip",
			"demo",
			"demo_1",
			"demo_2",
		],
		scripts=[
			VHSTape.create_keymap_toml_with_keymap(
				{DEFAULT_KEY: "extract --reveal"}
			),
			VHSTape.create_nested_archive(4, "{0}"),
		],
		yazi_body=[
			'Type "/{0}" Enter',
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			'Type "h"',
			SLEEP_TIME,
			'Type "n"',
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			'Type "h"',
			SLEEP_TIME,
			'Type "n"',
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
		],
	),
	VHSTape(
		name="Extract remove extracted archive",
		files_and_directories=["demo.zip"],
		scripts=[
			VHSTape.create_keymap_toml_with_keymap(
				{DEFAULT_KEY: "extract --remove"}
			),
			VHSTape.create_nested_archive(4, "{0}"),
		],
		yazi_body=[
			'Type "/{0}" Enter',
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			'Type "/{0}" Enter',
		],
	),
	VHSTape(
		name="Smart enter",
		yazi_body=[
			'Type "l"',
			SLEEP_TIME,
			'Type "h"',
			SLEEP_TIME,
			'Type "jl"',
			SLEEP_TIME,
			'Type "h"',
			SLEEP_TIME,
			'Type "jl"',
			SLEEP_TIME,
			'Type "h"',
			SLEEP_TIME,
			'Type "G"',
			SLEEP_TIME,
			'Type "l"',
			SLEEP_TIME,
			'Type ":q!" Enter',
			SLEEP_TIME,
			'Type "kl"',
			SLEEP_TIME,
			'Type ":q!" Enter',
			SLEEP_TIME,
			'Type "kl"',
			SLEEP_TIME,
			'Type ":q!" Enter',
		],
	),
	VHSTape(
		name="Enter skip single subdirectory",
		yazi_body=[
			f'Type "/{FOLDER_WITH_SUBDIRECTORY}" Enter',
			SLEEP_TIME,
			'Type "l"',
			SLEEP_TIME,
			"Left",
			SLEEP_TIME,
			"Left",
		],
	),
	VHSTape(
		name="Leave skip single subdirectory",
		scripts=[
			Script(
				setup=f"Type `cd './{FOLDER_WITH_SUBDIRECTORY}/subdirectory/'`"
				+ "Enter",
			),
		],
		yazi_body=[
			'Type "h"',
			SLEEP_TIME,
			f'Type "/{FOLDER_WITH_SUBDIRECTORY}" Enter',
			"Right",
			SLEEP_TIME,
			"Right",
		],
	),
	VHSTape(
		name="Rename must have hovered item",
		yazi_body=[
			f'Type "/{FIRST_FILE_NAME}" Enter',
			SLEEP_TIME,
			'Type "j"',
			"Space@300ms 3",
			SLEEP_TIME,
			f'Type "/{EMPTY_FOLDER}" Enter',
			SLEEP_TIME,
			'Type "l"',
			SLEEP_TIME,
			'Type "r"',
			LONG_SLEEP_TIME,
			'Type "h"',
			SLEEP_TIME,
			'Type "r"',
			"Backspace@300ms 3",
			SLEEP_TIME,
			"Ctrl+c",
		],
	),
	VHSTape(
		name="Rename hovered item optional",
		scripts=[
			VHSTape.edit_plugin_config("must_have_hovered_item", False),
		],
		yazi_body=[
			f'Type "/{FIRST_FILE_NAME}" Enter',
			SLEEP_TIME,
			'Type "j"',
			"Space@300ms 3",
			SLEEP_TIME,
			f'Type "/{EMPTY_FOLDER}" Enter',
			SLEEP_TIME,
			'Type "l"',
			SLEEP_TIME,
			'Type "r"',
			SLEEP_TIME,
			'Type ":q!" Enter',
			SLEEP_TIME,
			'Type "h"',
			SLEEP_TIME,
			'Type "r"',
			"Backspace@300ms 3",
			SLEEP_TIME,
			"Ctrl+c",
		],
	),
	VHSTape(
		name="Rename prompt",
		scripts=[
			VHSTape.edit_plugin_config("prompt", True),
		],
		yazi_body=[
			f'Type "/{FIRST_FILE_NAME}" Enter',
			"Space@300ms 3",
			'Type "r"',
			SLEEP_TIME,
			'Type "h"',
			SLEEP_TIME,
			"Enter",
			SLEEP_TIME,
			"Escape",
			'Type "b"',
			SLEEP_TIME,
			"Ctrl+c",
			SLEEP_TIME,
			'Type "r"',
			SLEEP_TIME,
			'Type "s"',
			SLEEP_TIME,
			"Enter",
			SLEEP_TIME,
			'Type ":q!" Enter',
			SLEEP_TIME,
			'Type "r"',
			SLEEP_TIME,
			"Enter",
			SLEEP_TIME,
			"Escape",
			'Type "b"',
			SLEEP_TIME,
			"Ctrl+c",
		],
	),
	VHSTape(
		name="Rename behaviour",
		yazi_body=[
			f'Type "/{FIRST_FILE_NAME}" Enter',
			"Space@300ms 3",
			SLEEP_TIME,
			'Type "r"',
			SLEEP_TIME,
			"Escape",
			'Type "b"',
			SLEEP_TIME,
			"Ctrl+c",
			SLEEP_TIME,
			'Type "j"',
			SLEEP_TIME,
			'Type "r"',
			SLEEP_TIME,
			"Escape",
			'Type "b"',
			SLEEP_TIME,
			"Ctrl+c",
			SLEEP_TIME,
			'Type "kk"',
			SLEEP_TIME,
			'Type "r"',
			SLEEP_TIME,
			'Type ":q!" Enter',
		],
	),
	VHSTape(
		name="Remove must have hovered item",
		yazi_body=[
			f'Type "/{FIRST_FILE_NAME}" Enter',
			SLEEP_TIME,
			'Type "j"',
			"Space@300ms 3",
			SLEEP_TIME,
			f'Type "/{EMPTY_FOLDER}" Enter',
			SLEEP_TIME,
			'Type "l"',
			'Type "x"',
			LONG_SLEEP_TIME,
			'Type "h"',
			SLEEP_TIME,
			'Type "x"',
			SLEEP_TIME,
			"Ctrl+c",
		],
	),
	VHSTape(
		name="Remove hovered item optional",
		scripts=[
			VHSTape.edit_plugin_config("must_have_hovered_item", False),
		],
		yazi_body=[
			f'Type "/{FIRST_FILE_NAME}" Enter',
			SLEEP_TIME,
			'Type "j"',
			"Space@300ms 3",
			SLEEP_TIME,
			f'Type "/{EMPTY_FOLDER}" Enter',
			SLEEP_TIME,
			'Type "l"',
			SLEEP_TIME,
			'Type "x"',
			SLEEP_TIME,
			"Ctrl+c",
			SLEEP_TIME,
			'Type "h"',
			SLEEP_TIME,
			'Type "x"',
			SLEEP_TIME,
			"Ctrl+c",
		],
	),
	VHSTape(
		name="Remove prompt",
		scripts=[
			VHSTape.edit_plugin_config("prompt", True),
		],
		yazi_body=[
			f'Type "/{FIRST_FILE_NAME}" Enter',
			"Space@300ms 3",
			'Type "x"',
			SLEEP_TIME,
			'Type "h"',
			SLEEP_TIME,
			"Enter",
			SLEEP_TIME,
			"Ctrl+c",
			SLEEP_TIME,
			'Type "x"',
			SLEEP_TIME,
			'Type "s"',
			SLEEP_TIME,
			"Enter",
			SLEEP_TIME,
			"Ctrl+c",
			SLEEP_TIME,
			'Type "x"',
			SLEEP_TIME,
			"Enter",
			SLEEP_TIME,
			"Ctrl+c",
		],
	),
	VHSTape(
		name="Remove behaviour",
		yazi_body=[
			f'Type "/{FIRST_FILE_NAME}" Enter',
			"Space@300ms 3",
			SLEEP_TIME,
			'Type "x"',
			SLEEP_TIME,
			"Ctrl+c",
			SLEEP_TIME,
			'Type "j"',
			SLEEP_TIME,
			'Type "x"',
			SLEEP_TIME,
			"Ctrl+c",
			SLEEP_TIME,
			'Type "kk"',
			SLEEP_TIME,
			'Type "x"',
			SLEEP_TIME,
			"Ctrl+c",
		],
	),
	VHSTape(
		name="Copy must have hovered item",
		scripts=[
			VHSTape.copy_text_to_clipboard(),
		],
		yazi_body=[
			f'Type "/{FIRST_FILE_NAME}" Enter',
			SLEEP_TIME,
			'Type "j"',
			"Space@300ms 3",
			SLEEP_TIME,
			f'Type "/{EMPTY_FOLDER}" Enter',
			SLEEP_TIME,
			'Type "l"',
			SLEEP_TIME,
			'Type "cf"',
			SLEEP_TIME,
			'Type ":" Escape',
			'Type "p"',
			SLEEP_TIME,
			"Ctrl+c",
			SLEEP_TIME,
			'Type "h"',
			SLEEP_TIME,
			'Type "cf"',
			SLEEP_TIME,
			'Type ":" Escape',
			'Type "p"',
			SLEEP_TIME,
			"Ctrl+c",
		],
	),
	VHSTape(
		name="Copy hovered item optional",
		scripts=[
			VHSTape.copy_text_to_clipboard(),
			VHSTape.edit_plugin_config("must_have_hovered_item", False),
		],
		yazi_body=[
			f'Type "/{FIRST_FILE_NAME}" Enter',
			SLEEP_TIME,
			'Type "j"',
			"Space@300ms 3",
			SLEEP_TIME,
			f'Type "/{EMPTY_FOLDER}" Enter',
			SLEEP_TIME,
			'Type "l"',
			SLEEP_TIME,
			'Type "cf"',
			SLEEP_TIME,
			'Type ":" Escape',
			'Type "p"',
			SLEEP_TIME,
			"Ctrl+c",
			SLEEP_TIME,
			'Type "h"',
			SLEEP_TIME,
			'Type "cf"',
			SLEEP_TIME,
			'Type ":" Escape',
			'Type "p"',
			SLEEP_TIME,
			"Ctrl+c",
		],
	),
	VHSTape(
		name="Copy prompt",
		scripts=[
			VHSTape.copy_text_to_clipboard(),
			VHSTape.edit_plugin_config("prompt", True),
		],
		yazi_body=[
			f'Type "/{FIRST_FILE_NAME}" Enter',
			"Space@300ms 3",
			'Type "cf"',
			SLEEP_TIME,
			'Type "h"',
			SLEEP_TIME,
			"Enter",
			SLEEP_TIME,
			'Type ":" Escape',
			'Type "p"',
			SLEEP_TIME,
			"Ctrl+c",
			SLEEP_TIME,
			'Type "cf"',
			SLEEP_TIME,
			'Type "s"',
			SLEEP_TIME,
			"Enter",
			SLEEP_TIME,
			'Type ":" Escape',
			'Type "p"',
			SLEEP_TIME,
			"Ctrl+c",
			SLEEP_TIME,
			'Type "cf"',
			SLEEP_TIME,
			"Enter",
			SLEEP_TIME,
			'Type ":" Escape',
			'Type "p"',
			SLEEP_TIME,
			"Ctrl+c",
		],
	),
	VHSTape(
		name="Copy behaviour",
		scripts=[
			VHSTape.copy_text_to_clipboard(),
		],
		yazi_body=[
			f'Type "/{FIRST_FILE_NAME}" Enter',
			"Space@300ms 3",
			SLEEP_TIME,
			'Type "cf"',
			SLEEP_TIME,
			'Type ":" Escape',
			'Type "p"',
			SLEEP_TIME,
			"Ctrl+c",
			SLEEP_TIME,
			'Type "j"',
			SLEEP_TIME,
			'Type "cf"',
			SLEEP_TIME,
			'Type ":" Escape',
			'Type "p"',
			SLEEP_TIME,
			"Ctrl+c",
			SLEEP_TIME,
			'Type "kk"',
			SLEEP_TIME,
			'Type "cf"',
			SLEEP_TIME,
			'Type ":" Escape',
			'Type "p"',
			SLEEP_TIME,
			"Ctrl+c",
		],
	),
	VHSTape(
		name="Create behaviour",
		files_and_directories=[
			"demo_file.txt",
			"test_file.txt",
			"demo_dir",
			"test_dir",
			"demo_dir.txt",
			"dir_to_overwrite",
			"file_to_overwrite.txt",
		],
		scripts=[
			Script(
				setup="Type `mkdir '{5}'` Enter", required_programs=["mkdir"]
			),
			Script(
				setup="Type `touch '{6}'` Enter", required_programs=["touch"]
			),
		],
		yazi_body=[
			'Type "_{0}" Enter',
			SLEEP_TIME,
			'Type "/{0}" Enter',
			SLEEP_TIME,
			'Type "_{1}" Enter',
			SLEEP_TIME,
			'Type "/{1}" Enter',
			SLEEP_TIME,
			'Type "_{2}" Enter',
			SLEEP_TIME,
			'Type "/{2}" Enter',
			SLEEP_TIME,
			'Type "_{3}/" Enter',
			SLEEP_TIME,
			'Type "/{3}" Enter',
			SLEEP_TIME,
			'Type "_{4}/"',
			SLEEP_TIME,
			"Enter",
			SLEEP_TIME,
			'Type "/{4}" Enter',
			SLEEP_TIME,
			'Type "_{5}" Enter',
			SLEEP_TIME,
			"Ctrl+c",
			SLEEP_TIME,
			'Type "/{5}" Enter',
			SLEEP_TIME,
			'Type "_{6}" Enter',
			SLEEP_TIME,
			"Ctrl+c",
			SLEEP_TIME,
			'Type "/{6}" Enter',
		],
	),
	VHSTape(
		name="Create and open files",
		files_and_directories=[
			"demo_file.txt",
			"test_file.txt",
			"demo_dir",
			"test_dir",
		],
		scripts=[
			VHSTape.edit_plugin_config("open_file_after_creation", True),
		],
		yazi_body=[
			'Type "_{0}" Enter',
			SLEEP_TIME,
			'Type ":q!" Enter',
			SLEEP_TIME,
			'Type "_{1}" Enter',
			SLEEP_TIME,
			'Type ":q!" Enter',
			SLEEP_TIME,
			'Type "_{2}" Enter',
			SLEEP_TIME,
			'Type "/{2}" Enter',
			SLEEP_TIME,
			'Type "_{3}/" Enter',
			SLEEP_TIME,
			'Type "/{3}" Enter',
		],
	),
	VHSTape(
		name="Create and enter directories",
		files_and_directories=[
			"demo_dir",
			"test_dir",
			"demo_file.txt",
			"test_file.txt",
		],
		scripts=[
			VHSTape.edit_plugin_config("enter_directory_after_creation", True),
		],
		yazi_body=[
			'Type "_{0}" Enter',
			SLEEP_TIME,
			'Type "h"',
			SLEEP_TIME,
			'Type "_{1}/"',
			SLEEP_TIME,
			"Enter",
			SLEEP_TIME,
			'Type "h"',
			SLEEP_TIME,
			'Type "_{2}" Enter',
			SLEEP_TIME,
			'Type "/{2}" Enter',
			SLEEP_TIME,
			'Type "_{3}" Enter',
			SLEEP_TIME,
			'Type "/{3}" Enter',
		],
	),
	VHSTape(
		name="Create and open files and directories",
		files_and_directories=[
			"demo_file.txt",
			"test_file.txt",
			"demo_dir",
			"test_dir",
		],
		scripts=[
			VHSTape.edit_plugin_config("open_file_after_creation", True),
			VHSTape.edit_plugin_config("enter_directory_after_creation", True),
		],
		yazi_body=[
			'Type "_{0}" Enter',
			SLEEP_TIME,
			'Type ":q!" Enter',
			SLEEP_TIME,
			'Type "_{1}" Enter',
			SLEEP_TIME,
			'Type ":q!" Enter',
			SLEEP_TIME,
			'Type "_{2}" Enter',
			SLEEP_TIME,
			'Type "h"',
			SLEEP_TIME,
			'Type "_{3}/" Enter',
			SLEEP_TIME,
			'Type "h"',
		],
	),
	VHSTape(
		name="Create default behaviour",
		files_and_directories=[
			"demo_file.txt",
			"test_file.txt",
			"demo_dir",
			"test_dir",
		],
		scripts=[
			VHSTape.edit_plugin_config("use_default_create_behaviour", True)
		],
		yazi_body=[
			'Type "_{0}" Enter',
			SLEEP_TIME,
			'Type "/{0}" Enter',
			SLEEP_TIME,
			'Type "_{1}" Enter',
			SLEEP_TIME,
			'Type "/{1}" Enter',
			SLEEP_TIME,
			'Type "_{2}" Enter',
			SLEEP_TIME,
			'Type "/{2}" Enter',
			SLEEP_TIME,
			'Type "_{3}/" Enter',
			SLEEP_TIME,
			'Type "/{3}" Enter',
		],
	),
	VHSTape(
		name="Shell must have hovered item",
		scripts=[
			VHSTape.create_shell_keymap_toml(
				DEFAULT_KEY, r"\$SHELL", ["block"]
			),
		],
		yazi_body=[
			f'Type "/{FIRST_FILE_NAME}" Enter',
			SLEEP_TIME,
			'Type "j"',
			"Space@300ms 3",
			SLEEP_TIME,
			f'Type "/{EMPTY_FOLDER}" Enter',
			SLEEP_TIME,
			'Type "l"',
			f'Type "{DEFAULT_KEY}"',
			LONG_SLEEP_TIME,
			'Type "h"',
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			'Type "exit" Enter',
		],
	),
	VHSTape(
		name="Shell hovered item optional",
		scripts=[
			VHSTape.edit_plugin_config("must_have_hovered_item", False),
			VHSTape.create_shell_keymap_toml(
				DEFAULT_KEY, r"\$SHELL", ["block"]
			),
		],
		yazi_body=[
			f'Type "/{FIRST_FILE_NAME}" Enter',
			SLEEP_TIME,
			'Type "j"',
			"Space@300ms 3",
			SLEEP_TIME,
			f'Type "/{EMPTY_FOLDER}" Enter',
			SLEEP_TIME,
			'Type "l"',
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			'Type "exit" Enter',
			SLEEP_TIME,
			'Type "h"',
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			'Type "exit" Enter',
		],
	),
	VHSTape(
		name="Shell prompt",
		skip_quitting_yazi=True,
		scripts=[
			VHSTape.edit_plugin_config("prompt", True),
			VHSTape.create_shell_keymap_toml(
				DEFAULT_KEY, r"echo \$0", ["block"]
			),
		],
		yazi_body=[
			f'Type "/{FIRST_FILE_NAME}" Enter',
			"Space@300ms 3",
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			'Type "h"',
			SLEEP_TIME,
			"Enter",
			SLEEP_TIME,
			'Type "q"',
			LONG_SLEEP_TIME,
			'Type "yazi" Enter',
			SLEEP_TIME,
			f'Type "/{FIRST_FILE_NAME}" Enter',
			"Space@300ms 3",
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			'Type "s"',
			SLEEP_TIME,
			"Enter",
			SLEEP_TIME,
			'Type "q"',
			LONG_SLEEP_TIME,
			'Type "yazi" Enter',
			SLEEP_TIME,
			f'Type "/{FIRST_FILE_NAME}" Enter',
			"Space@300ms 3",
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			"Enter",
			SLEEP_TIME,
			'Type "q"',
			LONG_SLEEP_TIME,
		],
	),
	VHSTape(
		name="Shell behaviour",
		skip_quitting_yazi=True,
		scripts=[
			VHSTape.create_shell_keymap_toml(
				DEFAULT_KEY, r"echo \$0", ["block"]
			),
		],
		yazi_body=[
			f'Type "/{FIRST_FILE_NAME}" Enter',
			"Space@300ms 3",
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			'Type "q"',
			LONG_SLEEP_TIME,
			'Type "yazi" Enter',
			SLEEP_TIME,
			f'Type "/{FIRST_FILE_NAME}" Enter',
			"Space@300ms 3",
			'Type "j"',
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			'Type "q"',
			LONG_SLEEP_TIME,
			'Type "yazi" Enter',
			SLEEP_TIME,
			f'Type "/{FIRST_FILE_NAME}" Enter',
			"Space@300ms 3",
			'Type "k"',
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			'Type "q"',
			LONG_SLEEP_TIME,
		],
	),
	VHSTape(
		name="Shell exit if directory",
		scripts=[
			VHSTape.create_shell_keymap_toml(
				DEFAULT_KEY, r"\$SHELL", ["block", "exit-if-dir"]
			),
		],
		yazi_body=[
			f'Type "/{FIRST_FILE_NAME}" Enter',
			"Space@300ms 3",
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			'Type "exit" Enter',
			SLEEP_TIME,
			'Type "j"',
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			'Type "exit" Enter',
			SLEEP_TIME,
			'Type "kk"',
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			'Type "exit" Enter',
			SLEEP_TIME,
			'Type "gg"',
			"Space@300ms 2",
			'Type "k"',
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			'Type "exit" Enter',
			SLEEP_TIME,
			"Escape 2",
			'Type "gg"',
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			'Type "j"',
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			'Type "gg"',
			"Space@300ms 2",
			'Type "k"',
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
		],
	),
	VHSTape(
		name="Smart paste",
		files_and_directories=[
			"demo.txt",
			"demo_1.txt",
			"**/demo.txt",
			"**/demo_1.txt",
		],
		scripts=[
			VHSTape.edit_plugin_config("smart_paste", True),
			Script(
				setup=f"Type `echo '{DEFAULT_TEXT_FILE_CONTENT}' "
				+ "> {0}` Enter",
				required_programs=["echo"],
			),
		],
		yazi_body=[
			'Type "/{0}" Enter',
			'Type "y"',
			SLEEP_TIME,
			'Type "gg"',
			SLEEP_TIME,
			'Type "p"',
			SLEEP_TIME,
			'Type "l"',
			SLEEP_TIME,
			'Type "/{0}" Enter',
			SLEEP_TIME,
			'Type "h"',
			SLEEP_TIME,
			'Type "j"',
			SLEEP_TIME,
			'Type "p"',
			SLEEP_TIME,
			'Type "l"',
			SLEEP_TIME,
			'Type "n"',
			SLEEP_TIME,
			'Type "h"',
			SLEEP_TIME,
			'Type "j"',
			SLEEP_TIME,
			'Type "p"',
			SLEEP_TIME,
			'Type "l"',
			SLEEP_TIME,
			'Type "n"',
			SLEEP_TIME,
			'Type "k"',
			SLEEP_TIME,
			'Type "p"',
			SLEEP_TIME,
			'Type "l"',
			SLEEP_TIME,
			'Type "hh"',
			SLEEP_TIME,
			'Type "n"',
			SLEEP_TIME,
			'Type "p"',
			SLEEP_TIME,
			'Type "/{1}" Enter',
		],
	),
	VHSTape(
		name="Smart tab create",
		scripts=[
			VHSTape.edit_plugin_config("smart_tab_create", True),
		],
		yazi_body=[
			f'Type "/{FIRST_FILE_NAME}" Enter',
			SLEEP_TIME,
			'Type "t"',
			SLEEP_TIME,
			'Type "j"',
			SLEEP_TIME,
			'Type "t"',
			SLEEP_TIME,
			'Type "gg"',
			SLEEP_TIME,
			'Type "t"',
			SLEEP_TIME,
			'Type "t"',
			SLEEP_TIME,
			'Type "h"',
			SLEEP_TIME,
			'Type "j"',
			SLEEP_TIME,
			'Type "t"',
			SLEEP_TIME,
			'Type "t"',
		],
	),
	VHSTape(
		name="Smart tab switch",
		scripts=[
			VHSTape.edit_plugin_config("smart_tab_switch", True),
			VHSTape.create_tab_switch_keymap_toml(),
		],
		yazi_body=[
			'Type "l"',
			SLEEP_TIME,
			'Type "2"',
			SLEEP_TIME,
			'Type "]"',
			SLEEP_TIME,
			'Type "h"',
			SLEEP_TIME,
			VHSTape.press_key_repeatedly("]", 4),
			SLEEP_TIME,
			'Type "8"',
			SLEEP_TIME,
			VHSTape.press_key_repeatedly("]", 17),
		],
	),
	VHSTape(
		name="Quit with confirmation",
		skip_quitting_yazi=True,
		scripts=[
			VHSTape.create_keymap_toml_with_keymap({"q": "quit"}),
		],
		yazi_body=[
			SLEEP_TIME,
			'Type "q"',
			'Type "yazi" Enter',
			SLEEP_TIME,
			'Type "t"',
			SLEEP_TIME,
			'Type "q"',
			SLEEP_TIME,
			'Type "n"',
			SLEEP_TIME,
			'Type "q"',
			SLEEP_TIME,
			'Type "y"',
			SLEEP_TIME,
		],
	),
	VHSTape(
		name="Smooth arrow",
		scripts=[
			VHSTape.edit_plugin_config("wraparound_file_navigation", False),
			VHSTape.edit_plugin_config("smooth_scrolling", True),
			VHSTape.create_keymap_toml_with_keymap(
				{
					"j": "arrow 10",
					"k": "arrow -10",
				}
			),
		],
		yazi_body=[
			"Type 'j'",
			SLEEP_TIME,
			"Type 'j'",
			SLEEP_TIME,
			"Type 'k'",
			SLEEP_TIME,
			"Type 'k'",
			SLEEP_TIME,
			"Type 'j'",
			"Type 'j'",
			SLEEP_TIME,
			"Type 'k'",
			"Type 'k'",
		],
	),
	VHSTape(
		name="Wraparound arrow",
		yazi_body=[
			VHSTape.press_key_repeatedly("j", 20),
			SLEEP_TIME,
			VHSTape.press_key_repeatedly("k", 20),
		],
	),
	VHSTape(
		name="Smooth wraparound arrow",
		scripts=[
			VHSTape.edit_plugin_config("smooth_scrolling", True),
			VHSTape.create_keymap_toml_with_keymap(
				{
					"d": "arrow 10",
					"u": "arrow -10",
				}
			),
		],
		yazi_body=[
			VHSTape.press_key_repeatedly("j", 5),
			SLEEP_TIME,
			"Type 'u'",
			SLEEP_TIME,
			"Type 'u'",
			SLEEP_TIME,
			"Type 'G'",
			SLEEP_TIME,
			VHSTape.press_key_repeatedly("k", 5),
			SLEEP_TIME,
			"Type 'd'",
			SLEEP_TIME,
			"Type 'd'",
		],
	),
	VHSTape(
		name="Parent arrow",
		scripts=[
			VHSTape.edit_plugin_config("wraparound_file_navigation", False),
		],
		yazi_body=[
			'Type "l"',
			SHORT_SLEEP_TIME,
			'Type "l"',
			SLEEP_TIME,
			VHSTape.press_key_repeatedly("J", 4),
			SLEEP_TIME,
			VHSTape.press_key_repeatedly("K", 4),
			SLEEP_TIME,
			VHSTape.press_key_repeatedly("J", 4),
			SLEEP_TIME,
			VHSTape.press_key_repeatedly("K", 4),
		],
	),
	VHSTape(
		name="Smooth parent arrow",
		scripts=[
			VHSTape.edit_plugin_config("wraparound_file_navigation", False),
			VHSTape.edit_plugin_config("smooth_scrolling", True),
			VHSTape.create_keymap_toml_with_keymap(
				{
					"J": "parent_arrow 5",
					"K": "parent_arrow -5",
				}
			),
		],
		yazi_body=[
			"Type 'l'",
			SLEEP_TIME,
			"Type 'J'",
			SLEEP_TIME,
			"Type 'K'",
			SLEEP_TIME,
			"Type 'J'",
			SLEEP_TIME,
			"Type 'K'",
			SLEEP_TIME,
			"Type 'J'",
			"Type 'K'",
			SLEEP_TIME,
			"Type 'J'",
			"Type 'K'",
		],
	),
	VHSTape(
		name="Wraparound parent arrow",
		yazi_body=[
			'Type "l"',
			SHORT_SLEEP_TIME,
			'Type "l"',
			SLEEP_TIME,
			VHSTape.press_key_repeatedly("J", 20),
			SLEEP_TIME,
			VHSTape.press_key_repeatedly("K", 20),
		],
	),
	VHSTape(
		name="Smooth wraparound parent arrow",
		scripts=[
			VHSTape.edit_plugin_config("smooth_scrolling", True),
			VHSTape.create_keymap_toml_with_keymap(
				{
					"J": "parent_arrow 1",
					"K": "parent_arrow -1",
					"d": "parent_arrow 5",
					"u": "parent_arrow -5",
				}
			),
		],
		yazi_body=[
			"Type 'l'",
			SLEEP_TIME,
			VHSTape.press_key_repeatedly("J", 5),
			SLEEP_TIME,
			"Type 'u'",
			SLEEP_TIME,
			"Type 'u'",
			SLEEP_TIME,
			"Type 'h'",
			SLEEP_TIME,
			f'Type "/{FIRST_FILE_NAME}" Enter',
			SLEEP_TIME,
			"Type 'k'",
			SLEEP_TIME,
			"Type 'l'",
			SLEEP_TIME,
			VHSTape.press_key_repeatedly("K", 5),
			SLEEP_TIME,
			"Type 'd'",
			SLEEP_TIME,
			"Type 'd'",
		],
	),
	VHSTape(
		name="Archive must have hovered item",
		files_and_directories=["demo.zip"],
		scripts=[
			VHSTape.edit_plugin_config("reveal_created_archive", False),
			VHSTape.create_keymap_toml_with_keymap({DEFAULT_KEY: "archive"}),
		],
		yazi_body=[
			f'Type "/{FIRST_FILE_NAME}" Enter',
			SLEEP_TIME,
			'Type "j"',
			"Space@300ms 3",
			SLEEP_TIME,
			f'Type "/{EMPTY_FOLDER}" Enter',
			SLEEP_TIME,
			'Type "l"',
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			LONG_SLEEP_TIME,
			'Type "h"',
			SLEEP_TIME,
			f'Type "/{FIRST_FILE_NAME}" Enter',
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			'Type "{0}" Enter',
			SLEEP_TIME,
			'Type "gg"',
			SLEEP_TIME,
			'Type "/{0}" Enter',
		],
	),
	VHSTape(
		name="Archive hovered item optional",
		files_and_directories=["demo.zip", "**/demo.zip"],
		scripts=[
			VHSTape.edit_plugin_config("must_have_hovered_item", False),
			VHSTape.edit_plugin_config("reveal_created_archive", False),
			VHSTape.create_keymap_toml_with_keymap({DEFAULT_KEY: "archive"}),
		],
		yazi_body=[
			f'Type "/{FIRST_FILE_NAME}" Enter',
			SLEEP_TIME,
			'Type "j"',
			"Space@300ms 3",
			SLEEP_TIME,
			f'Type "/{EMPTY_FOLDER}" Enter',
			SLEEP_TIME,
			'Type "l"',
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			'Type "{0}" Enter',
			SLEEP_TIME,
			'Type "/{0}" Enter',
			SLEEP_TIME,
			'Type "h"',
			SLEEP_TIME,
			f'Type "/{FIRST_FILE_NAME}" Enter',
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			'Type "{0}" Enter',
			SLEEP_TIME,
			'Type "/{0}" Enter',
		],
	),
	VHSTape(
		name="Archive prompt",
		files_and_directories=[
			"demo.zip",
			"demo-1.zip",
			"demo-2.zip",
		],
		scripts=[
			VHSTape.edit_plugin_config("prompt", True),
			VHSTape.edit_plugin_config("reveal_created_archive", False),
			VHSTape.create_keymap_toml_with_keymap({DEFAULT_KEY: "archive"}),
		],
		yazi_body=[
			f'Type "/{FIRST_FILE_NAME}" Enter',
			SLEEP_TIME,
			'Type "j"',
			"Space@300ms 3",
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			'Type "h" Enter',
			SLEEP_TIME,
			'Type "{0}" Enter',
			SLEEP_TIME,
			'Type "gg"',
			SLEEP_TIME,
			'Type "/{0}" Enter',
			SLEEP_TIME,
			f'Type "/{FIRST_FILE_NAME}" Enter',
			'Type "jjjj"',
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			'Type "s" Enter',
			SLEEP_TIME,
			'Type "{1}" Enter',
			SLEEP_TIME,
			'Type "gg"',
			SLEEP_TIME,
			'Type "/{1}" Enter',
			SLEEP_TIME,
			f'Type "/{FIRST_FILE_NAME}" Enter',
			'Type "jjjj"',
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			"Enter",
			SLEEP_TIME,
			'Type "{2}" Enter',
			SLEEP_TIME,
			'Type "gg"',
			SLEEP_TIME,
			'Type "/{2}" Enter',
		],
	),
	VHSTape(
		name="Archive behaviour",
		files_and_directories=[
			"demo.zip",
			"demo-1.zip",
			"demo.txt",
			"demo.txt.zip",
			"demo-2",
			"demo-2.zip",
			"archive_to_overwrite.zip",
		],
		scripts=[
			VHSTape.edit_plugin_config("reveal_created_archive", False),
			VHSTape.create_keymap_toml_with_keymap({DEFAULT_KEY: "archive"}),
			VHSTape.create_nested_archive(4, "{6}"),
			Script(
				setup=[
					f"Type `echo '{DEFAULT_TEXT_FILE_CONTENT}' > "
					+ "{2}` Enter"
				],
				required_programs=["echo"],
			),
		],
		yazi_body=[
			f'Type "/{FIRST_FILE_NAME}" Enter',
			SLEEP_TIME,
			'Type "j"',
			"Space@300ms 3",
			'Type "k"',
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			'Type "{0}" Enter',
			SLEEP_TIME,
			'Type "gg"',
			SLEEP_TIME,
			'Type "/{0}" Enter',
			SLEEP_TIME,
			f'Type "/{FIRST_FILE_NAME}" Enter',
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			'Type "{1}" Enter',
			SLEEP_TIME,
			'Type "gg"',
			SLEEP_TIME,
			'Type "/{1}" Enter',
			SLEEP_TIME,
			'Type "/{2}" Enter',
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			"Enter",
			SLEEP_TIME,
			'Type "gg"',
			SLEEP_TIME,
			'Type "/{3}" Enter',
			SLEEP_TIME,
			f'Type "/{FIRST_FILE_NAME}" Enter',
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			'Type "{4}" Enter',
			SLEEP_TIME,
			'Type "/{5}" Enter',
			SLEEP_TIME,
			f'Type "/{FIRST_FILE_NAME}" Enter',
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			'Type "{6}" Enter',
			SLEEP_TIME,
			"Ctrl+c",
			SLEEP_TIME,
			'Type "/{6}" Enter',
		],
	),
	VHSTape(
		name="Archive encrypt files",
		files_and_directories=["demo.7z"],
		scripts=[
			VHSTape.edit_plugin_config("reveal_created_archive", False),
			VHSTape.create_keymap_toml_with_keymap(
				{DEFAULT_KEY: "archive --encrypt --encrypt-headers"}
			),
		],
		yazi_body=[
			f'Type "/{FIRST_FILE_NAME}" Enter',
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			'Type "{0}" Enter',
			SLEEP_TIME,
			'Type "{0}" Enter',
			SLEEP_TIME,
			'Type "{0}" Enter',
			SLEEP_TIME,
			'Type "/{0}" Enter',
		],
	),
	VHSTape(
		name="Archive reveal created archive",
		files_and_directories=["demo.zip"],
		scripts=[
			VHSTape.create_keymap_toml_with_keymap({DEFAULT_KEY: "archive"}),
		],
		yazi_body=[
			f'Type "/{FIRST_FILE_NAME}" Enter',
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			'Type "{0}" Enter',
		],
	),
	VHSTape(
		name="Archive remove archived files",
		files_and_directories=[
			"demo.zip",
			"demo-1.txt",
			"demo-2.txt",
			"demo-3.txt",
			"demo-4.txt",
			"demo-5.txt",
		],
		scripts=[
			VHSTape.edit_plugin_config("reveal_created_archive", False),
			VHSTape.create_keymap_toml_with_keymap(
				{DEFAULT_KEY: "archive --remove"}
			),
			Script(
				setup=[
					f"Type `echo '{DEFAULT_TEXT_FILE_CONTENT}' > "
					+ "{"
					+ str(i)
					+ "}` Enter"
					for i in range(1, 6)
				],
				required_programs=["echo"],
			),
		],
		yazi_body=[
			'Type "/{1}" Enter',
			SLEEP_TIME,
			"Space@300ms 5",
			'Type "k"',
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			'Type "{0}" Enter',
			SLEEP_TIME,
			'Type "/{1}" Enter',
		],
	),
	VHSTape(
		name="Emit Yazi command",
		scripts=[VHSTape.create_keymap_toml_with_keymap({DEFAULT_KEY: "emit"})],
		yazi_body=[
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			'Type "arrow next" Enter',
		],
	),
	VHSTape(
		name="Emit plugin command",
		scripts=[
			VHSTape.create_keymap_toml_with_keymap(
				{DEFAULT_KEY: "emit --plugin"}
			)
		],
		yazi_body=[
			'Type "l"',
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			'Type "augment-command -- parent_arrow 1" Enter',
		],
	),
	VHSTape(
		name="Emit augmented command",
		scripts=[
			VHSTape.create_keymap_toml_with_keymap(
				{DEFAULT_KEY: "emit --augmented"}
			)
		],
		yazi_body=[
			'Type "l"',
			SLEEP_TIME,
			f'Type "{DEFAULT_KEY}"',
			SLEEP_TIME,
			'Type "parent_arrow 1" Enter',
		],
	),
	VHSTape(
		name="Editor must have hovered item",
		editor="nano",
		yazi_body=[
			f'Type "/{FIRST_FILE_NAME}" Enter',
			SLEEP_TIME,
			'Type "j"',
			"Space@300ms 3",
			SLEEP_TIME,
			f'Type "/{EMPTY_FOLDER}" Enter',
			SLEEP_TIME,
			'Type "l"',
			'Type "o"',
			LONG_SLEEP_TIME,
			'Type "h"',
			SLEEP_TIME,
			f'Type "/{FIRST_FILE_NAME}" Enter',
			SLEEP_TIME,
			'Type "o"',
			SLEEP_TIME,
			"Ctrl+x",
		],
	),
	VHSTape(
		name="Editor hovered item optional",
		editor="nano",
		scripts=[
			VHSTape.edit_plugin_config("must_have_hovered_item", False),
		],
		yazi_body=[
			f'Type "/{FIRST_FILE_NAME}" Enter',
			SLEEP_TIME,
			'Type "j"',
			"Space@300ms 3",
			SLEEP_TIME,
			f'Type "/{EMPTY_FOLDER}" Enter',
			SLEEP_TIME,
			'Type "l"',
			SLEEP_TIME,
			'Type "o"',
			SLEEP_TIME,
			"Ctrl+x",
			SLEEP_TIME,
			"Ctrl+x",
			SLEEP_TIME,
			"Ctrl+x",
			SLEEP_TIME,
			'Type "h"',
			SLEEP_TIME,
			f'Type "/{FIRST_FILE_NAME}" Enter',
			SLEEP_TIME,
			'Type "o"',
			SLEEP_TIME,
			"Ctrl+x",
		],
	),
	VHSTape(
		name="Editor prompt",
		editor="nano",
		scripts=[
			VHSTape.edit_plugin_config("prompt", True),
		],
		yazi_body=[
			f'Type "/{FIRST_FILE_NAME}" Enter',
			"Space@300ms 3",
			'Type "o"',
			SLEEP_TIME,
			'Type "h"',
			SLEEP_TIME,
			"Enter",
			SLEEP_TIME,
			"Ctrl+x",
			SLEEP_TIME,
			'Type "o"',
			SLEEP_TIME,
			'Type "s"',
			SLEEP_TIME,
			"Enter",
			SLEEP_TIME,
			"Ctrl+x",
			SLEEP_TIME,
			"Ctrl+x",
			SLEEP_TIME,
			"Ctrl+x",
			SLEEP_TIME,
			'Type "o"',
			SLEEP_TIME,
			"Enter",
			SLEEP_TIME,
			"Ctrl+x",
		],
	),
	VHSTape(
		name="Editor behaviour",
		editor="nano",
		yazi_body=[
			f'Type "/{FIRST_FILE_NAME}" Enter',
			"Space@300ms 3",
			SLEEP_TIME,
			'Type "o"',
			SLEEP_TIME,
			"Ctrl+x",
			SLEEP_TIME,
			'Type "j"',
			SLEEP_TIME,
			'Type "o"',
			SLEEP_TIME,
			"Ctrl+x",
			SLEEP_TIME,
			'Type "kk"',
			SLEEP_TIME,
			'Type "o"',
			SLEEP_TIME,
			"Ctrl+x",
			SLEEP_TIME,
			"Ctrl+x",
			SLEEP_TIME,
			"Ctrl+x",
		],
	),
	VHSTape(
		name="Pager must have hovered item",
		yazi_body=[
			f'Type "/{FIRST_FILE_NAME}" Enter',
			SLEEP_TIME,
			'Type "j"',
			"Space@300ms 3",
			SLEEP_TIME,
			f'Type "/{EMPTY_FOLDER}" Enter',
			SLEEP_TIME,
			'Type "l"',
			'Type "i"',
			LONG_SLEEP_TIME,
			'Type "h"',
			SLEEP_TIME,
			f'Type "/{FIRST_FILE_NAME}" Enter',
			SLEEP_TIME,
			'Type "i"',
			SLEEP_TIME,
			'Type "q"',
		],
	),
	VHSTape(
		name="Pager hovered item optional",
		scripts=[
			VHSTape.edit_plugin_config("must_have_hovered_item", False),
		],
		yazi_body=[
			f'Type "/{FIRST_FILE_NAME}" Enter',
			SLEEP_TIME,
			'Type "j"',
			"Space@300ms 3",
			SLEEP_TIME,
			f'Type "/{EMPTY_FOLDER}" Enter',
			SLEEP_TIME,
			'Type "l"',
			SLEEP_TIME,
			'Type "i"',
			SLEEP_TIME,
			'Type ":n"',
			SLEEP_TIME,
			'Type ":n"',
			SLEEP_TIME,
			'Type ":n"',
			SLEEP_TIME,
			'Type "q"',
			SLEEP_TIME,
			'Type "h"',
			SLEEP_TIME,
			f'Type "/{FIRST_FILE_NAME}" Enter',
			SLEEP_TIME,
			'Type "i"',
			SLEEP_TIME,
			'Type "q"',
		],
	),
	VHSTape(
		name="Pager prompt",
		scripts=[
			VHSTape.edit_plugin_config("prompt", True),
		],
		yazi_body=[
			f'Type "/{FIRST_FILE_NAME}" Enter',
			"Space@300ms 3",
			'Type "i"',
			SLEEP_TIME,
			'Type "h"',
			SLEEP_TIME,
			"Enter",
			SLEEP_TIME,
			'Type "q"',
			SLEEP_TIME,
			'Type "i"',
			SLEEP_TIME,
			'Type "s"',
			SLEEP_TIME,
			"Enter",
			SLEEP_TIME,
			'Type ":n"',
			SLEEP_TIME,
			'Type ":n"',
			SLEEP_TIME,
			'Type ":n"',
			SLEEP_TIME,
			'Type "q"',
			SLEEP_TIME,
			'Type "i"',
			SLEEP_TIME,
			"Enter",
			SLEEP_TIME,
			'Type "q"',
		],
	),
	VHSTape(
		name="Pager behaviour",
		yazi_body=[
			f'Type "/{FIRST_FILE_NAME}" Enter',
			"Space@300ms 3",
			SLEEP_TIME,
			'Type "i"',
			SLEEP_TIME,
			'Type "q"',
			SLEEP_TIME,
			'Type "j"',
			SLEEP_TIME,
			'Type "i"',
			SLEEP_TIME,
			'Type "q"',
			SLEEP_TIME,
			'Type "kk"',
			SLEEP_TIME,
			'Type "i"',
			SLEEP_TIME,
			'Type ":n"',
			SLEEP_TIME,
			'Type ":n"',
			SLEEP_TIME,
			'Type ":n"',
			SLEEP_TIME,
			'Type "q"',
			SLEEP_TIME,
			'Type "gg"',
			"Space@300ms 2",
			'Type "k"',
			SLEEP_TIME,
			'Type "i"',
			SLEEP_TIME,
			"Enter",
			SLEEP_TIME,
			'Type ":n"',
			SLEEP_TIME,
			'Type ":n"',
			SLEEP_TIME,
			'Type ":n"',
			SLEEP_TIME,
			'Type "q"',
			SLEEP_TIME,
			"Escape 2",
			'Type "gg"',
			SLEEP_TIME,
			'Type "u"',
			SLEEP_TIME,
			'Type "i"',
			SLEEP_TIME,
			'Type "j"',
			SLEEP_TIME,
			'Type "i"',
			SLEEP_TIME,
			'Type "gg"',
			"Space@300ms 2",
			'Type "k"',
			SLEEP_TIME,
			'Type "i"',
		],
	),
]


async def main():
	"Main function to run to generate the VHS tapes"

	# Get the arguments to the script
	args = get_command_line_arguments()

	# Create the demonstration directory if it does not exist
	if not os.path.isdir(DEMONSTRATION_DIRECTORY):
		os.mkdir(DEMONSTRATION_DIRECTORY)

	# Change directory to the demonstration directory
	os.chdir(DEMONSTRATION_DIRECTORY)

	# Create the VHS tapes directory if it does not exist
	if not os.path.isdir(VHS_TAPES_DIRECTORY):
		os.mkdir(VHS_TAPES_DIRECTORY)

	# Create the files and folders for the demonstration
	for folder in [EMPTY_FOLDER, "."] + [
		f"folder_{number}" for number in range(1, 4)
	]:
		#

		# If the folder is the empty folder
		if folder == EMPTY_FOLDER:
			#

			# Create the folder
			os.mkdir(folder)

			# Continue the loop
			continue

		# Create an inner folder
		Path(f"{folder}/inner_folder/").mkdir(parents=True)

		# Iterate over the files for the folder
		for file_number in range(1, 11):
			#

			# Create the file with the demonstration text
			_ = Path(f"{folder}/file_{file_number}.txt").write_text(
				DEMONSTRATION_TEXT
			)

	# The path to the file in the folder with subdirectory
	file_in_folder_with_subdirectory = Path(
		f"./{FOLDER_WITH_SUBDIRECTORY}/subdirectory/hi_there.txt"
	)

	# Create the folder with the subdirectory
	file_in_folder_with_subdirectory.parent.mkdir(parents=True)

	# Write to the file in the folder with subdirectory
	_ = file_in_folder_with_subdirectory.write_text("Skipped!")

	# Get the current theme
	darkman_result = subprocess.run(["darkman", "get"], capture_output=True)

	# Get the theme from the stdout
	initial_theme = darkman_result.stdout.decode("utf-8").strip()

	# If the theme is light, change the theme to dark
	if initial_theme == "light":
		_ = subprocess.run(["darkman", "set", "dark"])

	# Initialise the list of threads
	threads: list[Coroutine[None, None, None]] = []

	# Initialise the list of vhs tapes
	vhs_tapes = VHS_TAPES

	# If a search term is given,
	# then get only the vhs tapes
	# that contain the search terms
	if (search_term := cast(str | None, args.search_term)) is not None:
		vhs_tapes = list(
			filter(
				lambda tape: all(
					term in tape.name.lower()
					for term in search_term.lower().split()
				),
				vhs_tapes,
			)
		)

	# Create the VHS tapes
	for vhs_tape in vhs_tapes:
		threads.append(asyncio.to_thread(vhs_tape.write_to_file))

	# Wait for all the threads to complete
	_ = await asyncio.gather(*threads)

	# Iterate over the VHS tapes
	for vhs_tape in vhs_tapes:
		#

		# Get the file path for the VHS tape
		file_path = vhs_tape.get_file_path()

		# Create the video for the VHS tape
		_ = subprocess.run(["vhs", file_path], check=True)

	# Remove the demonstration directory
	shutil.rmtree(DEMONSTRATION_DIRECTORY)

	# Set the theme back to light if the theme was initially light
	if initial_theme == "light":
		_ = subprocess.run(["darkman", "set", "light"])


# Name safeguard
if __name__ == "__main__":
	asyncio.run(main())
