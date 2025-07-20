function Get-ChatmodeContent {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [string]$ChatModeName
    )

    begin {
        $repoOwner = 'github'
        $repoName = 'awesome-copilot'
        $directory = 'chatmodes'
        if (-not $env:GITHUB_TOKEN) {
            $headers = @{ 'User-Agent' = 'PowerShell' }
        }
        else {
            $headers = @{
                'Authorization' = "token $($env:GITHUB_TOKEN)"
                'User-Agent'    = 'PowerShell'
            }
        }
    }
    process {
        if (-not $ChatModeName) {
            Write-Error 'You must specify a ChatModeName.'
            return
        }
        # Support .chatmode and .md extensions, default to .md if neither is present
        if ($ChatModeName -notmatch '\.(md|chatmode)$') {
            $fileName = "$ChatModeName.md"
        }
        else {
            $fileName = $ChatModeName
        }
        $apiUrl = "https://api.github.com/repos/$repoOwner/$repoName/contents/$directory/$fileName"
        try {
            $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -ErrorAction Stop
            if ($response.content) {
                $decoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($response.content))
                Write-Output $decoded
            }
            else {
                Write-Host "No content found for $ChatModeName" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "Error fetching content for $($ChatModeName): $($_)" -ForegroundColor Red
        }
    }
}

# Example usage:
# Get-Chatmode | Get-ChatmodeContent
# Get-ChatmodeContent -ChatModeName 'sql-expert'
