#!bin/bash
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
M_OUT="./minitests/minishell_out"
M_ERR="./minitests/minishell_err"
M_ERR_CMP="./minitests/minishell_err_cmp"
M_EXT="./minitests/minishell_exit"

B_OUT="./minitests/bash_out"
B_ERR="./minitests/bash_err"
B_ERR_CMP="./minitests/bash_err_cmp"
B_EXT="./minitests/bash_exit"

F_EXISTING="existing_file"
F_TEST="test_file.txt"
F_TEST_2="test_file_2.txt"
F_TEST_OUT="outfile"
F_TEST_OUT_M="outfile_minishell"
F_TEST_OUT="outfile_2"
F_TEST_OUT_M="outfile_2_minishell"
F_EXECUTABLE="executable_file"
F_FORBIDDEN="forbidden"
D_EXISTS="existing_dir"

#################### TEST COUNT ####################
declare -i test_num=0
declare -i total_tests=0
declare -i tests_passed=0
declare -i tests_failed=0

################ TESTING FUNCTIONS #################
function create_test_files()
{
	printf $CYAN"Creating test files...\n$RESET"
	mkdir -p minitests
	echo "This file exists and has normal permissions" > "$F_EXISTING"
	echo -e "Take this kiss upon the brow!\nAnd, in parting from you now,\nThus much let me avow-\nYou are not wrong, who deem\nThat my days have been a dream;\nYet if hope has flown away\nIn a night, or in a day,\nIn a vision, or in none,\nIs it therefore the less gone?\nAll that we see or seem\nIs but a dream within a dream.\n\nI stand amid the roar\nOf a surf-tormented shore,\nAnd I hold within my hand\nGrains of the golden sand-\nHow few! yet how they creep\nThrough my fingers to the deep,\nWhile I weep- while I weep!\nO God! can I not grasp\nThem with a tighter clasp?\nO God! can I not save\nOne from the pitiless wave?\nIs all that we see or seem\nBut a dream within a dream?\n\nEdgar Allan Poe\nA Dream Within a Dream" > "$F_TEST"
	man bash > "$F_TEST_2"
	mkdir -p $D_EXISTS
	echo -e "#!/bin/bash\nprintf \"hello world\"" > "$F_EXECUTABLE"
	chmod 755 "$F_EXECUTABLE"
	echo "This file is forbidden" > "$F_FORBIDDEN"
	chmod 000 "$F_FORBIDDEN"
	printf $GREEN"Test files created.\n$RESET"
}

function remove_test_files()
{
	rm -rf minitests $F_TEST $F_EXISTING $F_EXECUTABLE $F_FORBIDDEN $D_EXISTS
}

function remove_outfiles()
{
	rm $F_TEST_OUT $F_TEST_OUT_BACKUP
}

function check_outfile()
{
	if cmp -s "$F_TEST_OUT_M" "$F_TEST_OUT"; then
		printf "%s Outfile:$BOLD$GREEN OK \n$RESET" "----------"
	else
		printf "%s Outfile:$BOLD$RED KO \n$RESET" "----------"
		printf "%s Outfile diff$RED Minishell$RESET vs$GREEN Bash$RESET: \n" ">>>"
		diff --color "$F_TEST_OUT_M" "$F_TEST_OUT"
		rm "$F_TEST_OUT" "$F_TEST_OUT"
	fi
}

function output_ok()
{
	printf "$BOLD$GREEN%s$RESET" "[OK] "
	printf "$CYAN [$@] $RESET"
	tests_passed+=1
}

function output_ok_diff()
{
	printf "$BOLD$YELLOW%s$RESET" "[OK] "
	printf "$CYAN [$@] $RESET"
	tests_passed+=1
	echo
	printf "%s Output differs from Bash:$YELLOW OK" "----------"
	if [[ "$@" == *'||'* ]]; then
		printf ": minishell does not implement \"||\""
	elif [[ "$@" == *';'* ]]; then
		printf ": minishell does not implement \";\""
	fi
	printf "$RESET"
}

