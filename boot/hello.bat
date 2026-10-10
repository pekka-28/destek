@rem hello.bat

@echo off
setlocal
pushd "%~dp0"
copy /b /y "Bootstrap.bin"+"Hello.bin" "HelloStaged.bin"
if errorlevel 1 goto failed
popd
exit /b 0
:failed
popd
exit /b 1
