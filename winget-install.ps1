# Attempt to import the ThreadJob module
# try {
#     Import-Module ThreadJob -ErrorAction Stop
#     Write-Host "ThreadJob module imported successfully."
# }
# catch {
#     Write-Warning "ThreadJob module not found. Attempting to install..."
#     try {
#         Install-Module ThreadJob -Scope CurrentUser -Force -ErrorAction Stop
#         Import-Module ThreadJob -ErrorAction Stop
#         Write-Host "ThreadJob module installed and imported successfully."
#     }
#     catch {
#         Write-Error "Failed to install or import ThreadJob module: $($_.Exception.Message)"
#     }
# }

$downloadsFolder = "$HOME\Downloads"

# Dependencies
$deps = @(
    @{
        name = "WinGet msixbundle"
        url = "https://github.com/microsoft/winget-cli/releases/download/v1.10.390/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
        filename = "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
    }
    @{
        name = "WinGet License"
        url = "https://github.com/microsoft/winget-cli/releases/download/v1.10.390/e53e159d00e04f729cc2180cffd1c02e_License1.xml"
        filename = "e53e159d00e04f729cc2180cffd1c02e_License1.xml"
    }
    @{
        name = "VSLibs Desktop Framework"
        url = "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx"
        filename = "Microsoft.VCLibs.x64.14.00.Desktop.appx"
    }
    @{
        name = "Microsoft.UI.Xaml.2.8"
        url = "https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.8.7"
        filename = "microsoft.ui.xaml.2.8.7.nupkg"
    }
)

# Download multiple files at the same time
# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-webrequest?view=powershell-7.5#example-8-download-multiple-files-at-the-same-time
$downloadsQueue = @()

foreach($dep in $deps) {
    $downloadsQueue += Start-ThreadJob -Name $dep.name -ScriptBlock {
        $params = $Using:dep
        $downloadPath = $Using:downloadsFolder
        $outfile = "$($downloadPath)\$($params.filename)"
        if (Test-Path $outfile) {
            Write-Host "$($params.name) is already downloaded."
        } else {
            Write-Host "Downloading $($params.name)"
            Invoke-WebRequest -Uri $params.url -OutFile $outfile
        }
    }
}

Write-Host "Installing Dependencies"
Wait-Job -Job $downloadsQueue

foreach ($job in $downloadsQueue) {
    Receive-Job -Job $job
}

# if (Test-Path "$($downloadsFolder)\microsoft.ui.xaml.2.8.7.nupkg") {
#     Write-Host "Renaming microsoft.ui.xaml.2.8.7.nupkg to microsoft.ui.xaml.2.8.7.zip"
#     Move-Item -Path "$($downloadsFolder)\microsoft.ui.xaml.2.8.7.nupkg" -Destination "$($downloadsFolder)\microsoft.ui.xaml.2.8.7.zip" -Force
# }

Write-Host "Extracting microsoft.ui.xaml.2.8.7.zip to $($downloadsFolder)\microsoft.ui.xaml.2.8.7"
Expand-Archive -Path "$($downloadsFolder)\microsoft.ui.xaml.2.8.7.zip" -DestinationPath "$($downloadsFolder)\microsoft.ui.xaml.2.8.7" -Force
Write-Host "Moving Microsoft.UI.Xaml.2.8.appx from extracted zip to $($downloadsFolder)\Microsoft.UI.Xaml.2.8.appx"
Move-Item -Path "$($downloadsFolder)\microsoft.ui.xaml.2.8.7\tools\AppX\x64\Release\Microsoft.UI.Xaml.2.8.appx" -Destination "$($downloadsFolder)\Microsoft.UI.Xaml.2.8.appx" -Force

# Install WinGet Client
# foreach($dep in $deps) {
#     Add-AppxPackage -Path "$($downloadsFolder)\$($dep.filename)"
# }
Add-AppxPackage -Path "$($downloadsFolder)\$($deps.Where({$_.name -eq "VSLibs Desktop Framework"}).filename)" -WhatIf
Add-AppxPackage -Path "$($downloadsFolder)\Microsoft.UI.Xaml.2.8.appx" -WhatIf
Add-AppxPackage -Path "$($downloadsFolder)\$($deps.Where({$_.name -eq "WinGet msixbundle"}).filename)" -WhatIf
Add-AppxProvisionedPackage -Online -PackagePath "$($downloadsFolder)\$($deps.Where({$_.name -eq "WinGet msixbundle"}).filename)" -LicensePath "$($downloadsFolder)\$($deps.Where({$_.name -eq "WinGet License"}).filename)"

Read-Host -Prompt "Press Enter to continue"
