#!bin/bash
###################### NOTES #######################
# TODO: add testing for files with strange names, i.e. with quotes

################## MINISHELL PATH ##################
MINISHELL_PATH="../"
MINISHELL_NAME="minishell"

###################### COLORS ######################
RESET="\e[0m"
BOLD="\e[1m"
BLACK="\e[30m"
RED="\e[31m"
BRED="\e[91m"
GREEN="\e[32m"
BGREEN="\e[92m"
YELLOW="\e[33m"
BYELLOW="\e[93m"
BLUE="\e[34m"
BBLUE="\e[94m"
MAGENTA="\e[35m"
BMAGENTA="\e[95m"
CYAN="\e[36m"
BCYAN="\e[96m"
WHITE="\e[37m"
BWHITE="\e[97m"

#################### TEST FILES ####################
declare -i stdout_ok=0
declare -i stderr_ok=0
declare -i exit_ok=0
declare -i output_diff_ok=0
# Store minishell STDOUT output
M_OUT="./minitests/minishell_out"
# Store minishell STDERR output
M_ERR="./minitests/minishell_err"
# Store minishell error message only for comparison with bash
M_ERR_CMP="./minitests/minishell_err_cmp"
# Store minishell exit status
M_EXT="./minitests/minishell_exit"

# Store bash STDOUT output
B_OUT="./minitests/bash_out"
# Store bash STDERR output
B_ERR="./minitests/bash_err"
# Store bash error message only for comparison with minishell
B_ERR_CMP="./minitests/bash_err_cmp"
# Store bash exit status
B_EXT="./minitests/bash_exit"

# Test dirs
D_EXISTS="existing_dir"
D_FORBIDDEN="forbidden_dir"

# Test files
F_EXISTING="existing_file"
F_DOES_NOT_EXIST="file_does_not_exist"
F_EXECUTABLE="executable_file"
F_FORBIDDEN="forbidden"

# Test infiles
F_IN1="infile.txt"
F_IN2="infile_2.txt"

# Test outfiles
declare -i outfile1_ok=0
declare -i outfile2_ok=0
F_OUT1="out"
F_OUT1_M="out_minishell"
F_OUT1_B="out_bash"
F_OUT2="out_2"
F_OUT2_M="out_2_minishell"
F_OUT2_B="out_2_bash"

#################### TEST COUNT ####################
declare -i test_num=0
declare -i tests_passed=0
declare -i tests_failed=0

################ TESTING FUNCTIONS #################

###################################### File management
function create_test_files()
{
	printf $CYAN"Creating test files...\n$RESET"

	# Make a directory to store minishell and bash outputs
	mkdir -p minitests
	# Make a directory with normal permissions
	mkdir -p $D_EXISTS
	# Make a directory with no permissions
	mkdir "$D_FORBIDDEN"
	chmod 000 "$D_FORBIDDEN"
	# Make existing file with normal permissions
	echo "This file exists and has normal permissions" > "$F_EXISTING"
	# Make basic file test 1 for input
	echo -e "Take this kiss upon the brow!\nAnd, in parting from you now,\nThus much let me avow-\nYou are not wrong, who deem\nThat my days have been a dream;\nYet if hope has flown away\nIn a night, or in a day,\nIn a vision, or in none,\nIs it therefore the less gone?\nAll that we see or seem\nIs but a dream within a dream.\n\nI stand amid the roar\nOf a surf-tormented shore,\nAnd I hold within my hand\nGrains of the golden sand-\nHow few! yet how they creep\nThrough my fingers to the deep,\nWhile I weep- while I weep!\nO God! can I not grasp\nThem with a tighter clasp?\nO God! can I not save\nOne from the pitiless wave?\nIs all that we see or seem\nBut a dream within a dream?\n\nEdgar Allan Poe\nA Dream Within a Dream" > "$F_IN1"
	# Make basic file test 2 for input
	man bash | head -n 12 > "$F_IN2"
	# Make basic executable file
	echo -e "#!/bin/bash\nprintf \"hello world\"" > "$F_EXECUTABLE"
	chmod 755 "$F_EXECUTABLE"
	# Make file with no permissions
	echo "This file is forbidden" > "$F_FORBIDDEN"
	chmod 000 "$F_FORBIDDEN"

	printf $GREEN"Test files created.\n$RESET"
}

function remove_test_files()
{
	rm -rf minitests $D_EXISTS $D_FORBIDDEN
	rm -f $F_IN1 $F_IN2 $F_EXISTING $F_EXECUTABLE $F_FORBIDDEN
}

function remove_outfiles()
{
	rm -f $F_OUT1 $F_OUT1_M $F_OUT1_B $F_OUT2 $F_OUT2_M $F_OUT2_B
}

###################################### Output checking
function reset_comparators()
{
	stdout_ok=0
	stderr_ok=0
	exit_ok=0
	output_diff_ok=0
	outfile1_ok=0
	outfile2_ok=0
}

function check_outfiles()
{
	# ok = 2 if neither the bash file nor the minishell file exist
	# ok = 1 if both bash file and minishell file exist and are the same
	# ok = 0 if one or the other does not exist or if their contents do not match
	if test -f "$F_OUT1_B"; then
		if test -f "$F_OUT1_M" && cmp -s "$F_OUT1_M" "$F_OUT1_B"; then
			outfile1_ok=1
		else
			outfile1_ok=0
		fi
	elif test -f "$F_OUT1_M"; then
		outfile1_ok=0
	else
		outfile1_ok=2
	fi
	if test -f "$F_OUT2_B"; then
		if test -f "$F_OUT2_M" && cmp -s "$F_OUT2_M" "$F_OUT2_B"; then
			outfile2_ok=1
		else
			outfile2_ok=0
		fi
	elif test -f "$F_OUT2_M"; then
		outfile2_ok=0
	else
		outfile2_ok=2
	fi
}

function check_stdout()
{
	if cmp -s "$M_OUT" "$B_OUT"; then
		stdout_ok=1
	elif grep -q "goinfre" "$M_OUT" && grep -q "goinfre" "$B_OUT"; then
		stdout_ok=1
	else
		stdout_ok=0
	fi
}

function check_stderr()
{
	cat -e $M_ERR | head -1 | rev | cut -d ':' -f 1 | tr '[:upper:]' '[:lower:]' | rev >$M_ERR_CMP
	cat -e $B_ERR | head -1 | rev | cut -d ':' -f 1 | tr '[:upper:]' '[:lower:]' | rev >$B_ERR_CMP
	if cmp -s "$M_ERR_CMP" "$B_ERR_CMP"; then
		stderr_ok=1
	elif grep -q "syntax error" "$M_ERR" && grep -q "syntax error" "$B_ERR"; then
		stderr_ok=1
	else
		stderr_ok=0
	fi
}

function check_exit_status()
{
	if cmp -s "$M_EXT" "$B_EXT"; then
		exit_ok=1
	else
		exit_ok=0
	fi
}

function check_output_diff()
{
	if [[ "$@" == '.' ]] && grep -q "command not found" "$M_ERR" && grep -q "127" "$M_EXT"; then
		output_diff_ok=1
	elif [[ "$@" == *'; .' ]] && grep -q "directory" "$M_ERR" && (grep -q "126" "$M_EXT" || grep -q "127" "$M_EXT"); then
		output_diff_ok=1
	elif [[ "$@" == *'||'* ]] && grep -q "syntax error" "$M_ERR" && (grep -q "2" "$M_EXT" || grep -q "1" "$M_EXT"); then
		output_diff_ok=2
	elif [[ "$@" == *'unset'* ]] && grep -q "not a valid identifier" "$M_ERR"; then
		output_diff_ok=3
	elif [[ "$@" == *'$$'* ]] && grep -q '$$' "$M_OUT" && [ $outfile1_ok -ge 1 ] && [ $outfile2_ok -ge 1 ] && [ $stderr_ok -eq 1 ] && [ $exit_ok -eq 1 ]; then
		output_diff_ok=4
	else
		output_diff_ok=0;
	fi
}