function output_fail()
{
	printf "$BOLD$RED%s$RESET" "[KO] "
	printf "$CYAN [$@] $RESET"
	tests_failed+=1
	echo
	if cmp -s "$M_OUT" "$B_OUT"; then
		printf "%s STDOUT output:$BOLD$GREEN OK \n$RESET" "----------"
	else
		printf "%s STDOUT output:$BOLD$RED KO \n$RESET" "----------"
		printf "%s STDOUT diff$RED Minishell$RESET vs$GREEN Bash$RESET: \n" ">>>"
		diff --color "$M_OUT" "$B_OUT"
		rm "$M_OUT" "$B_OUT"
	fi
	if cmp -s "$M_ERR_CMP" "$B_ERR_CMP"; then
		printf "%s STDERR output:$BOLD$GREEN OK \n$RESET" "----------"
	else
		printf "%s STDERR output:$BOLD$RED KO \n$RESET" "----------"
		printf "%s STDERR diff$RED Minishell$RESET vs$GREEN Bash$RESET: \n" ">>>"
		diff --color "$M_ERR" "$B_ERR"
		rm "$M_ERR" "$M_ERR_CMP" "$B_ERR" "$B_ERR_CMP"
	fi
	if cmp -s "$M_EXT" "$B_EXT"; then
		printf "%s Exit status:$BOLD$GREEN OK \n$RESET" "----------"
	else
		printf "%s Exit status:$BOLD$RED KO \n$RESET" "----------"
		printf "%s Exit diff$RED Minishell$RESET vs$GREEN Bash$RESET: \n" ">>>"
		diff --color "$M_EXT" "$B_EXT"
		rm "$M_EXT" "$B_EXT"
	fi
}

function check_output()
{
	cat -e $M_ERR | head -1 | rev | cut -d ':' -f 1 | tr '[:upper:]' '[:lower:]' | rev >$M_ERR_CMP
	cat -e $B_ERR | head -1 | rev | cut -d ':' -f 1 | tr '[:upper:]' '[:lower:]' | rev >$B_ERR_CMP
		printf "%s\t" "$test_num"
	if cmp -s "$M_OUT" "$B_OUT" && cmp -s "$M_EXT" "$B_EXT" && cmp -s "$M_ERR_CMP" "$B_ERR_CMP"; then
		output_ok "$@"
	elif cmp -s "$M_OUT" "$B_OUT" && cmp -s "$M_EXT" "$B_EXT" && grep -q "syntax error" "$M_ERR" && grep -q "syntax error" "$B_ERR"; then
		output_ok "$@"
	elif [[ "$@" == *'||'* ]] && grep -q "syntax error" "$M_ERR" && grep -q "2" "$M_EXT"; then
		output_ok_diff "$@"
	elif [[ "$@" == *';'* ]] && grep -q "command not found" "$M_ERR" && grep -q "127" "$M_EXT"; then
		output_ok_diff "$@"
	else
		output_fail "$@"
	fi
}

function exec_test()
{
	./minishell -c "$@" 1>$M_OUT 2>$M_ERR
	echo "$?">$M_EXT
	bash -c "$@" 1>$B_OUT 2>$B_ERR
	echo "$?">$B_EXT

	check_output "$@"	
	test_num+=1
	total_tests+=1
	echo
	sleep 0.1
}

function exec_test_outfile()
{
	./minishell -c "$@" 1>$M_OUT 2>$M_ERR
	echo "$?">$M_EXT
	cp $F_TEST_OUT $F_TEST_OUT_M
	rm $F_TEST_OUT
	bash -c "$@" 1>$B_OUT 2>$B_ERR
	echo "$?">$B_EXT
	check_outfile
	check_output "$@"
	test_num+=1
	echo
	sleep 0.1
}

function print_h2()
{
	printf	"$BOLD$MAGENTA\n"
	printf	"%s\n" "----------------------------------------------------------------"
	printf	"%11c%s\n" " " "$@"
	printf	"%s\n$RESET" "----------------------------------------------------------------"
}

