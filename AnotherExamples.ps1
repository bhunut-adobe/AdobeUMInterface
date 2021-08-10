# Import Module
$ScriptDir = split-path -parent $MyInvocation.MyCommand.Definition
Import-Module "$ScriptDir\AdobeUMInterface.psm1"

# Load cert for auth
$thumbprint = Get-ChildItem Cert:\CurrentUser\My | Where-Object Subject -Like 'CN=ADOBEAUTH*'
$SignatureCert = Import-AdobeUMCert -CertThumbprint $thumbprint.Thumbprint -CertStore "CurrentUser"

# Client info from https://console.adobe.io/
$ClientInformation = New-ClientInformation -APIKey "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" -OrganizationID "xxxxxxxxxxxxxxxxxxxxxxxx@AdobeOrg" -ClientSecret "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" `
    -TechnicalAccountID "xxxxxxxxxxxxxxxxxxxxxxxx@techacct.adobe.com" -TechnicalAccountEmail "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx@techacct.adobe.com"

# Required auth token for further adobe queries. (Is placed in ClientInformation)
Get-AdobeAuthToken -ClientInformation $ClientInformation -SignatureCert $SignatureCert

# Get Group Members and Export it to CSV
$groupMembers = Get-AdobeGroupMembers -ClientInformation $ClientInformation -GroupName "Group 1" -Verbose
$groupMembers | ForEach-Object { $_.groups = $_.groups -join ','; $_ } | Export-Csv GroupMembershipExport.csv -NoTypeInformation


# Get all the users in the admin console.
Get-AdobeUsers -ClientInformation $ClientInformation

# Remove 1000 users from a group
$groupName = "Group 1"
$groupMembers = Get-AdobeGroupMembers -ClientInformation $ClientInformation -GroupName $groupName -Verbose
$requests = $groupMembers[0..999] | ForEach-Object { New-RemoveUserFromGroupRequest -UserName $_.username -Groups @($groupName) }
Send-UserManagementRequest -ClientInformation $ClientInformation -Requests $requests -Verbose


