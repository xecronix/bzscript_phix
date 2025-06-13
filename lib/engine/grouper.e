-- grouper.e
-- this is a mini scripting language a little like C

with trace
include lexer.e
include ../utils/ezbzll1.e
include ast_token.e
include language.e

sequence _stack    = {}
sequence _symbols  = {}
sequence _keywords = {}
sequence _paired   = {}
sequence _tokens   = {}



-- Safe hint lookup function
public function token_hint(integer hint_idx)
    for i = 1 to length(value_hints) do
        if value_hints[i][1] = hint_idx then
            return value_hints[i][2]
        end if
    end for
    return ""
end function

-- TODO I'm going to want this for matching pairs
-- I'm going to want this for matching pairs
public function is_open_pair(sequence str)
    integer found = 0
    for i = 1 to length(language:paired) do
        sequence p = language:paired[i]
        if equal(p[1], str) then
            found = 1
            exit
        end if
    end for
    return found
end function 

-- I'm going to want this for matching pairs
public function is_closing_pair(sequence str)
    integer found = 0
    integer val = 2
    for key = 1 to length(language:paired) do
        sequence p = language:paired[key]
        if equal(p[val], str) then
            found = 1
            exit
        end if
    end for
    return found
end function 

function keyword_idx(sequence char)
    integer i = 1
    while i <= length(_keywords) do
        sequence k = _keywords[i][_keyword_name]
        if equal(char, k) then
            return i
        end if
        i += 1
    end while
    return 0
end function

function symbol_child_location(t_ast_token t)
    integer i = 1
    sequence t_name = t[ast_token_name]
    while i <= length(symbols) do
        sequence k_name = symbols[i][_keyword_name]
        if equal(t_name, k_name) then
            return symbols[i][_child_location]
        end if
        i += 1
    end while
    -- This will cause an error... but instead of the error happening here
    -- it will happen in the caller. IDK... maybe it's better to abort now?
    -- I think it might be more useful to abort closer to where ever t_ast_token 
    -- came from so that I can figure out how an unknown symbol happened in the 
    -- first place. 
    return sprintf("symbol_child_location: unknown symbol child location for symbol[%s] line[%d] col[%d]",
                {t_name, t[ast_token_line_num], t[ast_token_col_num]}) 
end function

-- I use this to prevent typos.  If location is
-- found in the sequence of locations I let it 
-- thru the filter.  If not abort.  
public function filter_child_location(sequence location)
    for i = 1 to length(children_stream_locations) do
        if equal(children_stream_locations[i], location) then
            return location
        end if
    end for
    printf(1, "filter_child_location: [%s] is not a valid child location.\n ", {location})
    abort(1)
end function