function output_ok()
{
	printf "$BOLD%s$RESET\t" "$test_num"
	printf "$BOLD$GREEN%s$RESET" "[OK] "
	printf "$CYAN [$@] $RESET"
	tests_passed+=1
}

function output_ok_diff()
{
	printf "$BOLD$YELLOW%s$RESET\n" "----------------------------------------------------------------"
	printf "$BOLD%s$RESET\t" "$test_num"
	printf "$BOLD$YELLOW%s$RESET" "[OK] "
	printf "$CYAN [$@] $RESET"
	tests_passed+=1
	echo
	printf "%s Output differs from Bash:$YELLOW\nOK" "----------"
	if [ $output_diff_ok -eq 1 ]; then
		printf ": \".\" implementation not required in minishell"
	elif [ $output_diff_ok -eq 2 ]; then
		printf ": \"||\" implementation not required in minishell mandatory part"
	elif [ $output_diff_ok -eq 3 ]; then
		printf ": minishell shows 'not a valid identifier' error whereas Bash no longer does on some systems"
	elif [ $output_diff_ok -eq 4 ]; then
		printf ": \"\$\$\" implementation not required in minishell"
	fi
	printf "$RESET\n"
	printf "$BOLD$YELLOW%s$RESET" "----------------------------------------------------------------"
}

function output_fail()
{
	printf "$BOLD$RED%s$RESET\n" "----------------------------------------------------------------"
	printf "$BOLD%s$RESET\t" "$test_num"
	printf "$BOLD$RED%s$RESET" "[KO] "
	printf "$CYAN [$@] $RESET"
	tests_failed+=1
	echo
	if test -f $F_OUT1_B; then
		if [[ $outfile1_ok -eq 1 && "$@" == *"$F_OUT1"* ]]; then
			printf "%s Outfile "\'$F_OUT1\'":$BOLD$GREEN OK \n$RESET" "----------"
		elif [ $outfile1_ok -eq 0 ]; then
			printf "%s Outfile "\'$F_OUT1\'":$BOLD$RED KO \n$RESET" "----------"
			printf "%s Outfile diff$RED Minishell$RESET vs$GREEN Bash$RESET: \n" ">>>"
			diff --color "$F_OUT1_M" "$F_OUT1_B"
			rm -f "$F_OUT1_M" "$F_OUT1_B"
		fi
	fi
	if test -f $F_OUT2_B; then
		if [[ $outfile2_ok -eq 1 && "$@" == *"$F_OUT2"* ]]; then
			printf "%s Outfile "\'$F_OUT2\'":$BOLD$GREEN OK \n$RESET" "----------"
		elif [ $outfile2_ok -eq 0 ]; then
			printf "%s Outfile "\'$F_OUT2\'":$BOLD$RED KO \n$RESET" "----------"
			printf "%s Outfile diff$RED Minishell$RESET vs$GREEN Bash$RESET: \n" ">>>"
			diff --color "$F_OUT2_M" "$F_OUT2_B"
			rm -f "$F_OUT2_M" "$F_OUT2_B"
		fi
	fi
	if [ $stdout_ok -eq 1 ]; then
		printf "%s STDOUT output:$BOLD$GREEN OK \n$RESET" "----------"
	else
		printf "%s STDOUT output:$BOLD$RED KO \n$RESET" "----------"
		printf "%s STDOUT diff$RED Minishell$RESET vs$GREEN Bash$RESET: \n" ">>>"
		diff --color "$M_OUT" "$B_OUT"
		rm -f "$M_OUT" "$B_OUT"
	fi
	if [ $stderr_ok -eq 1 ]; then
		printf "%s STDERR output:$BOLD$GREEN OK \n$RESET" "----------"
	else
		printf "%s STDERR output:$BOLD$RED KO \n$RESET" "----------"
		if [[ "$@" == '.' ]]; then
			printf $YELLOW"\".\" implementation not required in minishell\n"
			printf "Expected 'command not found' error$RESET\n"
		elif [[ "$@" == *'; .' ]]; then
			printf $YELLOW"\".\" implementation not required in minishell\n"
			printf "Expected 'is a directory' or 'no such file or directory' error$RESET\n"
		fi
		printf "%s STDERR diff$RED Minishell$RESET vs$GREEN Bash$RESET: \n" ">>>"
		diff --color "$M_ERR" "$B_ERR"
		rm -f "$M_ERR" "$M_ERR_CMP" "$B_ERR" "$B_ERR_CMP"
	fi
	if [ $exit_ok -eq 1 ]; then
		printf "%s Exit status:$BOLD$GREEN OK \n$RESET" "----------"
	else
		printf "%s Exit status:$BOLD$RED KO \n$RESET" "----------"
		printf "%s Exit diff$RED Minishell$RESET vs$GREEN Bash$RESET: \n" ">>>"
		diff --color "$M_EXT" "$B_EXT"
		rm -f "$M_EXT" "$B_EXT"
	fi
	printf "$BOLD$RED%s$RESET\n" "----------------------------------------------------------------"
}

function check_output()
{
	check_outfiles
	check_stdout
	check_exit_status
	check_stderr

	if [ $outfile1_ok -ge 1 ] && [ $outfile2_ok -ge 1 ] && [ $stdout_ok -eq 1 ] && [ $stderr_ok -eq 1 ] && [ $exit_ok -eq 1 ]; then
		output_ok "$@"
	else
		check_output_diff "$@"
		if [ $output_diff_ok -ge 1 ]; then
			output_ok_diff "$@"
		else
			output_fail "$@"
		fi
	fi
	reset_comparators
}

function restore_outfiles()
{
	if [ $@ == "M" ]; then
		if test -f "$F_OUT1_M"; then
			rm -f "$F_OUT1"
			mv "$F_OUT1_M" "$F_OUT1"
			rm -f "$F_OUT1_M"
		fi
		if test -f "$F_OUT2_M"; then
			rm -f "$F_OUT2"
			mv "$F_OUT2_M" "$F_OUT2"
			rm -f "$F_OUT2_M"
		fi
	elif [ $@ == "B" ]; then
		if test -f $F_OUT1_B; then
			rm -f "$F_OUT1"
			mv "$F_OUT1_B" "$F_OUT1"
			rm -f "$F_OUT1_B"
		fi
		if test -f $F_OUT2_B; then
			rm -f "$F_OUT2"
			mv "$F_OUT2_B" "$F_OUT2"
			rm -f "$F_OUT2_B"
		fi
	fi
}

function save_outfiles()
{
	if [ $@ == "M" ]; then
		if test -f "$F_OUT1"; then
			mv "$F_OUT1" "$F_OUT1_M"
		fi
		if test -f "$F_OUT2"; then
			mv "$F_OUT2" "$F_OUT2_M"
		fi
	fi
	if [ $@ == "B" ]; then
		if test -f "$F_OUT1"; then
			mv "$F_OUT1" "$F_OUT1_B"
		fi
		if test -f "$F_OUT2"; then
			mv "$F_OUT2" "$F_OUT2_B"
		fi
	fi
}

function debug_print_outfiles()
{
	echo "=============== DEBUG PRINT OUTFILES ================="
	echo "------------ OUTFILE 1 ------------"
	if test -f "$F_OUT1"; then
		cat -e "$F_OUT1"
		echo
		echo "-----------------------------------"
	else
		echo "No outfile1"
		echo "-----------------------------------"
	fi
	echo "------------ OUTFILE 2 ------------"
	if test -f "$F_OUT2"; then
		cat -e "$F_OUT2"
	else
		echo "No outfile2"
		echo "-----------------------------------"
	fi
}

