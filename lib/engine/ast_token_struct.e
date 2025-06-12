-- token_struct.e
-- 
-- Phix-native version of TAstToken using struct
-- Implements the same functionality with improved field access, safety, and clarity

public struct Token
    string  name = ""
    integer kind = 0
    integer line = 0
    integer col = 0
    object  value = 0
    string  factory_request_str = ""
    string  child_stream_location = ""
    sequence ast_tokens = {}
end struct

-- IMPORTANT: Use Token t = new() to properly initialize with defaults

public procedure print_token(Token token, integer indent = 0)
    string indentation = repeat(" ", indent * 3)
    printf(1, "%sname: %s line: %d col: %d value: %s factory_request_str: %s child_count: %d\n",
        {indentation, token.name, token.line, token.col, 
         sprint(token.value), token.factory_request_str, length(token.ast_tokens)})
    indent += 1
    for i = 1 to length(token.ast_tokens) do
        print_token(token.ast_tokens[i], indent)
    end for
end procedure

public procedure print_token_list(sequence tokens)
    for i = 1 to length(tokens) do
        print_token(tokens[i])
    end for
end procedure

public function append_token(sequence lst, Token t)
    return append(lst, t)
end function

public function add_child(Token parent, Token child)
    parent.ast_tokens = append(parent.ast_tokens, child)
    return parent
end function
