@echo off
setlocal enabledelayedexpansion
REM Load configuration from config.env file
set CONFIG_FILE=%~dp0config.env

REM Read config.env and set environment variables
if exist "%CONFIG_FILE%" (
    echo Loading configuration from: %CONFIG_FILE%
    for /f "usebackq tokens=1,2 delims==" %%a in ("%CONFIG_FILE%") do (
        REM Skip empty lines and comments (Windows-compatible regex)
        echo.%%a | findstr /r "^[ 	]*$" >nul && goto :continue
        echo.%%a | findstr /r "^[ 	]*#" >nul && goto :continue
        
        REM Handle variable expansion for ${VARIABLE} syntax
        set "temp_value=%%b"
        call :expand_variables temp_value
        set "%%a=!temp_value!"
        :continue
    )
) else (
    echo Warning: Configuration file not found: %CONFIG_FILE%
)

REM Function to expand ${VARIABLE} syntax in values
:expand_variables
setlocal enabledelayedexpansion
set "value=!%1!"
REM Replace ${SCRIPTS_DIR} with actual value
if defined SCRIPTS_DIR (
    set "value=!value:${SCRIPTS_DIR}=%SCRIPTS_DIR%!"
)
REM Add more variable expansions as needed
endlocal & set "%1=%value%"
goto :eof

REM Use environment variables with fallback defaults
if "%LOG_FILE%"=="" set LOG_FILE=C:\path\to\your\logs\rename-radarr-folders.log
if "%GIT_BASH_PATH%"=="" set GIT_BASH_PATH=C:\Program Files\Git\bin\bash.exe
if "%RENAME_SH_PATH%"=="" set RENAME_SH_PATH=C:\path\to\your\scripts\rename-radarr-folders.sh

REM Validate critical paths before execution
if not exist "%GIT_BASH_PATH%" (
    echo [%date% %time%] ERROR: Git Bash not found at: %GIT_BASH_PATH% >> "%LOG_FILE%" 2>&1
    echo ERROR: Git Bash not found at: %GIT_BASH_PATH%
    exit /b 1
)

if not exist "%RENAME_SH_PATH%" (
    echo [%date% %time%] ERROR: Script not found at: %RENAME_SH_PATH% >> "%LOG_FILE%" 2>&1
    echo ERROR: Script not found at: %RENAME_SH_PATH%
    exit /b 2
)

REM Create log directory if it doesn't exist
for %%F in ("%LOG_FILE%") do mkdir "%%~dpF" 2>nul

echo [%date% %time%] Starting rename-radarr-folders >> "%LOG_FILE%"
echo [%date% %time%] Git Bash: %GIT_BASH_PATH% >> "%LOG_FILE%"
echo [%date% %time%] Script: %RENAME_SH_PATH% >> "%LOG_FILE%"

"%GIT_BASH_PATH%" "%RENAME_SH_PATH%" %* >> "%LOG_FILE%" 2>&1
set SCRIPT_EXIT_CODE=%ERRORLEVEL%

echo [%date% %time%] Finished rename-radarr-folders, errorlevel=%SCRIPT_EXIT_CODE% >> "%LOG_FILE%"

if %SCRIPT_EXIT_CODE% neq 0 (
    echo [%date% %time%] WARNING: Script failed with exit code %SCRIPT_EXIT_CODE% >> "%LOG_FILE%"
)

exit /b %SCRIPT_EXIT_CODE%
