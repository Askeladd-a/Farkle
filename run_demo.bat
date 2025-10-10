@echo off
echo =====================================
echo    FARKLE 3D BOARD DEMO
echo =====================================
echo.
echo Avviando il demo della board 3D...
echo.

REM Controlla se LOVE2D è installato
where love >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo LOVE2D trovato! Avviando demo...
    love demo_board3d.lua
) else (
    echo ERRORE: LOVE2D non trovato nel PATH
    echo.
    echo Installa LOVE2D da: https://love2d.org/
    echo Oppure aggiungi LOVE2D al PATH di sistema
    echo.
    echo Alternativamente, puoi trascinare demo_board3d.lua
    echo sull'eseguibile di LOVE2D per avviarlo
    echo.
    pause
)

echo.
echo Demo terminato.
pause