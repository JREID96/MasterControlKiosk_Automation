### KioskCreator v1.1.0
### This script automates the creation of kiosk computers
### Jarred Reid - 2019

Write-Host "You must run this script as the Administrator account initially!"
Write-Host "The script will automatically log you out, please login in as the newly created 'kioskmode' user afterwards and re-run the script."

Read-Host -Prompt "Press any key to execute the script."

Clear-Host

Write-Host "Creating kioskmode user...."
### Create kioskmode user (Here you are first creating the user, then piping to set the properties of said user.)
New-LocalUser -Name "kioskmode" -NoPassword -AccountNeverExpires -UserMayNotChangePassword -FullName "Kiosk User" -Description "User for the Kiosk Mode account" | Set-LocalUser -PasswordNeverExpires $true
Write-Host "User created."

Write-Host "Adding kioskmode user to 'users' group...."
### Getting the prompt to change the user's password upon logon, need to figure out how to disable this #######################################
Add-LocalGroupMember -Group "Users" -Member "kioskmode"
Write-Host "kioskmode added to 'users' group."


Write-Host "Removing ITAdmin account...."
### Remove ITAdmin account
Remove-LocalUser -Name "ITAdmin"
Write-Host "ITAdmin Account removed."

### Set kioskmode user to automatically log on to the computer 

Write-Host "Configuring kioskmode to login on Windows startup...."
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
$DefaultUsername = "kioskmode"
Set-ItemProperty -Path $RegPath "DefaultUsername" -Value "$DefaultUsername" -type String
Set-ItemProperty -Path $RegPath "AutoAdminLogon" -Value "1" -type String
Write-Host "Account configured."

Write-Host "Uninstalling OneDrive...."
### Uninstall OneDrive
taskkill /f /im OneDrive.exe
& "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" /uninstall
Write-Host "Task killed and OneDrive has been uninstalled."

Write-Host "You will now be logged out of the Administrator account."
Write-Host "Please sign in as the 'Kiosk User' account and run this script again."
Read-Host -Prompt "Press any key to continue."

New-Item C:\Temp\stage2.mcka
shutdown -l

#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#

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
