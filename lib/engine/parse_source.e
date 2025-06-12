-- File: parser/parse_source.e
-- Purpose: Load, tokenize, and parse a source file into an AST
-- Supports include path resolution using:
--   - Current working directory
--   - Path relative to including file
--   - Colon-separated paths in $BZINC environment variable
-- Avoids duplicate parsing using canonical path tracking
-- Injects _file_name into all AST tokens
-- On failure, lists all paths attempted

--include std/filesys.e
--include std/io.e
--include std/text.e
--include std/search.e
--include std/get.e
--include std/sequence.e
--include std/map.e


with trace
include ast_token.e
include lexer.e
include grouper.e
include parser.e

global sequence g_parsed_files = {}  -- stores canonical paths of files already parsed

-- Forward declarations
forward function resolve_include_path(sequence file_name, sequence starting_path)
forward function read_text_file(sequence path)
forward function annotate_ast_with_filename(sequence tokens, sequence filename)
forward function already_parsed(sequence path)

public function parse_source(sequence source_file_name, sequence starting_path)
    sequence result = resolve_include_path(source_file_name, starting_path)
    sequence resolved_path = result[1]
    sequence attempts = result[2]

    if resolved_path = "" then
        printf(2, "Error: Could not resolve include file: %s\n", source_file_name)
        printf(2, "Paths attempted:\n")
        for i = 1 to length(attempts) do
            printf(2, "  - %s\n", {attempts[i]})
        end for
        abort(1)
    end if

    sequence canon_path = canonical_path(resolved_path)
    if already_parsed(canon_path) then
        return new_empty_ast_token()
    end if

    g_parsed_files &= {canon_path}

    object source = read_text_file(resolved_path)
    if atom(source) then
        printf(2, "Error: Failed to read file: %s\n", resolved_path)
        abort(1)
    end if
    
    printf(1, "parse_source: path %s", {resolved_path})
    printf(1, "parse_source: source %s", {source})

    sequence tokens = make_tokens(source, symbols, keywords, paired)
    tokens = group_tokens(source, tokens, symbols, keywords, paired)
    tokens = annotate_ast_with_filename(tokens, canon_path)
    print_ast_token_list(tokens)
    TAstToken ast = make_ast(tokens)

    -- (Optional) Namespace detection hook
    -- You could extract `namespace` from top-level tokens here if desired

    return ast
end function


function resolve_include_path(sequence file_name, sequence starting_path)
    sequence attempts = {}

    -- 1. Try relative to current working directory
    sequence path1 = canonical_path(file_name)
    if file_exists(path1) then
        return {path1, attempts}
    end if
    attempts &= {path1}

    -- 2. Try relative to starting path
    sequence path2 = canonical_path(starting_path & "/" & file_name)
    if file_exists(path2) then
        return {path2, attempts}
    end if
    attempts &= {path2}

    -- 3. Try BZINC paths
    object bzinc_raw = getenv("BZINC")
    if not atom(bzinc_raw) then
        sequence b_raw = bzinc_raw
        sequence bzinc_paths = split(b_raw, ':')
        for i = 1 to length(bzinc_paths) do
            sequence path3 = canonical_path(bzinc_paths[i] & "/" & file_name)
            if file_exists(path3) then
                return {path3, attempts}
            end if
            attempts &= {path3}
        end for
    end if

    return {"", attempts}
end function


function already_parsed(sequence path)
    return find(path, g_parsed_files)
end function


function read_text_file(sequence path)
    integer fn = open(path, "r")
    if fn = -1 then
        return -1
    end if

    sequence content = ""
    object line
    while 1 do
        line = gets(fn)
        if atom(line) then
            exit
        end if
        content = append(content, line)
    end while
    close(fn)
    return join(content,"")
end function

function annotate_ast_with_filename(sequence tokens, sequence filename)
    for i = 1 to length(tokens) do
        tokens[i][_file_name] = filename
    end for
    return tokens
end function

function testme(sequence testfile_name)
    TAstToken t = parse_source(testfile_name, ".")
    print_ast_token(t)
    return t
end function

-- TAstToken t = testme("a.bzs")

