@echo off
pushd %~dp0
cd etc\builds
call python build.py %*
popd
