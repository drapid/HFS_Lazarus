@ECHO OFF
BuiltTime.exe
@REM Copy rsvars.bat from Delphi bin directory
@ECHO SET variable D_COMPONENTS with path for components
@call rsvars.bat
@ECHO compiling
%BDS%\bin\brcc32 res\data.rc -fodata.res