function debug_print_mini_outfiles()
{
	echo "=========== DEBUG PRINT MINI OUTFILES ================"
	echo "------------ OUTFILE 1 ------------"
	if test -f "$F_OUT1_M"; then
		cat -e "$F_OUT1_M"
		echo
		echo "-----------------------------------"
	else
		echo "No minishell outfile1"
		echo "-----------------------------------"
	fi
	if test -f "$F_OUT2_M"; then
		cat -e "$F_OUT2_M"
		echo
		echo "-----------------------------------"
	else
		echo "No minishell outfile2"
		echo "-----------------------------------"
	fi
}

function debug_print_bash_outfiles()
{
	echo "=========== DEBUG PRINT BASH OUTFILES ================"
	echo "------------ OUTFILE 1 ------------"
	if test -f "$F_OUT1_B"; then
		cat -e "$F_OUT1_B"
		echo
		echo "-----------------------------------"
	else
		echo "No bash outfile1"
		echo "-----------------------------------"
	fi
	if test -f "$F_OUT2_B"; then
		cat -e "$F_OUT2_B"
		echo
		echo "-----------------------------------"
	else
		echo "No bash outfile2"
		echo "-----------------------------------"
	fi
}

###################################### Tester function
function exec_test()
{
	restore_outfiles "M"
	./minishell -c "$@" 1>$M_OUT 2>$M_ERR
	echo "$?">$M_EXT
	save_outfiles "M"
	restore_outfiles "B"
	bash -c "$@" 1>$B_OUT 2>$B_ERR
	echo "$?">$B_EXT
	save_outfiles "B"

	check_output "$@"
	test_num+=1
	echo
	sleep 0.1
}

function exec_test_no_env()
{
	restore_outfiles "M"
	env -i ./minishell -c "$@" 1>$M_OUT 2>$M_ERR
	echo "$?">$M_EXT
	save_outfiles "M"
	restore_outfiles "B"
	env -i bash -c "$@" 1>$B_OUT 2>$B_ERR
	echo "$?">$B_EXT
	save_outfiles "B"

	check_output "$@"
	test_num+=1
	echo
	sleep 0.1
}

###################################### Display
function print_h2()
{
	printf	"$BOLD$MAGENTA\n"
	printf	"%s\n\n" "+=============================================================+"
	printf	"%11c%s\n\n" " " "$@"
	printf	"%s\n$RESET" "+=============================================================+"
}

function print_h3()
{
	printf	"$BOLD$YELLOW\n"
	printf	"%s\n" "+=============================================================+"
	printf	"%11c%s\n" " " "$@"
	printf	"%s\n$RESET" "+=============================================================+"
}

################### TEST FUNCTIONS ##################

function test_exec_basic()
{
	print_h3 "BASIC EXECUTION"
	exec_test 'ls'
	exec_test 'ls -la'
	exec_test '/usr/bin/ls'
	exec_test 'usr/bin/ls'
	exec_test './ls'
	exec_test 'hello'
	exec_test '/usr/bin/hello'
	exec_test './hello'
	exec_test '""'
	exec_test '.'
	exec_test '..'
	exec_test '$'
	exec_test './'
	exec_test '../'
	exec_test "./$D_EXISTS"
	exec_test '../fake_dir/'
	exec_test "./$F_EXISTING"
	exec_test './nonexistant_file'
	exec_test "./$F_EXECUTABLE"
	exec_test ".$F_EXECUTABLE"
	exec_test "$F_EXECUTABLE"
}

function test_exec_basic_no_env()
{
	print_h3 "BASIC EXECUTION (no environment)"
	exec_test_no_env 'unset PATH; pwd'
	exec_test_no_env 'unset PATH; echo hello'
	exec_test_no_env 'unset PATH; /usr/bin/ls'
	exec_test_no_env 'unset PATH; usr/bin/ls'
	exec_test_no_env 'unset PATH; ./ls'
	exec_test_no_env 'unset PATH; hello'
	exec_test_no_env 'unset PATH; /usr/bin/hello'
	exec_test_no_env 'unset PATH; ./hello'
	exec_test_no_env 'unset PATH; ""'
	exec_test_no_env 'unset PATH; .'
	exec_test_no_env 'unset PATH; ..'
	exec_test_no_env 'unset PATH; $'
	exec_test_no_env 'unset PATH; ./'
	exec_test_no_env 'unset PATH; ../'
	exec_test_no_env "unset PATH; ./$D_EXISTS"
	exec_test_no_env 'unset PATH; ../fake_dir/'
	exec_test_no_env "unset PATH; ./$F_EXISTING"
	exec_test_no_env 'unset PATH; ./nonexistant_file'
	exec_test_no_env "unset PATH; ./$F_EXECUTABLE"
	exec_test_no_env "unset PATH; .$F_EXECUTABLE"
	exec_test_no_env "unset PATH; $F_EXECUTABLE"
}

function test_pipes()
{
	print_h3 "PIPELINE"
	exec_test 'ls -l | wc -l'
	exec_test "cat $F_IN1 | grep dream"
	exec_test "cat $F_IN1 | grep dream | cat -e"
	exec_test "cat $F_IN1 | grep dream | wc -l"
	exec_test "cat $F_IN1 | grep dream | wc -l | cd x"
	exec_test "cat $F_IN1 | grep dream | wc -l | x"
	exec_test "x | cat $F_IN1 | grep dream | wc -l"
	exec_test "cat $F_IN1 | x | grep dream | wc -l"
	exec_test "cat $F_IN1 | grep dream | x | wc -l"
	exec_test 'cat /dev/random | head -c 100 | wc -c'
	exec_test 'x | x | x | x | x'
	exec_test 'x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x'
	exec_test 'ls | ls | ls'
	exec_test 'ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls'
}

function test_spaces()
{
	print_h3 "SPACES"
	exec_test '""'
	exec_test '"                        "'
	exec_test '						     '
	exec_test "\t\t\t\t\t\t\t\t\t\t      "
	exec_test "\t\n\r\v\f                "
	exec_test "       \t    \t\t\t       "
	exec_test "ls                        "
	exec_test "           ls             "
	exec_test "                        ls"
	exec_test "ls\t\t\t\t\t\t\t\t\t\t\t\t"
	exec_test "\t\t\t\t\t\tls\t\t\t\t\t\t"
	exec_test "\t\t\t\t\t\t\t\t\t\t\t\tls"
	exec_test "\t\t\t\t            \t\tls"
	exec_test "      ls         -l     -a"
	exec_test "\t\tls\t\t\t\t-l\t\t\t\t-a"
	exec_test "\t    ls\t\t  -l -a\t\t   "
}

function test_syntax_quotes()
{
	print_h3 "QUOTE HANDLING"
	exec_test 'ec""ho test'
	exec_test 'ec''ho test'
	exec_test '""echo test'
	exec_test '''echo test'
	exec_test 'echo"" test'
	exec_test 'echo'' test'
	exec_test 'echo "" test'
	exec_test 'echo '' test'
	exec_test 'echo "" "" "" test'
	exec_test 'echo '' '' '' test'
	exec_test 'echo """""" test'
	exec_test 'echo '''''' test'
	exec_test 'echo $USE""R'
	exec_test 'echo $USE''R'
	exec_test 'echo ""$USER'
	exec_test 'echo ''$USER'
	exec_test 'echo "$"USER'
	exec_test 'echo '$'USER'
	exec_test 'echo $""USER'
	exec_test 'echo $''USER'
	exec_test 'echo $USER"" '''
	exec_test "echo \"cat $F_IN1 | cat > $F_OUT1\""
	exec_test "echo 'cat $F_IN1 | cat > $F_OUT1'"
	exec_test 'ls ""'
	exec_test "ls '\""
	exec_test "ls \"\'"
	exec_test 'ls " "'
	exec_test "ls \" ' \""
	exec_test '"ls"'
	exec_test 'l"s"'
}

