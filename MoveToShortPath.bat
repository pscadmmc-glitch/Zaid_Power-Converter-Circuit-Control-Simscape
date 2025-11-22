@echo off
REM Move repository to short path to fix Windows 260 character limit
REM Run this file from the repository root directory

echo ============================================================
echo Move Repository to Short Path
echo ============================================================
echo.
echo This will move the repository from:
echo   %CD%
echo.
echo To:
echo   C:\GFM\PowerConverter
echo.
echo This fixes the Windows 260-character path limit issue.
echo.

set /p CONFIRM="Continue? (Y/N): "
if /i not "%CONFIRM%"=="Y" (
    echo Cancelled.
    pause
    exit /b
)

echo.
echo Creating target directory...
if not exist "C:\GFM" mkdir "C:\GFM"

echo.
echo Moving repository (this may take a minute)...
xcopy "%CD%" "C:\GFM\PowerConverter" /E /I /H /Y

if errorlevel 1 (
    echo.
    echo ERROR: Move failed!
    echo Please try running this batch file as Administrator
    pause
    exit /b 1
)

echo.
echo ============================================================
echo SUCCESS! Repository moved to C:\GFM\PowerConverter
echo ============================================================
echo.
echo Next steps:
echo 1. Open MATLAB
echo 2. Run: cd C:\GFM\PowerConverter\Script_Data
echo 3. Run: ConfigureShortPaths
echo 4. Run your simulations normally
echo.
echo You can safely delete the old folder:
echo   %CD%
echo.
echo Opening new location in Explorer...
explorer "C:\GFM\PowerConverter"
echo.

pause
