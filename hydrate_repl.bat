:: hydrate_repl.bat – Sets up REPL architecture scaffolding
@echo off
setlocal

echo Creating REPL support files...

:: Ensure folders exist
mkdir lib\engine

:: Create repl.e
if not exist lib\engine\repl.e (
    echo -- lib/engine/repl.e > lib\engine\repl.e
    echo include std/io.e >> lib\engine\repl.e
    echo include lib/engine/state.e >> lib\engine\repl.e
    echo include lib/engine/interpreter.e >> lib\engine\repl.e
    echo >> lib\engine\repl.e
    echo procedure run_repl() >> lib\engine\repl.e
    echo     object state = init_state() >> lib\engine\repl.e
    echo     while 1 do >> lib\engine\repl.e
    echo         printf(1, "\nBZ> ") >> lib\engine\repl.e
    echo         object line = gets(0) >> lib\engine\repl.e
    echo         if atom(line) then exit end if >> lib\engine\repl.e
    echo         -- TODO: lex, group, parse, then evaluate >> lib\engine\repl.e
    echo         printf(1, "You entered: %%s\n", {line}) >> lib\engine\repl.e
    echo     end while >> lib\engine\repl.e
    echo end procedure >> lib\engine\repl.e
)

:: Create state.e
if not exist lib\engine\state.e (
    echo -- lib/engine/state.e > lib\engine\state.e
    echo public function init_state() >> lib\engine\state.e
    echo     return {} -- empty placeholder >> lib\engine\state.e
    echo end function >> lib\engine\state.e
)

:: Create interpreter.e
if not exist lib\engine\interpreter.e (
    echo -- lib/engine/interpreter.e > lib\engine\interpreter.e
    echo public function evaluate(object ast, object state) >> lib\engine\interpreter.e
    echo     -- TODO: route to appropriate ANT handler >> lib\engine\interpreter.e
    echo     return 0 >> lib\engine\interpreter.e
    echo end function >> lib\engine\interpreter.e
)

:: Patch bzs.ex to include repl.e if not already present
findstr /C:"include lib/engine/repl.e" bzs.ex >nul
if errorlevel 1 (
    echo include lib/engine/repl.e >> bzs.ex
    echo run_repl() >> bzs.ex
    echo Added REPL launch to bzs.ex
) else (
    echo REPL already included in bzs.ex
)

echo Done.
pause
endlocal
