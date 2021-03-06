###############################################################################################################################
#
# Retrieve the status of all Azure Virtual Machines across all Subscriptions associated with a specific Azure AD Tenant
#
# NOTE: Download latest Azure and AzureAD Powershell modules, using the following PowerShell commands with elevated privileges
#
#       >Install-Module AzureRM -AllowClobber -Force -Confirm
#       >Set-ExecutionPolicy RemoteSigned -Confirm -Force
#
# NOTE: Download latest version of Chocolatey package manager for Windows
#
#       >https://chocolatey.org/install
#
# NOTE: Download latest version of ArmClient
#
#       >https://chocolatey.org/packages/ARMClient
#
###############################################################################################################################

#region Function Get-ChildObject

Function Get-ChildObject
{
    param(
        [System.Object]$Object,
        [string]$Path
    )
    process
    {
        $ReturnValue = ""
        if($Object -and $Path)
        {
            $EvaluationExpression = '$Object'

            foreach($Token in $Path.Split("."))
            {
                If($Token)
                {
                    $EvaluationExpression += '.' + $Token
                    if((Invoke-Expression $EvaluationExpression) -ne $null)
                    {
                        $ReturnValue = Invoke-Expression $EvaluationExpression
                    }
                    else
                    {
                        $ReturnValue = ""
                    }
                }
            }
        }
        Write-Output -InputObject $ReturnValue
    }
}

#endregion

$ErrorActionPreference = 'Stop'
$DateTime = Get-Date -f 'yyyy-MM-dd HHmmss'

#region Login

# Login to the user's default Azure AD Tenant
Write-Host -BackgroundColor Yellow -ForegroundColor DarkBlue "Login to User's default Azure AD Tenant"
$Account = Add-AzureRmAccount
Write-Host

# Get the list of Azure AD Tenants this user has access to, and select the correct one
Write-Host -BackgroundColor Yellow -ForegroundColor DarkBlue "Retrieving list of Azure AD Tenants for this User"
$Tenants = @(Get-AzureRmTenant)
Write-Host

# Get the list of Azure AD Tenants this user has access to, and select the correct one
if($Tenants.Count -gt 1) # User has access to more than one Azure AD Tenant
{
    $Tenant = $Tenants |  Out-GridView -Title "Select the Azure AD Tenant you wish to use..." -OutputMode Single
}
elseif($Tenants.Count -eq 1) # User has access to only one Azure AD Tenant
{
    $Tenant = $Tenants.Item(0)
}
else # User has access to no Azure AD Tenant
{
    Return
}

# Get Authentication Token, just in case it is required in future
$TokenCache = (Get-AzureRmContext).TokenCache
$Token = $TokenCache.ReadItems() | Where-Object { $_.TenantId -eq $Tenant.Id }

# Check if the current Azure AD Tenant is the required Tenant
if($Account.Context.Tenant.Id -ne $Tenant.Id)
{
    # Login to the required Azure AD Tenant
    Write-Host -BackgroundColor Yellow -ForegroundColor DarkBlue "Login to correct Azure AD Tenant"
    $Account = Add-AzureRmAccount -TenantId $Tenant.Id
    Write-Host
}

#endregion

#region Select subscriptions

# Get list of Subscriptions associated with this Azure AD Tenant, for which this User has access
Write-Host -BackgroundColor Yellow -ForegroundColor DarkBlue "Retrieving list of Azure Subscriptions for this Azure AD Tenant"
$AllSubscriptions = @(Get-AzureRmSubscription -TenantId $Tenant.Id)
Write-Host

if($AllSubscriptions.Count -gt 1) # User has access to more than one Azure Subscription
{
    $SelectedSubscriptions = $AllSubscriptions |  Out-GridView -Title "Select the Azure Subscriptions you wish to use..." -OutputMode Multiple
}
elseif($AllSubscriptions.Count -eq 1) # User has access to only one Azure Subscription
{
    $SelectedSubscriptions = @($AllSubscriptions.Item(0))
}
else # User has access to no Azure Subscription
{
    Return
}

