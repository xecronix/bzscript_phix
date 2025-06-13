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
include lib/engine/sysmap.e

integer expressions_executed = 0

procedure load_map(t_ast_token t)
trace(1)
    for i = 1 to t[ast_token_child_count] do
        t_ast_token file_token = t[ast_token_tokens][i]
        for x = 1 to file_token[ast_token_child_count] do
            t_ast_token child = file_token[ast_token_tokens][x]
            puts(1, "load_map: Child token\n")
            print_ast_token(child)
            
            if equal(child[ast_token_factory_request_str], "scope") then
                integer scope_idx =  find(child[ast_token_name], scope_str)
                integer ident_idx = find(child[ast_token_tokens][1][ast_token_factory_request_str], 
                                    {"fun", "let"})
                if ident_idx then
                    t_ast_token funvar_name_token = child[ast_token_tokens][2]
                    integer success = 0
                    if ident_idx = 1 then -- function 
                        success = add_fun(scope_idx, 
                                funvar_name_token[ast_token_file_name], 
                                funvar_name_token[ast_token_name], 
                                funvar_name_token,
                                ""
                        )
                    else
                        success = add_var(scope_idx, 
                                funvar_name_token[ast_token_file_name], 
                                funvar_name_token[ast_token_name], 
                                funvar_name_token,
                                ""
                        )
                    end if
                    if not success then
                        puts(1, "load_map: aborting for some reason\n")
                        abort(1)
                    end if
                end if
            end if
        end for
    end for
    logger(DEBUG, "var_map")
    logger(DEBUG, var_map_str())
    logger(DEBUG, "fun_map")
    logger(DEBUG, fun_map_str())
    
end procedure

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
    script_path = "scripts/a.bzs"

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
    
    t_ast_token ast = parse_source(script_path, ".")
    load_map(ast)
    print_ast_token(ast) --TODO this should go to the logger instead of stdout.
    do_block(ast)
    logger(DEBUG, sprintf("main: Expressions Executed %d", {expressions_executed}))

    logger(DEBUG, "End of Main")
    close_logger()
    puts(1, "BZScript Ended Normally.\n")
end procedure

main()
