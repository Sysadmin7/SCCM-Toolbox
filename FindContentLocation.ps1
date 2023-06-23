# Connect to the SCCM site
$SiteCode = "KAL"
$ProviderMachine = "kalsccm01.kaleidahealth.org"
$OutputFilePath = "C:\Path\to\Output.txt"  # Specify the desired output file path

# Import SCCM module
Import-Module ($ProviderMachine + "\AdminUI\bin\ConfigurationManager.psd1")

# Set the current location
Set-Location "$($ProviderMachine):\"

# Get all application deployments
$ApplicationDeployments = Get-CMDeployment -DeploymentType Application | Select-Object -Property PackageID, ContentLocation

# Create a function to save output to a text file
function Save-OutputToFile {
    Param (
        [Parameter(Mandatory = $true)]
        [string]$Output,
        
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    $Output | Out-File -FilePath $FilePath -Append
}

# Iterate through each application deployment
foreach ($Deployment in $ApplicationDeployments) {
    $PackageID = $Deployment.PackageID
    $ContentLocation = $Deployment.ContentLocation

    # Get application name
    $Application = Get-CMDeployment -PackageID $PackageID
    $ApplicationName = $Application.Name

    # Determine if content is stored locally or on a separate share
    if ($ContentLocation.StartsWith("X:\") -or $ContentLocation.StartsWith("\\bghcsa01.kaleidahealth.org\")) {
        $StorageLocation = "Local"
    } else {
        $StorageLocation = "Share"
    }

    # Output the application name, package ID, and content storage location
    $Output = "Application Name: $ApplicationName | Package ID: $PackageID | Content Storage: $StorageLocation"
    Write-Output $Output

    # Save the output to the text file
    Save-OutputToFile -Output $Output -FilePath $OutputFilePath
}
