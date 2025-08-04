# copilot-chatmodes.psm1
. $PSScriptRoot\Public\Get-Chatmode.ps1
. $PSScriptRoot\Public\Get-ChatmodeContent.ps1
. $PSScriptRoot\Public\Get-ChatmodeTool.ps1
. $PSScriptRoot\Public\Install-Chatmode.ps1

# Create aliases
Set-Alias -Name gcmt -Value Get-ChatmodeTool

. $PSScriptRoot\Public\Show-ChatmodeWebsite.ps1
