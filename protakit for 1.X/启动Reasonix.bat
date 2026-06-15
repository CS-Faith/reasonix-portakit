@echo off
setlocal EnableDelayedExpansion

pushd "%~dp0"
set "RX_ROOT=%CD%"
popd

set "REAL_APPDATA=%APPDATA%"
set "PORTABLE_DATA=%RX_ROOT%\portable-data\reasonix"
set "HOST_DATA=%REAL_APPDATA%\reasonix"

if not exist "%PORTABLE_DATA%" mkdir "%PORTABLE_DATA%"

set IS_JUNCTION=0
dir /al "%HOST_DATA%" >nul 2>&1 && set IS_JUNCTION=1

if "!IS_JUNCTION!"=="0" (
    if exist "%PORTABLE_DATA%\sessions\" (
        if exist "%HOST_DATA%\" (
            echo Host data found. Backing up and creating junction...
            robocopy "%HOST_DATA%" "%PORTABLE_DATA%" /E /XO /NFL /NDL /NJH /NJS >nul
            move "%HOST_DATA%" "%REAL_APPDATA%\reasonix.backup" >nul 2>&1
        )
        mklink /J "%HOST_DATA%" "%PORTABLE_DATA%" >nul 2>&1
    ) else (
        if exist "%HOST_DATA%\" (
            echo First run: migrating host data to portable...
            robocopy "%HOST_DATA%" "%PORTABLE_DATA%" /E /XO /NFL /NDL /NJH /NJS >nul
            move "%HOST_DATA%" "%REAL_APPDATA%\reasonix.backup" >nul 2>&1
            mklink /J "%HOST_DATA%" "%PORTABLE_DATA%" >nul 2>&1
        )
    )
)

set "HOME=%RX_ROOT%"
set "USERPROFILE=%RX_ROOT%"
set "APPDATA=%REAL_APPDATA%"
set "LOCALAPPDATA=%RX_ROOT%\AppData\Local"

if exist "%RX_ROOT%\reasonix.exe" (
    start "" "%RX_ROOT%\reasonix.exe"
) else if exist "%RX_ROOT%\reasonix-desktop.exe" (
    start "" "%RX_ROOT%\reasonix-desktop.exe"
) else (
    echo ERROR: reasonix.exe not found in %RX_ROOT%
    pause
)
endlocal
