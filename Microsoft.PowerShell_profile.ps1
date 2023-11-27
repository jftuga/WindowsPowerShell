# remove undesired aliases
Remove-Item Alias:\cat -force
Remove-Item Alias:\curl -force
Remove-Item Alias:\diff -force
Remove-Item Alias:\ls -force
Remove-Item Alias:\sv -force
Remove-Item Alias:\wget -force

# function: of: Out-File - save file in ASCII format
function of($fname) { $input | Out-File -Encoding ascii $fname }

# function: rf: Read-File (this is much faster than using Get-Content)
function rf($fname) { [System.IO.File]::ReadLines($fname) }

# function: ph: (print help) GUI for Get-Help
function ph($topic) { Get-Help $topic | Out-GridView -PassThru | Get-Help -ShowWindow }

# function: diron: directory, sort by name
function diron($name) {
    Get-ChildItem $name | Sort-Object Name | Select-Object LastWriteTime, Length, Name | `
    format-table `
        @{Label="Time";Expression={$_.LastWriteTime.ToString("yyyy-MM-dd HH:MM")}},
        @{Label="Length";Expression={('{0:N0}' -f $_.Length).PadLeft(13)}},
        Name `
}

# function: dirod: directory, sort by date
function dirod($name) {
    Get-ChildItem $name | Sort-Object LastWriteTime, Name | Select-Object LastWriteTime, Length, Name | `
    format-table `
        @{Label="Time";Expression={$_.LastWriteTime.ToString("yyyy-MM-dd HH:MM")}},
        @{Label="Length";Expression={('{0:N0}' -f $_.Length).PadLeft(13)}},
        Name `
}

# function: diros: directory, sort by size
function diros($name) {
    Get-ChildItem $name | Sort-Object Length, Name | Select-Object LastWriteTime, Length, Name | `
    format-table `
        @{Label="Time";Expression={$_.LastWriteTime.ToString("yyyy-MM-dd HH:MM")}},
        @{Label="Length";Expression={('{0:N0}' -f $_.Length).PadLeft(13)}},
        Name `
}

# function: diroe: directory, sort by extension
function diroe($name) {
    Get-ChildItem $name | Sort-Object Extension,Name | Select-Object LastWriteTime, Length, Name | `
    format-table `
        @{Label="Time";Expression={$_.LastWriteTime.ToString("yyyy-MM-dd HH:MM")}},
        @{Label="Length";Expression={('{0:N0}' -f $_.Length).PadLeft(13)}},
        Name `
}

# function: dirsb: directory, full name
function dirsb($filter, $depth) {
    $f = $filter
    $d = $depth
    if( $null -eq $filter) {
        $f = ""
        $d = 1000
    }

    if( $null -eq $d ) {
        $d = 0
    }
    (Get-ChildItem -Recurse -depth $d -filter $f).FullName -replace "\\.\\", "\"
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

# function: rg1: ripgrep with a max depth of 1
function rg1($pattern) {
	rg --max-depth 1 $pattern
}

# function: title: change window title
function title($t) {
    $host.UI.RawUI.WindowTitle = $t
}

# function: Get-Grps: show all AD groups a user is a member
function Get-Grps($username_id) {
    ([ADSISEARCHER]"samaccountname=$username_id").Findone().Properties.memberof -replace '^CN=([^,]+).+$','$1' | Sort-Object | Select-Object @{Name="Group Name";expression={$_}}
}

# Source: http://webcache.googleusercontent.com/search?q=cache:Eq41nBrlGzAJ:https://www.powershellbros.com/get-process-remotely-for-user-using-powershell/&hl=en&gl=us&strip=1&vwsrc=0
# Examples:
#     Get-UserProcess -Computername ADFS01,ADFS02,ADFS03 -Verbose | Sort-Object ProcessName
#     Get-UserProcess -Computername (GC "C:\temp\servers.txt") -Verbose | Out-GridView -Title "Procs"
#     Get-UserProcess -Computername ADFS01,ADFS02,ADFS03 -Username "system" -Verbose | Sort-Object Processname | format-table
#     Get-UserProcess -Computername ADFS01,ADFS02,ADFS03 -Username "system" -Verbose | Sort-Object Processname | Export-Csv -Path C:\users\$env:username\desktop\results.csv -NoTypeInformation

# function: Get-UserProess: show processes on remote system
Function Get-UserProcess {
    [CmdletBinding()]
    param (
        [Parameter(Position=0, Mandatory = $true, HelpMessage="Provide server names", ValueFromPipeline = $true)] $Computername,
        [Parameter(Position=1, Mandatory = $false, HelpMessage="Provide username", ValueFromPipeline = $false)] $UserName = $env:USERNAME
    )
    $Array = @()
    Foreach ($Comp in $Computername) {
        $Comp = $Comp.Trim()
        Write-Verbose "Processing $Comp"
        Try{
            $Procs = $null
            $Procs = Invoke-Command $Comp -ErrorAction Stop -ScriptBlock{param($Username) Get-Process -IncludeUserName | Where-Object {$_.username -match $Username}} -ArgumentList $Username
            If ($Procs) {
                Foreach ($P in $Procs) {
                    $Object = $Mem = $CPU = $null
                    $Mem = [math]::Round($P.ws / 1mb,1)
                    $CPU = [math]::Round($P.CPU, 1)
                    $Object = New-Object PSObject -Property ([ordered]@{
                                "ServerName"             = $Comp
                                "UserName"               = $P.username
                                "ProcessName"            = $P.processname
                                "CPU"                    = $CPU
                                "Memory(MB)"             = $Mem
                    })
                    $Array += $Object
                }
            }
            Else {
                Write-Verbose "No process found for $Username on $Comp"
            }
        }
        Catch{
            Write-Verbose "Failed to query $Comp"
            Continue
        }
    }
    If ($Array) {
        Return $Array
    }
}

# function: Get-Weather: 3-day forecast
Function Get-Weather{
    (Invoke-WebRequest "http://wttr.in/" -UserAgent "curl").Content
}
New-Alias wttr Get-Weather -ErrorAction SilentlyContinue

# function sv: activate a python virtual environment
Function sv {
    .\venv\Scripts\activate
}

# function pmvv: create python virtual environment
Function pmvv {
    python -m venv venv
    sv
    python -m pip install --upgrade pip
    pip install wheel boto3 flake8 black
    pip3 list
}

# Search path for Import-Module
$env:PSModulePath = "$env:PSModulePath;$env:USERPROFILE\Documents\WindowsPowerShell\Modules"

# change windows title to: 'user@hostname date/time'  -or-  'user@hostname [ADMIN] date/time'
$host.UI.RawUI.WindowTitle = $(if (Test-Elevated) {"[ADMIN] "} else {""}) + $env:username.ToLower() + "@" + $env:computername.ToLower() + " "  + (get-date -Format g)

# emulate MacOS
Set-Alias -name pbcopy -value Set-Clipboard
Set-Alias -name pbpaste -value Get-Clipboard

# other aliases
Set-Alias -name goland -value "C:\Program Files (x86)\JetBrains\GoLand 2023.2\bin\goland64.exe"
Set-Alias -name wm -value "C:\Program Files\WinMerge\WinMergeU.exe"
Set-Alias -name tf -value "C:\ProgramData\chocolatey\bin\terraform.exe"
Set-Alias -name zen -value "C:\Users\$env:USERNAME\venv_zen_3.11\Scripts\Activate.ps1"

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
