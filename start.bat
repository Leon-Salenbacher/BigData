@echo off

set IMAGE_NAME=bigdata-exercises-image
set CONTAINER_NAME=bigdata

echo ========================================
echo   Building BigData Environment
echo ========================================

docker build -t %IMAGE_NAME% .

if %ERRORLEVEL% NEQ 0 (
    echo Build failed.
    pause
    exit /b 1
)

echo.
echo ========================================
echo   Removing old container
echo ========================================

docker rm -f %CONTAINER_NAME% >nul 2>&1

echo.
echo ========================================
echo   Starting BigData
echo ========================================

docker run -it ^
    --name %CONTAINER_NAME% ^
    --env-file .env ^
    -p 8088:8088 ^
    %IMAGE_NAME%

pause