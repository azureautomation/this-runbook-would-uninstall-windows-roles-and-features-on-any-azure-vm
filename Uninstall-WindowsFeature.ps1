﻿<#
.SYNOPSIS 
    Uninstalls a Windows feature like Web-server from an existing virtual machine. 

.DESCRIPTION
    This runbooks un-installs a Windows feature from a virtual machine.
    These features are typically Uninstalled using powershell. The feature would be uninstalled
    and if the feature demands a reboot, the virtual machine can reboot automatically using restart switch.

.PARAMETER AzureSubscriptionName
    Name of the Azure subscription to connect to
    
.PARAMETER VMName    
    Name of the virtual machine from whom you want to uninstall a feature.  

.PARAMETER FeatureName
    The Name of the Windows feature that you want to uninstall on a server e.g Web-server, DSC-Service.

.PARAMETER ServiceName
     Name of the Cloud Service that hosts and contains the Virtual machine
    
.PARAMETER AzureCredentials
    A credential containing an Org Id username / password with access to this Azure subscription.

	If invoking this runbook inline from within another runbook, pass a PSCredential for this parameter.

	If starting this runbook using Start-AzureAutomationRunbook, or via the Azure portal UI, pass as a string the
	name of an Azure Automation PSCredential asset instead. Azure Automation will automatically grab the asset with
	that name and pass it into the runbook.

.EXAMPLE
    Uninstall-WindowsFeature -AzureSubscriptionName "Visual Studio Ultimate with MSDN" -VMName "Sample VM Name" -FeatureName "DSC-Service" -ServiceName "CloudServiceName"  -AzureCredentials $cred -Restart $false

.NOTES
    AUTHOR:Ritesh Modi
    LASTEDIT: March 30, 2015 
    Blog: http://automationnext.wordpress.com
    email: callritz@hotmail.com
#>
workflow Uninstall-WindowsFeature
{
    param
    (
        [parameter(Mandatory=$true)]
        [String]
        $AzureSubscriptionName,
     
        [parameter(Mandatory=$true)]
        [String]
        $VMName,
        
        [parameter(Mandatory=$true)]
        [String]
        $FeatureName,

        [parameter(Mandatory=$true)]
        [String]
        $ServiceName,

        [parameter(Mandatory=$true)]
        [String]
        $AzureCredentials,

        [parameter(Mandatory=$true)]
        [boolean]
        $Restart
    )
    
    # Get the credential to use for Authentication to Azure and Azure Subscription Name 
    $Cred = Get-AutomationPSCredential -Name $AzureCredentials 

   # get the username and password from credential object  
   $CredUsername = $Cred.UserName
   $CredPassword = $Cred.GetNetworkCredential().Password

    # Select an appropriate organization ID for connecting to Azure 
    $AzureAccount = Add-AzureAccount -Credential $Cred 

    # Connect to Azure and Select Azure Subscription 
    $AzureSubscription = Select-AzureSubscription -SubscriptionName $AzureSubscriptionName 

    # invoking Connect-AzureVM runbook for installing the management certificate to be used for authentication
    Connect-AzureVM -AzureSubscriptionName $AzureSubscriptionName -ServiceName $ServiceName -VMName $VMName

    # obtaining the uri of remove virtual machine winrm
    $uri = Get-AzureWinRMUri -ServiceName $ServiceName -Name $VMName 

     # Inline script for installation of windows feature on Virtual machine
    $OutputMessage = inlinescript {
          
          # the OutputMessage variable will be used for returning the message to the user
          $OutputMessage = ""
          
           try{ # start of try block
                     $subscriptionPass = $using:CredPassword
                     $subscriptionUser = $using:CredUsername
                     $password = Convertto-SecureString -String $subscriptionPass -AsPlainText -Force

                     # creating credential object used for remoting to the virtual machine
                     $cred = New-Object System.Management.Automation.PSCredential $subscriptionUser, $password   
                    
                    # invoking the remote command on target virtual machine with custom script block
                     $OutputMessage =   Invoke-Command -ConnectionUri $using:uri -credential $cred `
                                            -ArgumentList  $using:FeatureName, $using:VMName, $using:ServiceName -ScriptBlock {
                        param ($FeatureName, $VMName, $ServiceName)

                      try {
                                # uninstalling the windows feature
                                if($using:Restart){
                                    $Status = Uninstall-WindowsFeature -Name DSC-Service -Restart -IncludeManagementTools
                                }  else  {
                                    $Status = Uninstall-WindowsFeature -Name DSC-Service -IncludeManagementTools
                                }
                                # If there is a returned status after installing windows feature
                                if($Status) {
                                       $OutputMessage ="Windows feature  $FeatureName was un-installed on Virtual Machine $VMName in Cloud Service $ServiceName successfully !!"
                                   }else  { 
                                      $OutputMessage = "Windows feature  $FeatureName could not be un-installed on Virtual Machine $VMName in Cloud Service $ServiceName !!"
                                }
                     } catch {
                            $OutputMessage ="Error un-installing feature  $using:FeatureName on Virtual Machine $using:VMName in Cloud Service $using:ServiceName !!"
                     }   
                    
                    return $OutputMessage        
                 } # end of invoke-command scriptblock  
                   
            } catch {
                $OutputMessage +="Error remoting to Virtual Machine $using:VMName in Cloud Service $using:ServiceName  !!"
            }   
         return $OutputMessage
    }
          $OutputMessage # final output of the entire installation operation
}




    
