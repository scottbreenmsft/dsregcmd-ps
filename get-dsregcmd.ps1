
function Get-DSRegCMD {
<#
.SYNOPSIS
Retrieves Azure AD connection information from the dsregcmd.exe command line tool.

.DESCRIPTION
Retrieves Azure AD connection information from the dsregcmd.exe command line tool.

.NOTES
Author: Scott Breen

VERSION HISTORY
0.1   Initial version            Scott Breen
#>

    $dsregcmd=dsregcmd /status
    $inDeviceState=$false
    $sectionBreakCounter=0
    $AzureADJoined=$false
    $DomainName=""
    $DomainJoined=$false
    $AzureADTenantID=""
    $AzureADDeviceID=""
    $WorkplaceAccounts=@()

    #get device state
    foreach ($line in $dsregcmd) {
        If ($line -like "| Device State*" -or $line -like "| Device Details*" -or $line -like "| Tenant Details*") {
            $inDeviceState=$true
        }

        IF ($inDeviceState) {
            If ($line -like "+-----*") {
                $sectionBreakCounter++
                IF ($sectionBreakCounter -gt 1) {
                    $inDeviceState=$false
                    $sectionBreakCounter=0
                }
            } else {
                if ($line -like "*:*") {
                    $TrimedLine=$line.trim().replace(" : ","`t").split("`t")
                    IF ($TrimedLine[0] -eq "AzureADJoined") {
                        If ($TrimedLine[1] -eq "YES") {
                            $AzureADJoined=$true
                        } else {
                            $AzureADJoined=$false
                        }
                    }
                    IF ($TrimedLine[0] -eq "DomainJoined") {
                        If ($TrimedLine[1] -eq "YES") {
                            $DomainJoined=$true
                        } else {
                            $DomainJoined=$false
                        }
                    }
                    IF ($TrimedLine[0] -eq "DeviceID") {
                        $AzureADDeviceID=$TrimedLine[1]
                    }

                    IF ($TrimedLine[0] -eq "TenantID") {
                        $AzureADTenantID=$TrimedLine[1]
                    }
                    IF ($TrimedLine[0] -eq "DomainName") {
                        $DomainName=$TrimedLine[1]
                    }


                }            
            }
        
        }




        #Workplace accounts
        If ($line -like "| Work Account*") {
            $inWorkAccount=$true
        }

        IF ($inWorkAccount) {
            If ($line -like "+-----*") {
                $sectionBreakCounter++
                IF ($sectionBreakCounter -gt 1) {
                    $inWorkAccount=$false
                    $sectionBreakCounter=0
                }
            } else {
                if ($line -like "*:*") {
                    $TrimedLine=$line.trim().replace(" : ","`t").split("`t")
                    IF ($TrimedLine[0] -eq "WorkplaceTenantName") {
                        $WorkplaceAccounts+=$TrimedLine[1]
                    }
                }
            }
        }


    }


    #create object
    $Object = New-Object PSObject -Property @{
	    AzureADJoined=$AzureADJoined
        DomainName=$DomainName
        DomainJoined=$DomainJoined
        AzureADTenantID=$AzureADTenantID
        AzureADDeviceID=$AzureADDeviceID
        WorkplaceAccounts=$WorkplaceAccounts -join ";"
    }

    return $Object
}
