from tester import (
    print_test_block_options,
    run_tests,
    cleanup_directories,
    setup_directories,
    print_total,
    get_args,
    parse_test_file,
)


def main():
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

    run_tests(selected_blocks, test_blocks)

    print_total()
    cleanup_directories()


if __name__ == "__main__":
    main()
