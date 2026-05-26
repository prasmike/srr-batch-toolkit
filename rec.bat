@echo off
setlocal ENABLEDELAYEDEXPANSION

rem ============================================================
rem  pyReScene SRR Batch Toolkit v0.9.0
rem  rec.bat - SRR reconstruction + optional SRS rebuild
rem ============================================================

rem ---- USER CONFIGURABLE PATH ----
set "PYRESCENE_DIR=C:\Tools\pyrescene"
set "RAR_DIR=%PYRESCENE_DIR%\rar"
set "CFV_EXE=C:\Tools\cfv-1.18.3\cfv.exe"

rem ---- EXE PATHS ----
set "SRR_EXE=%PYRESCENE_DIR%\srr.exe"
set "SRS_EXE=%PYRESCENE_DIR%\srs.exe"

rem ---- DEFAULTS ----
set "TEMP_DIR=%cd%"
set "OUTPUT_DIR=%cd%"
set "REBUILD_SAMPLES=0"

rem ---- PARAMETER PARSING ----
:parse
if "%~1"=="" goto params_done

if /i "%~1"=="-t" (
    set "TEMP_DIR=%~2"
    shift & shift
    goto parse
)

if /i "%~1"=="-o" (
    set "OUTPUT_DIR=%~2"
    shift & shift
    goto parse
)

if /i "%~1"=="-rs" (
    set "REBUILD_SAMPLES=1"
    shift
    goto parse
)

if /i "%~1"=="-h" (
    echo Usage: rec.bat [-t tempdir] [-o outputdir] [-rs]
    exit /b
)

echo Unknown parameter: %1
exit /b 1

:params_done

echo.
echo ============================================
echo   SRR Reconstruction Started
echo ============================================
echo.

set "SRR_COUNT=0"
set "SRS_OK=0"
set "SRS_FAIL=0"

set "SRS_SUM=%TEMP%\srs_summary.tmp"
del "%SRS_SUM%" >nul 2>&1

rem ---- PROCESS SRR FILES ----
for /f "delims=" %%A in ('dir /b /on *.srr 2^>nul') do (

    set "SRRFILE=%%A"
    set "SRRNAME=%%~nA"
    set "TARGET_DIR=%OUTPUT_DIR%\!SRRNAME!"

    echo --------------------------------------------
    echo Processing: !SRRFILE!
    echo Output dir: !TARGET_DIR!
    echo --------------------------------------------

    mkdir "!TARGET_DIR!" >nul 2>&1

    rem ---- Extract stored file list safely ----
    "%SRR_EXE%" -e "!SRRFILE!" > "%TEMP_DIR%\srr_list.tmp"

    rem ---- CREATE SUBDIRS ----
    for /f "tokens=1,* delims=:" %%X in ('findstr /c:"+Stored file name:" "%TEMP_DIR%\srr_list.tmp"') do (

        set "STORED=%%Y"

        if "!STORED:~0,1!"==" " set "STORED=!STORED:~1!"

        echo !STORED! | find "/" >nul
        if !errorlevel! equ 0 (

            set "PATHFIX=!STORED:\=/!"

            for /f "tokens=1* delims=/" %%i in ("!PATHFIX!") do (
                set "SUBDIR=%%i"
                mkdir "!TARGET_DIR!\!SUBDIR!" >nul 2>&1
            )
        )
    )

    rem ---- RECONSTRUCT RELEASE ----
    "%SRR_EXE%" "!SRRFILE!" -t "%TEMP_DIR%" -o "!TARGET_DIR!" -z "%RAR_DIR%"
    set "RET=!ERRORLEVEL!"

    if !RET! NEQ 0 (

        echo ERROR: Reconstruction failed for !SRRFILE!

    ) else (

        echo OK: !SRRFILE! reconstructed.
        set /a SRR_COUNT+=1
    )

    rem ---- MOVE STORED FILES INTO THEIR SUBDIRS ----
    for /f "tokens=1,* delims=:" %%X in ('findstr /c:"+Stored file name:" "%TEMP_DIR%\srr_list.tmp"') do (

        set "STORED=%%Y"

        if "!STORED:~0,1!"==" " set "STORED=!STORED:~1!"

        set "PATHFIX=!STORED:\=/!"

        for /f "tokens=1* delims=/" %%i in ("!PATHFIX!") do (
            set "SUBDIR=%%i"
            set "REST=%%j"
        )

        if not "!REST!"=="" (

            set "FILENAME=!REST!"

            if exist "!TARGET_DIR!\!FILENAME!" (

                move /Y "!TARGET_DIR!\!FILENAME!" "!TARGET_DIR!\!SUBDIR!\!FILENAME!" >nul

            ) else (

                for %%F in ("!TARGET_DIR!\*!FILENAME!*") do (
                    if exist "%%F" (
                        move /Y "%%F" "!TARGET_DIR!\!SUBDIR!\%%~nxF" >nul
                    )
                )
            )
        )
    )

    rem ========================================================
    rem  OPTIONAL SAMPLE REBUILD
    rem ========================================================

    if !REBUILD_SAMPLES! EQU 1 (

        echo.
        echo Rebuilding samples for !SRRNAME! ...

        set "FIRST_RAR="
        set "SRS_FOUND=0"

        rem ---- FIND FIRST RAR ----
        for %%R in ("!TARGET_DIR!\*.rar") do (
            if not defined FIRST_RAR (
                set "FIRST_RAR=%%R"
            )
        )

        if defined FIRST_RAR (

            rem ---- FIND SRS FILES ----
            echo   Searching for .srs files in !TARGET_DIR!

            for /f "delims=" %%S in ('dir /b /s "!TARGET_DIR!\*.srs" 2^>nul') do (

                echo   Found SRS: %%S

                set "SRS_FOUND=1"

                echo   Rebuilding: %%~nxS

                pushd "%%~dpS"

                "%SRS_EXE%" "%%~fS" "!FIRST_RAR!"
                set "SRS_RET=!ERRORLEVEL!"

                popd

                if !SRS_RET! EQU 0 (

                    echo   [OK ] %%~nxS
                    echo [OK ] !SRRNAME! >> "%SRS_SUM%"

                    del /q "%%~fS" >nul 2>&1

                    set /a SRS_OK+=1

                ) else (

                    echo   [FAIL] %%~nxS
                    echo [FAIL] !SRRNAME! >> "%SRS_SUM%"

                    set /a SRS_FAIL+=1
                )
            )

            if !SRS_FOUND! EQU 0 (
                echo   No .srs files found.
            )

        ) else (

            echo   [FAIL] No RAR files found.
            echo [FAIL] !SRRNAME! - No RAR files found >> "%SRS_SUM%"

            set /a SRS_FAIL+=1
        )
    )
)

