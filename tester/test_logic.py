import filecmp
import os
import subprocess
from .config import bash_dir, mini_dir
from .utils import (
    strip_invisible_chars,
    print_formatted,
    print_test_block_header,
    print_test_header,
)
from .config import (
    globals,
    bash_path,
    minishell_path,
    test_files,
)


def run_command(command, shell_path, working_dir=None, no_env=False):
    env = {} if no_env else None
    try:
        result = subprocess.run(
            [shell_path, "-c", command], cwd=working_dir, capture_output=True, env=env
        )
        stdout = result.stdout.decode("utf-8", errors="ignore")
        stderr = result.stderr.decode("utf-8", errors="ignore")
        return stdout, stderr, result.returncode
    except Exception as e:
        print(f"Error running command '{command}': {e}")
        return "", "", 1


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


def is_stderr_exception(bash_stderr, mini_stderr):
    bash_output = strip_invisible_chars(bash_stderr.split(":")[-1].strip())

    if "free" in mini_stderr.lower():
        return False

    if "syntax error" in bash_stderr.lower() and "syntax error" in mini_stderr.lower():
        return True

    if bash_output in mini_stderr:
        return True


def stderr_ok(bash_stderr, mini_stderr):
    bash_output = strip_invisible_chars(bash_stderr.split(":")[-1].strip())
    mini_output = strip_invisible_chars(mini_stderr.split(":")[-1].strip()).rstrip("\n")

    if bash_output != mini_output:
        if not is_stderr_exception(bash_stderr, mini_stderr):
            print_formatted("stderr", "KO")
            print(f"--> Bash stderr:\n{bash_stderr}")
            print(f"--> Minishell stderr:\n{mini_stderr}")
            return False
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
            print(f"--> File content mismatch: {file1} vs {file2}")
            with open(file1, "r") as f1, open(file2, "r") as f2:
                content1 = f1.read()
                content2 = f2.read()
                print(f"--> {file1} content:\n{content1}")
                print(f"--> {file2} content:\n{content2}")
                return False
        else:
            return True
    else:
        print(f"--> One or both files do not exist: {file1}, {file2}")
        return False


def output_files_ok():
    all_files_ok = True

    bash_files = set()
    mini_files = set()

    for root, _, files in os.walk(bash_dir):
        for file in files:
            bash_files.add(os.path.relpath(os.path.join(root, file), bash_dir))

    for root, _, files in os.walk(mini_dir):
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


def is_exceptional_command(command):
    not_required = ["||", "&&"]

    if "." in command:
        has_special_dot = any(part.strip() == "." for part in command.split(";"))
        return has_special_dot

    for symbol in not_required:
        if symbol in command:
            print(
                f"Note: '{symbol}' implementation not required in minishell: bash output differs; 'syntax error' expected for minishell stderr"
            )
            return True

    if "$$" in command:
        print(
            f"Note: '$$' implementation not required in minishell: bash output differs; '$$' expected for minishell stdout"
        )
        return True

    return False


def exceptional_command_ok(
    command,
    mini_stdout,
    mini_stderr,
    mini_returncode,
    bash_stdout,
    bash_stderr,
    bash_returncode,
):
    not_required = ["||", "&&"]

    if "." in command:
        if (
            "command not found" in mini_stderr
            and mini_returncode == globals["cmd_not_found_exit"]
        ):
            print_formatted("stdout", "OK")
            print_formatted("stderr", "OK")
            print_formatted("exit code", "OK")
            return 3
        elif (
            "is a directory" in mini_stderr.lower()
            and mini_returncode == globals["is_directory_exit"]
        ):
            print_formatted("stdout", "OK")
            print_formatted("stderr", "OK")
            print_formatted("exit code", "OK")
            return 3
        else:
            print(f"Expected 'command not found' or 'is a directory' error")
            passed = 0
            passed += stdout_ok(bash_stdout, mini_stdout)
            passed += stderr_ok(bash_stderr, mini_stderr)
            passed += returncode_ok(bash_returncode, mini_returncode)

            return 0

    for symbol in not_required:
        if (
            symbol in command
            and "syntax error" in mini_stderr
            and mini_returncode == globals["syntax_error_exit"]
        ):
            print_formatted("stdout", "OK")
            print_formatted("stderr", "OK")
            print_formatted("exit code", "OK")
            return 3

    if "$$" in command and "$$" in mini_stdout:
        passed = 1
        print_formatted("stdout", "OK")
        passed += stderr_ok(bash_stderr, mini_stderr)
        passed += returncode_ok(bash_returncode, mini_returncode)
        return passed

    return 0


def test_command(command, no_env=False):
    globals["test_count"] += 1
    passed = 0
    expected_passed = 3

    print_test_header(globals["test_count"], command)
    bash_stdout, bash_stderr, bash_returncode = run_command(
        command, bash_path, bash_dir, no_env=no_env
    )
    mini_stdout, mini_stderr, mini_returncode = run_command(
        command, minishell_path, mini_dir, no_env=no_env
    )

    if is_exceptional_command(command):
        passed += exceptional_command_ok(
            command,
            mini_stdout,
            mini_stderr,
            mini_returncode,
            bash_stdout,
            bash_stderr,
            bash_returncode,
        )
    else:
        passed += stdout_ok(bash_stdout, mini_stdout)
        passed += stderr_ok(bash_stderr, mini_stderr)
        passed += returncode_ok(bash_returncode, mini_returncode)

    if ">" in command or ">>" in command:
        expected_passed += 1
        passed += output_files_ok()

    if passed == expected_passed:
        globals["test_pass_count"] += 1
    else:
        globals["test_fail_count"] += 1


def run_tests(selected_blocks, test_blocks):
    for block in selected_blocks:
        if block in test_blocks:
            no_env = "no-env" in block.lower()
            print_test_block_header(block)
            for command in test_blocks[block]:
                test_command(command, no_env=no_env)
        else:
            print(f"Test block {block} not found in test file.")
            exit(2)
