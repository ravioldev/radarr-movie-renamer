@echo off
setlocal enabledelayedexpansion

echo ===== DEBUG BAT =====
echo Current directory: %CD%
echo.

REM Load configuration from config file
set "CONFIG_FILE=%~dp0config-raviol.env"
echo Config file: %CONFIG_FILE%
echo Config exists: 
if exist "%CONFIG_FILE%" (echo YES) else (echo NO)
echo.

REM Read config and show variables
if exist "%CONFIG_FILE%" (
    echo Loading config...
    for /f "usebackq tokens=*" %%a in ("%CONFIG_FILE%") do (
        set "line=%%a"
        if not "!line!"=="" (
            echo !line! | findstr /b /c:"#" >nul
            if errorlevel 1 (
                echo !line! | findstr /c:"=" >nul
                if not errorlevel 1 (
                    for /f "tokens=1,2 delims==" %%b in ("!line!") do (
                        set "var_name=%%b"
                        set "var_value=%%c"
                        set "!var_name!=!var_value!"
                        echo Set: !var_name!=!var_value!
                    )
                )
            )
        )
    )
)

REM Expand ${SCRIPTS_DIR} in RENAME_SH_PATH if needed
if defined SCRIPTS_DIR (
    if defined RENAME_SH_PATH (
        set "RENAME_SH_PATH=!RENAME_SH_PATH:${SCRIPTS_DIR}=%SCRIPTS_DIR%!"
        echo Expanded RENAME_SH_PATH: !RENAME_SH_PATH!
    )
)

echo.
echo ===== FINAL VARIABLES =====
echo LOG_FILE=%LOG_FILE%
echo GIT_BASH_PATH=%GIT_BASH_PATH%
echo RENAME_SH_PATH=%RENAME_SH_PATH%

echo ===== END DEBUG ===== 