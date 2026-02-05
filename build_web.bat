@echo off
REM Script de compilacion para Flutter Web - Produccion
REM Uso: build_web.bat

echo.
echo ========================================
echo    Compilando Flutter Web (Produccion)
echo ========================================
echo.

REM Limpiar builds anteriores
echo [1/4] Limpiando builds anteriores...
call flutter clean
if errorlevel 1 goto :error

REM Obtener dependencias
echo [2/4] Obteniendo dependencias...
call flutter pub get
if errorlevel 1 goto :error

REM Compilar para web
echo [3/4] Compilando aplicacion web...
call flutter build web --release --dart-define=FLUTTER_APP_ENV=production
if errorlevel 1 goto :error

echo.
echo ========================================
echo    [EXITO] Compilacion completada
echo ========================================
echo.
echo Archivos compilados en: build\web\
echo.
echo Proximos pasos:
echo   1. Copiar carpeta build\web a tu servidor
echo   2. Configurar Nginx para servir estos archivos
echo   3. Asegurar que API_URL apunta a tu dominio
echo.
pause
exit /b 0

:error
echo.
echo ========================================
echo    [ERROR] La compilacion fallo
echo ========================================
echo Revisa los errores arriba.
echo.
pause
exit /b 1
