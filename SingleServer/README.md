# Minecraft - Single Server

This template allows you to deploy a single Windows VM running Minecraft.
 
This template deploys the following resources:
<ul>
	<li>Network Security Group</li>
	<li>Public IP</li>
	<li>Storage Account</li>
	<li>Virtual Machine (A3)</li>
	<li>Virtual Machine Extension (PowerShell DSC)</li>
	<li>vNet</li>
</ul>

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FDCtheGeek%2FAzureMinecraft%2Fmaster%2FSingleServer%2FSingleServer.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

Once the Deployment is complete, you'll need to connect to the VM and modify eula.txt to accept the Mojang EULA (https://account.mojang.com/documents/minecraft_eula).  
Then just run <i>start_minecraft.bat</i> to relaunch Minecraft or wait for the next execution cycle of PowerShell Desired State 
Configuration (PS-DSC).