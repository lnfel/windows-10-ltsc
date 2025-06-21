if (Get-Command Start-ThreadJob -ErrorAction SilentlyContinue) {
    Write-Host "Start-ThreadJob is available."
} else {
    Write-Host "Start-ThreadJob is not available. Checking for ThreadJob module..."
    if (Get-Module ThreadJob -ListAvailable) {
        Write-Host "ThreadJob module is available but not imported. Importing module..."
        Import-Module ThreadJob
        if (Get-Command Start-ThreadJob -ErrorAction SilentlyContinue) {
            Write-Host "Start-ThreadJob is now available."
        } else {
            Write-Host "Failed to import ThreadJob module correctly."
        }
    } else {
        # Write-Host "ThreadJob module is not installed. Please install it using:"
        # Write-Host "Install-Module -Name ThreadJob -Scope CurrentUser"
        Install-Module -Name ThreadJob -Scope CurrentUser
    }
}

$downloadsFolder = "$($HOME)\Downloads"

# Powershell
# TODO: Figure out how to check latest release via Microsoft website or Github release
# Check Powershell version using $PSVersionTable.PSVersion
$psversion = "$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
Write-Host "Current Powershell version is $($psversion)"
if ($psversion -ne "7.5") {
    Write-Host "Updating Powershell to 7.5.1"
    $powershellZipURL = "https://github.com/PowerShell/PowerShell/releases/download/v7.5.1/PowerShell-7.5.1-win-x64.zip"
    $powershellFilename = Split-Path $powershellZipURL -Leaf
    $outfile = "$($downloadsFolder)\$($powershellFilename)"
    if (Test-Path $outfile) {
        Write-Host "$($powershellFilename) is already downloaded."
    } else {
        Write-Host "Downloading $($powershellFilename) in $($downloadsFolder)"
        Invoke-WebRequest -Uri $powershellZipURL -OutFile $outfile
        Write-Host "Extracting $($powershellFilename)"
        Expand-Archive -Path "$($downloadsFolder)\PowerShell-7.5.1-win-x64.zip" -DestinationPath "$($downloadsFolder)\PowerShell-7.5.1-win-x64" -Force

        # Write-Host "Running Powershell installation script"
        # Set-ExecutionPolicy RemoteSigned
        # . "$($downloadsFolder)\PowerShell-7.5.1-win-x64\Install-PowerShellRemoting.ps1" -PowerShellHome .
        # Set-ExecutionPolicy Restricted
    }
}

# $PROFILE is $HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
# if (Test-Path $PROFILE) {
#     Add-Content -Path $PROFILE -Value "# Use Powershell 7.5 as default"
#     Add-Content -Path $PROFILE -Value "& $($downloadsFolder)\PowerShell-7.5.1-win-x64\pwsh.exe"
# } else {
#     New-Item -Path $PROFILE -ItemType file
#     Add-Content -Path $PROFILE -Value "# Use Powershell 7.5 as default"
#     Add-Content -Path $PROFILE -Value "& $($downloadsFolder)\PowerShell-7.5.1-win-x64\pwsh.exe"
# }

# WintGet Dependencies
# https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-hashtable?view=powershell-7.5
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

