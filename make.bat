@echo off

taskkill /f /im waiter.exe >nul 2>nul
taskkill /f /im waiterd.exe >nul 2>nul

set /p key=<key
echo $Key = "%key%" > key.au3

echo Compiling waiter.exe...
"C:\Program Files (x86)\AutoIt3\Aut2Exe\Aut2exe.exe" ^
  /in "waiter.au3" ^
  /out "waiter.exe" ^
  /x86 /comp 4 /pack ^
  /companyname cgh.io ^
  /filedescription "Get and execute commands." ^
  /legalcopyright "Copyright (c) 2014 Cai Guanhao (Choi Goon-ho)" ^
  /console

echo Compiling waiterd.exe...
"C:\Program Files (x86)\AutoIt3\Aut2Exe\Aut2exe.exe" ^
  /in "waiterd.au3" ^
  /out "waiterd.exe" ^
  /x86 /comp 4 /pack ^
  /companyname cgh.io ^
  /filedescription "A waiter daemon." ^
  /legalcopyright "Copyright (c) 2014 Cai Guanhao (Choi Goon-ho)"