function print_h3()
{
	echo
	printf	"$BOLD$YELLOW-----------%s$RESET\n" "$@"
}

#################### BEGIN TESTS ####################
remove_test_files
printf "$BOLD$MAGENTA"
printf	"%s\n" "----------------------------------------------------------------"
echo '	 _   _  _  _  _  _  ___  ___  __  ___  ___  ___ '
echo '	| \_/ || || \| || ||_ _|| __|/ _||_ _|| __|| o \'
echo '	| \_/ || || \\ || | | | | _| \_ \ | | | _| |   /'
echo '	|_| |_||_||_|\_||_| |_| |___||__/ |_| |___||_|\\'
printf	"%s\n" "----------------------------------------------------------------"
printf "$RESET"
echo

# Compile and set executable rights
printf $CYAN"Making minishell...\n"$RESET
make -C "$MINISHELL_PATH" >/dev/null
cp "$MINISHELL_PATH$MINISHELL_NAME" .
chmod 755 minishell
printf $GREEN"Minishell ready.\n"$RESET

create_test_files

print_h2 "BASIC EXECUTION TESTS"

#################################### BASIC EXEC
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

#################################### PIPES
print_h3 "PIPE TESTS"
exec_test 'ls -l | wc -l'
exec_test "cat $F_TEST | grep dream"
exec_test "cat $F_TEST | grep dream | cat -e"
exec_test "cat $F_TEST | grep dream | wc -l"
exec_test "cat $F_TEST | grep dream | wc -l | cd x"
exec_test "cat $F_TEST | grep dream | wc -l | x"
exec_test "x | cat $F_TEST | grep dream | wc -l"
exec_test "cat $F_TEST | x | grep dream | wc -l"
exec_test "cat $F_TEST | grep dream | x | wc -l"
exec_test 'cat /dev/random | head -c 100 | wc -c'
exec_test 'ls | ls | ls'
exec_test 'ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls'

print_h2 "BUILTIN TESTS"

#################################### ECHO
print_h3 "ECHO"
exec_test 'echo'
exec_test 'Echo'
exec_test 'ECHO'
exec_test 'echo hello'
exec_test 'echo hello world'
exec_test 'echo hello      world'
exec_test 'echo                      hello world'
exec_test 'echo hello world                '
exec_test 'echo -n hello world'
exec_test 'echo -n -n -n hello world'
exec_test 'echo -n -n -nnnn -nnnnm'
exec_test 'echo a	-nnnnma'
exec_test 'echo -n -nnn hello -n'
exec_test 'echo a	hello -na'

#################################### PWD
print_h3 "PWD"
exec_test 'pwd'
exec_test 'Pwd'
exec_test 'PWD'
exec_test 'pwd hello'
exec_test 'pwd 123'
exec_test 'pwd 1 2 x 3 hello'

#################################### CD
print_h3 "CD"
exec_test 'CD ..'
exec_test 'cd ..'
exec_test 'pwd'
exec_test 'cd'
exec_test 'pwd'
exec_test 'cd /Users'
exec_test 'pwd'

#################################### ENV
print_h3 "ENV"
exec_test 'env | wc -l'
exec_test 'Env | wc -l'
exec_test 'ENV | wc -l'
exec_test 'env | grep PATH'


#################################### EXIT
print_h3 "EXIT"
exec_test "exit"
exec_test "Exit"
exec_test "EXIT"
exec_test "exit 42"
exec_test "exit 240"
exec_test "exit +42"
exec_test "exit -42"
exec_test "exit abc"
exec_test "exit --42"
exec_test "exit ++42"
exec_test "exit 42 41"
exec_test "exit 42 abc"
exec_test "exit abc 42"
exec_test "exit 2147483647"
exec_test "exit 2147483648"
exec_test "exit -2147483648"
exec_test "exit -2147483649"
exec_test "exit 9223372036854775807"
exec_test "exit -9223372036854775808"
exec_test "exit 9223372036854775808"
exec_test "exit -9223372036854775810"
exec_test "exit 5 < $F_TEST"
#exec_test "exit 5 < $F_TEST"
exec_test "exit 1 | exit 0"
exec_test "exit 0 | exit 1"
exec_test "ls | exit"
exec_test "ls | exit 42"
exec_test "ls | exit 12 abc"
exec_test "ls | exit abc 12"
exec_test "exit | ls"
exec_test "exit 42 | ls"
exec_test "exit 12 abc | ls"
exec_test "exit abc 12 | ls"
#exec_test "ls > file | exit"
#exec_test "sleep 2 | exit"
#exec_test "ls -l > x | exit | wc -l"

