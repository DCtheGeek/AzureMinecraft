Configuration SingleServer {
	# Import Custom Resources
	Import-DscResource -Module xNetworking
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

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