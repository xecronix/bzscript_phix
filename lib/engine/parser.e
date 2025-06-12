-- file ast.e
with trace
include ../utils/ezbzll1.e 
include ast_token.e  -- for the money!! This has been the target all along.
include lexer.e  -- for the ast_token
include grouper.e
include ast_token.e
include language.e
--include parse_source.e

sequence _tokens = {}
sequence _fun_stack = {} 
sequence _xml = {}

enum _group, _fuse_sequence, _function, _sign, 
    _exponent, _multdiv, _addsub, 
    _bool, _logic, _assign, _language, _ptypes
    
sequence _openers = {"grp_open", "sequence_open"}
sequence _closers = {"grp_close", "sequence_close"}

-- forward declarations 
--
forward function locate_closer(sequence expression, integer start)
forward function parse_expression(sequence expression)

    
function pop_stack()
    sequence ast = _fun_stack[length(_fun_stack)]
    _fun_stack = remove(_fun_stack, length(_fun_stack))
    return ast
end function     

function push_stack(TAstToken ast)
    _fun_stack = ast_list_append(_fun_stack,ast)
    return length(_fun_stack)
end function

-- This prints the name field of each TAstToken
-- in a given sequence.  Not exactly what the source
-- code looked like but close enough for debugging.
procedure print_expression(sequence expression)
    sequence names = {}
    integer i = 0 
    while i < length(expression) do
        i += 1
        object t = expression[i]
        if sequence(t) and length(t) >= _name then
            names = append(names, t[_name])
        else
            names = append(names, "<invalid>")
        end if
    end while

    sequence line = ""
    if length(names) then
        line = join(names, " ")
    end if 
    printf(1, "Expression:\n%s\n", {line})
end procedure

-- To best explian what this function does lets consider these 2 tokens 
-- #x ++ .  The token on the left should be a child to the one on the 
-- right.  So the AST tree we we want is something like
-- ++
-- -- #x
-- meaning the token on the left becomes a child token to the one on the 
-- right.  All of the op_* functions have the logic to determine where 
-- where the childern are in relation to the parent.  This just
-- orders things accordingly. 
function child_on_left()
    TAstToken parent = current()
    parent = add_child(parent, recall())    -- flying lose here 
    return parent
end function 

-- See comment for child_on_left().  This does the opposite.  
-- There is a stream manager in place.  It's called ezbzll1.e 
-- The tokens it's using for stacking are found there.  
-- See op_addsub for how that's done.  Or, most of the 
-- op_* functions for that matter.
function child_on_right()
    TAstToken parent = current()
    parent = add_child(parent, look_next())   -- flying lose here  TODO ERROR CHECK
    return parent
end function 

-- To best explian what this function does lets consider these 3 tokens 
-- #x = 5 .  The token on the left and right of the = should be children. 
-- The children's order aka child 1 or child 2 is the order they appear
-- left to right in the source code.
-- =
-- -- #x
-- -- 5
-- All of the op_* functions have the logic to determine where 
-- where the childern are in relation to the parent.  This just
-- orders things accordingly.
function child_on_both_sides()
    TAstToken parent = current()
    -- if (has_less() and has_more()) then
        parent = add_child(parent, recall())      -- flying lose here 
        parent = add_child(parent, look_next())   -- flying lose here  TODO ERROR CHECK
    --end if
     return parent
end function

function op_assign(sequence expression)
    init(expression)
    sequence new_expression = {}
    while 1 do
        TAstToken ast_token = current()
        if find(ast_token[_factory_request_str], {"assignment",
            "increase_by", "subtract_by", "multiply_by", "divide_by"}) then
            new_expression = remove(new_expression, length(new_expression))
            ast_token = child_on_both_sides()
             next()
        elsif find(ast_token[_factory_request_str], {"increment","decrement"}) then
            new_expression = remove(new_expression, length(new_expression))
            ast_token = child_on_left()
        end if
        new_expression = ast_list_append(new_expression, ast_token)

        if (has_more()) then
             next()
        else
            exit
        end if
    end while
    return new_expression
