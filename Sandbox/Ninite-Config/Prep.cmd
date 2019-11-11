explorer.exe C:\Users\WDAGUtilityAccount\Desktop\Ninite\Prep.exe"
Powershell Set-ExecutionPolicy unrestricted
Powershell -file C:\Users\WDAGUtilityAccount\Desktop\Ninite\Set-WallPaper.ps1
Timeout 10
RUNDLL32.EXE USER32.DLL,UpdatePerUserSystemParameters 1, True
Pause
