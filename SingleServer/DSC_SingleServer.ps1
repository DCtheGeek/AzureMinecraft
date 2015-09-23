Configuration SingleServer {
	# Import Custom Resources
	Import-DscResource -Module PackageManagementProviderResource,xNetworking
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

	# Setup the server
	Node ('localhost') {
		# Install - .NET 3.5
		WindowsFeature NET35 {
			Name = "NET-Framework-Core"
			Ensure = "Present"
		}

		# Install - Chocolatey Package Provider (beta)
        Script ChocolateyProvider {
            GetScript = "Get-PackageProvider"
            TestScript = { (Get-PackageProvider | Where-Object {$_.Name -eq 'Chocolatey'}).Count -eq 1 }
            SetScript = "Get-PackageProvider -Name Chocolatey -Force -ForceBootstrap"
        }        

        # Install - Java (via Chocolatey)
        Script JavaInstall {
            GetScript = "Get-Package"
            TestScript = { (Get-Package | Where-Object {$_.Name -eq 'jre8'}).Count -eq 1 }
            SetScript = "Install-Package jre8 -ProviderName chocolatey -Force"
            DependsOn = "[Script]ChocolateyProvider"
        }

		# Setting - Disable Java Autoupdate
		Registry JavaAutoUpdate {
			Key = "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\JavaSoft\Java Update\Policy\EnableJavaUpdate"
            ValueName = "0"
            ValueType = "Dword"
            Ensure = "Present"
            DependsOn = "[Script]JavaInstall"
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
            DependsOn = "[WindowsFeature]NET35","[Script]ChocolateyProvider","[Script]JavaInstall","[File]MinecraftFolder","[Environment]MinecraftRoot","[Script]CreeperHubSource","[xFirewall]MinecraftFW"
        }
	}
}