#!/bin/bash

sed 's/\r//g' available.bat > enabled.bat_
perl -p -i -e 's/\n/\r\n/' enabled.bat_
iconv -f utf8 -t gb2312 enabled.bat_ > enabled.bat
rm -f enabled.bat_
