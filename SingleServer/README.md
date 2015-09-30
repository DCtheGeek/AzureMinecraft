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

Note that any value in <i>server.properties</i>, <i>eula.txt</i>, or <i>ops.json</i> configured by PowerShell DSC should be updated using PowerShell DSC.  In other words, if you 
make the change directly in the respective file, since PowerShell DSC configured that setting, it will set it back to whatever DSC initially set it as.  This
serves to not only configure the system as desired, but maintain that configuration from being changed or corrupted unexpectedly, which is the nature
and the value of PowerShell DSC (zero-drift in configuration).

In the case of <i>ops.json</i> specifically, the script used checks to validate that the originally specified user is an Op.  If they are, no
other changes will be made to the file (it passes the Test, so Set never runs).  In other words, if you add other Ops to the system (so long as
that change is valid JSON and doesn't break in Minecraft) and the originally provided UserName is still part of that file, it will not recreate.  
However, if the originally provided UserName is missing from <i>ops.json</i>, the DSC Configuration will delete whatever is there and create it clean.

All other Minecraft related settings simply delete the incorrect value from the configuration file and write back the provided value.