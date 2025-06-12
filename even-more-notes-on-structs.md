-- Awesome Euphoria Feature!  Let's define what a TAstToken looks like. 
public type TAstToken (sequence s) 
    return is_TAstToken(s)
end type 

public function is_TAstToken (s)
if s[__MYSIZE__] = SIZEOF_AST_TOKEN then 
        if equal(s[__TYPE__], AST_TOKEN_ID) then 
            return 1 
        end if 
    end if 
    return 0 
end function
