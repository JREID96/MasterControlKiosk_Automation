### KioskCreator v1.2.0
### This script automates the creation of kiosk computers
### Jarred Reid - 2019

Clear-Host

function InstallStageOne {

    ### Create kioskmode user (Here you are first creating the user, then piping to set the properties of said user.)
    Write-Host "Creating kioskmode user...."
    New-LocalUser -Name "kioskmode" -NoPassword -AccountNeverExpires -UserMayNotChangePassword -FullName "Kiosk User" -Description "User for the Kiosk Mode account" | Set-LocalUser -PasswordNeverExpires $true
    Write-Host "User created."
    
    Write-Host

    Write-Host "Adding kioskmode user to 'users' group...."
    Add-LocalGroupMember -Group "Users" -Member "kioskmode"
    Write-Host "kioskmode added to 'users' group."
    
    Write-Host
    
      ### Remove ITAdmin account
    Write-Host "Removing ITAdmin account...."
    Remove-LocalUser -Name "ITAdmin"
    Write-Host "ITAdmin Account removed."
    
    Write-Host

    ### Set kioskmode user to automatically log on to the computer 
    Write-Host "Configuring kioskmode user to auto-login on Windows startup...."
    $RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
    $DefaultUsername = "kioskmode"
    Set-ItemProperty -Path $RegPath "DefaultUsername" -Value "$DefaultUsername" -type String
    Set-ItemProperty -Path $RegPath "AutoAdminLogon" -Value "1" -type String
    Write-Host "Account auto-login configured."
    
    Write-Host

    Write-Host "Uninstalling OneDrive...."
    ### Uninstall OneDrive
    taskkill /f /im OneDrive.exe
    & "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" /uninstall
    Write-Host "Task killed and OneDrive has been uninstalled."
    
    Write-Host

    #### Install Acrobat Reader
    Write-Host "Installing Acrobat Reader DC...."
    Start-Process C:\Temp\MasterControl\programs\AcroRdrDC1901220034_en_US.exe -Wait -ArgumentList /sAll
    Write-Host "Acrobat Reader DC installed."

    Write-Host

    #### Install LibreOffice
    Write-Host 'Installing LibreOffice....'
    Start-Process msiexec -Wait -ArgumentList '/i C:\Temp\MasterControl\programs\LibreOffice_6.2.5_Win_x64.msi /qn'
    Write-Host 'LibreOffice installed.'

    Write-Host

    ### Log out of admin account
    Write-Host "You will now be logged out of the Administrator account."
    Write-Host "Please sign in as the 'Kiosk User' account and run this script again."
    Read-Host -Prompt "Press any key to continue."

    Write-Host 

    Write-Host "Creating checkpoint file...."
    New-Item C:\Temp\MasterControl\stage1complete.mcka
    Write-Host "Checkpoint file has been created."

    shutdown -l
}

#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#

function InstallStageTwo {
### Configure MasterControl shortcuts

Write-Host "Installing MasterControl shortcut...."
Copy-Item -Path "C:\Temp\MasterControl\shortcut\MasterControl.lnk" -Destination "C:\Users\kioskmode\AppData\Roaming\Microsoft\Windows\Start Menu\Programs"
Remove-Item -Path "C:\Users\kioskmode\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Accessories\Internet Explorer.lnk"
Write-Host "Shortcut installed."
### Set ACL permissions to allow Admin access to kioskmode user folder ########################################

Write-Host

### Get the SID for the kioskmode user
Write-Host "Obtaining SID...."
$User = New-Object System.Security.Principal.NTAccount("kioskmode")
$sid = $User.Translate([System.Security.Principal.SecurityIdentifier]).value
Write-Host "SID obtained."

Write-Host

### Inject SID into Registry Keys
Write-Host "Injecting regkeys into registry...."
(Get-Content "C:\Temp\MasterControl\regkeys\Set_Restrictions.reg") -replace 'insertSIDhere', $sid | Set-Content "C:\Temp\MasterControl\regkeys\Set_Restrictions.reg"
regedit.exe /s "C:\Temp\MasterControl\regkeys\Set_Restrictions.reg"
Write-Host "Regkeys injected."

Write-Host

### Enable Dummy Proxy for LAN
Write-Host "Configuring Internet Explorer proxy settings...."
$regKey="HKU:\$sid\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
$proxy = "0.0.0.0:80"
$whitelist = {https://*.mastercontrol.com;http://windowsupdate.microsoft.com;http://*.windowsupdate.microsoft.com;https://*.windowsupdate.microsoft.com;http://download.windowsupdate.com;http://*.download.windowsupdate.com;http://*.windowsupdate.com;http://wustat.windows.com;http://ntservicepack.microsoft.com;http://*update.microsoft.com;https://*update.microsoft.com;http://download.windowsupdate.com;http://*.microsoft.com;http://*.adobe.com;http://keystoneind.mastercontrol.com;http://*learnshare.com;https://lms2.learnshare.com}

Write-Host

### Mount HKEY_USERS as a PSDrive in order to manipulate the registry
Write-Host "Mounting HKEY_USERS hive.... " 
New-PSDrive HKU Registry HKEY_USERS 
Write-Host "Hive mounted."

Set-ItemProperty -path $regkey ProxyEnable 1
Set-ItemProperty -path $regKey ProxyServer -value $proxy
Set-ItemProperty -path $regKey ProxyOverride -value $whitelist
Write-Host "Proxy configured and enabled."

### Install MasterControl Provisioned Package
Write-Host "Installing provisioned package...."
Install-ProvisioningPackage -PackagePath "C:\Temp\MasterControl\provisioned_package\MasterControl.ppkg" -QuietInstall
Write-Host "Provisioned package installed successfully."

Write-Host 

Write-Host "Removing checkpoint file...."
Remove-Item C:\Temp\stage1complete.mcka
Write-Host "File removed."

Read-Host -prompt "MasterControl kiosk has been configured successfully. Press any key to reboot the machine."
shutdown -r -t 30
}


$file = "C:\Temp\stage1complete.mcka"
if((Test-Path $file))
{
    Write-Host "Previous install configuration detected. Please make sure you are signed in as the 'kioskmode' user inside a non-elevated Powershell window"
    Read-Host -Prompt "Press any key to execute the script."
    InstallStageTwo
}

if(!(Test-Path $file))
{
    Write-Host "No previous install configuration detected. Please run this script in an elevated Powershell window."
    Read-Host -Prompt "Press any key to execute the script."
    InstallStageOne
}
