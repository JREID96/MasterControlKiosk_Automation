### KioskCreator v1.0.0
### This script automates the creation of kiosk computers
### Jarred Reid - 2019

Clear-Host

### Create kioskmode user
New-LocalUser "kioskmode" -NoPassword -FullName "Kiosk User" -Description "User for the Kiosk Mode account" -AccountNeverExpires
### Getting the prompt to change the user's password upon logon, need to figure out how to disable this #######################################
Add-LocalGroupMember -Group "Users" -Member "kioskmode"

### Remove ITAdmin account
Remove-LocalUser -Name "ITAdmin"

### Set kioskmode user to automatically log on to the computer 
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
$DefaultUsername = "kioskmode"
Set-ItemProperty -Path $RegPath "DefaultUsername" -Value "$DefaultUsername" -type String
Set-ItemProperty -Path $RegPath "AutoAdminLogon" -Value "1" -type String

### Uninstall OneDrive
taskkill /f /im OneDrive.exe
& "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" /uninstall

### Configure MasterControl shortcuts
Copy-Item -Path "C:\Temp\files\MasterControl.lnk" -Destination "C:\Users\kioskmode\AppData\Roaming\Microsoft\Windows\Start Menu\Programs"
Remove-Item -Path "C:\Users\kioskmode\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Accessories\Internet Explorer.lnk"
### Set ACL permissions to allow Admin access to kioskmode user folder ########################################

### Get the SID for the kioskmode user
$User = New-Object System.Security.Principal.NTAccount("kioskmode")
$sid = $User.Translate([System.Security.Principal.SecurityIdentifier]).value

### Inject SID into Registry Keys
(Get-Content "C:\Temp\Files\Set_Restrictions.reg") -replace 'insertSIDhere', $sid | Set-Content "C:\Temp\Files\Set_Restrictions.reg"
regedit.exe /s "C:\Temp\Files\Set_Restrictions.reg"
### The kioskmode user SID is not present in registry, need a fix #####################################

### Enable Dummy Proxy for LAN
$regKey="HKU:\$sid\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
$proxy = "0.0.0.0:80"
$whitelist = {enter domains}
New-PSDrive HKU Registry HKEY_USERS ### Mount HKEY_USERS as a PSDrive in order to manipulate

Set-ItemProperty -path $regkey ProxyEnable 1
Set-ItemProperty -path $regKey ProxyServer -value $proxy
Set-ItemProperty -path $regKey ProxyOverride -value $whitelist

### Install MasterControl Provisioned Package
Install-ProvisioningPackage -PackagePath "C:\Temp\Files\MasterControl3.0_Provisioned_Package\MasterControl3.0.ppkg" -QuietInstall

shutdown -r -t 30

### LibreOffice Install
