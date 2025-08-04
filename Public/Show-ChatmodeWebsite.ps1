<#
.SYNOPSIS
    Opens the GitHub Awesome-Copilot website in your default browser.

.DESCRIPTION
    This function provides a quick way to access the GitHub Awesome-Copilot repository
    website, which contains various chatmodes and related information. It uses
    `Start-Process` to open the URL in the system's default web browser.

.EXAMPLE
    Show-ChatmodeWebsite

    Opens the GitHub Awesome-Copilot website.
#>
function Show-ChatmodeWebsite {
    [CmdletBinding()]
    param()

    Start-Process "https://github.com/github/awesome-copilot"
}