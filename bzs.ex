-- File: bzs.eu
-- Main entry point for BZScript in Euphoria
-- Usage: eui bzs.eu scripts/demo.bzs
with trace

include lib/shared/constants.e
include lib/utils/logger.e
include lib/engine/parser.e
include lib/engine/parse_source.e
include lib/engine/vm.e
include lib/engine/ast_token.e

integer expressions_executed = 0

procedure main()
    init_logger()
    logger(DEBUG, "Starting main")
    sequence cmd_args = command_line()
    
    -- We expect the 3rd argument to be the script path:
    --   cmd_args[1] = interpreter (eui)
    --   cmd_args[2] = this file (bzs.eu)
    --   cmd_args[3] = script path (scripts/demo.bzs)
    if length(cmd_args) < 3 then
        puts(1, "Usage: eui bzs.ex <script.bzs>\n")
        abort(1)
    end if

    sequence script_path = cmd_args[3]

    -- Check file exists
    if not file_exists(script_path) then
        printf(1, "Error: File not found: %s\n", {script_path})
        abort(1)
    end if

    -- Read file contents
    integer fn = open(script_path, "r")
    if fn = -1 then
        printf(1, "Error: Failed to open file: %s\n", {script_path})
        abort(1)
    end if
    
    --sequence source = get_text(script_path)
    
    TAstToken ast = parse_source(script_path, ".")
    
    print_ast_token(ast) --TODO this should go to the logger instead of stdout.
    do_block(ast)
    logger(DEBUG, sprintf("main: Expressions Executed %d", {expressions_executed}))

    logger(DEBUG, "End of Main")
    close_logger()
    puts(1, "BZScript Ended Normally.\n")
end procedure

main()