-- *Params*
-- raw_source: is used to provide context for debugging output and/or helpful user error messages.
-- tokens: are a sequence of token generically grouped and ready for meaning. see notes below.
-- symbols: all the symbols for a bztklite language
-- keywords: all the keywords for a bztklite language
-- paired: used for validation of properly open/closed blocked statements/constructs  {}, (), [].  
-- *Descr*
-- What we have now is a group of tokens that have some meaning as tokens but not meaning
-- relative to the language we're writing.  for example {"$", "first_name"} might be 2 tokens in
-- the stream... side by side.  What we want is {"$first_name"} to be known as a variable.  Other
-- such meanings are needed.  {"("} for example.  Is this a grouping for math? Are we defining a
-- function?  Maybe we're calling a function?  Eventually, an Ant worker could figure this out, but
-- we can do it now, ONCE, and save the Ant the trouble.  We'll use the token[_value] like data for
-- Ants to use.  These values could be:  "__FUN_DEF__", "__FUN_CALL__", "__MATH__" etc.  I'm sure
-- others will popup.  Hopefully, I'll remember to update this comment, but, if I don't check for
-- a sequence at the top of this file called value_hints.  I'll go make it right now.  Done.
public function group_tokens(sequence raw_source, sequence tokens, 
    sequence symbols, sequence keywords, sequence paired)
    
    _symbols = symbols
    _keywords = keywords
    _paired = paired
    _tokens = {} -- <-- not a mistake... make sure it's empty... this is what we're building.
    ezbzll1:init(tokens)
    
    if length(raw_source) = 0 then
        puts(1, "group_tokens: No raw source file.  Error messages that tie back to source might not be possible\n")
    end if
    
            
    while 1 do
        sequence token = current()
        sequence next_token = new_empty_ast_token()
        sequence prev_token = new_empty_ast_token()
        
        if (has_more()) then
            next_token = look_next()        
        end if
        
        if (length(_tokens)) then
            prev_token = _tokens[length(_tokens)]
            if length(prev_token[ast_token_child_stream_location]) = 0 then
                prev_token[ast_token_child_stream_location] = filter_child_location("right_only")
                _tokens[length(_tokens)] = prev_token
            end if
        end if
        
        sequence token_name = token[ast_token_name] -- easy to view in debugger
        
        
        if equal(token[ast_token_kind], BZKIND_LITERAL) then
            -- if the token is a literal... add to _tokens
            token[ast_token_child_stream_location] = filter_child_location("no_children")
            _tokens = append(_tokens, token)            
            
        elsif find(token[ast_token_name], {"$", "#", "@"}) then
            -- else if the token is a sigil the thing that follows 
            -- is a var name. fuse and add to tokens
            
            token[ast_token_name] = sprintf("%s%s", {token[ast_token_name], next_token[ast_token_name]})
            token[ast_token_child_stream_location] = filter_child_location("no_children")
            _tokens = append(_tokens, token)
             next()
            t_ast_token pk = look_next()
            if equal(prev_token[ast_token_name], "let") then
                if equal(pk[ast_token_factory_request_str], "assignment") then
                    t_ast_token term = new_empty_ast_token()
                    term[ast_token_name] = ";"
                    term[ast_token_factory_request_str] = "expression_end" 
                    _tokens = append(_tokens, term)
                    _tokens = append(_tokens, copy_token(token))
                elsif equal(pk[ast_token_factory_request_str], "expression_end") then
                    -- do nothing
                else
                    printf(1, "group_tokens: Invalid symbol at line: [%d] col:[%d]\n", 
                        {pk[ast_token_line_num],pk[ast_token_col_num]})
                    printf(1, "group_tokens: expected [;] or [=] but found [%s] \n", 
                        {pk[ast_token_name]})
                    abort(1)
                end if
            end if
            
        elsif equal(token[ast_token_name], "-") then 
            -- if the thing before me is not a number, or a varible that's a number
            -- or the close of a function... then I'm a negative sign.
            token[ast_token_child_stream_location] = filter_child_location("left_and_right")
            if equal(prev_token[ast_token_name], "__BZ__NUMBER__" ) = 0 and
                equal(prev_token[ast_token_factory_request_str], "var_number" ) = 0  and
                equal(prev_token[ast_token_factory_request_str], "group_close" ) = 0 then 
                
                token[ast_token_factory_request_str] = "negative"
                token[ast_token_child_stream_location] = filter_child_location("right_only")
            end if
            
            _tokens = append(_tokens, token)
            
        elsif equal(token[ast_token_name], "+") then 
            -- if the thing before me is not a number, or a varible that's a number
            -- or the close of a function... then I'm a negative sign.
            token[ast_token_child_stream_location] = filter_child_location("left_and_right")
            if equal(prev_token[ast_token_name], "__BZ__NUMBER__" ) = 0 and
                equal(prev_token[ast_token_factory_request_str], "var_number" ) = 0  and
                equal(prev_token[ast_token_factory_request_str], "group_close" ) = 0 then 
                
                token[ast_token_factory_request_str] = "positive"
                token[ast_token_child_stream_location] = filter_child_location("right_only")
            end if
            
            _tokens = append(_tokens, token)
            
            
        elsif keyword_idx(token[ast_token_name]) then
            integer kw_idx = keyword_idx(token[ast_token_name])
            sequence keyword_map = _keywords[kw_idx]
            
            sequence factory_str = keyword_map[_keyword_factory_str]
            sequence hint = token_hint(_bz_keyword)
            sequence child_loc = keyword_map[_child_location]
            
            token[ast_token_factory_request_str] = factory_str
            token[ast_token_value] = hint
            token[ast_token_child_stream_location] = filter_child_location(child_loc)
            
            _tokens = append(_tokens, token)
            
        elsif equal(prev_token[ast_token_name], "fun") then
            -- this is a function def
            token[ast_token_value] = token_hint(_fun_def)
            token[ast_token_factory_request_str] = "fun_def"
            token[ast_token_child_stream_location] = filter_child_location("right_only")
            _tokens = append(_tokens, token)
            
        elsif equal(token[ast_token_name], "(") then
            if equal(prev_token[ast_token_value], token_hint(_bz_keyword)) or
                equal(prev_token[ast_token_value], token_hint(_fun_call))  then
                
                token[ast_token_value] = token_hint(_fun_call_group)
            elsif equal(prev_token[ast_token_value], token_hint(_fun_def)) then
                token[ast_token_value] = token_hint(_fun_def_group)
            else
                token[ast_token_value] = token_hint(_math)
            end if
            
            token[ast_token_child_stream_location] = filter_child_location("right_only")
            _tokens = append(_tokens, token)  
        
        elsif length(token[ast_token_factory_request_str]) then
            -- token has a factory request str add to tokens. it's a symbol.
            -- Also, this symbol is considered recognizable soley by the
            -- factory_request_str.  Any symbol that needs further clarity 
            -- should be handled above this elsif.
            --
            -- For example - might be negative or it might be minus
            -- ( might be for a function call or maybe math
            
            sequence child_loc = symbol_child_location(token)
            token[ast_token_child_stream_location] = filter_child_location(child_loc)           
            _tokens = append(_tokens, token)
            
        else
            -- user function
            token[ast_token_value] = token_hint(_fun_call)
            token[ast_token_factory_request_str] = "fun_call"
            token[ast_token_child_stream_location] = filter_child_location("right_only")
            _tokens = append(_tokens, token)
        end if
        
        if (has_more()) then
            next()
        else
            exit
        end if
    end while  
    
    return _tokens  
end function



function test_bztklite_e()

    sequence input = join( {"fun begin(){",
        "let #x = 0;",
        "let #y = (0 + 1);",
        "do {",
        "    #y = 0 ;",
        "    fake_fun(#x, #y);",
        "    if (#x == 5) {",
        "        print (`halfway done\\n`)            ;",
        "    } ",
        "    do {",
        "        let @counts = [#x+1, #y+1] ;",
        "        printf( `Outer Loop:                  ##\\nInner Loop: ##\\n`, @counts) ;",
        "        #y += 1;",
        "        if(#y == 5) {break        ;            } ",
        "    } ",
        "    #x += 1 ",
        "    if(#x == 10) {break;} ",
        "} ",
        "return #x;",
        "} "}, "\n")
    
--    input = join( {"fun begin(){",
--        "    let #tax = .07;",
--        "    let #cost = 10;",
--        "    let #total = #cost + #cost * #tax;",
--       "    print($total);",
--      "}"}, "\n")


    sequence tokens = make_tokens(input, symbols, keywords, paired)
    tokens = group_tokens(input, tokens, symbols, keywords, paired)

    return 0
end function 

--test_bztklite_e()

