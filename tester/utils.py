import os
import re
from enum import Enum
from .config import globals


class Color(Enum):
    RED = "\033[91m"
    GREEN = "\033[92m"
    CYAN = "\033[96m"
    RESET = "\033[0m"


def create_write_file(path, content, mode=0o666):
    try:
        with open(path, "w") as file:
            file.write(content)
        os.chmod(path, mode)
    except OSError as e:
        print(f"Error creating file {path}: {e}")


def strip_invisible_chars(text):
    ansi_escape = re.compile(r"\x1B[@-_][0-?]*[ -/]*[@-~]")
    return ansi_escape.sub("", text)


def print_formatted(label, status, width=40):
    if globals["colored_output"] == True:
        color_code = Color.GREEN.value if status == "OK" else Color.RED.value
        reset_code = Color.RESET.value
        print(f"{label.ljust(width, '.')} {color_code}{status}{reset_code}")
    else:
        print(f"{label.ljust(width, '.')} {status}")


def print_total():
    print()
    print("-" * 40)
    print("\n\nRESULTS")
    print(
        f"Total: {globals['test_count']}; Fail: {globals['test_fail_count']}; Pass: {globals['test_pass_count']}"
    )

    print("\n\nNOTICE")
    print("This tester does not test for memory leaks.")
    print(
        "Some tests still need to be done manually, particularly for:\n\t* 'ctrl-c',\n\t* 'ctrl-\\',\n\t* 'ctrl-D',\n\t* << (heredoc)"
    )


def print_test_block_options(test_blocks):
    print("Available test blocks:")
    for block in test_blocks.keys():
        print(f"- {block}")


def print_test_header(test_count, command):
    print()
    print(f"[{test_count:03}]" + "-" * 40)
    if globals["colored_output"]:
        print(f"command: {Color.CYAN.value}{command}{Color.RESET.value}")
    else:
        print(f"command: {command}")


def print_test_block_header(block_title):
    print("-" * 40)
    print(f"\n\n{block_title}\n\n")


def print_minishell_not_found():
    print(
        """
Minishell binary not found.

Please build minishell and ensure that the minishell binary is executable.

Check that the files are as follows:
- minishell
- minitester_dir
   - minitester.py

Or update the minishell_path in tester/config.py
"""
    )
