@echo off
title IntelliStock Launcher

set "PROJECT=C:\Projects\IntelliStock"

if not exist "%PROJECT%\server\server.js" (
    echo ERROR: IntelliStock project was not found at:
    echo %PROJECT%
    echo.
    echo Edit the PROJECT path in this file if your project is stored elsewhere.
    pause
    exit /b 1
)

echo Starting IntelliStock services...
echo Keep the three service windows open while using the application.
echo.

start "IntelliStock Backend - Port 5000" cmd /k "cd /d "%PROJECT%\server" && npm run dev"

start "IntelliStock ML Service - Port 8000" cmd /k "cd /d "%PROJECT%\ml-service" && call venv\Scripts\activate.bat && python -m uvicorn main:app --host 127.0.0.1 --port 8000 --reload"

start "IntelliStock Frontend - Vite" cmd /k "cd /d "%PROJECT%\client" && npm run dev"

echo.
echo Startup commands sent.
echo Frontend: http://localhost:5174/
echo ML docs:  http://127.0.0.1:8000/docs
echo.
echo Wait until the Vite terminal displays its Local URL.
echo If it uses a different port, open the URL shown in that terminal.
pause
