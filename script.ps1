### KioskCreator v1.2.3
### This script automates the creation of kiosk computers
### Jarred Reid - 2019

Clear-Host

Write-Host "KioskCreator"
Write-Host "This script automates the creation of kiosk computers."

Write-Host

#-#-#-#-#-#-#-#-#-#
### Begin Stage 1
#-#-#-#-#-#-#-#-#-#
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
    
    Write-Host "Creating checkpoint file...."
    New-Item C:\Temp\MasterControl\stage1complete.mcka
    Write-Host "Checkpoint file has been created."

    Write-Host

    ### Log out of admin account
    Write-Host "You will now be logged out of the Administrator account."
    Write-Host "Please sign in as the 'Kiosk User' account and run this script again."
    Read-Host -Prompt "Press the Enter key to continue."

    shutdown -l
}
#-#-#-#-#-#-#-#-#-#
### End Stage 1
#-#-#-#-#-#-#-#-#-#


#-#-#-#-#-#-#-#-#-#
### Begin Stage 2
#-#-#-#-#-#-#-#-#-#
function InstallStageTwo {

### Configure MasterControl shortcuts
Write-Host "Installing MasterControl shortcut...."
Copy-Item -Path "C:\Temp\MasterControl\shortcut\MasterControl.lnk" -Destination "C:\Users\kioskmode\AppData\Roaming\Microsoft\Windows\Start Menu\Programs"
Remove-Item -Path "C:\Users\kioskmode\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Accessories\Internet Explorer.lnk"
Write-Host "Shortcut installed."

Write-Host

### Get the SID for the kioskmode user
Write-Host "Obtaining 'kioskmode' SID...."
$User = New-Object System.Security.Principal.NTAccount("kioskmode")
$sid = $User.Translate([System.Security.Principal.SecurityIdentifier]).value
Write-Host "SID obtained."

Write-Host

### Enable Dummy Proxy for LAN
$regKey="HKU:\$sid\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
$proxy = "0.0.0.0:80"
$whitelist = {}
###

Write-Host

### Mount HKEY_USERS as a PSDrive in order to manipulate the registry
Write-Host "Mounting HKEY_USERS registry hive.... " 
New-PSDrive HKU Registry HKEY_USERS 
Write-Host "Registry hive mounted."

Write-Host "Configuring proxy "
Set-ItemProperty -path $regkey ProxyEnable 1
Set-ItemProperty -path $regKey ProxyServer -value $proxy
Set-ItemProperty -path $regKey ProxyOverride -value $whitelist
Write-Host "Proxy configured."

### Inject SID into Registry Keys
Write-Host "Configuring Internet Explorer security settings...."
(Get-Content "C:\Temp\MasterControl\regkeys\IE_Settings.reg") -replace 'insertSIDhere', $sid | Set-Content "C:\Temp\MasterControl\regkeys\IE_Settings.reg"
Start-Process "regedit.exe" -Argument "/s C:\Temp\MasterControl\regkeys\IE_Settings.reg" -Verb RunAs
Write-Host "Security settings have been applied."

### Install MasterControl Provisioned Package
Write-Host "Installing provisioned package...."
Install-ProvisioningPackage -PackagePath "C:\Temp\MasterControl\provisioned_package\MasterControl.ppkg" -QuietInstall
Write-Host "Provisioned package installed successfully."

Write-Host 

Write-Host "Removing checkpoint file...."
Remove-Item C:\Temp\MasterControl\stage1complete.mcka
Write-Host "Checkpoint file removed."

Read-Host -prompt "Kiosk has been configured successfully. Press the Enter key to reboot the machine."

shutdown -r -t 0
}
#-#-#-#-#-#-#-#-#-#
### End Stage 2
#-#-#-#-#-#-#-#-#-#


$file = "C:\Temp\MasterControl\stage1complete.mcka"
if((Test-Path $file))
{
    Write-Host "Previous install configuration detected. Please make sure you are signed in as the 'kioskmode' user inside a non-elevated Powershell window"
    Read-Host -Prompt "Press the Enter key to execute the script."
    InstallStageTwo
}

if(!(Test-Path $file))
{
    Write-Host "No previous install configuration detected."

    # Elevate the script if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Read-Host -prompt "The Powershell window needs to be run as an administrator. Press the Enter key to elevate...."
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
     $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
     Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
     Exit
    }
   }
   
    Read-Host -Prompt "Press the Enter key to execute the script."
    InstallStageOne
}
