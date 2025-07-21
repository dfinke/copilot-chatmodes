function Get-Chatmode {
    [CmdletBinding()]
    param(
        [string[]]$ChatModeName = '*'
    )
    $repoOwner = 'github'
    $repoName = 'awesome-copilot'
    $directory = 'chatmodes'
    
    $apiUrl = "https://api.github.com/repos/$repoOwner/$repoName/contents/$directory"

    if (-not $env:GITHUB_TOKEN) {
        Write-Host "[INFO] For a better experience and higher rate limits, set the GITHUB_TOKEN environment variable."
        $headers = @{ 'User-Agent' = 'PowerShell' }
    }
    else {
        $headers = @{
            'Authorization' = "token $($env:GITHUB_TOKEN)"
            'User-Agent'    = 'PowerShell'
        }
    }

    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -ErrorAction Stop

        $files = $response | Where-Object { $_.type -eq 'file' }
        $allMatches = @()
        foreach ($pattern in $ChatModeName) {
            $filtered = $files | Where-Object {
                $nameWithoutExt = $_.name -replace '\.(md|chatmode)$', ''
                $nameWithoutExt -like $pattern
            }
            if ($filtered) {
                Write-Host "Files in '$directory' directory of $($repoOwner)/$($repoName) matching '$pattern':" -ForegroundColor Cyan
                $allMatches += $filtered
            }
            else {
                Write-Host "No files found matching '$pattern' in the directory." -ForegroundColor Yellow
            }
        }
        if ($allMatches) {
            $allMatches | Select-Object -Unique -ExpandProperty name
        }
    }
    catch {
        Write-Host "Error fetching data from GitHub: $_" -ForegroundColor Red
    }
}