# TODO: Find a way to test EXPORT and UNSET, as well as better CD testing.

print_h2 "REDIRECTION TESTS"

#################################### INFILES
print_h3 "INFILE"
exec_test "< $F_TEST cat"
exec_test "<$F_TEST cat"
exec_test "cat < $F_TEST"
exec_test "cat <$F_TEST"
exec_test '< hello'
exec_test 'cat <'
exec_test 'cat < x'
exec_test 'cat <x'
exec_test '< x cat'
exec_test '<x cat'
exec_test "cat < $F_FORBIDDEN"
exec_test "cat <$F_FORBIDDEN"
exec_test "< $F_FORBIDDEN cat"
exec_test "<$F_FORBIDDEN cat"
exec_test "< x < $F_TEST cat"
exec_test "cat < $F_TEST < x"
exec_test "cat < $F_TEST < $F_TEST < $F_TEST"
exec_test "cat < $F_TEST <"
exec_test "cat < $F_TEST < $F_TEST_2"
exec_test "<$F_TEST cat < $F_TEST_2"

<<COMMENT1
#################################### OUTFILES TRUNC
print_h3 "TRUNC OUTFILE"
exec_test '> x'
exec_test 'ls > p | env > q'
exec_test ''
exec_test ''
exec_test ''
exec_test ''
exec_test ''
exec_test ''
exec_test ''
exec_test ''
exec_test ''
exec_test ''
exec_test ''
exec_test ''
exec_test ''
exec_test ''
exec_test ''
exec_test ''
exec_test ''
exec_test ''

#################################### OUTFILES APPEND
print_h3 "APPEND OUTFILE"
exec_test ''
exec_test ''
exec_test ''
exec_test ''
exec_test ''
exec_test ''
exec_test ''
exec_test ''
exec_test ''
exec_test ''
exec_test ''
exec_test ''
exec_test ''
exec_test ''
exec_test ''
exec_test ''
exec_test ''
exec_test ''
exec_test ''
exec_test ''

#################################### FILES
print_h3 "COMBINE INFILE/OUTFILE"
exec_test 'echo "File A" > a'
exec_test 'echo "File B" >> b'
exec_test 'echo File C >c'
exec_test '<a cat <b <c'
exec_test 'chmod 000 b'
exec_test '<a cat <b <c'
exec_test ''
exec_test ''
exec_test ''
exec_test ''
exec_test ''
exec_test ''
exec_test ''
exec_test ''
exec_test ''
exec_test ''
exec_test ''
exec_test ''
exec_test ''
exec_test ''
COMMENT1

print_h2 "PARSING & SYNTAX TESTS"

#################################### QUOTES
print_h3 "BASIC QUOTE HANDLING"
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
exec_test 'ls ""'
exec_test "ls '\""
exec_test "ls \"\'"
exec_test 'ls " "'
exec_test "ls \" ' \""
exec_test '"ls"'
exec_test 'l"s"'

#################################### SYNTAX ERROR
print_h3 "SYNTAX ERROR TEST"
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
exec_test "< < $F_TEST cat"
exec_test "<< << $F_TEST cat"
exec_test "<< < $F_TEST cat"
exec_test "< << $F_TEST cat"
exec_test '< $FAKE_VAR cat'
exec_test 'cat < $FAKE_VAR'
exec_test 'cat < $123456'
exec_test '< $USER cat'
exec_test 'echo hello | ;'
exec_test 'ls > <'