function test_variable_expansion()
{
	print_h3 "VARIABLE EXPANSION"
	exec_test '$USER'
	exec_test 'ls $HOME'
	exec_test 'echo $'
	exec_test 'echo $$'
	exec_test 'echo $$$'
	exec_test 'echo $USER'
	exec_test 'echo $USE'
	exec_test 'echo $USE_'
	exec_test 'echo "$USER"'
	exec_test "echo '\$USER'"
	exec_test 'echo "|$USER|"'
	exec_test "echo '|\$USER|'"
	exec_test 'echo $USER $USER $USER'
	exec_test 'echo $USER$USER$USER'
	exec_test 'echo "$USER $USER $USER"'
	exec_test 'echo "$USER$USER$USER"'
	exec_test "echo '\$USER \$USER \$USER'"
	exec_test "echo '\$USER\$USER\$USER'"
	exec_test 'echo $USERhello'
	exec_test 'echo hello$USER'
	exec_test 'echo "$USERhello"'
	exec_test 'echo "hello$USER"'
	exec_test "echo '\$USERhello'"
	exec_test "echo 'hello\$USER'"
	exec_test 'echo hello $USER'
	exec_test 'echo hello $NOT_A_VAR $NOT_A_VAR $NOT_A_VAR $USER'
	exec_test 'echo $NOT_A_VAR $NOT_A_VAR $NOT_A_VAR $USER'
	exec_test 'echo hello $NOT_A_VAR $NOT_A_VAR $NOT_A_VAR'
	exec_test 'echo "hello $NOT_A_VAR $NOT_A_VAR $NOT_A_VAR $USER"'
	exec_test 'export ECHO=echo; $ECHO $ECHO'
	exec_test 'export L="ls -la"; $L'
	exec_test "export L='ls -la'; \$L"
}

function test_syntax_errors()
{
	print_h3 "SYNTAX ERROR"
	exec_test '|'
	exec_test '||'
	exec_test '|||'
	exec_test '<'
	exec_test '<<'
	exec_test '<<<<<<'
	exec_test '>'
	exec_test '>>'
	exec_test '>>>'
	exec_test '>>>>>>'
	exec_test 'ls |'
	exec_test 'ls ||'
	exec_test 'ls | |'
	exec_test '| ls'
	exec_test '| ls | cat'
	exec_test 'ls | cat |'
	exec_test 'ls || cat'
	exec_test 'ls | | cat'
	exec_test 'fake_cmd |'
	exec_test '| fake_cmd'
	exec_test 'fake_cmd || ls'
	exec_test 'fake_cmd | | ls'
	exec_test 'ls || fake_cmd'
	exec_test 'ls | | fake_cmd'
	exec_test 'ls >>'
	exec_test 'ls >'
	exec_test 'ls <'
	exec_test 'ls <<'
	exec_test 'ls < |'
	exec_test 'ls << |'
	exec_test 'ls > |'
	exec_test 'ls >> |'
	exec_test 'ls | <'
	exec_test 'ls | <<'
	exec_test 'ls | >'
	exec_test 'ls | >>'
	exec_test 'ls > >'
	exec_test 'ls > >>'
	exec_test 'ls > <'
	exec_test 'ls > <<'
	exec_test 'ls >> >'
	exec_test 'ls >> >>'
	exec_test 'ls >> <'
	exec_test 'ls >> <<'
	exec_test 'ls < >'
	exec_test 'ls < >>'
	exec_test 'ls < <'
	exec_test 'ls < <<'
	exec_test 'ls << >'
	exec_test 'ls << >>'
	exec_test 'ls << <'
	exec_test 'ls << <<'
	exec_test 'ls > >> |'
	exec_test "< < $F_IN1 cat"
	exec_test "<< << $F_IN1 cat"
	exec_test "<< < $F_IN1 cat"
	exec_test "< << $F_IN1 cat"
	exec_test '< $FAKE_VAR cat'
	exec_test 'cat < $FAKE_VAR'
	exec_test 'cat < $123456'
	exec_test '< $USER cat'
	exec_test 'echo hello | ;'
	exec_test 'ls > <'
}

function test_builtin_echo()
{
	print_h3 "ECHO"
	exec_test 'ECHO'
	exec_test 'Echo'
	exec_test 'echo'
	exec_test 'echo hello'
	exec_test 'echo hello'
	exec_test 'echo hello world'
	exec_test 'echo hello      world'
	exec_test 'echo                      hello world'
	exec_test 'echo hello world                '
	exec_test 'echo helololollllolllolol loollolllololllol lllol  looololololollllloooolll'
	exec_test 'echo helololollllolllolol                                 loollolllololllol                   lllol                looololololollllloooolll'
	exec_test 'echo -n'
	exec_test 'echo -n hello world'
	exec_test 'echo hello      world'
	exec_test 'echo                      hello world'
	exec_test 'echo -n hello world                '
	exec_test 'echo -n helololollllolllolol loollolllololllol lllol  looololololollllloooolll'
	exec_test 'echo -n helololollllolllolol                                 loollolllololllol                   lllol                looololololollllloooolll'
	exec_test 'echo hello -n'
	exec_test '             echo                 hello                world'
	exec_test '             echo             -n                  hello               world                       '
	exec_test "echo a '' b '' c '' d"
	exec_test 'echo a "" b "" c "" d'
	exec_test "echo -n a '' b '' c '' d"
	exec_test 'echo -n a "" b "" c "" d'
	exec_test 'echo -nhello world'
	exec_test 'echo -n -n -n hello world'
	exec_test 'echo -n -n -nnnn -nnnnm'
	exec_test 'echo a	-nnnnhello'
	exec_test 'echo -n -nnn hello -n'
	exec_test 'echo a	hello -nhello'
}

function test_builtin_echo_no_env()
{
	print_h3 "ECHO (no environment)"
	exec_test_no_env 'unset PATH; echo hello world'
	exec_test_no_env 'unset PATH; echo $USER'
	exec_test_no_env 'unset PATH; echo $PATH'
}

function test_builtin_env()
{
	print_h3 "ENV"
	exec_test 'ENV | sort | grep -v SHLVL | grep -v _='
	exec_test 'Env | sort | grep -v SHLVL | grep -v _='
	exec_test 'env | sort | grep -v SHLVL | grep -v _='
	exec_test 'env | wc -l'
	exec_test 'env | grep PATH'
}

function test_builtin_env_no_env()
{
	print_h3 "ENV (no environment)"
	exec_test_no_env 'unset PATH; env | grep PATH'
	exec_test_no_env 'unset PATH; env | grep USER'
	exec_test_no_env 'unset PATH; env | grep SHELL'
	exec_test_no_env 'unset PATH; env | grep PWD'
}