#endregion

#region Get VM Sizes

$VMSizes = @()
Write-Host -BackgroundColor Yellow -ForegroundColor DarkBlue "Retrieving list of Azure VM Sizes across all locations"

#$Context = Set-AzureRmContext -SubscriptionId $Subscription.Id -TenantId $Account.Context.Tenant.Id

# Get list of Azure Locations associated with this Subscription, for which this User has access and that support VMs
$Locations = Get-AzureRmLocation | where {$_.Providers -eq "Microsoft.Compute"}

# Loop through each Azure Location to retrieve a complete list of VM Sizes
foreach($Location in $Locations)
{
    try
    {
        $VMSizes += Get-AzureRmVMSize -Location $($Location.Location) | Select-Object Name, NumberOfCores, MemoryInMB, MaxDataDiskCount
        #$VMSizes += armclient GET https://management.azure.com/subscriptions/$($Subscription.Id)/providers/Microsoft.Compute/locations/$($Location.Location)/vmSizes?api-version=2017-12-01 | ConvertFrom-Json | Select -ExpandProperty value
        Write-Host -NoNewline "."
    }
    catch
    {
        #Do Nothing
    }
}
$VMSizes = $VMSizes | Select-Object -Unique Name, NumberOfCores, MemoryInMB, MaxDataDiskCount
Write-Host

# For some reason, Azure doesn't report these VM sizes, so we need to create them manually
$ExtraSmall = ($VMSizes | Where-Object {$_.Name -eq "Basic_A0"} | Get-Unique).PSObject.Copy()
$ExtraSmall.Name = "ExtraSmall"
$VMSizes += $ExtraSmall
$Small = ($VMSizes | Where-Object {$_.Name -eq "Basic_A1"} | Get-Unique).PSObject.Copy()
$Small.Name = "Small"
$VMSizes += $Small
$Medium = ($VMSizes | Where-Object {$_.Name -eq "Basic_A2"} | Get-Unique).PSObject.Copy()
$Medium.Name = "Medium"
$VMSizes += $Medium
$Large = ($VMSizes | Where-Object {$_.Name -eq "Basic_A3"} | Get-Unique).PSObject.Copy()
$Large.Name = "Large"
$VMSizes += $Large
$ExtraLarge = ($VMSizes | Where-Object {$_.Name -eq "Basic_A4"} | Get-Unique).PSObject.Copy()
$ExtraLarge.Name = "ExtraLarge"
$VMSizes += $ExtraLarge
$A5 = ($VMSizes | Where-Object {$_.Name -eq "Standard_A5"} | Get-Unique).PSObject.Copy()
$A5.Name = "A5"
$VMSizes += $A5
$A6 = ($VMSizes | Where-Object {$_.Name -eq "Standard_A6"} | Get-Unique).PSObject.Copy()
$A6.Name = "A6"
$VMSizes += $A6
$A7 = ($VMSizes | Where-Object {$_.Name -eq "Standard_A7"} | Get-Unique).PSObject.Copy()
$A7.Name = "A7"
$VMSizes += $A7
$A8 = ($VMSizes | Where-Object {$_.Name -eq "Standard_A8"} | Get-Unique).PSObject.Copy()
$A8.Name = "A8"
$VMSizes += $A8
$A9 = ($VMSizes | Where-Object {$_.Name -eq "Standard_A9"} | Get-Unique).PSObject.Copy()
$A9.Name = "A9"
$VMSizes += $A9
$A10 = ($VMSizes | Where-Object {$_.Name -eq "Standard_A10"} | Get-Unique).PSObject.Copy()
$A10.Name = "A10"
$VMSizes += $A10
$A11 = ($VMSizes | Where-Object {$_.Name -eq "Standard_A11"} | Get-Unique).PSObject.Copy()
$A11.Name = "A11"
$VMSizes += $A11

$VMSizes = $VMSizes | Select-Object -Unique Name, NumberOfCores, MemoryInMB, MaxDataDiskCount
Write-Host

#endregion

#region Get All Tags

