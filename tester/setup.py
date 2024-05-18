import argparse
import os
import shutil
from .config import bash_dir, mini_dir, test_dir


def setup_directories():
    try:
        os.makedirs(bash_dir, exist_ok=True)
        os.makedirs(mini_dir, exist_ok=True)
    except OSError as e:
        print(f"Error creating directories: {e}")
        exit(2)


def cleanup_directories():
    paths = [
        os.path.join(bash_dir, "forbidden_dir"),
        os.path.join(bash_dir, "forbidden_file"),
        os.path.join(mini_dir, "forbidden_dir"),
        os.path.join(mini_dir, "forbidden_file"),
    ]

    for path in paths:
        if os.path.exists(path):
            os.chmod(path, 0o666)

    try:
        shutil.rmtree(test_dir, ignore_errors=True)
    except OSError as e:
        print(f"Error cleaning up directories: {e}")
        exit(2)


def parse_test_file(filepath):
    test_blocks = {}
    current_block = None

    try:
        with open(filepath, "r") as file:
            for line in file:
                line = line.rstrip("\n")
                if line.strip():
                    if line.startswith("#"):
                        current_block = line.strip("# ").strip()
                        test_blocks[current_block] = []
                    elif current_block:
                        test_blocks[current_block].append(line)
    except FileNotFoundError:
        print(f"Error: test file '{filepath}' not found.")
        exit(2)
    except Exception as e:
        print(f"Error parsing test file: {e}")
        exit(2)

    return test_blocks


def get_args():
    parser = argparse.ArgumentParser(description="Run minishell tests")
    parser.add_argument("-a", "--all", action="store_true", help="Run all test blocks")
    parser.add_argument(
        "-l",
        "--list",
        action="store_true",
        help="List all available test blocks",
    )
    parser.add_argument(
        "-t",
        "--testblock",
        action="append",
        help="Specify test blocks to run (can be used multiple times)",
    )
    parser.add_argument(
        "-c",
        "--color",
        action="store_true",
        help="Display colored output (default no color)",
    )
    return parser, parser.parse_args()
