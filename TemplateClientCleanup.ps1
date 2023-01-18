#Script is used to remove all traces of the SCCM Client from the machine and then reinstall the client.
#The SiteCode, Fallback Status Point, SMS Provider, and Management Point must be defined and match your enviorment.

$machinename = hostname
Start-Transcript -Path "c:\windows\temp\$machinename.log"

# Attempt to run the SCCM uninstaller
function uninstallSCCM() {
    if (Test-Path -Path "$Env:SystemDrive\Windows\ccmsetup\ccmsetup.exe") {
        # Stop SCCM services
        Get-Service -Name CcmExec -ErrorAction SilentlyContinue | Stop-Service -Force -Verbose
        Get-Service -Name ccmsetup -ErrorAction SilentlyContinue | Stop-Service -Force -Verbose

        # Run the SCCM uninstaller
        Start-Process -FilePath "$Env:SystemDrive\Windows\ccmsetup\ccmsetup.exe" -ArgumentList '/uninstall'

        # Wait for the uninstaller to finish
        do {
            Start-Sleep -Milliseconds 1000
            $Process = (Get-Process ccmsetup -ErrorAction SilentlyContinue)
        } until ($null -eq $Process)

        Write-Host "SCCM uninstallation completed"
    }
}

# Forcefully remove all traces of SCCM from the computer
function removeSCCM() {
    # Stop SCCM services
    Get-Service -Name CcmExec -ErrorAction SilentlyContinue | Stop-Service -Force -Verbose
    Get-Service -Name ccmsetup -ErrorAction SilentlyContinue | Stop-Service -Force -Verbose

    # Take ownership of/delete SCCM's client folder and files
    $null = takeown /F "$($Env:WinDir)\CCM" /R /A /D Y 2>&1
    Remove-Item -Path "$($Env:WinDir)\CCM" -Force -Recurse -Confirm:$false -Verbose -ErrorAction SilentlyContinue
    
    # Take ownership of/delete SCCM's setup folder and files
    $null = takeown /F "$($Env:WinDir)\CCMSetup" /R /A /D Y 2>&1
    Remove-Item -Path "$($Env:WinDir)\CCMSetup" -Force -Recurse -Confirm:$false -Verbose -ErrorAction SilentlyContinue
    
    # Take ownership of/delete SCCM cache of downloaded packages and applications
    $null = takeown /F "$($Env:WinDir)\CCMCache" /R /A /D Y 2>&1
    Remove-Item -Path "$($Env:WinDir)\CCMCache" -Force -Recurse -Confirm:$false -Verbose -ErrorAction SilentlyContinue

    # Remove SCCM's smscfg file (contains GUID of previous installation)
    Remove-Item -Path "$($Env:WinDir)\smscfg.ini" -Force -Confirm:$false -Verbose -ErrorAction SilentlyContinue

    # Remove SCCM certificates
    Remove-Item -Path 'HKLM:\Software\Microsoft\SystemCertificates\SMS\Certificates\*' -Force -Confirm:$false -Verbose -ErrorAction SilentlyContinue

    # Remove CCM registry keys
    Remove-Item -Path 'HKLM:\SOFTWARE\Microsoft\CCM' -Force -Recurse -Verbose -ErrorAction SilentlyContinue
    Remove-Item -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\CCM' -Force -Recurse -Confirm:$false -Verbose -ErrorAction SilentlyContinue

    # Remove SMS registry keys
    Remove-Item -Path 'HKLM:\SOFTWARE\Microsoft\SMS' -Force -Recurse -Confirm:$false -Verbose -ErrorAction SilentlyContinue
    Remove-Item -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\SMS' -Force -Recurse -Confirm:$false -Verbose -ErrorAction SilentlyContinue

    # Remove CCMSetup registry keys
    Remove-Item -Path 'HKLM:\Software\Microsoft\CCMSetup' -Force -Recurse -Confirm:$false -Verbose -ErrorAction SilentlyContinue
    Remove-Item -Path 'HKLM:\Software\Wow6432Node\Microsoft\CCMSetup' -Force -Confirm:$false -Recurse -Verbose -ErrorAction SilentlyContinue

    # Remove CcmExec and ccmsetup services
    Remove-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\CcmExec' -Force -Recurse -Confirm:$false -Verbose -ErrorAction SilentlyContinue
    Remove-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\ccmsetup' -Force -Recurse -Confirm:$false -Verbose -ErrorAction SilentlyContinue

    # Remove SCCM namespaces from WMI repository
    Get-CimInstance -Query "Select * From __Namespace Where Name='CCM'" -Namespace "root" -ErrorAction SilentlyContinue | Remove-CimInstance -Verbose -Confirm:$false -ErrorAction SilentlyContinue
    Get-CimInstance -Query "Select * From __Namespace Where Name='CCMVDI'" -Namespace "root" -ErrorAction SilentlyContinue | Remove-CimInstance -Verbose -Confirm:$false -ErrorAction SilentlyContinue
    Get-CimInstance -Query "Select * From __Namespace Where Name='SmsDm'" -Namespace "root" -ErrorAction SilentlyContinue | Remove-CimInstance -Verbose -Confirm:$false -ErrorAction SilentlyContinue
    Get-CimInstance -Query "Select * From __Namespace Where Name='sms'" -Namespace "root\cimv2" -ErrorAction SilentlyContinue | Remove-CimInstance -Verbose -Confirm:$false -ErrorAction SilentlyContinue

    # Completed
    Write-Host "All traces of SCCM have been removed"
    Write-Host "--------------------------------------------------------"
}

# Run Client Install
function InstallSCCM() {
    Write-Host "Starting Client Install"
    New-Item -Path "c:\windows\ccmsetup" -type directory -Force 
    Copy-Item \\locationOf\ccmsetup.exe -Destination "c:\windows\ccmsetup\" -Force
    & cmd /c "c:\windows\ccmsetup\ccmsetup.exe /mp:sccm.yordomain.xyz SMSMP=sccm.yordomain.xyz SMSSITECODE=xxx FSP=sccm.yordomain.xyz RESETKEYINFORMATION=TRUE"
    Write-Host "Install Complete"
    Write-Host "--------------------------------------------------------"
}


# Main calls
uninstallSCCM
removeSCCM
InstallSCCM


Write-Host "=================================================================="
Write-Host "$machinename has been Cleaned and SCCM Client has been installed"
Write-Host "=================================================================="

stop-transcript
exit
