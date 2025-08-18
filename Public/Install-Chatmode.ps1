function Install-Chatmode {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(ValueFromPipelineByPropertyName = $true, Position = 0)]
        [string[]]$ChatModeName,
        # Accept FileName from pipeline (e.g. produced by Get-Chatmode)
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$FileName,
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$Owner,
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$RepoName,
        [string]$Destination = ".github/chatmodes"
    )

    begin {
        if (-not (Test-Path $Destination)) {
            New-Item -ItemType Directory -Path $Destination -Force | Out-Null
        }
    }
    process {
        # Input can come in three ways:
        # 1) Direct parameters: -ChatModeName 'a','b'
        # 2) Property-bound pipeline: Get-Chatmode | Install-Chatmode (properties bind to parameters)
        # 3) Full piped object: Get-Chatmode | Install-Chatmode (object available as $PSItem)

        # Build per-invocation values by preferring properties from a piped object when present.
        $invFileName = $null
        $invOwner = $null
        $invRepoName = $null
        $invChatModeNames = @()

        if ($PSItem -and ($PSItem -is [PSObject])) {
            # Extract common properties if the caller piped a full object
            if ($PSItem.PSObject.Properties.Match('FileName')) { $invFileName = $PSItem.FileName }
            if ($PSItem.PSObject.Properties.Match('ChatModeName')) { $invChatModeNames += $PSItem.ChatModeName }
            elseif ($PSItem.PSObject.Properties.Match('Name')) { $invChatModeNames += $PSItem.Name }
            if ($PSItem.PSObject.Properties.Match('Owner')) { $invOwner = $PSItem.Owner }
            if ($PSItem.PSObject.Properties.Match('RepoName')) { $invRepoName = $PSItem.RepoName }
            if ($PSItem.PSObject.Properties.Match('Repo')) { $invRepoName = $PSItem.Repo }
        }

        # Fall back to bound parameters when per-item properties are not provided
        if (-not $invFileName -and $FileName) { $invFileName = $FileName }
        if (-not $invOwner -and $Owner) { $invOwner = $Owner }
        if (-not $invRepoName -and $RepoName) { $invRepoName = $RepoName }
        if (($invChatModeNames.Count -eq 0) -and $ChatModeName) {
            if ($ChatModeName -is [System.Array]) { $invChatModeNames += $ChatModeName } else { $invChatModeNames += $ChatModeName }
        }

        # If we still have nothing to install, error out for this invocation
        if (($invChatModeNames.Count -eq 0) -and -not $invFileName) {
            Write-Error 'You must specify a ChatModeName.'
            return
        }

        # Normalize candidate names to iterate: if FileName is provided prefer that (it may be an array)
        $names = @()
        if ($invFileName) {
            if ($invFileName -is [System.Array]) { $names += $invFileName } else { $names += $invFileName }
        }
        else {
            $names += $invChatModeNames
        }

        foreach ($item in $names) {
            # For each item, build parameters for Get-ChatmodeContent. Use per-call overrides if present.
            $params = @{ ChatModeName = $item }

            if ($script:RepoOwner) { $params.Owner = $script:RepoOwner }
            if ($script:RepoName) { $params.RepoName = $script:RepoName }

            if ($Owner) { $params.Owner = $Owner }
            if ($RepoName) { $params.RepoName = $RepoName }

            if ($params.Owner -and -not $params.RepoName -and $script:RepoMap -and $script:RepoMap.ContainsKey($params.Owner)) {
                $params.RepoName = $script:RepoMap[$params.Owner]
            }

            if (-not $PSCmdlet.ShouldProcess($item, "Install chatmode")) {
                continue
            }

            $content = Get-ChatmodeContent @params
            if ($content) {
                # If the incoming pipeline object included the original FileName (with extension), prefer it.
                if ($FileName -and -not ($FileName -is [System.Array])) {
                    $fileName = $FileName
                }
                elseif ($item -match '\.(md|chatmode)$') {
                    $fileName = $item
                }
                else {
                    $fileName = "$item.md"
                }

                # Ensure destination folder exists
                if (-not (Test-Path $Destination)) { New-Item -ItemType Directory -Path $Destination -Force | Out-Null }

                $filePath = Join-Path $Destination $fileName
                Set-Content -Path $filePath -Value $content -Force
                Write-Host "Installed $fileName to $Destination" -ForegroundColor Green
            }
            else {
                Write-Host "No content found for $item, nothing installed." -ForegroundColor Yellow
            }
        }
    }
}

# Example usage:
# Get-Chatmode | Install-Chatmode
# Install-Chatmode -ChatModeName 'sql-expert'
