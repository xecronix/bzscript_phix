-- sysmap.e
-- This is where function and variable mapping is done. This is a 
-- list of struct like mapping and some helper functions
-- It purpose is to hold the AST for for functions 
-- And extended scoped variables.  (public, private, and global)
-- Why is private considered extended scope?  Because it resides
-- out side of a function block.

namespace sysmap 

sequence _funs = {}
sequence _vars = {}

public enum scope_private, scope_public, scope_global
public sequence scope_str = {"private", "public", "global"}

enum _fun_map, _var_map

enum _sysmap_type, 
	sysmap_scope,
	sysmap_file_name,
	sysmap_name,
	sysmap_token,
    sysmap_namespace, -- future
	_sysmap_my_size

-- 
-- ID pattern is SOME_NAME_THAT_MAKES_SENSE DOLLAR_SYMBOL SOME_RANDOM_CHARS 
--     
constant 
    SYSMAP_ID = "SYSMAP_ID$j5ESFWasdfga234%@^&$^" 

-- Awesome Euphoria Feature!  Let's define what a t_sysmap looks like.  
public function is_sysmap(object s)
    if sequence(s) then
        if s[_sysmap_my_size] = _sysmap_my_size then 
            if equal(s[_sysmap_type], SYSMAP_ID) then 
                return 1 
            end if 
        end if 
    end if
    return 0
end function

-- If the squence isn't a t_sysmap this will cause a crash... 
-- That is a desired feature.  Awesome!!  
type t_sysmap (sequence s) 
    return is_sysmap(s) 
end type 

public type t_scope(integer t)
    if find(t, {scope_private, scope_public, scope_global}) then
        return 1
    end if
    return 0
end type
    

function idx_of(integer mapid, t_scope scope, sequence file_name,sequence name, name_space = "" )
    if mapid = _fun_map then
        for i = 0 to length(_funs) do
            if _funs[i][sysmap_scope] = scope and
               _funs[i][sysmap_file_name] = file_name and
               _funs[i][sysmap_name] = name and
               _funs[i][sysmap_namespace] = name_space then
               return i
            end if
        end for
    elsif mapid = _var_map then
        for i = 0 to length(_vars) do
            if _vars[i][sysmap_scope] = scope and
               _vars[i][sysmap_file_name] = file_name and
               _vars[i][sysmap_name] = name and
               _vars[i][sysmap_namespace] = name_space then
               
               return i
            end if
        end for
    end if

    return 0
end function

function new_sysmap()
    sequence m = repeat(0, _sysmap_my_size)
    m[_sysmap_type] = SYSMAP_ID
    m[_sysmap_my_size] = _sysmap_my_size
    return m
end function 

function add_sysmap(integer mapid, t_scope scope, sequence file_name,sequence name, 
    t_ast_token token, name_space = "" )
    
    t_sysmap m = new_sysmap()
    if idx_of(mapid, scope, file_name, name, name_space) = 0 then
        m[sysmap_scope] = scope
        m[sysmap_file_name] = file_name
        m[sysmap_name] = name
        m[sysmap_token] = token
        m[sysmap_namespace] = name_space
    else 
        return 1
    end if
    
    if mapid = _fun_map then
        _funs = append(_funs, m)        
    elsif mapid = _var_map then
        _vars = append(_vars, m)        
    end if
    
    return 0 -- could not add fun/var.
end function

public function add_fun(t_scope scope, sequence file_name,sequence name, t_ast_token token, name_space = "" )
    return add_sysmap(_fun_map, scope, file_name, name, token, name_space)
end function

public function add_var(t_scope scope, sequence file_name,sequence name, t_ast_token token, name_space = "" )
    return add_sysmap(_var_map, scope, file_name, name, token, name_space)
end function

public function get_var(sequence file_name,sequence name, sequence name_space="")
    integer idx = 0
    idx = idx_of(_var_map, scope_private, file_name, name, name_space)
    if idx then
        return _vars[idx][sysmap_token]
    end if
    
    idx = idx_of(_var_map, scope_public, file_name, name, name_space)
    if idx then
        return _vars[idx][sysmap_token]
    end if
    
    idx = idx_of(_var_map, scope_global, file_name, name, name_space)
    if idx then
        return _vars[idx][sysmap_token]
    end if
        
    return 0
end function 

public function get_fun(sequence file_name,sequence name, sequence name_space="")
    integer idx = 0
    idx = idx_of(_fun_map, scope_private, file_name, name, name_space)
    if idx then
        return _funs[idx][sysmap_token]
    end if
    
    idx = idx_of(_fun_map, scope_public, file_name, name, name_space)
    if idx then
        return _funs[idx][sysmap_token]
    end if
    
    idx = idx_of(_fun_map, scope_global, file_name, name, name_space)
    if idx then
        return _funs[idx][sysmap_token]
    end if
        
    return 0
end function 


public function set_var(sequence file_name,sequence name, t_ast_token token, sequence name_space="")
    integer idx = 0
    idx = idx_of(_var_map, scope_private, file_name, name, name_space)
    if idx then
        _vars[idx][sysmap_token] = token
        return 1
    end if
    
    idx = idx_of(_var_map, scope_public, file_name, name, name_space)
    if idx then
        _vars[idx][sysmap_token] = token
        return 1
    end if
    
    idx = idx_of(_var_map, scope_global, file_name, name, name_space)
    if idx then
        _vars[idx][sysmap_token] = token
        return 1
    end if
    return 0
end function 

public function fun_map_str()
    sequence entries = repeat("", length(_funs))
    for i = 1 to length(_funs) do
        t_sysmap m = _funs[i]
        integer scope_idx = m[sysmap_scope]
        sequence scope_str = scope_str[scope_idx]
        sequence e = sprintf("scope: [%s] file name: [%s] name: [%s] namespace: [%s]", {
        scope_str, m[sysmap_file_name],m[sysmap_name], m[sysmap_namespace]
        })
        entries[i] = e
    end for
    
    return join(entries, "\n")
end function

public function var_map_str()
    sequence entries = repeat("", length(_vars))
    for i = 1 to length(_vars) do
        t_sysmap m = _vars[i]
        integer scope_idx = m[sysmap_scope]
        sequence scope_str = scope_str[scope_idx]
        sequence e = sprintf("scope: [%s] file name: [%s] name: [%s] namespace: [%s]", {
        scope_str, m[sysmap_file_name],m[sysmap_name], m[sysmap_namespace]
        })
        entries[i] = e
    end for
    
    return join(entries, "\n")
end function








