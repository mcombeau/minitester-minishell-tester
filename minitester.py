# TODO: Tests with 'pwd not working because bash and minishell are in different working directories

import os
import subprocess
import glob
import shutil
import filecmp
import re

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


def run_command(command, shell_path, working_dir=None):
    result = subprocess.run(
        [shell_path, "-c", command], cwd=working_dir, capture_output=True, text=True
    )
    return result.stdout, result.stderr, result.returncode


def strip_invisible_chars(text):
    ansi_escape = re.compile(r"\x1B[@-_][0-?]*[ -/]*[@-~]")
    return ansi_escape.sub("", text)


def stdout_ok(bash_stdout, mini_stdout):
    bash_stdout = strip_invisible_chars(bash_stdout)
    mini_stdout = strip_invisible_chars(mini_stdout)
    if bash_stdout != mini_stdout:
        print("\tstdout... KO")
        print(f"\t -- Bash stdout: {bash_stdout}")
        print(f"\t -- Minishell stdout: {mini_stdout}")
        return False
    else:
        print("\tstdout... OK")
        return True


def stderr_ok(bash_stderr, mini_stderr):
    bash_output = strip_invisible_chars(bash_stderr.split(":")[-1].strip())
    mini_output = strip_invisible_chars(mini_stderr.split(":")[-1].strip())
    if bash_output != mini_output:
        print("\tstderr... KO")
        print(f"\t -- Bash stderr: {bash_stderr}")
        print(f"\t -- Minishell stderr: {mini_stderr}")
        return False
    else:
        print("\tstderr... OK")
        return True


def returncode_ok(bash_returncode, mini_returncode):
    if bash_returncode != mini_returncode:
        print("\texit code... KO")
        print(f"\t -- Bash exit code: {bash_returncode}")
        print(f"\t -- Minishell exit code: {mini_returncode}")
        return False
    else:
        print("\texit code... OK")
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
        print(f"\tOutput files... OK")
    return all_files_ok


def test_command(command):
    global test_count
    global test_fail_count
    global test_pass_count
    test_count += 1
    expected_passed = 3
    print(f"{test_count}: [{command}]")

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


def main():
    global test_count
    global test_fail_count
    global test_pass_count

    cleanup_directories()
    setup_directories()
    setup_test_files(bash_dir)
    setup_test_files(mini_dir)

    try:
        with open("minishell_tests.txt", "r") as file:
            for line in file:
                if line.strip():
                    if line.startswith("--"):
                        print(f"{line}")
                    else:
                        command = line.rstrip("\n")
                        test_command(command)
    except FileNotFoundError:
        print("Error: minishell_tests.txt file not found.")
        return

    print(f"Total: {test_count}; Fail: {test_fail_count}; Pass: {test_pass_count}")

    cleanup_directories()


if __name__ == "__main__":
    main()
