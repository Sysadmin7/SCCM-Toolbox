#SCCM Client Remediation Script. Script forces removal and reinstallation of the SCCM Client on multiple machines across a single domain.
#Used to force compliance and communication with the SMS Site Server.
#Last edit 12/08/2022 by Brandon
#For questions email Brandon Todd at btoddr22@outlook.com

$path = "\\SCCM\Client"
$mp_address = "sccm.yourdomain.xyz" #FQDN Of management Point
$site_code = "XXX" #Sccm Primary Site Code

Get-Content \\SCCM\Client\PSScripts\computers.txt | #List of computers (IP Address) Exported from AD
  ForEach-Object{
   Write-Host "Running Remediation on $_" -ForegroundColor Red
   Start-Job -Name $_ -script {
    $computer = $args[0]
    $path = "$($env:windir)\ccmsetup"
    $mp_address = "sccm.yourdomain.xyz"
    $site_code = "NWD"
    $Clientinstall = "\\$computer -s -d cmd /c $path\ccmsetup.exe /mp:$mp_address SMSSITECODE=$site_code /forceinstall SMSMP=sccm.yourdomain.xyz FSP=sccm.yourdomain.xyz RESETKEYINFORMATION=TRUE"
    $Uninstall = "-s \\$computer c:\windows\ccmsetup\ccmsetup.exe /uninstall"
    $Clean = "\\$computer c:\windows\ccmsetup\ccmclean.exe /q" 

    
    #Start-Process -FilePath "C:\SCCM\PSEXEC\PSexec.exe" -ArgumentList $Uninstall -Wait 
    Copy-Item \\SCCM\PCScripts\ccmclean.exe -Destination "\\$computer\C$\windows\ccmsetup" -Force
    Start-Process -FilePath "C:\SCCM\PSEXEC\PSexec.exe" -ArgumentList $Clean -Wait
    Copy-Item \\SCCM\Client\ccmsetup.exe -Destination "\\$computer\C$\windows\ccmsetup" -Force
    Start-Process -FilePath "C:\SCCM\PSEXEC\PSexec.exe" -ArgumentList $Clientinstall -Wait 


    } -argumentlist $_
    Start-Sleep -s 2
  }

Write-Host "All jobs are running" -ForegroundColor green
Get-Job

#Get-job | Remove-Job -force
#Remove-Job -State NotStarted
#Remove-Job -State completed
