# TODO: Tests with 'pwd not working because bash and minishell are in different working directories

from enum import Enum
import argparse
import filecmp
import os
import re
import subprocess
import shutil

bash_path = "bash"
minishell_path = os.path.abspath("../minishell")

test_dir = "test_cwd"
bash_dir = os.path.join(test_dir, "bash")
mini_dir = os.path.join(test_dir, "minishell")

test_files = [
    "forbidden_dir",
    "forbidden_file",
    "valid_infile_1",
    "valid_infile_2",
    "executable_file",
    "existing_dir",
    "existing_file",
]

test_count = 0
test_fail_count = 0
test_pass_count = 0


class Color(Enum):
    RED = "\033[91m"
    GREEN = "\033[92m"
    CYAN = "\033[96m"
    RESET = "\033[0m"


def print_section_header(title):
    print("-" * 40)
    print(f"\n\n{title}\n\n")


def print_test_header(test_count, command):
    print()
    print(f"[{test_count:03}]" + "-" * 40)
    print(f"command: {Color.CYAN.value}{command}{Color.RESET.value}")


def print_formatted(label, status, width=40):
    if status == "OK":
        color_code = Color.GREEN.value
    else:
        color_code = Color.RED.value
    reset_code = Color.RESET.value
    print(f"{label.ljust(width, '.')} {color_code}{status}{reset_code}")


def print_total():
    print()
    print("-" * 40)
    print(f"\n\nRESULTS")
    print(f"Total: {test_count}; Fail: {test_fail_count}; Pass: {test_pass_count}")

    print("\n\nNOTICE")
    print("This tester does not test for memory leaks.")
    print(
        "Some tests still need to be done manually, particularly for:\n\t* 'ctrl-c',\n\t* 'ctrl-\\',\n\t* 'ctrl-D',\n\t* << (heredoc)"
    )


def run_command(command, shell_path, working_dir=None):
    result = subprocess.run(
        [shell_path, "-c", command], cwd=working_dir, capture_output=True
    )
    stdout = result.stdout.decode("utf-8", errors="ignore")
    stderr = result.stderr.decode("utf-8", errors="ignore")
    return stdout, stderr, result.returncode


def strip_invisible_chars(text):
    ansi_escape = re.compile(r"\x1B[@-_][0-?]*[ -/]*[@-~]")
    return ansi_escape.sub("", text)


def stdout_ok(bash_stdout, mini_stdout):
    bash_stdout = strip_invisible_chars(bash_stdout).rstrip("\n")
    mini_stdout = strip_invisible_chars(mini_stdout).rstrip("\n")

    normalized_bash_stdout = bash_stdout.replace(bash_dir, "[TEST_DIR]")
    normalized_mini_stdout = mini_stdout.replace(mini_dir, "[TEST_DIR]")

    if normalized_bash_stdout != normalized_mini_stdout:
        print_formatted("stdout", "KO")
        print(f"--> Bash stdout:\n{bash_stdout}")
        print(f"--> Minishell stdout:\n{mini_stdout}")
        return False
    else:
        print_formatted("stdout", "OK")
        return True


def stderr_ok(bash_stderr, mini_stderr):
    bash_output = strip_invisible_chars(bash_stderr.split(":")[-1].strip())
    mini_output = strip_invisible_chars(mini_stderr.split(":")[-1].strip()).rstrip("\n")
    if bash_output != mini_output:
        if bash_output in mini_stderr and "free" not in mini_stderr:
            print_formatted("stderr", "OK")
            return True
        print_formatted("stderr", "KO")
        print(f"--> Bash stderr:\n{bash_stderr}")
        print(f"--> Minishell stderr:\n{mini_stderr}")
        return False
    else:
        print_formatted("stderr", "OK")
        return True


def returncode_ok(bash_returncode, mini_returncode):
    if bash_returncode != mini_returncode:
        print_formatted("exit code", "KO")
        print(f"--> Bash exit code: {bash_returncode}")
        print(f"--> Minishell exit code: {mini_returncode}")
        return False
    else:
        print_formatted("exit code", "OK")
        return True


def compare_files(file1, file2):
    if os.path.exists(file1) and os.path.exists(file2):
        if not filecmp.cmp(file1, file2, shallow=False):
            print(f"File content mismatch: {file1} vs {file2}")
            with open(file1, "r") as f1, open(file2, "r") as f2:
                content1 = f1.read()
                content2 = f2.read()
                print(f"{file1} content: {content1}")
                print(f"{file2} content: {content2}")
                return False
        else:
            return True
    else:
        print(f"One or both files do not exist: {file1}, {file2}")
        return False


