@echo off
pushd %~dp0
call python build.py %*
popd
