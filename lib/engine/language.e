-- language.e
namespace language

-- Strongly typed hint enums
public enum _fun_call, _fun_def, _fun_call_group, _fun_def_group, _math, _bz_keyword
public enum _keyword_name, _keyword_factory_str, _child_location

-- Decoupled map: {enum, string}
public sequence value_hints = {
    {_fun_call,              "__FUN_CALL__"        },
    {_fun_def,               "__FUN_DEF__"         },
    {_fun_call_group,        "__FUN_CALL_GROUP__"  },
    {_fun_def_group,         "__FUN_DEF_GROUP__"   },
    {_math,                  "__MATH__"            },
    {_bz_keyword,               "__KEYWORD__"      }
}

public sequence children_stream_locations = {
    "left_only",
    "right_only",
    "left_and_right",
    "no_children",
    "left_optional",
    "right_optional",
    "left_right_optional"
}
    
public sequence symbols = {
    {";", "expression_end", "no_children"},
    {"@", "var_sequence", "no_children"},
    {"$", "var_string", "no_children"},
    {"#", "var_number", "no_children"},

    {"(", "grp_open", "right_only"},            -- parser will be change to group_open
    {")", "grp_close", "no_children"},          -- parser will drop
    {"{", "block_open", "right_only"},
    {"}", "block_close", "no_children"},        -- parser will drop

    {"[", "sequence_open", "right_only"},       -- parser will be change to group_open
    {"]", "sequence_close", "no_children"},     -- parser will drop

    {"+", "add", "left_and_right"},
    {"-", "subtract", "left_and_right"},
    {"*", "multiply", "left_and_right"},
    {"/", "divide", "left_and_right"},
    {"^", "exponent", "left_and_right"},

    {"=", "assignment", "left_and_right"},
    {"==", "num_compare_eq", "left_and_right"},
    {"!=", "num_compare_not_eq", "left_and_right"},
    {">", "num_compare_great", "left_and_right"},
    {"<", "num_compare_less", "left_and_right"},
    {">=", "num_compare_great_eq", "left_and_right"},
    {"<=", "num_compare_less_eq", "left_and_right"},

    {"+=", "increase_by", "left_and_right"},
    {"-=", "subtract_by", "left_and_right"},
    {"*=", "multiply_by", "left_and_right"},
    {"/=", "divide_by", "left_and_right"},

    {"++", "increment", "right_only"}, -- can be postfix or prefix
    {"--", "decrement", "right_only"}, -- same

    {"&&", "logic_and", "left_and_right"},
    {"||", "logic_or", "left_and_right"},

    {",", "delimiter", "left_and_right"},

    {"//", "__STRIP__", "no_children"},
    {"`", "__STRIP__", "no_children"},
    {"``", "__STRIP__", "no_children"}
}

public sequence keywords = {
    {"fun", "fun", "right_only"},
    {"via", "via", "left_and_right"},
    {"let", "let", "right_only"},
    {"public", "scope", "right_only"},
    {"private", "scope", "right_only"},
    {"global", "scope", "right_only"},
    {"if", "if", "right_only"},
    {"else", "else", "no_children"},
    {"elseif", "elseif", "right_only"},
    {"do", "do_loop", "right_optional"},
    {"break", "break", "right_optional"},
    {"continue", "continue", "right_optional"},
    {"return", "return", "right_optional"},
    {"include", "~include", "right_only"}
}


public sequence paired = {
    {"(", ")"},
    {"{", "}"},
    {"[", "]"}
}
