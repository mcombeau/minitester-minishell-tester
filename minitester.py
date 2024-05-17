# TODO: Tests with 'pwd not working because bash and minishell are in different working directories

import os
import subprocess
import glob
import shutil
import filecmp
import re

bash_path = 'bash'
minishell_path = os.path.abspath('../minishell')

bash_dir = 'test_output/bash'
mini_dir = 'test_output/minishell'

test_count = 0
test_fail_count = 0
test_pass_count = 0

def run_command(command, shell_path, working_dir=None):
    result = subprocess.run(
        [shell_path, '-c', command],
        cwd=working_dir,
        capture_output=True,
        text=True
    )
    return result.stdout, result.stderr, result.returncode

def strip_invisible_chars(text):
    ansi_escape = re.compile(r'\x1B[@-_][0-?]*[ -/]*[@-~]')
    return ansi_escape.sub('', text)

def stdout_ok(bash_stdout, mini_stdout):
    bash_stdout = strip_invisible_chars(bash_stdout)
    mini_stdout = strip_invisible_chars(mini_stdout)
    if bash_stdout != mini_stdout:
        print('\tstdout... KO')
        print(f'\t -- Bash stdout: {bash_stdout}')
        print(f'\t -- Minishell stdout: {mini_stdout}')
        return False
    else:
        print('\tstdout... OK')
        return True

def stderr_ok(bash_stderr, mini_stderr):
    bash_output = strip_invisible_chars(bash_stderr.split(':')[-1].strip())
    mini_output = strip_invisible_chars(mini_stderr.split(':')[-1].strip())
    if bash_output != mini_output:
        print('\tstderr... KO')
        print(f'\t -- Bash stderr: {bash_stderr}')
        print(f'\t -- Minishell stderr: {mini_stderr}')
        return False
    else:
        print('\tstderr... OK')
        return True

def returncode_ok(bash_returncode, mini_returncode):
    if bash_returncode != mini_returncode:
        print('\texit code... KO')
        print(f'\t -- Bash exit code: {bash_returncode}')
        print(f'\t -- Minishell exit code: {mini_returncode}')
        return False
    else:
        print('\texit code... OK')
        return True

def get_files_in_dir(directory):
    return set(glob.glob(os.path.join(directory, '*')))

def compare_files(file1, file2):
    if os.path.exists(file1) and os.path.exists(file2):
        if not filecmp.cmp(file1, file2, shallow=False):
            print(f'File content mismatch: {file1} vs {file2}')
            with open(file1, 'r') as f1, open(file2, 'r') as f2:
                content1 = f1.read()
                content2 = f2.read()
                print(f'{file1} content: {content1}')
                print(f'{file2} content: {content2}')
                return False
        else:
            return True
    else:
        print(f'One or both files do not exist: {file1}, {file2}')
        return False

def output_files_ok(bash_files, mini_files):
    ok = True

    if len(bash_files) != len(mini_files):
        print('Bash and minishell have different output files!')
        print(f'bash files: {bash_files}')
        print(f'mini files: {mini_files}')
        ok = False

    for file in bash_files:
        bash_file_path = os.path.join(bash_dir, os.path.basename(file))
        mini_file_path = os.path.join(mini_dir, os.path.basename(file))
        if compare_files(bash_file_path, mini_file_path) == False:
            ok = False

    if ok == True:
        print(f'\tOutput files... OK')

    return ok

def test_command(command):
    global test_count
    global test_fail_count
    global test_pass_count
    test_count += 1
    print(f'{test_count}: [{command}]')

    bash_stdout, bash_stderr, bash_returncode = run_command(command, bash_path, bash_dir)
    mini_stdout, mini_stderr, mini_returncode = run_command(command, minishell_path, mini_dir)

    bash_files = get_files_in_dir(bash_dir)
    mini_files = get_files_in_dir(mini_dir)

    passed = 0

    passed += stdout_ok(bash_stdout, mini_stdout)
    passed += stderr_ok(bash_stderr, mini_stderr)
    passed += returncode_ok(bash_returncode, mini_returncode)
    passed += output_files_ok(bash_files, mini_files)

    if passed == 4:
        test_pass_count += 1
    else:
        test_fail_count += 1

def setup_directories():
    shutil.rmtree('test_output', ignore_errors=True)
    os.makedirs('test_output/bash')
    os.makedirs('test_output/minishell')

def setup_test_files():
    shutil.rmtree('test_input', ignore_errors=True)
    os.makedirs('test_input')
    # TODO: make forbidden dir
    # TODO: make forbidden file
    # TODO: make valid input file 1
    # TODO: make valid input file 2
    # TODO: make executable file

def cleanup_directories():
    shutil.rmtree('test_output')

def main():
    global test_count
    global test_fail_count
    global test_pass_count

    setup_directories()
    setup_test_files()

    try:
        with open('minishell_tests.txt', 'r') as file:
            for line in file:
                if line.strip():
                    if line.startswith('--'):
                        print(f'{line}')
                    else:
                        command = line.rstrip('\n')
                        test_command(command)
    except FileNotFoundError:
        print('Error: minishell_tests.txt file not found.')
        return

    print(f'Total: {test_count}; Fail: {test_fail_count}; Pass: {test_pass_count}')

    cleanup_directories()

if __name__ == '__main__':
    main()
