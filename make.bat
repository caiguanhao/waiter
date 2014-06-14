@echo off
set /p key=<key
echo $Key = "%key%" > key.au3
echo Compiling waiter.exe...
"C:\Program Files (x86)\AutoIt3\Aut2Exe\Aut2exe.exe" ^
  /in "waiter.au3" ^
  /out "waiter.exe" ^
  /x86 /comp 4 /pack ^
  /companyname cgh.io ^
  /filedescription "Download and run bat script." ^
  /legalcopyright "Copyright (c) 2014 Cai Guanhao (Choi Goon-ho)" ^
  /console
