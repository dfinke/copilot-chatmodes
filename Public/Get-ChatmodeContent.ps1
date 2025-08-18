function Get-ChatmodeContent {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [string]$ChatModeName,
        # Optional original filename (including extension) provided by Get-Chatmode
        [string]$FileName,
        [string]$Owner,
        [string]$RepoName,
        [string]$Directory = 'chatmodes'
    )

    begin {
        # Default repo values; these may be overridden by script-level variables set by Get-Chatmode
        $repoOwner = if ($Owner) { $Owner } elseif ($script:RepoOwner) { $script:RepoOwner } else { 'github' }
        $repoName = if ($RepoName) { $RepoName } elseif ($script:RepoName) { $script:RepoName } else { 'awesome-copilot' }

        $directory = $Directory
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
        # Determine candidate filenames to try. Prefer explicit FileName, otherwise normalize
        # ChatModeName and try sensible variants to handle names like 'name', 'name.chatmode',
        # 'name.chatmode.md', or 'name.md'.
        $candidates = @()
        if ($FileName) { $candidates += $FileName }

        # Normalize and build candidates from ChatModeName
        $base = $ChatModeName
        if ($base -match '\.md$') {
            # already ends with .md — try as-is
            $candidates += $base
        }
        elseif ($base -match '\.chatmode$') {
            # ends with .chatmode (but not .md) — try adding .md first, then the raw name
            $candidates += "$base.md"
            $candidates += $base
        }
        else {
            # plain name — try both common extensions
            $candidates += "$base.chatmode.md"
            $candidates += "$base.md"
            $candidates += $base
        }

        $lastError = $null
        foreach ($candidate in $candidates) {
            $apiUrl = "https://api.github.com/repos/$repoOwner/$repoName/contents/$directory/$candidate"
            try {
                $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -ErrorAction Stop
                if ($response.content) {
                    $decoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($response.content))
                    return $decoded
                }
                else {
                    Write-Host "No content found for $candidate in $repoOwner/$repoName" -ForegroundColor Yellow
                }
            }
            catch {
                $lastError = $_
                # If 404, continue to next candidate; otherwise log and continue
                if ($_.Exception.Response -and $_.Exception.Response.StatusCode -eq 404) {
                    Write-Verbose "Not found: $candidate in $repoOwner/$repoName"
                    continue
                }
                else {
                    Write-Host "Error fetching content for $($candidate): $($_)" -ForegroundColor Red
                }
            }
        }
        if ($lastError) {
            Write-Host "Error fetching content for $($ChatModeName): $($lastError)" -ForegroundColor Red
        }
    }
}

# Example usage:
# Get-Chatmode | Get-ChatmodeContent
# Get-ChatmodeContent -ChatModeName 'sql-expert'