end function

function op_logic(sequence expression)
    init(expression)
    sequence new_expression = {}

    while 1 do
        TAstToken ast_token = current()
        if find(ast_token[_factory_request_str], {"logic_and", "logic_or"}) then
            new_expression = remove(new_expression, length(new_expression))
            ast_token = child_on_both_sides()
             next()
        end if
        new_expression = ast_list_append(new_expression,ast_token)

        if (has_more()) then
             next()
        else
            exit
        end if
    end while
    return new_expression
end function    

function op_bool(sequence expression)
    init(expression)
    sequence new_expression = {}
    while 1 do
        sequence ast_token = current()
        if find(ast_token[_factory_request_str], {"num_compare_eq", "num_compare_not_eq",
            "num_compare_great", "num_compare_less",
            "num_compare_great_eq", "num_compare_less_eq"}) then
            new_expression = remove(new_expression, length(new_expression))
            ast_token = child_on_both_sides()
             next()
        end if
        new_expression = ast_list_append(new_expression,ast_token)

        if (has_more()) then
             next()
        else
            exit
        end if
    end while
    return new_expression
end function    

function op_addsub(sequence expression)
    init(expression)
    sequence new_expression = {}

    while 1 do
        TAstToken ast_token = current()
        if find(ast_token[_factory_request_str], {"add", "subtract"}) then
            new_expression = remove(new_expression, length(new_expression))
            ast_token = child_on_both_sides()
             next()
        end if
        new_expression = ast_list_append(new_expression,ast_token)

        if (has_more()) then
             next()
        else
            exit
        end if
    end while
    return new_expression
end function    

function op_multdiv(sequence expression)
    init(expression)
    sequence new_expression = {}
    while 1 do
        TAstToken ast_token = current()
        if find(ast_token[_factory_request_str], {"multiply", "divide"}) then
            new_expression = remove(new_expression, length(new_expression))
            ast_token = child_on_both_sides()
             next()
        end if
        new_expression = ast_list_append(new_expression,ast_token)

        if (has_more()) then
             next()
        else
            exit
        end if
    end while
    return new_expression
end function    

function op_exponent(sequence expression)
    init(expression)
    sequence new_expression = {}
    while 1 do
        TAstToken ast_token = current()
        if find(ast_token[_factory_request_str], {"exponent"}) then
            new_expression = remove(new_expression, length(new_expression))
            ast_token = child_on_both_sides()
             next()
        end if
        new_expression = ast_list_append(new_expression,ast_token)

        if (has_more()) then
             next()
        else
            exit
        end if
    end while
    return new_expression
end function    

function op_sign(sequence expression)
    init(expression)
    sequence new_expression = {}
    while 1 do
        TAstToken ast_token = current()
        if find(ast_token[_factory_request_str], {"negative", "positive"}) then
            ast_token = child_on_right()
             next()
        end if
        new_expression = ast_list_append(new_expression,ast_token)

        if (has_more()) then
             next()
        else
            exit
        end if
    end while
    return new_expression
end function    

function op_fuse_sequence(sequence expression)
    init(expression)
    sequence new_expression = {}

    while 1 do
        TAstToken ast_token = current()
        if equal(ast_token[_factory_request_str], "var_sequence") then
            if has_more() then
                TAstToken next_token = look_next()
                if equal(next_token[_name], "[") then
                    ast_token = child_on_right()
                     next()
                end if 
            end if
        end if
        new_expression = ast_list_append(new_expression,ast_token)

        if (has_more()) then
             next()
        else
            exit
        end if
    end while
    return new_expression
end function

