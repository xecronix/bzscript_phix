-- ast_token.e
--  
-- this is our t_ast_token structure (let's hide the implementation details) 
--  

namespace ast_token
-- Internal string buffer (log-style, for to_string)
sequence _ast_string_lines = repeat("", 5000)
integer _ast_line_max = 5000
integer _ast_line_index = 0

public enum  
    _ast_token_type,                -- internal: must be first
    ast_token_kind,                 -- deprecated but visible
    ast_token_name,                 -- e.g., '@x', '[', or '__BZ_STRING__'
    ast_token_file_name,            -- source filename
    ast_token_line_num,             -- line in source
    ast_token_col_num,              -- column in source
    ast_token_value,                -- literal value or metadata
    ast_token_factory_request_str,  -- dispatcher hint (e.g., 'GroupNumberAnt')
    ast_token_child_stream_location,-- e.g., 'left_and_right'
    ast_token_child_count,          -- number of children
    ast_token_tokens,               -- children list
    _ast_token_my_size              -- internal: must be last
    
public constant
    BZKIND_RESOLVABLE = 1024,
    BZKIND_LITERAL    = 1025,
    BZKIND_ACTION     = 1026

-- 
-- ID pattern is SOME_NAME_THAT_MAKES_SENSE DOLLAR_SYMBOL SOME_RANDOM_CHARS 
--     
constant 
    AST_TOKEN_ID = "AST_TOKEN_ID$j56y7uw5tDESFWA#@$%^" 

-- Awesome Euphoria Feature!  Let's define what a t_ast_token looks like.  
public function is_token(object s)
    if sequence(s) then
        if s[_ast_token_my_size] = _ast_token_my_size then 
            if equal(s[_ast_token_type], AST_TOKEN_ID) then 
                return 1 
            end if 
        end if 
    end if
    return 0
end function

-- If the squence isn't a t_ast_token this will cause a crash... 
-- that is a desired feature.  Awesome!!  
public type t_ast_token (sequence s) 
    return is_token(s) 
end type 

-- since in Euphoria everything is pass by value anyway t is already
-- a copy... and now it's type checked too.  Just return it.
public function copy_token(t_ast_token t)
    return t
end function

public function new_empty_ast_token()
    -- NOTE TO SELF: changes here might mean there were 
    -- changes to the enum CHECK TOP OF CODE
    
    sequence token = repeat(0, _ast_token_my_size)
    token[_ast_token_type] = AST_TOKEN_ID
    token[ast_token_name] = ""
    token[ast_token_file_name] = ""
    token[ast_token_value] = ""
    token[ast_token_factory_request_str] = ""
    token[ast_token_child_stream_location] = ""
    token[ast_token_child_count] = 0
    token[ast_token_tokens] = {}
    token[_ast_token_my_size] = _ast_token_my_size
    return token
end function

public procedure print_ast_token(t_ast_token token, integer indent = 0)
    -- enum _kind, _name, _line_num, _col_num, _value, _factory_request_str, _ast_tokens
    --sequence indentation = repeat(" ", indent * 3)
    sequence indentation = ""
    for i = 0 to indent * 3 do
        indentation = sprintf("%s%s", {indentation, " "})
    end for
    --printf(1, "%skind: %d name: %s line: %d col: %d value: %s factory_request_str: %s child_stream_location: %s\n",
    printf(1, "%sname: %s line: %d col: %d value: %s factory_request_str: %s child_count: %d\n",
    {indentation,token[ast_token_name], token[ast_token_line_num],
    token[ast_token_col_num], token[ast_token_value], token[ast_token_factory_request_str], 
    token[ast_token_child_count]})
    indent += 1
    
    for i = 1 to length(token[ast_token_tokens]) do
        sequence child = token[ast_token_tokens][i]
        print_ast_token(child, indent)
    end for
end procedure

public function ast_list_append(sequence lst, t_ast_token t)
    return append(lst, t)
end function

public function add_child(t_ast_token parent, t_ast_token child)
    sequence children = parent[ast_token_tokens]
    children = append(children, child)
    parent[ast_token_tokens] = children
    parent[ast_token_child_count] += 1
    return parent
end function

procedure _ensure_capacity()
    if _ast_line_index >= _ast_line_max then
        integer new_size = floor(_ast_line_max * 1.5)
        _ast_string_lines &= repeat("", new_size - _ast_line_max)
        _ast_line_max = new_size
    end if
end procedure

procedure _append_line(sequence s)
    _ast_line_index += 1
    _ensure_capacity()
    _ast_string_lines[_ast_line_index] = s
end procedure

public procedure to_string(t_ast_token token, integer indent = 0)
    sequence indentation = repeat(' ', indent * 3)
    sequence line = sprintf(
        "%sname: %s line: %d col: %d value: %s factory_request_str: %s child_count: %d",
        {
            indentation,
            token[ast_token_name],
            token[ast_token_line_num],
            token[ast_token_col_num],
            token[ast_token_value],
            token[ast_token_factory_request_str],
            token[ast_token_child_count]
        })
    _append_line(line)

    for i = 1 to length(token[ast_token_tokens]) do
        to_string(token[ast_token_tokens][i], indent + 1)
    end for
end procedure

public function get_ast_token_string(sequence tokens)
    _ast_line_index = 0
    _ast_string_lines = repeat("", _ast_line_max)
    for i = 1 to length(tokens) do
        to_string(tokens[i])
    end for
    return join(_ast_string_lines[1.._ast_line_index], "\n")
end function

public procedure print_ast_token_list(sequence tokens)
    sequence out = get_ast_token_string(tokens)
    puts(1, out & "\n")
end procedure

