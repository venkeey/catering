@echo off
REM Create the fonts directory
mkdir assets\fonts 2>nul

REM Download Roboto fonts using PowerShell - using actual TTF files from GitHub
powershell -Command "Invoke-WebRequest -Uri 'https://github.com/google/fonts/raw/main/apache/roboto/Roboto-Regular.ttf' -OutFile 'assets\fonts\Roboto-Regular.ttf'"
powershell -Command "Invoke-WebRequest -Uri 'https://github.com/google/fonts/raw/main/apache/roboto/Roboto-Bold.ttf' -OutFile 'assets\fonts\Roboto-Bold.ttf'"
powershell -Command "Invoke-WebRequest -Uri 'https://github.com/google/fonts/raw/main/apache/roboto/Roboto-Italic.ttf' -OutFile 'assets\fonts\Roboto-Italic.ttf'"

echo Fonts downloaded successfully!