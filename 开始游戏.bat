@echo off
setlocal
cd /d "%~dp0"
set "GAME_ENGINE=%~dp0..\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe"
if exist "%GAME_ENGINE%" (
    start "" "%GAME_ENGINE%" --path "%~dp0."
    exit /b 0
)
where godot >nul 2>&1
if not errorlevel 1 (
    start "" godot --path "%~dp0."
    exit /b 0
)
echo Godot 4 was not found. Open project.godot in Godot 4 and press F5.
echo Expected engine: %GAME_ENGINE%
pause
