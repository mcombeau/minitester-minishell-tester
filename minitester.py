# TODO: tests failling that should not: export, unset, infile-outfile
import os
from tester import (
    print_test_block_options,
    run_tests,
    cleanup_directories,
    setup_directories,
    print_total,
    get_args,
    parse_test_file,
    minishell_path,
    print_minishell_not_found,
)
from tester.config import globals


def main():
    global colored_output
    argparser, args = get_args()

    if not (os.path.isfile(minishell_path) and os.access(minishell_path, os.X_OK)):
        print_minishell_not_found()
        exit(2)

    test_blocks = parse_test_file("minishell_tests.txt")

    if args.list:
        print_test_block_options(test_blocks)
        return

    if not args.testblock and not args.all:
        argparser.print_help()
        return

    if args.color:
        globals["colored_output"] = True

    selected_blocks = args.testblock if args.testblock else test_blocks.keys()

    cleanup_directories()
    setup_directories()

    run_tests(selected_blocks, test_blocks)

    print_total()
    cleanup_directories()


if __name__ == "__main__":
    main()
