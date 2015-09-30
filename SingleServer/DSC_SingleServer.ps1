Configuration SingleServer {
	# Parameters
    param(  
		[Parameter(Mandatory=$true)]  
		[ValidateNotNullorEmpty()]  
		[string]
		$mcEULA,

		[Parameter(Mandatory=$true)]  
		[ValidateNotNullorEmpty()]  
		[string]
		$mcServerName,

		[Parameter(Mandatory=$true)]  
		[ValidateNotNullorEmpty()]  
		[string]
		$mcServerMOTD,

		[Parameter(Mandatory=$true)]  
		[ValidateNotNullorEmpty()]  
		[string]
		$mcUserName,

		[Parameter(Mandatory=$true)]  
		[ValidateNotNullorEmpty()]  
		[string]
		$mcDifficulty,

		[Parameter(Mandatory=$true)]  
		[ValidateNotNullorEmpty()]  
		[string]
		$mcLevelName,

		[Parameter(Mandatory=$true)]  
		[ValidateNotNullorEmpty()]  
		[string]
		$mcGameMode,

		[Parameter(Mandatory=$true)]  
		[ValidateNotNullorEmpty()]  
		[string]
		$mcWhiteList,

		[Parameter(Mandatory=$true)]  
		[ValidateNotNullorEmpty()]  
		[string]
		$mcEnableCommandBlock,

		[Parameter(Mandatory=$true)]  
		[ValidateNotNullorEmpty()]  
		[string]
		$mcSpawnMonsters,

		[Parameter(Mandatory=$true)]  
		[ValidateNotNullorEmpty()]  
		[string]
		$mcGenerateStructures,

		[Parameter(Mandatory=$true)]  
		[ValidateNotNullorEmpty()]  
		[string]
		$mcLevelSeed
	)

	# Import Custom Resources
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration','xNetworking'

	# Setup the server
	Node ('localhost') {

		# Configure LCM for AutoCorrect
		LocalConfigurationManager {
			ConfigurationMode = "ApplyAndAutoCorrect"
			RefreshFrequencyMins = 30
			ConfigurationModeFrequencyMins = 60
			RefreshMode = "PUSH"
			RebootNodeIfNeeded = $true
		}

		# Install - .NET 3.5
		WindowsFeature NET35 {
			Name = "NET-Framework-Core"
			Ensure = "Present"
		}

        # File - Get Java Installer (JRE 8u60)
        Script fileJava {
            GetScript = "Get-Item -Path C:\Installs\jre-8u60-windows-i586.exe"
            TestScript = "Test-Path C:\Installs\jre-8u60-windows-i586.exe"
            SetScript = {
                New-Item -ItemType Container -Path C:\Installs -Force
                Invoke-WebRequest "http://javadl.sun.com/webapps/download/AutoDL?BundleId=109706" -OutFile C:\Installs\jre-8u60-windows-i586.exe
            }
        }

        # Install - Java (JRE 8u60)
        Package installJava {
            Name = "Install Java"
            Path = "C:\Installs\jre-8u60-windows-i586.exe"
            Arguments = "/s /l*vx C:\Installs\jre-8u60-windows-i586.log"
            ProductID = "26A24AE4-039D-4CA4-87B4-2F83218060F0"
            Ensure = "Present"
            DependsOn = "[Script]fileJava"
        }

		# Setting - Disable Java Autoupdate
		Registry JavaAutoUpdate {
			Key = "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\JavaSoft\Java Update\Policy\EnableJavaUpdate"
            ValueName = "0"
            ValueType = "Dword"
            Ensure = "Present"
            DependsOn = "[Package]installJava"
		}

		# Folder - Minecraft
		File MinecraftFolder {
			Destinationpath = "C:\Minecraft"
			Type = "Directory"
			Ensure = "Present"
		}

		# Env - MinecraftRoot
		Environment MinecraftRoot {
			Name = "MinecraftRoot"
			Value = "C:\Minecraft"
			Ensure = "Present"
			DependsOn = "[File]MinecraftFolder"
		}

		# Setting - Choco Source for CreeperHub
		Script CreeperHubSource {
			GetScript = "Get-PackageSource -Name CreeperHub -ErrorAction SilentlyContinue -WarningAction SilentlyContinue"
            TestScript = "(Get-PackageSource -Name CreeperHub -ErrorAction SilentlyContinue -WarningAction SilentlyContinue).Count -eq 1"
            SetScript = "Register-PackageSource -Name CreeperHub -ProviderName Chocolatey -Location http://creeperhub.azurewebsites.net/nuget -Trusted -Force"
		}

		# Setting - Firewall for Minecraft
		xFirewall MinecraftFW {
			Name = "DSC - Minecraft"
			DisplayName = "Minecraft"
			DisplayGroup = "Minecraft"
			Access = "Allow"
			State = "Enabled"
			Profile = ("Domain", "Private", "Public")
			Direction = "Inbound"
			LocalPort = "25565"
			Protocol = "TCP"
			Description = "Minecraft Server exception"
			Ensure = "Present"
		}

        # Setting - EULA for Minecraft (eula.txt)
        Script mcEULA {
            GetScript = { }
            TestScript = {
                if (Test-Path "C:\Minecraft\eula.txt") {
                    $file = Get-Content "C:\Minecraft\eula.txt"  
                    $containsKeyValue = $file | %{$_ -match "eula=$using:mcEULA"}
                    if ($containsKeyValue -contains $true) {
                        return $true
                    } else {
                        return $false
                    }
                } else {
                    return $false
                }
            }
            SetScript = {
                # Check to see if file exists, create if it doesn't
                if ((Test-Path "C:\Minecraft\eula.txt") -eq $false) {
                    # Create and add the new string to the file
                    Add-Content "C:\Minecraft\eula.txt" "eula=$using:mcEULA"
                } else {
                    # Remove the line that is no longer correct
                    $file = Get-Content "C:\Minecraft\eula.txt"
                    $file = $file | Where-Object {$_ -notmatch "eula="}
                    $file | Set-Content "C:\Minecraft\eula.txt" -Force

                    # Add the new string to the file
                    Add-Content "C:\Minecraft\eula.txt" "eula=$using:mcEULA"
                }
            }
            DependsOn = "[File]MinecraftFolder"
        }

		# Setting - Server Name for Minecraft (server.properties)
        Script mcServerName {
            GetScript = { }
            TestScript = {
                if (Test-Path "C:\Minecraft\server.properties") {
                    $file = Get-Content "C:\Minecraft\server.properties"  
                    $containsKeyValue = $file | %{$_ -match "server-name=$using:mcServerName"}
                    if ($containsKeyValue -contains $true) {
                        return $true
                    } else {
                        return $false
                    }
                } else {
                    return $false
                }
            }
            SetScript = {
                # Check to see if file exists, create if it doesn't
                if ((Test-Path "C:\Minecraft\server.properties") -eq $false) {
                    # Create and add the new string to the file
                    Add-Content "C:\Minecraft\server.properties" "server-name=$using:mcServerName"
                } else {
                    # Remove the line that is no longer correct
                    $file = Get-Content "C:\Minecraft\server.properties"
                    $file = $file | Where-Object {$_ -notmatch "server-name="}
                    $file | Set-Content "C:\Minecraft\server.properties" -Force

                    # Add the new string to the file
                    Add-Content "C:\Minecraft\server.properties" "server-name=$using:mcServerName"
                }
            }
            DependsOn = "[File]MinecraftFolder"
        }

		# Setting - Message of the Day for Minecraft (server.properties)
		Script mcServerMOTD {
            GetScript = { }
            TestScript = {
                if (Test-Path "C:\Minecraft\server.properties") {
                    $file = Get-Content "C:\Minecraft\server.properties"  
                    $containsKeyValue = $file | %{$_ -match "motd=$using:mcServerMOTD"}
                    if ($containsKeyValue -contains $true) {
                        return $true
                    } else {
                        return $false
                    }
                } else {
                    return $false
                }
            }
            SetScript = {
                # Check to see if file exists, create if it doesn't
                if ((Test-Path "C:\Minecraft\server.properties") -eq $false) {
                    # Create and add the new string to the file
                    Add-Content "C:\Minecraft\server.properties" "motd=$using:mcServerMOTD"
                } else {
                    # Remove the line that is no longer correct
                    $file = Get-Content "C:\Minecraft\server.properties"
                    $file = $file | Where-Object {$_ -notmatch "motd="}
                    $file | Set-Content "C:\Minecraft\server.properties" -Force

                    # Add the new string to the file
                    Add-Content "C:\Minecraft\server.properties" "motd=$using:mcServerMOTD"
                }
            }
            DependsOn = "[File]MinecraftFolder"
        }

		# Setting - Difficulty for Minecraft (server.properties)
		Script mcDifficulty {
            GetScript = { }
            TestScript = {
                if (Test-Path "C:\Minecraft\server.properties") {
                    $file = Get-Content "C:\Minecraft\server.properties"  
                    $containsKeyValue = $file | %{$_ -match "difficulty=$using:mcDifficulty"}
                    if ($containsKeyValue -contains $true) {
                        return $true
                    } else {
                        return $false
                    }
                } else {
                    return $false
                }
            }
            SetScript = {
                # Check to see if file exists, create if it doesn't
                if ((Test-Path "C:\Minecraft\server.properties") -eq $false) {
                    # Create and add the new string to the file
                    Add-Content "C:\Minecraft\server.properties" "difficulty=$using:mcDifficulty"
                } else {
                    # Remove the line that is no longer correct
                    $file = Get-Content "C:\Minecraft\server.properties"
                    $file = $file | Where-Object {$_ -notmatch "difficulty="}
                    $file | Set-Content "C:\Minecraft\server.properties" -Force

                    # Add the new string to the file
                    Add-Content "C:\Minecraft\server.properties" "difficulty=$using:mcDifficulty"
                }
            }
            DependsOn = "[File]MinecraftFolder"
        }

		# Setting - Level Name for Minecraft (server.properties)
		Script mcLevelName {
            GetScript = { }
            TestScript = {
                if (Test-Path "C:\Minecraft\server.properties") {
                    $file = Get-Content "C:\Minecraft\server.properties"  
                    $containsKeyValue = $file | %{$_ -match "level-name=$using:mcLevelName"}
                    if ($containsKeyValue -contains $true) {
                        return $true
                    } else {
                        return $false
                    }
                } else {
                    return $false
                }
            }
            SetScript = {
                # Check to see if file exists, create if it doesn't
                if ((Test-Path "C:\Minecraft\server.properties") -eq $false) {
                    # Create and add the new string to the file
                    Add-Content "C:\Minecraft\server.properties" "level-name=$using:mcLevelName"
                } else {
                    # Remove the line that is no longer correct
                    $file = Get-Content "C:\Minecraft\server.properties"
                    $file = $file | Where-Object {$_ -notmatch "level-name="}
                    $file | Set-Content "C:\Minecraft\server.properties" -Force

                    # Add the new string to the file
                    Add-Content "C:\Minecraft\server.properties" "level-name=$using:mcLevelName"
                }
            }
            DependsOn = "[File]MinecraftFolder"
        }

		# Setting - Game Mode for Minecraft (server.properties)
		Script mcGameMode {
            GetScript = { }
            TestScript = {
                if (Test-Path "C:\Minecraft\server.properties") {
                    $file = Get-Content "C:\Minecraft\server.properties"  
                    $containsKeyValue = $file | %{$_ -match "gamemode=$using:mcGameMode"}
                    if ($containsKeyValue -contains $true) {
                        return $true
                    } else {
                        return $false
                    }
                } else {
                    return $false
                }
            }
            SetScript = {
                # Check to see if file exists, create if it doesn't
                if ((Test-Path "C:\Minecraft\server.properties") -eq $false) {
                    # Create and add the new string to the file
                    Add-Content "C:\Minecraft\server.properties" "gamemode=$using:mcGameMode"
                } else {
                    # Remove the line that is no longer correct
                    $file = Get-Content "C:\Minecraft\server.properties"
                    $file = $file | Where-Object {$_ -notmatch "gamemode="}
                    $file | Set-Content "C:\Minecraft\server.properties" -Force

                    # Add the new string to the file
                    Add-Content "C:\Minecraft\server.properties" "gamemode=$using:mcGameMode"
                }
            }
            DependsOn = "[File]MinecraftFolder"
        }

		# Setting - White List for Minecraft (server.properties)
		Script mcWhiteList {
            GetScript = { }
            TestScript = {
                if (Test-Path "C:\Minecraft\server.properties") {
                    $file = Get-Content "C:\Minecraft\server.properties"  
                    $containsKeyValue = $file | %{$_ -match "white-list=$using:mcWhiteList"}
                    if ($containsKeyValue -contains $true) {
                        return $true
                    } else {
                        return $false
                    }
                } else {
                    return $false
                }
            }
            SetScript = {
                # Check to see if file exists, create if it doesn't
                if ((Test-Path "C:\Minecraft\server.properties") -eq $false) {
                    # Create and add the new string to the file
                    Add-Content "C:\Minecraft\server.properties" "white-list=$using:mcWhiteList"
                } else {
                    # Remove the line that is no longer correct
                    $file = Get-Content "C:\Minecraft\server.properties"
                    $file = $file | Where-Object {$_ -notmatch "white-list="}
                    $file | Set-Content "C:\Minecraft\server.properties" -Force

                    # Add the new string to the file
                    Add-Content "C:\Minecraft\server.properties" "white-list=$using:mcWhiteList"
                }
            }
            DependsOn = "[File]MinecraftFolder"
        }

		# Setting - Enable Command Block for Minecraft (server.properties)
		Script mcEnableCommandBlock {
            GetScript = { }
            TestScript = {
                if (Test-Path "C:\Minecraft\server.properties") {
                    $file = Get-Content "C:\Minecraft\server.properties"  
                    $containsKeyValue = $file | %{$_ -match "enable-command-block=$using:mcEnableCommandBlock"}
                    if ($containsKeyValue -contains $true) {
                        return $true
                    } else {
                        return $false
                    }
                } else {
                    return $false
                }
            }
            SetScript = {
                # Check to see if file exists, create if it doesn't
                if ((Test-Path "C:\Minecraft\server.properties") -eq $false) {
                    # Create and add the new string to the file
                    Add-Content "C:\Minecraft\server.properties" "enable-command-block=$using:mcEnableCommandBlock"
                } else {
                    # Remove the line that is no longer correct
                    $file = Get-Content "C:\Minecraft\server.properties"
                    $file = $file | Where-Object {$_ -notmatch "enable-command-block="}
                    $file | Set-Content "C:\Minecraft\server.properties" -Force

                    # Add the new string to the file
                    Add-Content "C:\Minecraft\server.properties" "enable-command-block=$using:mcEnableCommandBlock"
                }
            }
            DependsOn = "[File]MinecraftFolder"
        }

		# Setting - Spawn Monsters for Minecraft (server.properties)
		Script mcSpawnMonsters {
            GetScript = { }
            TestScript = {
                if (Test-Path "C:\Minecraft\server.properties") {
                    $file = Get-Content "C:\Minecraft\server.properties"  
                    $containsKeyValue = $file | %{$_ -match "spawn-monsters=$using:mcSpawnMonsters"}
                    if ($containsKeyValue -contains $true) {
                        return $true
                    } else {
                        return $false
                    }
                } else {
                    return $false
                }
            }
            SetScript = {
                # Check to see if file exists, create if it doesn't
                if ((Test-Path "C:\Minecraft\server.properties") -eq $false) {
                    # Create and add the new string to the file
                    Add-Content "C:\Minecraft\server.properties" "spawn-monsters=$using:mcSpawnMonsters"
                } else {
                    # Remove the line that is no longer correct
                    $file = Get-Content "C:\Minecraft\server.properties"
                    $file = $file | Where-Object {$_ -notmatch "spawn-monsters="}
                    $file | Set-Content "C:\Minecraft\server.properties" -Force

                    # Add the new string to the file
                    Add-Content "C:\Minecraft\server.properties" "spawn-monsters=$using:mcSpawnMonsters"
                }
            }
            DependsOn = "[File]MinecraftFolder"
        }

		# Setting - Generate Structures for Minecraft (server.properties)
		Script mcGenerateStructures {
            GetScript = { }
            TestScript = {
                if (Test-Path "C:\Minecraft\server.properties") {
                    $file = Get-Content "C:\Minecraft\server.properties"  
                    $containsKeyValue = $file | %{$_ -match "generate-structures=$using:mcGenerateStructures"}
                    if ($containsKeyValue -contains $true) {
                        return $true
                    } else {
                        return $false
                    }
                } else {
                    return $false
                }
            }
            SetScript = {
                # Check to see if file exists, create if it doesn't
                if ((Test-Path "C:\Minecraft\server.properties") -eq $false) {
                    # Create and add the new string to the file
                    Add-Content "C:\Minecraft\server.properties" "generate-structures=$using:mcGenerateStructures"
                } else {
                    # Remove the line that is no longer correct
                    $file = Get-Content "C:\Minecraft\server.properties"
                    $file = $file | Where-Object {$_ -notmatch "generate-structures="}
                    $file | Set-Content "C:\Minecraft\server.properties" -Force

                    # Add the new string to the file
                    Add-Content "C:\Minecraft\server.properties" "generate-structures=$using:mcGenerateStructures"
                }
            }
            DependsOn = "[File]MinecraftFolder"
        }

		# Setting - Level Seed for Minecraft (server.properties)
		Script mcLevelSeed {
            GetScript = { }
            TestScript = {
                if (Test-Path "C:\Minecraft\server.properties") {
                    $file = Get-Content "C:\Minecraft\server.properties"  
                    $containsKeyValue = $file | %{$_ -match "level-seed=$using:mcLevelSeed"}
                    if ($containsKeyValue -contains $true) {
                        return $true
                    } else {
                        return $false
                    }
                } else {
                    return $false
                }
            }
            SetScript = {
                # Check to see if file exists, create if it doesn't
                if ((Test-Path "C:\Minecraft\server.properties") -eq $false) {
                    # Create and add the new string to the file
                    Add-Content "C:\Minecraft\server.properties" "level-seed=$using:mcLevelSeed"
                } else {
                    # Remove the line that is no longer correct
                    $file = Get-Content "C:\Minecraft\server.properties"
                    $file = $file | Where-Object {$_ -notmatch "level-seed="}
                    $file | Set-Content "C:\Minecraft\server.properties" -Force

                    # Add the new string to the file
                    Add-Content "C:\Minecraft\server.properties" "level-seed=$using:mcLevelSeed"
                }
            }
            DependsOn = "[File]MinecraftFolder"
        }

		# Setting - Fix IE RunOnce for SYSTEM to allow Invoke-WebRequest in [Script]mcUserName
		Registry FixSystemRunOnce {
			Key = "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Internet Explorer\Main\RunOnceComplete"
            ValueName = "1"
            ValueType = "Dword"
            Ensure = "Present"
		}

		# Setting - User Name as Operator for Minecraft (ops.json with Mojang API call)
        Script mcUserName {
            GetScript = { }
            TestScript = {
                if (Test-Path "C:\Minecraft\ops.json") {
                    $file = Get-Content "C:\Minecraft\ops.json" | ConvertFrom-Json
                    $match = $false
                    $file | ForEach-Object {
                        if (($_.name -eq "$using:mcUserName") -and ($_.level -eq 4)) {
                            $match = $true
                        }
                    }
                    return $match
                } else {
                    return $false
                }
            }
            SetScript = {
                # Local Variable
                $urlUUID = "https://api.mojang.com/users/profiles/minecraft/$using:mcUserName"

                # Check to see if file exists, delete to clean up
                if ((Test-Path "C:\Minecraft\ops.json")) {
                    Remove-Item -Path "C:\Minecraft\ops.json" -Force
                }

                # Set only Op as what was passed to DSC
                $apiObj = Invoke-WebRequest $urlUUID | ConvertFrom-Json
                $mcUUID = $apiObj[0].id.Substring(0,8) + "-" + $apiObj[0].id.Substring(8,4) + "-" + $apiObj[0].id.Substring(12,4) + "-" + $apiObj[0].id.Substring(16,4) + "-" + $apiObj[0].id.Substring(20,12)
                "[`n {`n  ""uuid"":""$mcUUID"",`n  ""name"":""$using:mcUserName"",`n  ""level"":4`n }`n]" | Add-Content "C:\Minecraft\ops.json"
            }
            DependsOn = "[File]MinecraftFolder","[Registry]FixSystemRunOnce"
        }

		# Install - Minecraft (via Chocolatey)
        Script MinecraftInstall {
            GetScript = "Get-Package"
            TestScript = { (Get-Package | Where-Object {$_.Name -eq 'minecraft'}).Count -eq 1 }
            SetScript = "Install-Package minecraft -Source CreeperHub -ProviderName chocolatey  -Force"
            DependsOn = "[WindowsFeature]NET35","[Script]fileJava","[Package]installJava","[File]MinecraftFolder","[Environment]MinecraftRoot","[Script]CreeperHubSource","[xFirewall]MinecraftFW"
        }

		# Run - Minecraft (via Java)
        Script MinecraftRunning {
            GetScript = "Get-Process -Name java"
            TestScript = { (Get-WmiObject Win32_Process -Filter {CommandLine like '%minecraft_server.jar%'} | Measure-Object).Count -eq 1 }
            SetScript = { Start-Process -FilePath "C:\Program Files (x86)\Java\jre1.8.0_60\bin\java.exe" -ArgumentList "-Xmx1024M -Xms1024M -jar C:\Minecraft\minecraft_server.jar nogui" -WorkingDirectory C:\Minecraft }
			DependsOn = "[Script]MinecraftInstall"
        }
	}
}