# Loop through each Subscription to retireve a complete list of all the ARM Tags in use across all Subscriptions
Write-Host -BackgroundColor Yellow -ForegroundColor DarkBlue "Retrieving list of Tags in use across all Subscriptions"
$Tags = @()
foreach($Subscription in $AllSubscriptions)
{
    $Context = Set-AzureRmContext -SubscriptionId $Subscription -TenantId $Account.Context.Tenant.Id
    $Tags += Get-AzureRmTag
    #$Tags += armclient GET https://management.azure.com/subscriptions/$($Subscription.Id)/tagNames?api-version=2018-02-01  | ConvertFrom-Json | Select -ExpandProperty value
    Write-Host -NoNewline "."
}
$Tags = $Tags | sort -Unique Name
Write-Host

#endregion

#region Get ARM VM Details

# Loop through each Subscription
foreach ($Subscription in $SelectedSubscriptions)
{

    # Set the current Azure context
    Write-Host -BackgroundColor Yellow -ForegroundColor DarkBlue "Setting context for Subscription: $($Subscription.Name)"
    $Context = Set-AzureRmContext -SubscriptionId $Subscription -TenantId $Account.Context.Tenant.Id
    Write-Host

    # Get all the ARM VMs in the current Subscription
    Write-Host -BackgroundColor Yellow -ForegroundColor DarkBlue "Retrieving list of ARM Virtual Machines in Subscription: $($Subscription.Name)"
    $VMs = Get-AzureRmResource -ResourceType Microsoft.Compute/virtualMachines -ExpandProperties
    Write-Host

    # Get the status of all the ARM VMs in the current Subscription
    Write-Host -BackgroundColor Yellow -ForegroundColor DarkBlue "Retrieving status of ARM Virtual Machines in Subscription: $($Subscription.Name)"
    $VMStatuses = Get-AzureRmVM -Status
    Write-Host

    # Get the created & last updated date/time of all the ARM VMs in the current Subscription
    Write-Host -BackgroundColor Yellow -ForegroundColor DarkBlue "Retrieving created & last updated date/time of ARM Virtual Machines in Subscription: $($Subscription.Name)"
    $VMDates = armclient GET "https://management.azure.com/subscriptions/$($Subscription.Id)/resources?`$filter=resourcetype eq 'Microsoft.Compute/virtualMachines'&`$expand=createdTime,changedTime&api-version=2018-08-01" | ConvertFrom-Json | Select -ExpandProperty value
    Write-Host

    # Get all the ARM Network Interfaces in the current Subscription
    Write-Host -BackgroundColor Yellow -ForegroundColor DarkBlue "Retrieving list of ARM Network Interfaces in Subscription: $($Subscription.Name)"
    $NetworkInterfaces = Get-AzureRmNetworkInterface
    Write-Host

    # TO BE COMPLETED: Get all the ARM Public IPs in the current Subscription
    #Write-Host -BackgroundColor Yellow -ForegroundColor DarkBlue "Retrieving list of ARM Public IPs in Subscription: $($Subscription.Name)"
    #$PublicIpAddresses = Get-AzureRmPublicIpAddress
    #Write-Host

    # Create an empty Array to hold our custom VM objects
    $VMObjects = [PSCustomObject]@()

    if($VMs)
    {
        Write-Host -BackgroundColor Yellow -ForegroundColor DarkBlue "Creating custom list of ARM Virtual Machines in Subscription: $($Subscription.Name)"
        foreach ($VM in $VMs)
        {

            # Get the All Network Interface for this ARM VM
            $VMNetworkInterfaces = $NetworkInterfaces | Where-Object -FilterScript {$_.VirtualMachine.Id -eq $VM.ResourceId}

            # Get the Status for this ARM VM
            $VMStatus = $VMStatuses | Where-Object {$_.Id -eq $VM.ResourceId} | Get-Unique

            # Get the Created & Last Updated Date/Time for this ARM VM
            $VMDate = $VMDates | Where-Object {$_.id -eq $VM.ResourceId} | Get-Unique

            # Lookup the VM Size information for this ARM VM
            $VMSize = $VMSizes | Where-Object {$_.Name -eq $(Get-ChildObject -Object $VM -Path Properties.hardwareProfile.vmSize)}

            # Create a custom PowerShell object to hold the consolidated ARM VM information
            $VMHashTable = [Ordered]@{
                "Created On" = $(if(Get-ChildObject -Object $VMDate -Path createdTime){[DateTime]::Parse($(Get-ChildObject -Object $VMDate -Path createdTime)).ToUniversalTime()})
                "Modified On" = $(if(Get-ChildObject -Object $VMDate -Path changedTime){[DateTime]::Parse($(Get-ChildObject -Object $VMDate -Path changedTime)).ToUniversalTime()})
                "Subscription" = $(Get-ChildObject -Object $Subscription -Path Name)
                "Resource Group" = $(Get-ChildObject -Object $VM -Path ResourceGroupName)
                "VM Type" = "ARM"
                "VM Name" = $(Get-ChildObject -Object $VM -Path Name)
                "VM Location" = $(Get-ChildObject -Object $VM -Path Location)
                "VM Size" = $(Get-ChildObject -Object $VM -Path Properties.hardwareProfile.vmSize)
                "VM Processor Cores" = $(Get-ChildObject -Object $VMSize -Path NumberofCores)
                "VM Memory (GB)" = $([INT]$(Get-ChildObject -Object $VMSize -Path MemoryInMB)/1024)
                "Availability Set" = $((Get-ChildObject -Object $VM -Path Properties.availabilitySet.id).Split("/")[8])
                "VM ID" = $(Get-ChildObject -Object $VM -Path Properties.VmId)
                "Power State" = $(Get-ChildObject -Object $VMStatus -Path PowerState)
                "Provisioning State" = $(Get-ChildObject -Object $VMStatus -Path ProvisioningState)
                "Status Code" = $(Get-ChildObject -Object $VMStatus -Path StatusCode)
                "Maintenance - Self Service Window" = $(if(Get-ChildObject -Object $VMStatus -Path MaintenanceRedeployStatus){if((Get-ChildObject -Object $VMStatus -Path MaintenanceRedeployStatus.IsCustomerInitiatedMaintenanceAllowed) -eq $True){$(Get-ChildObject -Object $VMStatus -Path MaintenanceRedeployStatus.PreMaintenanceWindowStartTime).ToUniversalTime().ToString() + " - " + $(Get-ChildObject -Object $VMStatus -Path MaintenanceRedeployStatus.PreMaintenanceWindowEndTime).ToUniversalTime().ToString() + " UTC"}})
                "Maintenance - Scheduled Window" = $(if(Get-ChildObject -Object $VMStatus -Path MaintenanceRedeployStatus){if((Get-ChildObject -Object $VMStatus -Path MaintenanceRedeployStatus.IsCustomerInitiatedMaintenanceAllowed) -eq $True){$(Get-ChildObject -Object $VMStatus -Path MaintenanceRedeployStatus.MaintenanceWindowStartTime).ToUniversalTime().ToString() + " - " + $(Get-ChildObject -Object $VMStatus -Path MaintenanceRedeployStatus.MaintenanceWindowEndTime).ToUniversalTime().ToString() + " UTC"}})
                "Boot Diagnostics Enabled" = $(Get-ChildObject -Object $VM -Path Properties.DiagnosticsProfile.BootDiagnostics.Enabled)
                "OS Type" = $(Get-ChildObject -Object $VM -Path Properties.storageProfile.osDisk.OsType)
                "Windows Hybrid Benefit" = $(if((Get-ChildObject -Object $VM -Path Properties.StorageProfile.OsDisk.OsType) -eq "Windows"){if(Get-ChildObject -Object $VM -Path Properties.LicenseType){"Enabled"}else{"Not Enabled"}}else{"Not Supported"})
                "Image Publisher" = $(Get-ChildObject -Object $VM -Path Properties.storageProfile.ImageReference.Publisher)
                "Image Offer" = $(Get-ChildObject -Object $VM -Path Properties.storageProfile.ImageReference.Offer)
                "Image Sku" = $(Get-ChildObject -Object $VM -Path Properties.storageProfile.ImageReference.Sku)
                "Image Version" = $(Get-ChildObject -Object $VM -Path Properties.storageProfile.ImageReference.Version)
                "OS Disk Size" = $(Get-ChildObject -Object $VM -Path Properties.storageProfile.osDisk.DiskSizeGB)
                "OS Disk Caching" = $(Get-ChildObject -Object $VM -Path Properties.storageProfile.osDisk.Caching)
                "OS Disk Type" = $(if(Get-ChildObject -Object $VM -Path Properties.storageProfile.osDisk.ManagedDisk){"Managed"}elseif(Get-ChildObject -Object $VM -Path Properties.storageProfile.osDisk.vhd){"Unmanaged"})
                "OS Disk Storage Type" = $(Get-ChildObject -Object $VM -Path Properties.storageProfile.osDisk.ManagedDisk.StorageAccountType)
                "OS Disk Storage Account" = $(if($(Get-ChildObject -Object $VM -Path Properties.storageProfile.osDisk.vhd.uri) -ne ""){([System.Uri]$(Get-ChildObject -Object $VM -Path Properties.storageProfile.osDisk.vhd.uri)).Host}else{""})
                "Data Disk Count" = $(Get-ChildObject -Object $VM -Path Properties.storageProfile.dataDisks.Count)
                "Data Disk Max Count" = $(Get-ChildObject -Object $VMSize -Path MaxDataDiskCount)
                "NIC Count" = $(Get-ChildObject -Object $VM -Path Properties.networkProfile.networkInterfaces.Count)
            }

            # Get all the Network Interfaces for this VM
            $MaxNICCount = 2
            for($i=0; $i -lt $MaxNICCount; $i++)
            {
                if($VMNetworkInterfaces[$i])
                {
                    $VMPrimaryIpConfiguration = $VMNetworkInterfaces[$i].IpConfigurations | Where-Object -FilterScript {$_.Primary -eq $true} | Get-Unique

                    $NicHashTable = [Ordered]@{
                        "NIC $($i+1)" = $(Get-ChildObject -Object $VMNetworkInterfaces[$i] -Path Name)
                        "NIC $($i+1) Primary NIC" = $(Get-ChildObject -Object $VMNetworkInterfaces[$i] -Path Primary)
                        "NIC $($i+1) Accelerated Networking" = $(Get-ChildObject -Object $VMNetworkInterfaces[$i] -Path EnableAcceleratedNetworking)
                        "NIC $($i+1) Primary Config" = $(Get-ChildObject -Object $VMPrimaryIpConfiguration -Path Name)
                        "NIC $($i+1) Primary Config IP" = $(Get-ChildObject -Object $VMPrimaryIpConfiguration -Path PrivateIpAddress)
                        "NIC $($i+1) Primary Config Allocation" = $(Get-ChildObject -Object $VMPrimaryIpConfiguration -Path PrivateIpAllocationMethod)
                        "NIC $($i+1) VNET" = $((Get-ChildObject -Object $VMPrimaryIpConfiguration -Path Subnet.Id).Split("/")[8])
                        "NIC $($i+1) Subnet" = $((Get-ChildObject -Object $VMPrimaryIpConfiguration -Path Subnet.Id).Split("/")[10])
                    }
                }
                else
                {
                    $NicHashTable = [Ordered]@{
                        "NIC $($i+1)" = $null
                        "NIC $($i+1) Primary NIC" = $null
                        "NIC $($i+1) Accelerated Networking" = $null
                        "NIC $($i+1) Primary Config" = $null
                        "NIC $($i+1) Primary Config IP" = $null
                        "NIC $($i+1) Primary Config Allocation" = $null
                        "NIC $($i+1) VNET" = $null
                        "NIC $($i+1) Subnet" = $null
                    }
                }
                $VMHashTable += $NicHashTable
            }

            # Get all the Tags for this VM
            foreach($Tag in $Tags)
            {
                if((Get-ChildObject -Object $VM -Path Tags.keys).Contains($Tag.Name))
                {
                    #$VMObject | Add-Member -MemberType NoteProperty -Name $("TAG [" + $Tag.Name + "]") -Value $VM.Tags.Item($Tag.Name)
                    $TagHashTable = [Ordered]@{
                        $("TAG [" + $Tag.Name + "]") = $VM.Tags.Item($Tag.Name)
                    }
                }
                else
                {
                    #$VMObject | Add-Member -MemberType NoteProperty -Name $("TAG [" + $Tag.Name + "]") -Value $null
                    $TagHashTable = [Ordered]@{
                        $("TAG [" + $Tag.Name + "]") = $null
                    }
                }
                $VMHashTable += $TagHashTable
            }

            # TO BE COMPLETED: Retrieve a list of VM sizes to which this VM can be resized
            #$VMAvailableSizes = Get-AzureRmVMSize -ResourceGroupName $VM.ResourceGroupName -VMName $VM.Name
            #if($VMAvailableSizes)
            #{
            #    $VMResizeObject = [ordered]@{
            #        "VM Resize Options" = $([String]::Join(";",$VMAvailableSizes.Name))
            #    }
            #}
            #else
            #{
            #    $VMResizeObject = [ordered]@{
            #        "VM Resize Options" = $null
            #    }
            #}

            # Add the VM HashTable to the Custom Object Array
            $VMObjects += [PSCustomObject]$VMHashTable
            Write-Host -NoNewline "."
        }
        Write-Host
    }

    # Append to a CSV file on the user's Desktop
    Write-Host -BackgroundColor Yellow -ForegroundColor DarkBlue "Appending details of ARM Virtual Machines in Subscription: $($Subscription.Name) to file"
    $FilePath = "$env:HOMEDRIVE$env:HOMEPATH\Desktop\Azure VM Status $($DateTime) (ARM).csv"
    if($VMObjects){$VMObjects | Export-Csv -Path $FilePath -Append -NoTypeInformation}

    Write-Host

}

