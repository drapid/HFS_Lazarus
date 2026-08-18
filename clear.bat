@IF EXIST "*.~*" del *.~*
@IF EXIST "*.dcu" del *.dcu
@IF EXIST "*.ddp" del *.ddp
@IF EXIST "*.ppu" del *.ppu
@IF EXIST "*.o" del *.o
@IF EXIST "*.bak" del *.bak
@IF EXIST "*.identcache " del *.identcache 
@IF EXIST ".\Units\*.dcu" del .\Units\*.dcu
@IF EXIST ".\UnitsWin32\*.dcu" del .\UnitsWin32\*.dcu
@IF EXIST ".\UnitsWin64\*.dcu" del .\UnitsWin64\*.dcu
@IF EXIST ".\Units\x86_64-win64\*.dcu" del .\Units\x86_64-win64\*.dcu
@IF EXIST ".\Units\x86_64-win64\*.o" del .\Units\x86_64-win64\*.o
@IF EXIST ".\Units\x86_64-win64\*.ppu" del .\Units\x86_64-win64\*.ppu
@IF EXIST "Prefs\__history\*" del /q Prefs\__history\*
@IF EXIST "Prefs\*.bak" del /q Prefs\*.bak
@IF EXIST "Prefs\*.dcu" del /q Prefs\*.dcu
@IF EXIST "__history\*" del /q __history\*
@IF EXIST "srv\__history\*" del /q srv\__history\*
@IF EXIST "srv\*.bak" del /q srv\*.bak
@IF EXIST "lib\__history\*" del /q lib\__history\*
@IF EXIST "lib\*.bak" del /q lib\*.bak

@rem exit