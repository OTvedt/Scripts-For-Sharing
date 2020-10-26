# Script to search for and delete a named file in structure
$files = ls -Path . -Filter "annoying.txt" -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
ForEach ($item in $files) {
Remove-Item -force -path $item
}