function test_builtin_export()
{
	print_h3 "EXPORT"
	exec_test 'EXPORT'
	exec_test 'Export'
	exec_test 'export ""'
	exec_test 'export 42'
	exec_test 'export 42; env | grep 42'
	exec_test 'export ='
	exec_test 'export =; env | grep = | wc -l'
	exec_test 'export A'
	exec_test 'export A=; echo $A'
	exec_test 'export A=a; echo $A'
	exec_test 'export A=a B=b C=c; echo $A$B$C'
	exec_test 'export A=a B=b C=c; export A=c B=a C=b; echo $A$B$C'
	exec_test 'export A=a B=b C=c D=d E=e F=f G=g H=h I=i J=j K=k L=l M=m N=n O=o P=p Q=q R=r S=s T=t U=u V=v W=w X=x Y=y Z=z; echo $A$B$C$D$E$F$G$H$I$J$K$L$M$N$O$P$Q$R$S$T$U$V$W$X$Y$Z'
	exec_test 'export A==a; echo $A'
	exec_test 'export A===a; echo $A'
	exec_test 'export A====a; echo $A'
	exec_test 'export A=====a; echo $A'
	exec_test 'export A======a; echo $A'
	exec_test 'export A=a=a=a=a=a; echo $A'
	exec_test 'export HELLOWORLD=a; echo $HELLOWORLD'
	exec_test 'export helloworld=a; echo $helloworld'
	exec_test 'export hello_world=a; echo $hello_world'
	exec_test 'export HELLOWORLD1=a; echo $HELLOWORLD1'
	exec_test 'export H1ELL_0_W123Orld_a=a; echo $H1ELL_0_W123Orld_a'
	exec_test 'export a0123456789=a; echo $a0123456789'
	exec_test 'export abcdefghijklmnopqrstuvwxyz=a; echo $abcdefghijklmnopqrstuvwxyz'
	exec_test 'export __________________________=a; echo $__________________________'
	exec_test 'export _hello_=a; echo $_hello_'
	exec_test 'export 1'
	exec_test 'export 1='
	exec_test 'export 1=a'
	exec_test 'export HELLOWORLD =a'
	exec_test 'export HELLOWORLD= a'
	exec_test "export HELLO\'WORLD\'=a"
	exec_test "export HELLO\"WORLD\"=a"
	exec_test "export HELLO\$WORLD=a"
	exec_test "export HELLO_WORLD=a"
	exec_test "export A='hello this world is wonderful'; echo \$A"
	exec_test "export A=\"hello this world is wonderful\"; echo \$A"
	exec_test "export A 'asdf ' B ' asdf asdf asd f' ' asdf ' '' 'asdf ' C; echo \$A\$B\$C"
	exec_test "export 'asdf ' B ' asdf asdf asd f' ' asdf ' '' 'asdf ' C; echo \$A\$B\$C"
	exec_test "export A 'asdf ' B ' asdf asdf asd f' ' asdf ' '' 'asdf '; echo \$A\$B\$C"
	exec_test "export A B C; echo \$A\$B\$C"
	exec_test "export 'HELLO@'=hello"
	exec_test "export \"HELLO'\"=hello"
	exec_test "export 'HELLO\"'=hello"
	exec_test "export 'HELLO$'=hello"
	exec_test "export 'HELLO!'=hello"
	exec_test "export 'HELLO|'=hello"
	exec_test "export 'HELLO&'=hello"
	exec_test "export 'HELLO\\'=hello"
	exec_test 'export ALPHA="abc def ghi"; echo $ALPHA'
	exec_test "export ALPHA='abc def ghi'; echo \$ALPHA"
	exec_test 'export DIGITS="0 1 2 3 4 5 6 7 8 9"; echo $DIGITS'
	exec_test "export DIGITS='0 1 2 3 4 5 6 7 8 9'; echo \$DIGITS"
	exec_test 'export DIGITS=0 1 2 3 4 5 6 7 8 9; echo $DIGITS'
}

function test_builtin_export_no_env()
{
	print_h3 "EXPORT (no environment)"
	exec_test_no_env 'unset PATH; export hello=42'
	exec_test_no_env 'unset PATH; export 42=hello'
	exec_test_no_env 'unset PATH; export hello=42; echo $hello'
	exec_test_no_env 'unset PATH; export PATH=/usr/bin:/sbin/; ls'
}

function test_builtin_unset()
{
	print_h3 "UNSET"
	exec_test 'UNSET'
	exec_test 'Unset'
	exec_test 'unset'
	exec_test 'unset PATH'
	exec_test 'unset PATH USER; echo $PATH; echo $USER'
	exec_test 'unset PATH; echo $PATH'
	exec_test 'unset PATH; ls'
	exec_test 'unset NOT_A_VAR'
	exec_test 'unset ""'
	exec_test "unset ''"
	exec_test 'export A=a; unset A; echo $A'
	exec_test 'export A=a A2=a; unset A; echo $A $A2'
	exec_test "export A=a; unset 'A '; echo \$A"
	exec_test "export A=a; unset A=; echo \$A"
	exec_test "export A=a; unset 'A='; echo \$A"
	exec_test 'export A=a B=b C=c; unset A B C; echo $A$B$C'
	exec_test "export A=a B=b C=c; unset A 'asdf ' B ' asdf asdf asd f' ' asdf ' '' 'asdf ' C"
	exec_test "export A=a B=b C=c; unset A 'asdf ' B ' asdf asdf asd f' ' asdf ' '' 'asdf ' C; echo \$A\$B\$C"
	exec_test "export A=a B=b C=c; unset 'asdf ' B ' asdf asdf asd f' ' asdf ' '' 'asdf ' C"
	exec_test "export A=a B=b C=c; unset 'asdf ' B ' asdf asdf asd f' ' asdf ' '' 'asdf ' C; echo \$A\$B\$C"
	exec_test "export A=a B=b C=c; unset A 'asdf ' B ' asdf asdf asd f' ' asdf ' '' 'asdf '"
	exec_test "export A=a B=b C=c; unset A 'asdf ' B ' asdf asdf asd f' ' asdf ' '' 'asdf '; echo \$A\$B\$C"
	exec_test 'export A=a B=b C=c; unset A'
	exec_test 'export A=a B=b C=c; unset A; echo $A$B$C'
	exec_test 'export A=a B=b C=c; unset B'
	exec_test 'export A=a B=b C=c; unset B; echo $A$B$C'
	exec_test 'export A=a B=b C=c; unset C'
	exec_test 'export A=a B=b C=c; unset C; echo $A$B$C'
	exec_test "unset 'HELLO@'"
	exec_test "unset \"HELLO'\""
	exec_test "unset 'HELLO\"'"
	exec_test "unset 'HELLO$'"
	exec_test "unset 'HELLO!'"
	exec_test "unset 'HELLO|'"
	exec_test "unset 'HELLO&'"
	exec_test "unset 'HELLO\\'"
}

function test_builtin_unset_no_env()
{
	print_h3 "UNSET (no environment)"
	exec_test_no_env 'unset PATH'
	exec_test_no_env 'unset PATH; export hello=42; unset hello'
	exec_test_no_env 'unset PATH; export hello=42; unset hello; echo $hello'
	exec_test_no_env 'unset PATH; unset USER'
}

function test_builtin_pwd()
{
	print_h3 "PWD"
	exec_test 'PWD'
	exec_test 'Pwd'
	exec_test 'pwd'
	exec_test 'pwd | cat -e'	
	exec_test 'pwd hello'
	exec_test 'pwd 123'
	exec_test 'pwd 1 2 x 3 hello'
	exec_test 'pwd .'
	exec_test 'pwd ..'
	exec_test 'unset PWD; pwd | cat -e'
	exec_test 'unset OLDPWD; pwd | cat -e'
	exec_test 'unset PWD OLDPWD; pwd | cat -e'
	exec_test "export PWD='hello/world'; pwd | cat -e"
	exec_test "export PWD='/hello/world/'; pwd | cat -e"
	exec_test "export PWD='/usr/bin/'; pwd | cat -e"
	exec_test "export OLDPWD=abc/def; pwd | cat -e"
	exec_test "export PWD=hello/world OLDPWD=abc/def; pwd | cat -e"
	exec_test 'mkdir a a/b; cd a/b; rm -rf ../../a; pwd'
}

function test_builtin_pwd_no_env()
{
	print_h3 "PWD (no environment)"
	exec_test_no_env 'unset PATH; pwd'
	exec_test_no_env 'unset PATH; pwd'
	exec_test_no_env 'unset PATH; unset PWD; pwd'
	exec_test_no_env 'unset PATH; unset OLDPWD; pwd'
	exec_test_no_env 'unset PATH; unset PWD OLDPWD; pwd'
	exec_test_no_env "unset PATH; export PWD='hello/world'; pwd"
	exec_test_no_env "unset PATH; export PWD='/hello/world/'; pwd"
	exec_test_no_env "unset PATH; export PWD='/usr/bin/'; pwd"
}