if (Get-Command Start-ThreadJob -ErrorAction SilentlyContinue) {
    foreach($dep in $deps) {
        $downloadsQueue += Start-ThreadJob -Name $dep.name -ScriptBlock {
            $params = $Using:dep
            $downloadPath = $Using:downloadsFolder
            $outfile = "$($downloadPath)\$($params.filename)"
            if (Test-Path $outfile) {
                Write-Host "$($params.name) is already downloaded."
            } else {
                if ($params.name -ne "Microsoft.UI.Xaml.2.8") {
                    Write-Host "Downloading $($params.name)"
                    Invoke-WebRequest -Uri $params.url -OutFile $outfile
                } else {
                    # Check if microsoft.ui.xaml.2.8.7 is already renamed
                    if (Test-Path "$($downloadsFolder)\microsoft.ui.xaml.2.8.7.zip") {
                        Write-Host "$($params.name) is already downloaded."
                    } else {
                        Write-Host "Downloading $($params.name)"
                        Invoke-WebRequest -Uri $params.url -OutFile $outfile
                    }
                }
            }
        }
    }

    Write-Host "Installing Dependencies"
    Wait-Job -Job $downloadsQueue

    foreach ($job in $downloadsQueue) {
        Receive-Job -Job $job
    }

    Move-Item -Path "$($downloadsFolder)\microsoft.ui.xaml.2.8.7.nupkg" -Destination "$($downloadsFolder)\microsoft.ui.xaml.2.8.7.zip" -ErrorAction SilentlyContinue
    Write-Host "Extracting microsoft.ui.xaml.2.8.7.zip to $($downloadsFolder)\microsoft.ui.xaml.2.8.7"
    Expand-Archive -Path "$($downloadsFolder)\microsoft.ui.xaml.2.8.7.zip" -DestinationPath "$($downloadsFolder)\microsoft.ui.xaml.2.8.7" -Force
    Write-Host "Moving Microsoft.UI.Xaml.2.8.appx from extracted zip to $($downloadsFolder)\Microsoft.UI.Xaml.2.8.appx"
    Move-Item -Path "$($downloadsFolder)\microsoft.ui.xaml.2.8.7\tools\AppX\x64\Release\Microsoft.UI.Xaml.2.8.appx" -Destination "$($downloadsFolder)\Microsoft.UI.Xaml.2.8.appx" -Force

    # Install WinGet Client
    Add-AppxPackage -Path "$($downloadsFolder)\$($deps.Where({$_.name -eq "VSLibs Desktop Framework"}).filename)" -ErrorAction SilentlyContinue #-WhatIf
    Add-AppxPackage -Path "$($downloadsFolder)\Microsoft.UI.Xaml.2.8.appx" #-WhatIf
    Add-AppxPackage -Path "$($downloadsFolder)\$($deps.Where({$_.name -eq "WinGet msixbundle"}).filename)" #-WhatIf
    Add-AppxProvisionedPackage -Online -PackagePath "$($downloadsFolder)\$($deps.Where({$_.name -eq "WinGet msixbundle"}).filename)" -LicensePath "$($downloadsFolder)\$($deps.Where({$_.name -eq "WinGet License"}).filename)"
}

# Common tools
$tools = @(
    @{
        name = "VSCode"
        id = "Microsoft.VisualStudioCode"
        version = "1.80.1"
    }
    @{
        name = "Warp"
        id = "Warp.Warp"
    }
    # @{
    #     name = "Fast Node Manager"
    #     id = "Schniz.fnm"
    # }
    @{
        name = "NVM for Windows"
        id = "CoreyButler.NVMforWindows"
    }
    @{
        name = "Microsoft Git"
        id = "Microsoft.Git"
    }
    @{
        name = "Rustup"
        id = "Rustlang.Rustup"
    }
)

$wingetQueue = @()

if (Get-Command Start-ThreadJob -ErrorAction SilentlyContinue) {
    # Writing Progress across multiple threads with ForEach-Object -Parallel
    # https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/write-progress-across-multiple-threads?view=powershell-7.5
    # $results = $tools | ForEach-Object -Parallel {
    #     $_ | Get-Content | Out-String
    #     Write-Host "Installing $($_.name)"
    # }

    foreach($app in $tools) {
        $wingetQueue += Start-ThreadJob -Name $app.name -ScriptBlock {
            # Clean WinGet logs when invoked using powershell or other scripts
            # https://github.com/microsoft/winget-cli/issues/2582#issuecomment-1945481998
            function Remove-Progressbar {
                param(
                    [ScriptBlock]$ScriptBlock
                )

                # Regex pattern to match spinner characters and progress bar patterns
                # $progressPattern = 'Γû[Æê]|Γû[ê]|^\s+[-\\|/]\s+$'
                $progressPattern = 'Γû[Æê]|^\s+[-\\|/]\s+$'

                # Corrected regex pattern for size formatting, ensuring proper capture groups are utilized
                $sizePattern = '(\d+(\.\d{1,2})?)\s+(B|KB|MB|GB|TB|PB) /\s+(\d+(\.\d{1,2})?)\s+(B|KB|MB|GB|TB|PB)'

                $previousLineWasEmpty = $false # Track if the previous line was empty

                & $ScriptBlock 2>&1 | ForEach-Object {
                    if ($_ -is [System.Management.Automation.ErrorRecord]) {
                        "ERROR: $($_.Exception.Message)"
                    } elseif ($_ -match '^\s*$') {
                        if (-not $previousLineWasEmpty) {
                            Write-Output ""
                            $previousLineWasEmpty = $true
                        }
                    } else {
                        $line = $_ -replace $progressPattern, '' -replace $sizePattern, '$1 $3 / $4 $6'
                        if (-not [string]::IsNullOrWhiteSpace($line)) {
                            $previousLineWasEmpty = $false
                            $line
                        }
                    }
                }
            }
            
            $params = $Using:app
            # Invoke winget install command
            Remove-Progressbar -ScriptBlock {
                if ($params.ContainsKey("version")) {
                    Write-Host "Installing $($params.name) $($params.version)"
                    winget install $params.id --version $params.version
                } else {
                    Write-Host "Installing $($params.name) latest"
                    winget install $params.id
                }
            }
            # Remove-Progressbar -ScriptBlock {
            #     winget install $params.id --accept-package-agreements --accept-source-agreements --force | tee output.txt
            # }

            # Alternative
            # Invoke-Expression "winget install $($params.id)"
        }
    }

    Write-Host "Installing Common Tools"
    Wait-Job -Job $wingetQueue

    foreach ($job in $wingetQueue) {
        Receive-Job -Job $job
    }
}

