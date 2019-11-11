Function Set-WallPaper($Value)

{

 Set-ItemProperty -path 'HKCU:\Control Panel\Desktop\' -name wallpaper -value $value

 rundll32.exe user32.dll, UpdatePerUserSystemParameters 1, True

}

Set-WallPaper -value "C:\Users\WDAGUtilityAccount\Desktop\WallPaper\Background.bmp"
