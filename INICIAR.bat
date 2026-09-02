@echo off
title BarberFlow - Servidor local
where py >nul 2>nul
if %errorlevel%==0 (
  start "" http://127.0.0.1:8000
  py -m http.server 8000
  goto :eof
)
where python >nul 2>nul
if %errorlevel%==0 (
  start "" http://127.0.0.1:8000
  python -m http.server 8000
  goto :eof
)
echo Python nao encontrado.
echo Para GitHub Pages isso nao e necessario.
pause