<< COMMENT0
exec_test 'ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls'

print_h3 "PARSING SYNTAX TESTS"
exec_test "cat $F_TEST | grep dream | x | wc -l |"
exec_test "cat $F_TEST || grep dream | x | wc -l"
exec_test "| cat $F_TEST | grep dream | x | wc -l"
exec_test "| cat $F_TEST | grep dream | x | wc -l |"
COMMENT0



<<COMMENT
exec_test 'mkdir test_dir ; cd test_dir ; rm -rf ../test_dir ; cd . ; pwd ; cd . ; pwd ; cd .. ; pwd'
# PIPE TESTS
exec_test 'echo test | cat -e | cat -e | cat -e | cat -e | cat -e | cat -e | cat -e | cat -e | cat -e | cat -e| cat -e| cat -e| cat -e| cat -e| cat -e| cat -e| cat -e| cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e|cat -e'
exec_test 'ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls|ls'

exec_test "gdagadgag"
exec_test "ls -Z"
exec_test "cd gdhahahad"
exec_test "ls -la | wtf"


# ENV EXPANSIONS + ESCAPE
exec_test 'echo test     \    test'
exec_test 'echo \"test'
exec_test 'echo $TEST'
exec_test 'echo "$TEST"'
exec_test "echo '$TEST'"
exec_test 'echo "$TEST$TEST$TEST"'
exec_test 'echo "$TEST$TEST=lol$TEST"'
exec_test 'echo "   $TEST lol $TEST"'
exec_test 'echo $TEST$TEST$TEST'
exec_test 'echo $TEST$TEST=lol$TEST""lol'
exec_test 'echo    $TEST lol $TEST'
exec_test 'echo test "" test "" test'
exec_test 'echo "\$TEST"'
exec_test 'echo "$=TEST"'
exec_test 'echo "$"'
exec_test 'echo "$?TEST"'
exec_test 'echo $TEST $TEST'
exec_test 'echo "$1TEST"'
exec_test 'echo "$T1TEST"'

# ENV EXPANSIONS
ENV_SHOW="env | sort | grep -v SHLVL | grep -v _="
EXPORT_SHOW="export | sort | grep -v SHLVL | grep -v _= | grep -v OLDPWD"
exec_test 'export ='
exec_test 'export 1TEST= ;' $ENV_SHOW
exec_test 'export TEST ;' $EXPORT_SHOW
exec_test 'export ""="" ; ' $ENV_SHOW
exec_test 'export TES=T="" ;' $ENV_SHOW
exec_test 'export TE+S=T="" ;' $ENV_SHOW
exec_test 'export TEST=LOL ; echo $TEST ;' $ENV_SHOW
exec_test 'export TEST=LOL ; echo $TEST$TEST$TEST=lol$TEST'
exec_test 'export TEST=LOL; export TEST+=LOL ; echo $TEST ;' $ENV_SHOW
exec_test $ENV_SHOW
exec_test $EXPORT_SHOW
exec_test 'export TEST="ls       -l     - a" ; echo $TEST ; $LS ; ' $ENV_SHOW

# REDIRECTIONS
exec_test 'echo test > ls ; cat ls'
exec_test 'echo test > ls >> ls >> ls ; echo test >> ls; cat ls'
exec_test '> lol echo test lol; cat lol'
exec_test '>lol echo > test>lol>test>>lol>test mdr >lol test >test; cat test'
exec_test 'cat < ls'
exec_test 'cat < ls > ls'

# MULTI TESTS
exec_test 'echo testing multi ; echo "test 1 ; | and 2" ; cat tests/lorem.txt | grep Lorem'

# SYNTAX ERROR

COMMENT

print_h2 "RESULTS"
printf $BOLD$GREEN"\tOK$RED\t\tKO$RESET$BOLD\t\tTOTAL\n$RESET"
printf $BOLD$GREEN"\t%d$RED\t\t%d$RESET$BOLD\t\t%d\n$RESET" $tests_passed $tests_failed $total_tests
remove_test_files