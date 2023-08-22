# Script retrieves a list of all SCCM client machines using the Get-WmiObject cmdlet targeting the Root\ccm\ClientSDK namespace.
# Script iterates through each machine, querying the Win32_LogicalDisk class to get disk information.
# For each disk, it calculates the free space in gigabytes and compares it to the threshold. If the free space is lower than the threshold, it adds the machine's details to the $lowDiskSpaceMachines array.
# Brandon Todd - lotusvictim@gmail.com

# Define the threshold for low disk space (in gigabytes)
$thresholdGB = 10

# Get a list of all SCCM client machines
$computerNames = Get-WmiObject -Namespace "Root\ccm\ClientSDK" -Class CCM_Client | Select-Object -ExpandProperty Name

# Initialize an array to store results
$lowDiskSpaceMachines = @()

# Iterate through each machine and check disk space
foreach ($computerName in $computerNames) {
    $diskInfo = Get-WmiObject Win32_LogicalDisk -ComputerName $computerName -Filter "DriveType=3"
    
    foreach ($disk in $diskInfo) {
        $freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)
        
        if ($freeSpaceGB -lt $thresholdGB) {
            $lowDiskSpaceMachines += [PSCustomObject]@{
                ComputerName = $computerName
                DriveLetter = $disk.DeviceID
                FreeSpaceGB = $freeSpaceGB
            }
        }
    }
}

# Display results
$lowDiskSpaceMachines | Format-Table -AutoSize

# You can also export the results to a CSV file
# $lowDiskSpaceMachines | Export-Csv -Path "LowDiskSpaceMachines.csv" -NoTypeInformation