function test_builtin_cd()
{
	print_h3 "CD"
	exec_test 'CD'
	exec_test 'CD; pwd'
	exec_test 'Cd'
	exec_test 'Cd; pwd'
	exec_test 'cd'
	exec_test 'cd; pwd'
	exec_test 'cd .'
	exec_test 'cd .; pwd'
	exec_test 'cd ..'
	exec_test 'cd ..; pwd'
	exec_test "cd $D_EXISTS"
	exec_test "cd $D_EXISTS; pwd"
	exec_test 'cd /dev'
	exec_test 'cd /dev; pwd'
	exec_test 'cd /Users'
	exec_test 'cd /Users; pwd'
	exec_test 'cd fake_dir'
	exec_test 'cd fake_dir; pwd'
	exec_test "cd $D_FORBIDDEN"
	exec_test "cd $D_FORBIDDEN; pwd"
	exec_test "cd $F_EXISTING"
	exec_test "cd $F_EXISTING; pwd"
	exec_test "cd $F_FORBIDDEN"
	exec_test "cd $F_FORBIDDEN; pwd"
	exec_test 'cd ../../../../../../../../../../../../../../../../../../../../../../'
	exec_test 'cd ../../../../../../../../../../../../../../../../../../../../../../; pwd'
	exec_test 'cd $HOME'
	exec_test 'cd $HOME; pwd'
	exec_test 'unset HOME; cd $HOME'
	exec_test 'unset HOME; cd $HOME; pwd'
	exec_test 'unset HOME; cd'
	exec_test 'unset HOME; cd; pwd'
	exec_test 'mkdir a a/b; cd a/b; rm -rf ../../a; cd ..'
	exec_test 'mkdir a a/b; cd a/b; rm -rf ../../a; unset PWD OLDPWD; cd ..'
}

function test_builtin_cd_no_env()
{
	print_h3 "CD (no environment)"
	exec_test_no_env 'unset PATH; cd'
	exec_test_no_env 'unset PATH; cd; pwd'
	exec_test_no_env 'unset PATH; cd .'
	exec_test_no_env 'unset PATH; cd .; pwd'
	exec_test_no_env 'unset PATH; cd ..'
	exec_test_no_env 'unset PATH; cd ..; pwd'
	exec_test_no_env "unset PATH; cd $D_EXISTS"
	exec_test_no_env "unset PATH; cd $D_EXISTS; pwd"
	exec_test_no_env 'unset PATH; cd /dev'
	exec_test_no_env 'unset PATH; cd /dev; pwd'
	exec_test_no_env 'unset PATH; cd /Users'
	exec_test_no_env 'unset PATH; cd /Users; pwd'
	exec_test_no_env 'unset PATH; cd fake_dir'
	exec_test_no_env 'unset PATH; cd fake_dir; pwd'
	exec_test_no_env "unset PATH; cd $D_FORBIDDEN"
	exec_test_no_env "unset PATH; cd $D_FORBIDDEN; pwd"
	exec_test_no_env "unset PATH; cd $F_EXISTING"
	exec_test_no_env "unset PATH; cd $F_EXISTING; pwd"
	exec_test_no_env "unset PATH; cd $F_FORBIDDEN"
	exec_test_no_env "unset PATH; cd $F_FORBIDDEN; pwd"
	exec_test_no_env 'unset PATH; cd $HOME'
	exec_test_no_env 'unset PATH; cd $HOME; pwd'
	exec_test_no_env 'unset PATH; unset HOME; cd $HOME'
	exec_test_no_env 'unset PATH; unset HOME; cd $HOME; pwd'
	exec_test_no_env 'unset PATH; unset HOME; cd'
	exec_test_no_env 'unset PATH; unset HOME; cd; pwd'
}

function test_builtin_exit()
{
	print_h3 "EXIT"
	exec_test 'exit'
	exec_test 'Exit'
	exec_test 'EXIT'
	exec_test 'exit 42'
	exec_test 'exit 42; echo "Should have exited."'
	exec_test 'exit 240'
	exec_test 'exit +42'
	exec_test 'exit -42'
	exec_test 'exit 00000000000000000000000000000000000000000000001'
	exec_test 'exit 00000000000000000000000000000000000000000000000'
	exec_test 'exit -00000000000000000000000000000000000000000000001'
	exec_test 'exit -00000000000000000000000000000000000000000000000'
	exec_test 'exit abc'
	exec_test 'exit abc; echo "Should have exited."'
	exec_test 'exit --42'
	exec_test 'exit ++42'
	exec_test 'exit - 42'
	exec_test 'exit + 42'
	exec_test 'exit "0"'
	exec_test "exit '0'"
	exec_test 'exit ""'
	exec_test "exit ''"
	exec_test 'exit " "'
	exec_test "exit ' '"
	exec_test "exit ' 5'"
	exec_test "exit '\t5'"
	exec_test "exit '\t\f\r5'"
	exec_test "exit '5 '"
	exec_test "exit '5\t'"
	exec_test "exit '5\t\f\r'"
	exec_test "exit '5     x'"
	exec_test "exit '5\t\t\tx'"
	exec_test 'exit 42 41'
	exec_test 'exit 42 abc'
	exec_test 'exit abc 42'
	exec_test 'exit 2147483647'
	exec_test 'exit 2147483648'
	exec_test 'exit -2147483648'
	exec_test 'exit -2147483649'
	exec_test 'exit 9223372036854775807'
	exec_test 'exit -9223372036854775808'
	exec_test 'exit 9223372036854775808'
	exec_test 'exit -9223372036854775810'
	exec_test 'exit 9999999999999999999999999999999999999999999999'
	exec_test 'exit -9999999999999999999999999999999999999999999999'
	exec_test 'exit _0'
	exec_test 'exit 0_'
	exec_test "exit 5 < $F_IN1"
	exec_test 'exit 1 | exit 0'
	exec_test 'exit 0 | exit 1'
	exec_test 'ls | exit'
	exec_test 'ls | exit 42'
	exec_test 'ls | exit 12 abc'
	exec_test 'ls | exit abc 12'
	exec_test 'exit | ls'
	exec_test 'exit 42 | ls'
	exec_test 'exit 12 abc | ls'
	exec_test 'exit abc 12 | ls'
	#exec_test "ls > file | exit"
	#exec_test "ls -l > x | exit | wc -l"
}

function test_builtin_exit_no_env()
{
	print_h3 "EXIT (no environment)"
	exec_test_no_env 'unset PATH; exit'
	exec_test_no_env 'unset PATH; exit 42'
	exec_test_no_env 'unset PATH; exit 42; echo "Should have exited."'
	exec_test_no_env 'unset PATH; exit +42'
	exec_test_no_env 'unset PATH; exit -42'
	exec_test_no_env 'unset PATH; exit 00000000000000000000000000000000000000000000001'
	exec_test_no_env 'unset PATH; exit 00000000000000000000000000000000000000000000000'
	exec_test_no_env 'unset PATH; exit abc'
	exec_test_no_env 'unset PATH; exit abc; echo "Should have exited."'
	exec_test_no_env 'unset PATH; exit --42'
	exec_test_no_env 'unset PATH; exit ++42'
	exec_test_no_env 'unset PATH; exit - 42'
	exec_test_no_env 'unset PATH; exit + 42'
	exec_test_no_env 'unset PATH; exit 9999999999999999999999999999999999999999999999'
	exec_test_no_env 'unset PATH; exit -9999999999999999999999999999999999999999999999'
}

