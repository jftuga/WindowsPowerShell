# function: of: Out-File - save file in ASCII format
function of($fname) { $input | Out-File -Encoding ascii $fname }

# function: rf: Read-File (this is much faster than using Get-Content)
function rf($fname) { [System.IO.File]::ReadLines($fname) }

# function: ph: (print help) GUI for Get-Help
function ph($topic) { Get-Help $topic | Out-GridView -PassThru | Get-Help -ShowWindow }

# function: diron: directory, sort by name
function diron($dname) {
    Get-ChildItem | Sort-Object Name | Select-Object LastWriteTime, Length, Name | `
    format-table `
        @{Label="Time";Expression={$_.LastWriteTime.ToString("yyyy-MM-dd HH:MM")}},
        @{Label="Length";Expression={('{0:N0}' -f $_.Length).PadLeft(13)}},
        Name `
}

# function: dirod: directory, sort by date
function dirod($dname) {
    Get-ChildItem  | Sort-Object LastWriteTime | Select-Object LastWriteTime, Length, Name | `
    format-table `
        @{Label="Time";Expression={$_.LastWriteTime.ToString("yyyy-MM-dd HH:MM")}},
        @{Label="Length";Expression={('{0:N0}' -f $_.Length).PadLeft(13)}},
        Name `
}

# function: diros: directory, sort by size
function diros($dname) {
    Get-ChildItem -File $dname | Sort-Object Length | Select-Object LastWriteTime, Length, Name | `
    format-table `
        @{Label="Time";Expression={$_.LastWriteTime.ToString("yyyy-MM-dd HH:MM")}},
        @{Label="Length";Expression={('{0:N0}' -f $_.Length).PadLeft(13)}},
        Name `
}
# function: dirsb: directory, full name
function dirsb($dname) { 
    (Get-ChildItem -Recurse $dname).FullName
}

# function: rev: reverse the output of a pipeline
function rev { 
    $arr = @($input)
    [array]::reverse($arr)
    $arr
}

# function: env: similar to using 'bash set' under a cmd prompt
function env() { 
    Get-ChildItem env: | ft -HideTableHeaders -Wrap
    Get-Content $PROFILE | select-string -Pattern "^# function:" | `
    format-table @{Label="Functions";Expression={$_.Line}}
}

# function: Test-Elevated: Is PowerShell running as Admin?
function Test-Elevated {
    $wid = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $prp = New-Object System.Security.Principal.WindowsPrincipal($wid)
    $adm = [System.Security.Principal.WindowsBuiltInRole]::Administrator
    $prp.IsInRole($adm)
  }

# function: scoops: fast scoop search (this also uses ripgrep for highlightling)
function scoops($pkg) {
    Get-ChildItem $env:USERPROFILE\scoop\buckets\*\bucket\*$pkg* | `
    ForEach-Object { $p = $_.FullName.split("\"); $v = Get-Content $_ | ConvertFrom-Json | `
    Select-Object version; $p[5] + ":" + $p[7] + $v | rg ":.*?json" }
}

# function: title: change window title
function title($t) {
    $host.UI.RawUI.WindowTitle = $t
}

# Search path for Import-Module
$env:PSModulePath = "$env:PSModulePath;$env:USERPROFILE\Documents\WindowsPowerShell\Modules"

# change windows title to: 'user@hostname date/time'  -or-  'user@hostname [ADMIN] date/time'
$host.UI.RawUI.WindowTitle = $(if (Test-Elevated) {"[ADMIN] "} else {""}) + $env:username.ToLower() + "@" + $env:computername.ToLower() + " "  + (get-date -Format g)

# remove undesired aliases
Remove-Item Alias:\curl -force
Remove-Item Alias:\diff -force
Remove-Item Alias:\ls -force
Remove-Item Alias:\wget -force

# emulate MacOS
Set-Alias -name pbcopy -value Set-Clipboard
Set-Alias -name pbpaste -value Get-Clipboard

# other aliases
Set-Alias -name wm -value "C:\Program Files\WinMerge\WinMergeU.exe"
