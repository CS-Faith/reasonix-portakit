@echo off
chcp 65001 >nul 2>&1
setlocal

REM Get script directory without trailing backslash
pushd "%~dp0"
set "RX_ROOT=%CD%"
popd

REM Override HOME and USERPROFILE so Reasonix reads from sync-disk
set "HOME=%RX_ROOT%"
set "USERPROFILE=%RX_ROOT%"

REM Run setup script (hash computation, directory creation, merge from host, config patching)
if exist "%RX_ROOT%\_patch_config.ps1" (
    powershell -ExecutionPolicy Bypass -File "%RX_ROOT%\_patch_config.ps1" -ConfigPath "%RX_ROOT%\.reasonix\config.json"
)

REM Launch Reasonix
start "" "%RX_ROOT%\reasonix-desktop.exe"
endlocal