function test_redir_infile()
{
	print_h3 "INFILE"
	exec_test "< $F_IN1 cat"
	exec_test "<$F_IN1 cat"
	exec_test "cat < $F_IN1"
	exec_test "cat <$F_IN1"
	exec_test "< $F_IN1; echo \$?"
	exec_test "< $F_DOES_NOT_EXIST"
	exec_test "< $F_FORBIDDEN"
	exec_test 'cat <'
	exec_test "cat < $F_DOES_NOT_EXIST"
	exec_test "cat < $F_DOES_NOT_EXIST"
	exec_test "< $F_DOES_NOT_EXIST cat"
	exec_test "<$F_DOES_NOT_EXIST cat"
	exec_test "cat < $F_FORBIDDEN"
	exec_test "cat <$F_FORBIDDEN"
	exec_test "< $F_FORBIDDEN cat"
	exec_test "<$F_FORBIDDEN cat"
	exec_test "< $F_DOES_NOT_EXIST < $F_IN1 cat"
	exec_test "cat < $F_IN1 < $F_DOES_NOT_EXIST"
	exec_test "cat < $F_IN1 < $F_IN1 < $F_IN1"
	exec_test "cat < $F_IN1 <"
	exec_test "cat < $F_IN1 < $F_IN2"
	exec_test "<$F_IN1 cat < $F_IN2"
	exec_test "cat << < $F_IN1"
	exec_test "cat << << $F_IN1"
	exec_test "cat <<<< $F_IN1"
	exec_test "cat < $F_FORBIDDEN < $F_IN1"
	exec_test "cat < $F_IN1 < $F_FORBIDDEN"
	exec_test "cat < $F_FORBIDDEN | cat < $F_IN1"
	exec_test "cat < $F_IN1 | cat < $F_FORBIDDEN"
}

function test_redir_outfile_trunc()
{
	print_h3 "TRUNC OUTFILE"
	exec_test "> $F_OUT1; echo \$?"
	remove_outfiles
	exec_test "> $F_FORBIDDEN; echo \$?"
	exec_test "echo hello world >"
	exec_test "echo hello world > $F_OUT1"
	exec_test "echo abcdefghijk >$F_OUT1"
	exec_test "echo hello world> $F_OUT1"
	exec_test "> $F_OUT1 echo abcdefghijk"
	exec_test ">$F_OUT1 echo hello world"
	remove_outfiles
	exec_test "echo hello world > $F_FORBIDDEN"
	exec_test "> $F_OUT1 echo hi | echo bye"
	exec_test "echo ab | echo cde > $F_OUT1"
	exec_test "cat $F_IN1 > $F_OUT1"
	exec_test "cat $F_IN1 | wc -l > $F_OUT1"
	exec_test "cat $F_IN1 | grep dream | sed s/e/../g | sed s/d/X/g > $F_OUT1"
	exec_test "echo abcdefghijk > $F_OUT1 > $F_OUT2"
	exec_test "echo hello world > $F_OUT1 > $F_OUT1"
	exec_test "echo hello world > $F_OUT1 > $F_OUT1 > $F_OUT1 > $F_OUT1 > $F_OUT1 > $F_OUT1"
	exec_test "echo hello world > $F_OUT1 > $F_OUT1 > $F_OUT1 > $F_OUT1 > $F_OUT1 > $F_OUT2"
	remove_outfiles
	exec_test "echo abcdefghijk > $F_FORBIDDEN > $F_OUT1 > $F_OUT2"
	remove_outfiles
	exec_test "echo abcdefghijk > $F_OUT1 > $F_FORBIDDEN > $F_OUT2"
	remove_outfiles
	exec_test "echo abcdefghijk > $F_OUT1 > $F_OUT2 > $F_FORBIDDEN"
	exec_test "echo > $F_OUT1 a b c d e"
	exec_test "echo a > $F_OUT1 b c d e"
	exec_test "echo a b > $F_OUT1 c d e"
	exec_test "echo a b c > $F_OUT1 d e"
	exec_test "echo a b c d > $F_OUT1 e"
	exec_test "echo a b c d e > $F_OUT1"
	exec_test "echo > $F_OUT1 a b c d e > $F_OUT2"
	exec_test "echo a > $F_OUT1 b c d e > $F_OUT2"
	exec_test "echo a b > $F_OUT1 c d e > $F_OUT2"
	exec_test "echo a b c > $F_OUT1 d e > $F_OUT2"
	exec_test "echo a b c d > $F_OUT1 e > $F_OUT2"
	exec_test "echo a b c d e > $F_OUT1 > $F_OUT2"
	exec_test "echo hello > $F_OUT1 | echo world > $F_OUT1"
	exec_test "echo 01234 > $F_OUT1 | echo 56789 > $F_OUT2"
	remove_outfiles
	exec_test "echo hello > $F_OUT1 | echo world > $F_FORBIDDEN"
	remove_outfiles
	exec_test "echo 01234 > $F_FORBIDDEN | echo 56789 > $F_OUT1"
	remove_outfiles
}

function test_redir_outfile_append()
{
	print_h3 "APPEND OUTFILE"
	exec_test ">> $F_OUT1; echo \$?"
	remove_outfiles
	exec_test ">> $F_FORBIDDEN; echo \$?"
	exec_test "echo hello world >>"
	exec_test "echo hello world >> $F_OUT1"
	exec_test "echo abcdefghijk >>$F_OUT1"
	exec_test "echo hello world>> $F_OUT1"
	exec_test ">> $F_OUT1 echo abcdefghijk"
	exec_test ">>$F_OUT1 echo hello world"
	remove_outfiles
	exec_test "echo hello world >> $F_FORBIDDEN"
	exec_test ">> $F_OUT1 echo hi | echo bye"
	exec_test "echo ab | echo cde >> $F_OUT1"
	exec_test "cat $F_IN1 >> $F_OUT1"
	exec_test "cat $F_IN1 | wc -l >> $F_OUT1"
	exec_test "cat $F_IN1 | grep dream | sed s/e/../g | sed s/d/X/g >> $F_OUT1"
	exec_test "echo abcdefghijk >> $F_OUT1 >> $F_OUT2"
	exec_test "echo hello world >> $F_OUT1 >> $F_OUT1"
	exec_test "echo hello world >> $F_OUT1 >> $F_OUT1 >> $F_OUT1 >> $F_OUT1 >> $F_OUT1 >> $F_OUT1"
	exec_test "echo hello world >> $F_OUT1 >> $F_OUT1 >> $F_OUT1 >> $F_OUT1 >> $F_OUT1 >> $F_OUT2"
	remove_outfiles
	exec_test "echo abcdefghijk >> $F_FORBIDDEN >> $F_OUT1 >> $F_OUT2"
	remove_outfiles
	exec_test "echo abcdefghijk >> $F_OUT1 >> $F_FORBIDDEN >> $F_OUT2"
	remove_outfiles
	exec_test "echo abcdefghijk >> $F_OUT1 >> $F_OUT2 >> $F_FORBIDDEN"
	remove_outfiles
	exec_test "echo >> $F_OUT1 a b c d e"
	exec_test "echo a >> $F_OUT1 b c d e"
	exec_test "echo a b >> $F_OUT1 c d e"
	exec_test "echo a b c >> $F_OUT1 d e"
	exec_test "echo a b c d >> $F_OUT1 e"
	exec_test "echo a b c d e >> $F_OUT1"
	remove_outfiles
	exec_test "echo >> $F_OUT1 a b c d e >> $F_OUT2"
	exec_test "echo a >> $F_OUT1 b c d e >> $F_OUT2"
	exec_test "echo a b >> $F_OUT1 c d e >> $F_OUT2"
	exec_test "echo a b c >> $F_OUT1 d e >> $F_OUT2"
	exec_test "echo a b c d >> $F_OUT1 e >> $F_OUT2"
	exec_test "echo a b c d e >> $F_OUT1 >> $F_OUT2"
	remove_outfiles
	exec_test "echo hello >> $F_OUT1 | echo world >> $F_OUT1"
	exec_test "echo 01234 >> $F_OUT1 | echo 56789 >> $F_OUT2"
	remove_outfiles
	exec_test "echo hello >> $F_OUT1 | echo world >> $F_FORBIDDEN"
	remove_outfiles
	exec_test "echo 01234 >> $F_FORBIDDEN | echo 56789 >> $F_OUT1"
	remove_outfiles
}