function op_function(sequence expression)
    init(expression)
    sequence new_expression = {}

    while 1 do
        TAstToken ast_token = current()
        if find(ast_token[_value], {token_hint(_fun_call),token_hint(_fun_def)})then
            sequence name = ast_token[_name]
            sequence val = ast_token[_value]
            sequence hint_call = token_hint(_fun_call)
            sequence hint_def = token_hint(_fun_def)
            --trace(1)
            print_expression(expression)
            ast_token = child_on_right()
             next()
        end if
        new_expression = ast_list_append(new_expression,ast_token)

        if (has_more()) then
             next()
        else
            exit
        end if
    end while
    return new_expression
end function    

-- TODO
function op_language(sequence expression)
    init(expression)
    sequence new_expression = {}

    while 1 do
        TAstToken ast_token = current()
        if equal(ast_token[_value], token_hint(_bz_keyword) ) then
            sequence child_loc = ast_token[_child_stream_location]
            if equal(child_loc, filter_child_location("left_only")) then
                new_expression = remove(new_expression, length(new_expression))
                ast_token = child_on_left()
            elsif equal(child_loc, filter_child_location("right_only")) then
                print_expression(expression)
                ast_token = child_on_right()
                 next()
            elsif equal(child_loc, filter_child_location("left_and_right")) then
                new_expression = remove(new_expression, length(new_expression))
                ast_token = child_on_both_sides()
                 next()
            elsif equal(child_loc, filter_child_location("no_children")) then
                -- do nothing
            elsif equal(child_loc, filter_child_location("left_optional")) then
                if length(new_expression) then
                    new_expression = remove(new_expression, length(new_expression))
                    ast_token = child_on_left()
                end if
            elsif equal(child_loc, filter_child_location("right_optional")) then
                if has_more() then
                    ast_token = child_on_right()
                     next()
                end if
            elsif equal(child_loc, filter_child_location("left_right_optional"))then
                if length(new_expression) then
                    new_expression = remove(new_expression, length(new_expression))
                    ast_token = child_on_left()
                end if
                
                if has_more() then
                    ast_token = child_on_right()
                     next()
                end if
                
            end if
        end if -- if token is bz_keyword

        new_expression = ast_list_append(new_expression,ast_token)

        if (has_more()) then
             next()
        else
            exit
        end if
    end while
    return new_expression
end function    

-- MUST return a single TAstToken.  Don't send an 
-- empty expression.  Bad things will happen. And it's too late
-- to do anything about it now.
function op_math(TAstToken parent, sequence expression)
    parent = add_child(parent, parse_expression(expression))
    return parent
end function

-- Important: This reduces multiple expressions to a single parent 
-- sequence node. MUST return a single TAstToken.  Don't send an 
-- empty expression.  Bad things will happen. And it's too late
-- to do anything about it now.
function op_sequence(TAstToken parent, sequence expression)
    sequence new_expression = {}
    integer i = 0

    while i < length(expression) do
        i += 1
        TAstToken ast_token = expression[i]
        
        if find(ast_token[_factory_request_str], _openers) then
            integer pos = locate_closer(expression, i)
            new_expression = ast_list_append(new_expression, ast_token) -- add the parent
            
            -- Slurp all tokens until we get to the matching opener.  We
            -- don't care what they are.  We don't want to deal with them.
            -- We just need them in the new_expression for parsing later.
            while i < pos do
                i+=1
                new_expression = ast_list_append(new_expression, expression[i])
            end while
        
        -- We have a little mini group in the group.  Parse it and add
        -- to the parent.
        elsif find(ast_token[_factory_request_str], _closers) then
            parent = add_child(parent, parse_expression(new_expression))
        
        -- Here we found the comma.  Send the expression to the parser
        -- and and it to the parent.  But don't return yet. There might
        -- be more commas to find and expressions to parse.        
        elsif equal(ast_token[_factory_request_str], "delimiter") then
            parent = add_child(parent, parse_expression(new_expression))
            new_expression = {}
        
        -- We'll this is just a token to gather up and parse later.
        else
            new_expression = ast_list_append(new_expression, ast_token)
        end if
    end while

    -- op_group trimmed the closing ) from the expression before it
    -- got here. so... we're definately going to reach this point.
    if length(new_expression) then
        parent = add_child(parent, parse_expression(new_expression))
    end if

    return parent
