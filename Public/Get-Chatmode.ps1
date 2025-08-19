if (-not $script:RepoMap) {
    # map owner -> repo name for convenient lookup by Install-Chatmode
    $script:RepoMap = @{
        'github' = 'awesome-copilot'
        'dfinke' = 'awesome-copilot-chatmodes'
    }
}

if (-not $script:Repos) {
    # default list of owner/repo entries
    $script:Repos = @('github/awesome-copilot', 'dfinke/awesome-copilot-chatmodes')
}

function Get-Chatmode {
    [CmdletBinding()]
    param(
        [string[]]$ChatModeName = '*',
        # Optional owner (e.g. 'dfinke'). When provided, only search repos for that owner.
        [string[]]$Owner = $null,
        # Accept repos in owner/repo format. Default includes the original repo and the new one.
        [string[]]$Repo = $null,
        [string]$Directory = 'chatmodes'
    )

    if (-not $env:GITHUB_TOKEN) {
        Write-Host "[INFO] For a better experience and higher rate limits, set the GITHUB_TOKEN environment variable." -ForegroundColor Yellow
        $headers = @{ 'User-Agent' = 'PowerShell' }
    }
    else {
        $headers = @{
            'Authorization' = "token $($env:GITHUB_TOKEN)"
            'User-Agent'    = 'PowerShell'
        }
    }

    $allMatches = @()

    # If caller didn't provide a Repo list, use the script-level defaults
    if (-not $Repo -or $Repo.Count -eq 0) {
        if ($Owner -and $Owner.Count -gt 0) {
            # Build repo list from owner(s) using RepoMap when available, otherwise look in default Repos
            $Repo = @()
            foreach ($o in $Owner) {
                if ($script:RepoMap -and $script:RepoMap.ContainsKey($o)) {
                    $Repo += "$o/$($script:RepoMap[$o])"
                }
                else {
                    # Try to find matching entries in the default Repos (owner/*)
                    $matches = $script:Repos | Where-Object { $_ -like "$o/*" }
                    if ($matches) {
                        $Repo += $matches
                    }
                    else {
                        Write-Host "Owner '$o' not found in RepoMap or default repo list. Skipping." -ForegroundColor Yellow
                    }
                }
            }
        }
        else {
            $Repo = $script:Repos
        }
    }

    foreach ($r in $Repo) {
        if (-not ($r -match '/')) {
            Write-Host "Repo '$r' is not in 'owner/repo' format. Skipping." -ForegroundColor Yellow
            continue
        }

        $parts = $r -split '/' 
        $repoOwner = $parts[0]
        $repoName = $parts[1]
        $apiUrl = "https://api.github.com/repos/$repoOwner/$repoName/contents/$Directory"

        try {
            $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -ErrorAction Stop

            $files = $response | Where-Object { $_.type -eq 'file' }

            foreach ($pattern in $ChatModeName) {
                $filtered = $files | Where-Object {
                    $nameWithoutExt = $_.name -replace '\.(md|chatmode)$', ''
                    $nameWithoutExt -like $pattern
                }

                if ($filtered) {
                    Write-Host "Files in '$Directory' directory of $($repoOwner)/$($repoName) matching '$pattern':" -ForegroundColor Cyan
                    foreach ($f in $filtered) {
                        $nameWithoutExt = $f.name -replace '\.(md|chatmode)$', ''
                        # Expose the current repo to module/script scope so downstream commands
                        # (Install-Chatmode, Get-ChatmodeContent) can use it when piped.
                        $script:RepoOwner = $repoOwner
                        $script:RepoName = $repoName
                        $script:Repo = "$repoOwner/$repoName"

                        $allMatches += [PSCustomObject]@{
                            Owner        = $repoOwner
                            Repo         = $repoName
                            RepoName     = $repoName
                            # Backward-compatible short name (no extension)
                            Name         = $nameWithoutExt
                            # ChatModeName is the value Install-Chatmode expects when bound by property name.
                            ChatModeName = $nameWithoutExt
                            # Preserve the original file name (including extension) for callers that need it.
                            FileName     = $f.name
                        }
                    }
                }
                else {
                    Write-Host "No files found matching '$pattern' in $($repoOwner)/$($repoName)." -ForegroundColor Yellow
                }
            }
        }
        catch {
            Write-Host "Error fetching data from $($repoOwner)/$($repoName): $_" -ForegroundColor Red
        }
    }

    if ($allMatches) {
        # Keep full objects for downstream piping, but when running interactively
        # print a simplified display (Owner and ChatModeName only).
        $results = $allMatches | Sort-Object Owner, Name -Unique

        # If this command is part of a larger pipeline (e.g. piped to Install-Chatmode),
        # return full objects so downstream commands can consume them. When run
        # interactively (no further pipeline), print a simplified display only.
        if ($MyInvocation.PipelineLength -gt 1) {
            return $results
        }
        else {
            # Interactive display: show a clean table with Owner and Name (ChatModeName)
            $results | Select-Object @{Name = 'Owner'; Expression = { $_.Owner } }, @{Name = 'Name'; Expression = { $_.ChatModeName } } | Format-Table -AutoSize | Out-Host
            return
        }
    }
}
