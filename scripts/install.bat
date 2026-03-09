@ECHO OFF
REM ================================================================
REM Oracle Forms Migration Skill — Installer for Windows
REM Copia el skill a %USERPROFILE%\.claude\skills\
REM ================================================================

SETLOCAL ENABLEDELAYEDEXPANSION

SET SCRIPT_DIR=%~dp0
SET REPO_DIR=%SCRIPT_DIR%..
SET SKILL_SRC=%REPO_DIR%\skills\oracle-forms-migration
SET SKILL_DST=%USERPROFILE%\.claude\skills\oracle-forms-migration

ECHO === Oracle Forms Migration Skill — Instalador ===
ECHO.

REM 1. Verificar Java
ECHO [1/4] Verificando Java...
WHERE java >NUL 2>&1
IF %ERRORLEVEL% EQU 0 (
    java -version 2>&1 | findstr /i "version"
    ECHO   OK: Java encontrado
) ELSE (
    ECHO   ADVERTENCIA: Java no encontrado en PATH.
    ECHO   frmf2xml y rdf2xml requieren Java 8+.
    ECHO   Descargar: https://adoptium.net/temurin/releases/
)

REM 2. Verificar Claude Code
ECHO [2/4] Verificando Claude Code...
IF EXIST "%USERPROFILE%\.claude" (
    ECHO   OK: .claude encontrado
) ELSE (
    ECHO   ERROR: .claude no existe. Instala Claude Code primero.
    EXIT /B 1
)

REM 3. Instalar
ECHO [3/4] Instalando skill...
IF NOT EXIST "%SKILL_DST%" MKDIR "%SKILL_DST%"
XCOPY "%SKILL_SRC%\*" "%SKILL_DST%\" /S /E /Y /Q >NUL
ECHO   OK: Skill instalado en %SKILL_DST%

REM 4. Verificar
ECHO [4/4] Verificando...
SET ERRORS=0
IF NOT EXIST "%SKILL_DST%\SKILL.md" (ECHO   ERROR: SKILL.md falta & SET /A ERRORS+=1)
IF NOT EXIST "%SKILL_DST%\tools\frmf2xml\frmxmltools.jar" (ECHO   ERROR: frmxmltools.jar falta & SET /A ERRORS+=1)
IF NOT EXIST "%SKILL_DST%\tools\rdf2xml\rdf2xml.jar" (ECHO   ERROR: rdf2xml.jar falta & SET /A ERRORS+=1)

IF !ERRORS! EQU 0 (ECHO   OK: Todo verificado)

ECHO.
ECHO === Instalacion completada ===
ECHO.
ECHO Uso:
ECHO   1. Abri Claude Code en cualquier proyecto
ECHO   2. Escribi: /oracle-forms-migration
ECHO   3. Segui las instrucciones del agente
ECHO.

ENDLOCAL