end function

-- This reduces groups out of an expression.  Lot's of 
-- comments inline.  Very much worth the read.  This
-- must return an expression of 1 or more TAstTokens.  
function op_group(sequence expression)
    sequence new_expression = {} -- the reduced expression: the whole point if this function
    integer i = 0
    while  i < length(expression) do
        i += 1
        TAstToken t = expression[i]
        if find(t[_factory_request_str], _openers) then
            -- at this point we know t isn't some random token
            -- it's a node opening token.  I'm tempted to rename it
            -- now.  I guess I'm overwhelmed with temptation.
            TAstToken parent = t
            parent[_factory_request_str] = "group_open"
            integer end_pos = locate_closer(expression, i)
            sequence exp_frag = {}
            
            i += 1 -- skip the opener aka parent.
            while i < end_pos do
                exp_frag = ast_list_append(exp_frag, expression[i])
                i+=1
            end while
            
            -- exp_frag should be the expression except the opening and closing
            -- token. we're not putting the open tag in there becuase we mutated
            -- it and gave it "group_open". The mutation was needed so we don't
            -- end up in an endless loop. 
            
            -- Let's find out how to route this 
            -- token is "math" or "not math" aka -> sequence
            -- handle empty groups here.
            TAstToken group
            if length(exp_frag) then
                if equal(parent[_value], token_hint(_math)) then
                    group = op_math(parent, exp_frag)
                else
                    group = op_sequence(parent, exp_frag)
                end if
            else
                -- the exp_frag was empty. But were here. We'll create
                -- an empty node.  It might be and probably will be 
                -- needed for other reductions, not related to grouping.
                -- for example #x = random() * 4 
                group = parent
            end if
                          
            new_expression = ast_list_append(new_expression, group)
            --slurp up the rest of the expression
            -- i is setting on the closing ) of the expression we sent to the op
            -- we don't want it.
            while i < length(expression) do
                i+=1 -- on the first loop we smite the close )
                new_expression = ast_list_append(new_expression, expression[i])
            end while
            
            -- And finally... the little dance 
            -- We did some reductions, we need to start all over until
            -- there are no more reductions.
            expression = new_expression
            new_expression = {}
            i = 0            
        else
            new_expression = ast_list_append(new_expression, t)
        end if
    end while    
    return new_expression
end function

-- This is how order of operations are mananged.  The 
-- while loop is visually deceiving.  The order of the
-- if/elsif/else isn't controlling the Order of Operations.
-- This controlled by an enum.  The order of the enum
-- is what's actually controlling the order.  See top
-- of file for enum.  Check the top of the file 
-- for enum.
--
-- Also, This method must return a single TAstToken.
-- Definately bad things will happen if it can't
function parse_expression(sequence expression)

    integer prec = 1
    while prec < _ptypes do
            if prec = _group then
                expression = op_group(expression)
            elsif prec = _fuse_sequence then
                expression = op_fuse_sequence(expression)
            elsif prec = _language then
                expression = op_language(expression)
            elsif prec = _function then
                expression = op_function(expression)
            elsif prec = _sign then
                expression = op_sign(expression)
            elsif prec = _exponent then
                expression = op_exponent(expression)
            elsif prec = _multdiv then
                expression = op_multdiv(expression)
            elsif prec = _addsub then
                expression = op_addsub(expression)
            elsif prec = _bool then
                expression = op_bool(expression)
            elsif prec = _logic then
                expression = op_logic(expression)
            elsif prec = _assign then
                expression = op_assign(expression)
            end if
        prec += 1
       
    end while
    integer exp_len = length(expression)
    if exp_len > 1 then
        -- TODO make this a better error message about a missing
        -- semi colon.  add the line/col number and show the line
        -- of source code.  But for now... abort.
        sequence message = join({"parse_expression: failed to reduce expression to",
        "a single token.  Expected ; on line[%d] col[%d]"}, " ")
        printf(1, message, {expression[2][_line_num], expression[2][_col_num]})
        abort(1)
    end if
    return expression[1]
