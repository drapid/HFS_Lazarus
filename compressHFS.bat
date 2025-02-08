@set BB=324
@IF "%1" EQU "x64" goto x64
@ECHO Processing x86
@copy bin\Win32\hfs_i386.exe "bin\Win32\HFS%BB%_RDfpc.exe"
@upx.exe -9 --lzma "bin\Win32\HFS%BB%_RDfpc.exe"
exit
:x64
@ECHO Processing x64
@copy bin\Win64\hfs_x86_64.exe "bin\Win64\HFS%BB%_RDx64fpc.exe"
@upx.exe -9 --lzma "bin\Win64\HFS%BB%_RDx64fpc.exe"