#endregion

#region Get Classic VM Details

# Loop through each Subscription
foreach ($Subscription in $SelectedSubscriptions)
{

    # Set the current Azure context
    Write-Host -BackgroundColor Yellow -ForegroundColor DarkBlue "Setting context for Subscription: $($Subscription.Name)"
    $Context = Set-AzureRmContext -SubscriptionId $Subscription -TenantId $Account.Context.Tenant.Id
    Write-Host

    # Get all the Classic VMs in the current Subscription
    Write-Host -BackgroundColor Yellow -ForegroundColor DarkBlue "Retrieving list of Classic Virtual Machines in Subscription: $($Subscription.Name)"
    $VMs = Get-AzureRmResource -ResourceType Microsoft.ClassicCompute/virtualMachines -ExpandProperties
    Write-Host

    # Get the created & last updated date/time of all the ARM VMs in the current Subscription
    Write-Host -BackgroundColor Yellow -ForegroundColor DarkBlue "Retrieving created & last updated date/time of Classic Virtual Machines in Subscription: $($Subscription.Name)"
    $VMDates = armclient GET "https://management.azure.com/subscriptions/$($Subscription.Id)/resources?`$filter=resourcetype eq 'Microsoft.ClassicCompute/virtualMachines'&`$expand=createdTime,changedTime&api-version=2018-08-01" | ConvertFrom-Json | Select -ExpandProperty value
    Write-Host

    # Create an empty Array to hold our custom VM objects
    $VMObjects = [PSCustomObject]@()

    if($VMs)
    {
        Write-Host -BackgroundColor Yellow -ForegroundColor DarkBlue "Creating custom list of ClaSsic Virtual Machines in Subscription: $($Subscription.Name)"
        foreach($VM in $VMs)
        {

            # Lookup the VM Size information for this ARM VM
            $VMSize = $VMSizes | Where-Object {$_.Name -eq $(Get-ChildObject -Object $VM -Path Properties.hardwareProfile.size)}

            # Get the Created & Last Updated Date/Time for this ARM VM
            $VMDate = $VMDates | Where-Object {$_.id -eq $VM.ResourceId} | Get-Unique

            # Create a custom PowerShell object to hold the consolidated Classic VM information
            $VMHashTable = [Ordered]@{
                "Created On" = $([DateTime]::Parse($(Get-ChildObject -Object $VMDate -Path createdTime)).ToUniversalTime())
                "Modified On" = $([DateTime]::Parse($(Get-ChildObject -Object $VMDate -Path changedTime)).ToUniversalTime())
                "Subscription" = $(Get-ChildObject -Object $Subscription -Path Name)
                "Resource Group" = $(Get-ChildObject -Object $VM -Path ResourceGroupName)
                "VM Type" = "Classic"
                "VM Name" = $(Get-ChildObject -Object $VM -Path Name)
                "VM Location" = $(Get-ChildObject -Object $VM -Path Location)
                "VM Size" = $(Get-ChildObject -Object $VM -Path Properties.hardwareProfile.size)
                "VM Processor Cores" = $(Get-ChildObject -Object $VMSize -Path NumberofCores)
                "VM Memory (GB)" = $([INT]$(Get-ChildObject -Object $VMSize -Path MemoryInMB)/1024)
                "Status" = $(Get-ChildObject -Object $VM -Path Properties.instanceView.status)
                "Power State" = $(Get-ChildObject -Object $VM -Path Properties.instanceView.powerState)
                "Provisioning State" = $(Get-ChildObject -Object $VM -Path Properties.provisioningState)
                "Boot Diagnostics Enabled" = $(Get-ChildObject -Object $VM -Path Properties.debugProfile.bootDiagnosticsEnabled)
                "OS Type" = $(Get-ChildObject -Object $VM -Path Properties.storageProfile.operatingSystemDisk.operatingSystem)
                "OS Disk Caching" = $(Get-ChildObject -Object $VM -Path Properties.storageProfile.operatingSystemDisk.caching)
                "OS Disk IO Type" = $(Get-ChildObject -Object $VM -Path Properties.storageProfile.operatingSystemDisk.ioType)
                "OS Disk Source Image Name" = $(Get-ChildObject -Object $VM -Path Properties.storageProfile.operatingSystemDisk.sourceImageName)
                "OS Disk Storage Account" = $(if($(Get-ChildObject -Object $VM -Path Properties.storageProfile.operatingSystemDisk.vhduri) -ne ""){([System.Uri]$(Get-ChildObject -Object $VM -Path Properties.storageProfile.operatingSystemDisk.vhduri)).Host}else{""})
                "Data Disk Count" = $(Get-ChildObject -Object $VM -Path Properties.storageProfile.dataDisks.Count)
                "Data Disk Max Count" = $(Get-ChildObject -Object $VMSize -Path MaxDataDiskCount)
                "Private IP Address" = $(Get-ChildObject -Object $VM -Path Properties.instanceView.privateIpAddress)
                "Public IP Address" = $(Get-ChildObject -Object $VM -Path Properties.instanceView.publicIpAddresses[0])
                "VNET" = $(Get-ChildObject -Object $VM -Path Properties.networkProfile.virtualNetwork.name)
                "Subnet" = $(Get-ChildObject -Object $VM -Path Properties.networkProfile.virtualNetwork.subnetNames[0])
            }

            # Add the VM HashTable to the Custom Object Array
            $VMObjects += [PSCustomObject]$VMHashTable
            Write-Host -NoNewline "."
        }
        Write-Host
    }
    
    # Output to a CSV file on the user's Desktop
    Write-Host -BackgroundColor Yellow -ForegroundColor DarkBlue "Appending details of Classic Virtual Machines in Subscription: $($Subscription.Name) to file"
    $FilePath = "$env:HOMEDRIVE$env:HOMEPATH\Desktop\Azure VM Status $($DateTime) (Classic).csv"
    if($VMObjects){$VMObjects | Export-Csv -Path $FilePath -Append -NoTypeInformation}

    Write-Host

}

#endregion