end function

-- This function must return a single TAstToken Anything else
-- will cause crashes later.  Don't call this function with 
-- any empty ast_tokens sequence. Bad things will happen and 
-- there is nothing that can be done about now.
function ast_block_builder(TAstToken parent, sequence ast_tokens, integer nest_level)
    integer i = 0
    sequence expression = {}
   
    while i < length(ast_tokens) do
        i += 1
        TAstToken ast_token = ast_tokens[i]
        if equal(ast_token[_factory_request_str], "block_open") then
            -- expression that start blocks don't end with ;
            if length(expression) then
                parent = add_child(parent, parse_expression(expression))
                expression = {}
            end if
            nest_level+=1
            -- find the closing }
            sequence exp_frag = {}
            integer pos = locate_closer(ast_tokens, i)
            -- slurp up the tokens up to closing } into an exp fragment
            -- this will leave i sitting on the closing }
            
            while i < pos do
                i += 1 -- on the first loop smite the }
                exp_frag = ast_list_append(exp_frag, ast_tokens[i])
            end while
            -- send the fragment to self with the bumped up nest level
            if length(exp_frag) then
                nest_level += 1
                parent = add_child(parent, ast_block_builder(ast_token, exp_frag, nest_level))
                nest_level -= 1
            else
                parent = add_child(parent, ast_token)
            end if 
        elsif equal(ast_token[_factory_request_str], "block_close") then
            return parent
        elsif equal(ast_token[_factory_request_str], "expression_end") then
            TAstToken reduced_t = parse_expression(expression)                                         
            parent = add_child(parent, reduced_t)
            expression = {}
        else
            expression = ast_list_append(expression, ast_token)
        end if
    end while
    if length(expression) then
        parent = add_child(parent, parse_expression(expression))
    end if
    return parent
end function

-- If the symbol called open_symbol is a matched
-- pair, it will return the closing symbol.  For
-- example given ( the return value will be )
function find_closing_symbol(sequence open_symbol)
    sequence closing_sym = ""
    integer key = 1
    integer val = 2
    for i = 1 to length(paired) do
        sequence p = paired[i]
        if equal(p[key], open_symbol) then
            closing_sym = p[val]
            exit
        end if
    end for
    return closing_sym
end function

-- The expression isn't assumed to be a fragment.  It might
-- be a very long expression that as a dev you might be part
-- way into parsing.  With that in mind start is the starting
-- TAstToken postion in an expression to start looking for 
-- a matched pair.  The return value is the position
-- in the expression of the matched pair.  My original purpose
-- for this function was to find a the location or a matched pair
-- and uncondtionally slurp up tokens until that point.  
function locate_closer(sequence expression, integer start)
    integer pos = start
    TAstToken match_this_token = expression[pos]
    sequence open_sym = match_this_token[_name]
    sequence close_sym = find_closing_symbol(open_sym)
    
    if length(close_sym) = 0 then
        printf(1, "locate_closer: Could not find closing symbol for token:[%s] on line:[%d], col:[%d]\n", {open_sym,
            match_this_token[_line_num],
            match_this_token[_col_num]})
        abort(1)
    end if

    integer nest_level = 0
    integer stop = length(expression) + 1
    while pos < stop do
        TAstToken t = expression[pos] 
        sequence current_sym = t[_name]
        if equal(current_sym, open_sym) then
            nest_level+=1
        elsif equal(current_sym, close_sym) then
            nest_level-=1
        end if

        if nest_level = 0 then
            return pos
        end if
        pos += 1
    end while
    printf(1, "locate_closer: Could not find symbol. Looked for closing symbol for token:[%s] on line:[%d], col:[%d]\n", {open_sym,
        match_this_token[_line_num],
        match_this_token[_col_num]})
    abort(1)
    