if %SRR_COUNT%==0 (
    echo No .srr files found.
    exit /b
)

echo.
echo.
echo ============================================
echo   All SRR processed. Starting CRC checks.
echo ============================================
echo.

rem ---- CRC CHECK ----

set "REL_SUM=%TEMP%\cfv_rel_summary.tmp"
set "ERR_TMP=%TEMP%\cfv_errors.tmp"
set "CFV_OUT=%TEMP%\cfv_out.tmp"
set "CFV_ERR=%TEMP%\cfv_err.tmp"

del "%REL_SUM%" >nul 2>&1
del "%ERR_TMP%" >nul 2>&1
del "%CFV_OUT%" >nul 2>&1
del "%CFV_ERR%" >nul 2>&1

echo Starting CRC checks...
echo.

for /d %%D in ("%OUTPUT_DIR%\*") do (

    if exist "%%D\*.sfv" (

        echo Checking CRC in: %%D

        pushd "%%D"

        set "RELNAME=%%~nxD"
        set "HAS_ERROR=0"

        for %%S in ("*.sfv") do (

            echo   SFV: %%S

            "%CFV_EXE%" -f "%%S" > "%CFV_OUT%" 2>&1

            findstr /i /c:"badcrc" /c:"not found" /c:"No such file" /c:"crc does not match" "%CFV_OUT%" > "%CFV_ERR%"

            for %%X in ("%CFV_ERR%") do (

                if %%~zX GTR 0 (

                    set "HAS_ERROR=1"

                    echo. >> "%ERR_TMP%"
                    echo --- !RELNAME! --- >> "%ERR_TMP%"

                    for /f "delims=" %%L in (%CFV_ERR%) do (

                        set "LINE=%%L"

                        set "LINE=!LINE:No such file or directory=MiSSiNG!"
                        set "LINE=!LINE:not found=MiSSiNG!"
                        set "LINE=!LINE:crc does not match=BADCRC!"
                        set "LINE=!LINE:badcrc=BADCRC!"

                        echo !LINE! >> "%ERR_TMP%"
                    )
                )
            )
        )

        if !HAS_ERROR!==1 (
            echo [BAD] !RELNAME! >> "%REL_SUM%"
        ) else (
            echo [OK ] !RELNAME! >> "%REL_SUM%"
        )

        popd
    )
)

echo.
echo.
echo ============================================
echo   CRC SUMMARY
echo ============================================
echo.

echo Detailed errors:

if exist "%ERR_TMP%" (
    type "%ERR_TMP%"
) else (
    echo No CRC errors. All releases OK.
)

echo.
echo Release status:

type "%REL_SUM%"

if %REBUILD_SAMPLES%==1 (
    echo.
    echo.
    echo ============================================
    echo   SAMPLE REBUILD SUMMARY
    echo ============================================
    echo.

    if exist "%SRS_SUM%" (
        type "%SRS_SUM%"
    ) else (
        echo No sample rebuild operations performed.
    )

    echo.
    echo Successful sample rebuilds : %SRS_OK%
    echo Failed sample rebuilds     : %SRS_FAIL%
)

echo.
echo Done.
echo.

del "%TEMP_DIR%\srr_list.tmp" >nul 2>&1

echo Press any key to exit...
pause >nul

endlocal
exit /b