def output_files_ok():
    all_files_ok = True

    bash_files = set()
    mini_files = set()

    for root, dirs, files in os.walk(bash_dir):
        for file in files:
            bash_files.add(os.path.relpath(os.path.join(root, file), bash_dir))

    for root, dirs, files in os.walk(mini_dir):
        for file in files:
            mini_files.add(os.path.relpath(os.path.join(root, file), mini_dir))

    bash_files = {
        file for file in bash_files if os.path.basename(file) not in test_files
    }
    mini_files = {
        file for file in mini_files if os.path.basename(file) not in test_files
    }

    if bash_files != mini_files:
        print("Bash and minishell have different output files!")
        print(f"bash files: {bash_files}")
        print(f"mini files: {mini_files}")
        all_files_ok = False

    for file in bash_files:
        bash_file_path = os.path.join(bash_dir, file)
        mini_file_path = os.path.join(mini_dir, file)
        if not compare_files(bash_file_path, mini_file_path):
            all_files_ok = False

    if all_files_ok:
        print_formatted("output files", "OK")
    else:
        print_formatted("output files", "KO")
    return all_files_ok


def test_command(command):
    global test_count
    global test_fail_count
    global test_pass_count
    test_count += 1
    expected_passed = 3

    print_test_header(test_count, command)

    bash_stdout, bash_stderr, bash_returncode = run_command(
        command, bash_path, bash_dir
    )
    mini_stdout, mini_stderr, mini_returncode = run_command(
        command, minishell_path, mini_dir
    )

    passed = 0

    passed += stdout_ok(bash_stdout, mini_stdout)
    passed += stderr_ok(bash_stderr, mini_stderr)
    passed += returncode_ok(bash_returncode, mini_returncode)
    if ">" in command or ">>" in command:
        expected_passed += 1
        passed += output_files_ok()

    if passed == expected_passed:
        test_pass_count += 1
    else:
        test_fail_count += 1


def setup_directories():
    os.makedirs(bash_dir, exist_ok=True)
    os.makedirs(mini_dir, exist_ok=True)


def create_write_file(path, content, mode=0o666):
    with open(path, "w") as file:
        file.write(content)
    os.chmod(path, mode)


def setup_test_files(path):
    os.makedirs(os.path.join(path, "existing_dir"), exist_ok=True)
    os.makedirs(os.path.join(path, "forbidden_dir"), exist_ok=True)
    os.chmod(os.path.join(path, "forbidden_dir"), 0o000)

    create_write_file(
        os.path.join(path, "existing_file"),
        "This is a file that exists with r/w permissions",
    )

    create_write_file(
        os.path.join(path, "forbidden_file"), "This is a forbidden file", 0o000
    )

    create_write_file(
        os.path.join(path, "valid_infile_1"),
        "Take this kiss upon the brow!\nAnd, in parting from you now,\nThus much let me avow-\nYou are not wrong, who deem\nThat my days have been a dream;\nYet if hope has flown away\nIn a night, or in a day,\nIn a vision, or in none,\nIs it therefore the less gone?\nAll that we see or seem\nIs but a dream within a dream.\n\nI stand amid the roar\nOf a surf-tormented shore,\nAnd I hold within my hand\nGrains of the golden sand-\nHow few! yet how they creep\nThrough my fingers to the deep,\nWhile I weep- while I weep!\nO God! can I not grasp\nThem with a tighter clasp?\nO God! can I not save\nOne from the pitiless wave?\nIs all that we see or seem\nBut a dream within a dream?\n\nEdgar Allan Poe\nA Dream Within a Dream",
    )

    man_bash_output = subprocess.run(
        ["man", "bash"], stdout=subprocess.PIPE, text=True
    ).stdout
    head_output = subprocess.run(
        ["head", "-n", "12"], input=man_bash_output, text=True, stdout=subprocess.PIPE
    ).stdout

    create_write_file(os.path.join(path, "valid_infile_2"), head_output)

    create_write_file(
        os.path.join(path, "executable_file"),
        '#!/bin/bash\necho "This is an executable file."',
        0o755,
    )


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

    shutil.rmtree(test_dir, ignore_errors=True)


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
    return parser, parser.parse_args()


def parse_test_file(filepath):
    test_blocks = {}
    current_block = None

    with open(filepath, "r") as file:
        for line in file:
            line = line.rstrip("\n")
            if line.strip():
                if line.startswith("#"):
                    current_block = line.strip("# ").strip()
                    test_blocks[current_block] = []
                elif current_block:
                    test_blocks[current_block].append(line)

    return test_blocks


def print_test_block_options(test_blocks):
    print("Available test blocks:")
    for block in test_blocks.keys():
        print(f"- {block}")


def main():
    global test_count
    global test_fail_count
    global test_pass_count

    argparser, args = get_args()
    test_blocks = parse_test_file("minishell_tests.txt")

    if args.list:
        print_test_block_options(test_blocks)
        return

    if not args.testblock and not args.all:
        argparser.print_help()
        return

    selected_blocks = args.testblock if args.testblock else test_blocks.keys()

    cleanup_directories()
    setup_directories()
    setup_test_files(bash_dir)
    setup_test_files(mini_dir)

    for block in selected_blocks:
        if block in test_blocks:
            print(f"\nRunning test block: {block}")
            for command in test_blocks[block]:
                test_command(command)
        else:
            print(f"Test block {block} not found in test file.")

    print_total()
    cleanup_directories()


if __name__ == "__main__":
    main()
