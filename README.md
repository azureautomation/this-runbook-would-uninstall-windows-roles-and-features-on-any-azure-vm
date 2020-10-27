This runbook would UN-Install Windows roles and features on any Azure VM
========================================================================

            

This runbook uninstalls a windows role/feature on a virtual machine. These features are typically uninstalled using powershell and/or server manager. The festure will be uninstalled and if the feature demands a reboot, the virtual machine will reboot automatically.
 E.g of these roles and features include uninstalling IIS using the web-server role/feature. This runbook can be invoked from other runbooks.



 



 






 

 


        
    
TechNet gallery is retiring! This script was migrated from TechNet script center to GitHub by Microsoft Azure Automation product group. All the Script Center fields like Rating, RatingCount and DownloadCount have been carried over to Github as-is for the migrated scripts only. Note : The Script Center fields will not be applicable for the new repositories created in Github & hence those fields will not show up for new Github repositories.
