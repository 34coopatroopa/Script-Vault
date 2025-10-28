@echo off
echo ========================================
echo  ScriptVault UI - Starting...
echo ========================================
echo.

cd /d "%~dp0"
cd utilities\python

echo Checking for Python...
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python not found!
    echo Please install Python from https://www.python.org/
    pause
    exit /b 1
)

echo Installing Flask if needed...
pip install flask -q

echo.
echo Starting ScriptVault UI...
echo.
python scriptvault_ui.py

pause

