import os

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

