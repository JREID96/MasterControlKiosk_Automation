MasterControl Kiosk Deployment v1.2.3

This script automates the creation of the MasterControl kiosks. 
If regkey changes need to be made, please use the "Remove_Restrictions.reg" to merge original changes back into the registry.

Changelog:
1.2.3 - Fixed an issue where pages would not load properly due to Internet Explorer Intranet settings.
      - Removed unecessary UAC prompts by consolidating regkey injections into a single file.

1.2.0 - Added File Explorer functionality. Users are restricted to the "Downloads" folder. 
1.1.0 - Added support for LibreOffice to open XLSX and DOCX files from inside MasterControl
1.0.1 - Fixed a bug where the Adobe Acrobat Reader DC Update task was blocked by assigned access mode. Supplemental executable files have been whitelisted as well.
1.0.0 - Initial Release

Upcoming Features:

Automatically purge the "Downloads" directory after a set amount of time.
