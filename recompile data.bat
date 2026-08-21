@ECHO OFF
BuiltTime.exe
@REM set fpc_bin_path=C:\codetyphon\fpc\fpc32\bin\i386-win32\
set fpc_bin_path=C:\Coding\lazarus\fpc\3.2.2\bin\x86_64-win64\
%fpc_bin_path%fpcres.exe res\data.rc -o Units\data.res  -of res
exit
@REM Copy rsvars.bat from Delphi bin directory
@ECHO SET variable D_COMPONENTS with path for components
@call rsvars.bat
@ECHO compiling
%BDS%\bin\brcc32 res\data.rc -fodata.res
