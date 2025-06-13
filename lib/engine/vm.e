-- vm.e
include ast_token.e

global t_ast_token g_fun_retval = new_empty_ast_token()

forward public procedure ant_dispatcher(t_ast_token t)
forward public procedure do_block(t_ast_token block)


-- this is called everytime a new block is opened aka when a { is found
public procedure do_block(t_ast_token block)
    -- TODO create and push a stack for vars
    for i = 1 to block[ast_token_child_count] do
        t_ast_token child = block[ast_token_tokens][i]
        ant_dispatcher(child)
    end for
    -- TODO pop the var stack
end procedure

public procedure ant_dispatcher(t_ast_token t)
    if equal(t[ast_token_factory_request_str], "__NEVER_GOING_TO_MATCH_%$^@%$^@#$%___") then
    elsif equal(t[ast_token_factory_request_str], "fun") then
        -- dispatch the fun ant.  what should it do?  probalby just 
        -- map the location of the block
    else
        logger(DEBUG,sprintf("ant_dispatcher: Didn't know how to dispatch [%s]",
         {t[ast_token_factory_request_str]}))
        abort(1)
    end if
end procedure
