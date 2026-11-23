Get-ChildItem "$env:LOCALAPPDATA\BlackPen" -Recurse -File | Select-Object @{n='Path';e={$_.FullName.Replace("$env:LOCALAPPDATA\BlackPen\",'')}}, Length, LastWriteTime | Format-Table -AutoSize
