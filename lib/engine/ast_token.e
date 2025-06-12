-- ast_token.e
--  
-- this is our TAstToken structure (let's hide the implementation details) 
--  

public enum  
    __TYPE__,                   -- must be first value in enum 
    _kind,                      -- this is a contsant that represents resolveable, 
                                -- literal, or action. This turned out to be less 
                                -- valuable than I hoped. Targeted for deprecation.
    _name,                      -- the name of the data or symbol @x, [, 
                                -- or __BZ_STRING__ for example is a literal string.
    _file_name,                 -- the file name from which the token was generated.
    _line_num,                  -- line number of the original source code
    _col_num,                   -- column number of the original source code
    _value,                     -- for variables.. this is the value.  for not 
                                -- variables I may or may not use the field for 
                                -- meta data about the token.  
    _factory_request_str,       -- the interpreter dispactaches actions to something I call 
                                -- Ants.  This is data about which Ant to dispatch.
    _child_stream_location,     -- Metadata about where childern are located if the tokens were 
                                -- arraganed left to right in a row.  For example consider 5 + 6
                                -- + will have _child_stream_location of "left_and_right" becuase 
                                -- both 5 and 6 are needed to give + meaning.
    _child_count,               -- every token can have children.  This is how many they have.
    _ast_tokens,                -- the token's children
    __MYSIZE__                  -- must be last value in enum 
    
public constant
    BZKIND_RESOLVABLE = 1024,
    BZKIND_LITERAL    = 1025,
    BZKIND_ACTION     = 1026

-- Magic here is we can add remove "Properties" from our data struct 
-- Without needing remember to update this. 
public constant  
    SIZEOF_AST_TOKEN = __MYSIZE__  

-- 
-- ID pattern is SOME_NAME_THAT_MAKES_SENSE DOLLAR_SYMBOL SOME_RANDOM_CHARS 
--     
constant 
    AST_TOKEN_ID = "AST_TOKEN_ID$j56y7uw5tDESFWA#@$%^" 
 
-- Awesome Euphoria Feature!  Let's define what a TAstToken looks like. 
public type TAstToken (sequence s) 
    if s[__MYSIZE__] = SIZEOF_AST_TOKEN then 
        if equal(s[__TYPE__], AST_TOKEN_ID) then 
            return 1 
        end if 
    end if 
    return 0 
end type 

-- since in Euphoria everything is pass by value anyway t is aleady
-- a copy... and now it's type checked too.  Just return it.
public function copy_token(TAstToken t)
    return t
end function

public function new_empty_ast_token()
    -- NOTE TO SELF: changes here might mean there were 
    -- changes to the enum CHECK TOP OF CODE
    
    sequence token = repeat(0, SIZEOF_AST_TOKEN)
    token[__TYPE__] = AST_TOKEN_ID
    token[_name] = ""
    token[_file_name] = ""
    token[_factory_request_str] = ""
    token[_child_stream_location] = ""
    token[_child_count] = 0
    token[_ast_tokens] = {}
    token[__MYSIZE__] = SIZEOF_AST_TOKEN
    return token
end function

public procedure print_ast_token(TAstToken token, integer indent = 0)
    -- enum _kind, _name, _line_num, _col_num, _value, _factory_request_str, _ast_tokens
    --sequence indentation = repeat(" ", indent * 3)
    sequence indentation = ""
    for i = 0 to indent * 3 do
        indentation = sprintf("%s%s", {indentation, " "})
    end for
    --printf(1, "%skind: %d name: %s line: %d col: %d value: %s factory_request_str: %s child_stream_location: %s\n",
    printf(1, "%sname: %s line: %d col: %d value: %s factory_request_str: %s child_count: %d\n",
    {indentation,token[_name], token[_line_num],
    token[_col_num], token[_value], token[_factory_request_str], token[_child_count]})
    indent += 1
    
    for i = 1 to length(token[_ast_tokens]) do
        sequence child = token[_ast_tokens][i]
        print_ast_token(child, indent)
    end for
end procedure

public procedure print_ast_token_list(sequence tokens)
    for i = 1 to length(tokens) do
        print_ast_token(tokens[i])
    end for
end procedure

public function ast_list_append(sequence lst, TAstToken t)
    return append(lst, t)
end function

public function add_child(TAstToken parent, TAstToken child)
    sequence children = parent[_ast_tokens]
    children = append(children, child)
    parent[_ast_tokens] = children
    parent[_child_count] += 1
    return parent
end function
