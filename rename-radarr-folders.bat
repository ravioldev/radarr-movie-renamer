@echo off
setlocal enabledelayedexpansion

REM Load configuration from config file (default: config.env, can be overridden with CONFIG_FILE env var)
if not defined CONFIG_FILE set "CONFIG_FILE=%~dp0config.env"
if not exist "%CONFIG_FILE%" set "CONFIG_FILE=%~dp0config.env"

REM Read config.env and set environment variables
if exist "%CONFIG_FILE%" (
    for /f "usebackq tokens=*" %%a in ("%CONFIG_FILE%") do (
        set "line=%%a"
        REM Skip empty lines
        if not "!line!"=="" (
            REM Skip comments (lines starting with #)
            echo !line! | findstr /b /c:"#" >nul
            if errorlevel 1 (
                REM Process non-comment lines with = sign
                echo !line! | findstr /c:"=" >nul
                if not errorlevel 1 (
                    for /f "tokens=1,2 delims==" %%b in ("!line!") do (
                        set "var_name=%%b"
                        set "var_value=%%c"
                        REM Handle variable expansion for ${SCRIPTS_DIR}
                        if defined SCRIPTS_DIR (
                            set "var_value=!var_value:${SCRIPTS_DIR}=%SCRIPTS_DIR%!"
                        )
                        set "!var_name!=!var_value!"
                    )
                )
            )
        )
    )
)

REM Expand ${SCRIPTS_DIR} in paths first
if defined SCRIPTS_DIR (
    if defined RENAME_SH_PATH (
        set "RENAME_SH_PATH=!RENAME_SH_PATH:${SCRIPTS_DIR}=%SCRIPTS_DIR%!"
        REM Fix double backslashes that might occur
        set "RENAME_SH_PATH=!RENAME_SH_PATH:\\=\!"
    )
)

REM Use environment variables with fallback defaults
if "%LOG_FILE%"=="" set "LOG_FILE=C:\path\to\your\logs\rename-radarr-folders.log"
if "%GIT_BASH_PATH%"=="" set "GIT_BASH_PATH=C:\Program Files\Git\bin\bash.exe"
if "%RENAME_SH_PATH%"=="" set "RENAME_SH_PATH=C:\path\to\your\scripts\rename-radarr-folders.sh"

REM Validate critical paths before execution
echo [%date% %time%] DEBUG: Checking paths... >> "%LOG_FILE%"
echo [%date% %time%] DEBUG: GIT_BASH_PATH="%GIT_BASH_PATH%" >> "%LOG_FILE%"
echo [%date% %time%] DEBUG: RENAME_SH_PATH="%RENAME_SH_PATH%" >> "%LOG_FILE%"

if not exist "%GIT_BASH_PATH%" (
    echo [%date% %time%] ERROR: Git Bash not found at: "%GIT_BASH_PATH%" >> "%LOG_FILE%" 2>&1
    echo ERROR: Git Bash not found at: "%GIT_BASH_PATH%"
    exit /b 1
)

if not exist "%RENAME_SH_PATH%" (
    echo [%date% %time%] ERROR: Script not found at: "%RENAME_SH_PATH%" >> "%LOG_FILE%" 2>&1
    echo ERROR: Script not found at: "%RENAME_SH_PATH%"
    echo [%date% %time%] DEBUG: Directory listing of script directory: >> "%LOG_FILE%"
    dir "%~dp0" >> "%LOG_FILE%" 2>&1
    exit /b 2
)

REM Create log directory if it doesn't exist
for %%F in ("%LOG_FILE%") do mkdir "%%~dpF" 2>nul

echo [%date% %time%] Starting rename-radarr-folders >> "%LOG_FILE%"
echo [%date% %time%] Git Bash: "%GIT_BASH_PATH%" >> "%LOG_FILE%"
echo [%date% %time%] Script: "%RENAME_SH_PATH%" >> "%LOG_FILE%"
echo [%date% %time%] SCRIPTS_DIR: "%SCRIPTS_DIR%" >> "%LOG_FILE%"

REM Handle Radarr test event first
if "%radarr_eventtype%"=="Test" (
    echo [%date% %time%] Test event received from Radarr - Script validation successful >> "%LOG_FILE%"
    echo Test event received from Radarr - Script validation successful
    exit /b 0
)

REM Handle both Radarr environment variables and manual arguments
if defined radarr_movie_id (
    echo [%date% %time%] Mode: Radarr environment variables >> "%LOG_FILE%"
    echo [%date% %time%] radarr_movie_id=%radarr_movie_id% >> "%LOG_FILE%"
    echo [%date% %time%] radarr_movie_title=%radarr_movie_title% >> "%LOG_FILE%"
    echo [%date% %time%] radarr_movie_year=%radarr_movie_year% >> "%LOG_FILE%"
    echo [%date% %time%] radarr_moviefile_quality=%radarr_moviefile_quality% >> "%LOG_FILE%"
    
    set "ARG1=radarr_movie_id=%radarr_movie_id%"
    set "ARG2=radarr_movie_title=%radarr_movie_title%"
    set "ARG3=radarr_movie_year=%radarr_movie_year%"
    set "ARG4=radarr_moviefile_quality=%radarr_moviefile_quality%"
) else (
    echo [%date% %time%] Mode: Command line arguments >> "%LOG_FILE%"
    echo [%date% %time%] Arguments: %* >> "%LOG_FILE%"
    
    REM Pass all arguments as-is to bash script
    echo [%date% %time%] Executing with arguments: %* >> "%LOG_FILE%"
    "%GIT_BASH_PATH%" "%RENAME_SH_PATH%" %* >> "%LOG_FILE%" 2>&1
    goto :execute_done
)

echo [%date% %time%] Executing with arguments: >> "%LOG_FILE%"
echo [%date% %time%]   %ARG1% >> "%LOG_FILE%"
echo [%date% %time%]   %ARG2% >> "%LOG_FILE%"
echo [%date% %time%]   %ARG3% >> "%LOG_FILE%"
echo [%date% %time%]   %ARG4% >> "%LOG_FILE%"

"%GIT_BASH_PATH%" "%RENAME_SH_PATH%" "%ARG1%" "%ARG2%" "%ARG3%" "%ARG4%" >> "%LOG_FILE%" 2>&1

:execute_done
set SCRIPT_EXIT_CODE=%ERRORLEVEL%

echo [%date% %time%] Finished rename-radarr-folders, errorlevel=%SCRIPT_EXIT_CODE% >> "%LOG_FILE%"

if %SCRIPT_EXIT_CODE% neq 0 (
    echo [%date% %time%] WARNING: Script failed with exit code %SCRIPT_EXIT_CODE% >> "%LOG_FILE%"
)

exit /b %SCRIPT_EXIT_CODE%

REM Updated: Fixed argument parsing compatibility (v1.1)