function test_redir_all()
{
	print_h3 "COMBINATION INFILE/OUTFILE"
	exec_test "< >> >"
	exec_test "< > >>"
	exec_test "> < >>"
	exec_test "> >> <"
	exec_test ">> > <"
	exec_test ">> < >"
	exec_test "echo ABC > $F_OUT1 | echo DEF >> $F_OUT2"
	exec_test "echo GHI >> $F_OUT1 | echo KLM > $F_OUT2"
	exec_test "echo OPQ > $F_OUT1 >> $F_OUT2"
	exec_test "echo RST >> $F_OUT1 > $F_OUT2"
	exec_test "< $F_IN1 cat | echo UVW > $F_OUT1 | echo XYZ >> $F_OUT2"
	exec_test "< $F_IN1 cat > $F_OUT1 | echo ABC >> $F_OUT1 | echo DEF > $F_OUT2"
	exec_test "cat < $F_OUT1 >"
	exec_test "cat < $F_OUT1 >>"
	exec_test "cat < > $F_OUT1"
	exec_test "cat < >> $F_OUT1"
	exec_test "cat > >> $F_OUT1"
	exec_test "cat >> > $F_OUT1"
	exec_test "< $F_OUT1 cat > $F_OUT1"
	exec_test "< $F_OUT1 cat >> $F_OUT1"
	exec_test "cat > $F_OUT1 < $F_OUT1"
	exec_test "cat >> $F_OUT1 < $F_OUT1"
	exec_test "cat < $F_OUT1 > $F_OUT1"
	exec_test "cat < $F_OUT1 >> $F_OUT1"
	exec_test "< $F_IN1 < $F_IN2 cat > $F_OUT1 >> $F_OUT2"
	exec_test "< $F_IN1 < $F_IN2 cat >> $F_OUT1 > $F_OUT2"
	exec_test "< $F_FORBIDDEN < $F_IN2 cat > $F_OUT1 >> $F_OUT2"
	exec_test "< $F_IN1 < $F_FORBIDDEN cat > $F_OUT1 >> $F_OUT2"
	exec_test "< $F_IN1 < $F_IN2 cat > $F_FORBIDDEN >> $F_OUT1"
	exec_test "< $F_IN2 < $F_IN1 cat > $F_OUT1 >> $F_FORBIDDEN"
	exec_test "< $F_IN1 < $F_IN2 cat >> $F_FORBIDDEN > $F_OUT1"
	exec_test "< $F_IN2 < $F_IN1 cat >> $F_OUT1 > $F_FORBIDDEN"
	exec_test "< $F_FORBIDDEN cat > $F_FORBIDDEN >> $F_FORBIDDEN"
	exec_test "< $F_FORBIDDEN cat >> $F_FORBIDDEN > $F_FORBIDDEN"
	exec_test "cat >> $F_FORBIDDEN > $F_FORBIDDEN < $F_FORBIDDEN"
	exec_test "< $F_IN1 cat | grep dream > $F_FORBIDDEN"
	exec_test "< $F_IN2 cat | grep dream >> $F_FORBIDDEN"
	exec_test "< $F_IN1 cat >> $F_FORBIDDEN | wc -l > $F_OUT1"
	exec_test "< $F_IN2 cat > $F_FORBIDDEN | wc -l >> $F_OUT1"
	exec_test "< $F_IN1 cat >> $F_OUT1 | wc -l > $F_FORBIDDEN"
	exec_test "< $F_IN2 cat > $F_OUT1 | wc -l >> $F_FORBIDDEN"
	remove_outfiles
}

function test_exit_status()
{
	print_h3 "EXIT_STATUS"
	exec_test 'echo $?'
	exec_test 'echo; echo $?'
	exec_test '$?'
	exec_test '$? + $?'
	exec_test '$?; echo $?'
	exec_test 'fakecmd; echo $?'
	exec_test "cat < $F_DOES_NOT_EXIST; echo \$?"
	exec_test "cat < $F_FORBIDDEN; echo \$?"
	exec_test "./$F_FORBIDDEN; echo \$?"
	exec_test "cd $D_EXISTS; echo \$?" 
	exec_test "cd $D_FORBIDDEN; echo \$?"
	exec_test "cd dir_does_not_exist; echo \$?"
	exec_test "cd $F_DOES_NOT_EXIST; echo \$?"
	exec_test "cd $F_IN1; echo \$?"
	exec_test "ls dir_does_not_exist; echo \$?"
}

#################### BEGIN TESTS ####################
remove_test_files
remove_outfiles
printf "$BOLD$MAGENTA"
printf	"%s\n"				"----------------------------------------------------------------"
printf	"%s\n"				"	 _   _  _  _  _  _  ___  ___  __  ___  ___  ___ "
printf	"%s\n"				'	| \_/ || || \| || ||_ _|| __|/ _||_ _|| __|| o \'
printf	"%s\n"				'	| \_/ || || \\ || | | | | _| \_ \ | | | _| |   /'
printf	$RESET$BYELLOW"%s\n" '	|_| |_||_||_|\_||_| |_| |___||__/ |_| |___||_|\\'
printf	"%s\n"				"----------------------------------------------------------------"
printf "$RESET"
echo

# Compile and set executable rights
printf $CYAN"Making minishell...$RED\n"
make -C "$MINISHELL_PATH" >/dev/null
if [ $? -eq 0 ]; then
   printf $RESET$GREEN"Minishell ready.\n"$RESET
else
	printf $RESET$RED"Minishell compilation failed.\n"$RESET
	exit 1
fi
cp "$MINISHELL_PATH$MINISHELL_NAME" .
chmod 755 minishell

create_test_files

print_h2 "BASIC EXECUTION TESTS"
#################################### BASIC EXEC
test_exec_basic
#################################### PIPES
test_pipes

print_h2 "PARSING & SYNTAX TESTS"
#################################### SPACES
test_spaces
#################################### QUOTES
test_syntax_quotes
#################################### SYNTAX ERRORS
test_syntax_errors

print_h2 "BUILTIN TESTS"
#################################### ECHO
test_builtin_echo
#################################### ENV
test_builtin_env
#################################### EXPORT
test_builtin_export
#################################### UNSET
test_builtin_unset
#################################### PWD
test_builtin_pwd
#################################### CD
test_builtin_cd
#################################### EXIT
test_builtin_exit

print_h2 "VARIABLE EXPANSION TESTS"
#################################### VARIABLE EXPANSION
test_variable_expansion


print_h2 "REDIRECTION TESTS"
#################################### INFILES
test_redir_infile
#################################### OUTFILES TRUNC
test_redir_outfile_trunc
#################################### OUTFILES APPEND
test_redir_outfile_append
#################################### FILES
test_redir_all


print_h2 "EXIT STATUS TESTS"
#################################### EXIT STATUS
test_exit_status

print_h2 "NO ENVIRONMENT TESTS"
#################################### BASIC EXEC
test_exec_basic_no_env
#################################### ECHO
test_builtin_echo_no_env
#################################### ENV
test_builtin_env_no_env
#################################### EXPORT
test_builtin_export_no_env
#################################### UNSET
test_builtin_unset_no_env
#################################### PWD
test_builtin_pwd_no_env
#################################### CD
test_builtin_cd_no_env
#################################### EXIT
test_builtin_exit_no_env

print_h2 "RESULTS"
test_num+=1
printf $BOLD$GREEN"\tOK$RED\t\tKO$RESET$BOLD\t\tTOTAL\n$RESET"
printf $BOLD$GREEN"\t%d$RED\t\t%d$RESET$BOLD\t\t%d\n$RESET" $tests_passed $tests_failed $test_num

print_h2 "NOTICE"
printf "This tester does not test for memory leaks.\n"
printf "Some tests still need to be done manually, particularly for:\n\t* 'ctrl-c',\n\t* 'ctrl-\',\n\t* 'ctrl-D',\n\t* << (heredoc)\n"
remove_test_files
remove_outfiles
rm -f "./$MINISHELL_NAME"
