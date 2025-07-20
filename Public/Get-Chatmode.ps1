function Get-Chatmode {
    [CmdletBinding()]
    param(
        [string]$ChatModeName = '*'
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
        $filtered = $files | Where-Object { 
            $nameWithoutExt = $_.name -replace '\.(md|chatmode)$', ''
            $nameWithoutExt -like $ChatModeName 
        }
        if ($filtered) {
            Write-Host "Files in '$directory' directory of $($repoOwner)/$($repoName) matching '$ChatModeName':" -ForegroundColor Cyan
            $filtered.name
        }
        else {
            Write-Host "No files found matching '$ChatModeName' in the directory." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Error fetching data from GitHub: $_" -ForegroundColor Red
    }
}
