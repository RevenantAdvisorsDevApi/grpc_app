@echo off
cd .\RUN
start START_SERVER.bat
\timeout 1
start START_MAIN_APP.bat