end function
    
public function make_ast(sequence ast_tokens)
    TAstToken root = new_empty_ast_token()
    root[_name] = "__ast_token_root__"
    root[_factory_request_str] = "block_open"
    root = ast_block_builder(root, ast_tokens, 1)
    return root    
end function

--public function parse_source(sequence source)
--    sequence tokens = make_tokens(source, symbols, keywords, paired)
--    tokens = group_tokens(source, tokens, symbols, keywords, paired)
--    return make_ast(tokens)
--end function

procedure test_ast_e()

    sequence tokens
    sequence ast
    sequence input
    --input = "{#y = #x ^ 5;#z = #y >= .7;#a = #b *#z;}"
    --tokens = make_tokens(input, symbols, keywords, paired)
    --tokens = group_tokens(input, tokens, symbols, keywords, paired)
    --ast = make_ast(tokens)
    --print_ast_token(ast)
    
    --input = "{#y = (5+#x) * 12000;}"
    --tokens = make_tokens(input, symbols, keywords, paired)
    --tokens = group_tokens(input, tokens, symbols, keywords, paired)
    --ast = make_ast(tokens)
    --print_ast_token(ast)
    
    --input = "{(1);}"
    --input = "{#x= (5 +7) * (#e / 6);}"
    --input = "{#x= ((222 + #x),444,777 * #y);}"
    --input = "{#a = (1 + 2)+ (3 * (4 + #b)+ #c);}"
    --input = "{(5+(3+7));}"
    --input = "{((5+(3+7)));}"
    --input ="{((((#x+1)*2)));"
    --input ="{#n=((((#x+1)*2)-((3/(#y+4))+5)));}"
    --input ="{@a=[1,2,3,`and a string :)`];}"
    --input ="{@a=[1,[2,3],`Eagle's Nest :)`];}"
    --input ="{[1,2*3, 4];}"
    --input ="{@z=[1, [2+3], [4, [5]]];}"
    --input ="{{{@z.exp=[1, (5+2)+(9*0), [4, [`Level up + Power up = WAY UP`]]];}}}"
    --input ="{{@z.exp=[1, (5+2)+(9*0), [4, [`Level up + Power up = WAY UP`]]];\n$t=`taxi`; \n{#c=777;\n}}}"
    sequence lines = {
"fun predictable_num(#x, #y){",
"   let #z = #x + #y;",
"   let @a =[1, (5+2)+(9*0), [4, [`Level up + Power up = WAY UP`]]];",
"   let $b;",
"   return #z * 22;",
"}",
"predictable_num(5,7);"    
    }
    input = join(lines, "\n")
    
    input = join( {"fun begin(){",
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
    
    input = join( {"fun do_stuff(#x, $r, @t via TAstToken(@_arg[3])){",
    "#x = #x*5;",
    "print($r);",
    "printf(`%s`, @t[#_factory_request_str]);",
    "} ",
    "let @token;",
    "do_stuff(6, `me`, @token);"
    }, "\n")
    --input = "fn()[3][#idx];" -- should generate error about expected ; on col 5
    --input = "2_much_fun();" -- should generate error about expected ; on col 2
    --input = "#x += 3;"
    tokens = make_tokens(input, symbols, keywords, paired)
    tokens = group_tokens(input, tokens, symbols, keywords, paired)
    puts(1, "test_ast_e: Grouped token stream\n")
    print_ast_token_list(tokens)
    puts(1, "test_ast_e: Bulding AST...\n")
    ast = make_ast(tokens)
    --pretty_print(1, ast)
    printf(1, "input: \n\n%s\n\nOutput\n\n",{input})
    print_ast_token(ast)
    puts(1,"Program finished Successfully.  (Or at least it didn't crash.  :) )\n")
end procedure 

-- test_ast_e()


