@echo off

REM Get the port number from the command line
IF "%~1"=="" (
    set "PORT=0"
) ELSE (
    set "PORT=%~1"
)

REM Get the image name from the file
set /p IMAGE=<.podman/image_name

podman build -t %IMAGE% .

REM Copy the run script from the image
FOR /F %%i IN ('podman create %IMAGE%') DO SET CID=%%i
podman cp %CID%:/.podman/interface.ps1 .interface.ps1 >nul
podman rm -v %CID% >nul

REM Run the image's interface script
REM powershell -ExecutionPolicy Bypass -File .interface.ps1 %IMAGE%
IF %PORT% NEQ 0 (
    powershell -ExecutionPolicy Bypass -File .interface.ps1 -image %IMAGE% -port %PORT%
) ELSE (
    powershell -ExecutionPolicy Bypass -File .interface.ps1 -image %IMAGE%
)

pause