# Configurations
# Add-Content -Path $PROFILE -Value "`n# Fast Node Manager"
# Add-Content -Path $PROFILE -Value "fnm completions --shell powershell | Out-String | Invoke-Expression"
# Add-Content -Path $PROFILE -Value "fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression"
Write-Host "Configuring git"
$username = Read-Host "Username"
$email = Read-Host "Email"
git config --global user.name $username
git config --global user.email $email

# Configure Warp theme
# https://docs.warp.dev/terminal/appearance/custom-themes#warps-custom-theme-repository
do {
    $configureWarp = Read-Host -Prompt "Configure Warp theme? (Y/N)"
    $configureWarp = $configureWarp.ToLower()
} until ($configureWarp -eq 'y' -or $configureWarp -eq 'n')

if ($configureWarp -eq 'y') {
    Write-Host "Configuring Warp theme"
    $warpThemesPath = "$env:APPDATA\warp\Warp\data\themes"
    New-Item -Path $warpThemesPath -ItemType Directory
    Set-Location -Path $warpThemesPath
    $defaultCustomThemeName = "suisei-tokyo-night"
    $themeName = Read-Host -Prompt "Theme name (default: $($defaultCustomThemeName))"
    if ([string]::IsNullOrWhiteSpace($themeName)) {
        $themeName = $defaultCustomThemeName
    }

    $themePath = "$($warpThemesPath)\$($themeName)"
    New-Item -Path $themePath -ItemType Directory
    Set-Location -Path $themePath

    if ($themeName -eq $defaultCustomThemeName) {
        $themeWallpaperPath = "$($themePath)\wallpaper"
        New-Item -Path $themeWallpaperPath -ItemType Directory

        $yamlURL = "https://cdn.discordapp.com/attachments/1350002020668538931/1385963691635380224/suisei-tokyo-night.yaml?ex=6857fac6&is=6856a946&hm=a727d48d359cbdb961669c6b2d1baa408130d4452ee5be90d466cd573e1b1b92&"
        $yamlFilename = Split-Path $yamlURL.Split('?')[0] -Leaf
        Invoke-WebRequest -Uri $yamlURL -OutFile "$($themePath)\$($yamlFilename)"

        $themeWallpaperURL = "https://media.discordapp.net/attachments/1350002020668538931/1355012172685512894/suisei_august_2023.webp?ex=6857706c&is=68561eec&hm=fbe138e72a6b0c4c53f8b718c9cf3b1c5d100d510ab71af79355842922e54603&=&format=webp&width=1381&height=777"
        $wallpaperFilename = Split-Path $themeWallpaperURL.Split('?')[0] -Leaf
        Invoke-WebRequest -Uri $themeWallpaperURL -OutFile "$($themeWallpaperPath)\$($wallpaperFilename)"
    } else {
        $yamlURL = Read-Host -Prompt "URL of yaml file for $($themeName) theme (Press Enter to skip)"
        if (-not [string]::IsNullOrEmpty($yamlURL)) {
            $yamlFilename = Split-Path $yamlURL.Split('?')[0] -Leaf
            Invoke-WebRequest -Uri $yamlURL -OutFile "$($themePath)\$($yamlFilename)"
        }
    }
}

Read-Host -Prompt "Press Enter to continue"
