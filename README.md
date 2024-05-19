# Minitester: A simple Minishell tester

A simple tester for 42 school project minishell.

## Tests Performed

This tester compares your Minishell output (file output, standard output, standard error and exit codes) against Bash over 600+ tests:

- Execution tests: executables with relative and absolute paths, piped commands (`|`)
- Parsing & syntax error tests,
- Quote handling tests (`"` and `'`)
- Environment variable expansion tests (`$`)
- Builtin tests: `echo`, `env`, `export`, `unset`, `pwd`, `cd`, `exit`
- Redirection tests: `<`, `>`, `>>`
- Exit status tests (`$?`)
- Tests with no environment

If the output does not match, the tester displays the differences.

Python tester:
![minitester execution python](https://github.com/mcombeau/minitester-minishell-tester/blob/main/screenshots/minitester-python.png)

However, it does not test for memory leaks or for Norm errors. Some tests must still be performed manually, such as for signals and `ctrl-D` functionality, as well as for the heredoc.

## Prerequisites

This tester requires Python3.

To use this tester, your minishell must support the `-c` option, which allows passing a command as an argument, like Bash:

```bash
$ bash -c 'echo hello world | cat -e'
hello world$
$ ./minishell -c 'echo hello world | cat -e'
hello world$
```

This way, the line to parse is in your main function's `argv[2]`, instead of a `readline` input.

This test also requires a basic implementation of the semicolon `;` operator although the minishell subject does not. The semicolon operator allows passing multiple commands to be perfomed sequentially:

```Bash
$ bash -c 'echo hello | echo world'
world
$ bash -c 'echo hello; echo world'
hello
world
```

The easiest way to implement this is by using `ft_split` on your `argv[2]`. For example, an implementation might be:

```C
int	main(int argc, char **argv, char **envp)
{
	char	*readline_input;
	char	**arg_input;
	int		i;

	if (argc == 3 && ft_strcmp(argv[1], "-c") == 0 && argv[2])
	{
		arg_input = ft_split(argv[2], ';');
		if (!arg_input)
			// exit
		i = 0;
		while (arg_input[i])
		{
			// Parse arg_input[i]
			// Execute arg_input[i]
			i++;
		}
	}
	else
	{
		while (1)
		{
			readline_input = readline(PROMPT);
			//Parse readline input
			//Execute readline input
		}
	}
	// Free data and exit minishell when done
}
```

These requirements are necessary to be able to properly test builtins like `export` and `unset` (to be able to check the environment afterwards) as well as `cd` (to be able to check `pwd` afterwards)

## Usage

Clone this repository in your minishell directory.

```
git clone git@github.com:mcombeau/minitester-minishell-tester.git
```

If you wish to clone it elsewhere, please edit `minishell_path` in `tester/config.py` to point to your minishell binary.

To run the program:

```bash
$ python3 minitester.py
```

The tester runs the tests specified (one per line) in the `minishell_tests.txt` file. Each block of tests can be run independently (see options below).

```bash
usage: python3 minitester.py [-h] [-a] [-l] [-t TESTBLOCK] [-c]
```

Options are:

- `-h`: Show the help message
- `-a`: Run all test blocks
- `-l`: List all available test blocks
- `-t TESTBLOCK`: Specify tests blocks to run (can be used multiple times)
- `-c`: Display colored output (default no color)

For example, to run only tests related to the `echo` built in and display the results with color, you can run:

```bash
python3 minitester.py -c -t echo -t echo-no-env
```

---

Made by mcombeau: mcombeau@student.42.fr | LinkedIn: [mcombeau](https://www.linkedin.com/in/mia-combeau-86653420b/) | Website: [codequoi.com](https://www.codequoi.com)
