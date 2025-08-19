function Install-Chatmode {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(ValueFromPipelineByPropertyName = $true, Position = 0)]
        [string[]]$ChatModeName,
    # Optional owner filter. When provided, only install chatmodes from this owner(s).
    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string[]]$Owner,
        # Accept FileName from pipeline (e.g. produced by Get-Chatmode)
    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$FileName,
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

        # Normalize Owner parameter to an array of allowed owners (if provided)
        $allowedOwners = $null
        if ($Owner) {
            if ($Owner -is [System.Array]) { $allowedOwners = $Owner } else { $allowedOwners = @($Owner) }
        }

        # Fall back to bound parameters when per-item properties are not provided
        # If a per-item owner wasn't provided, prefer the first allowed owner for API calls
        if (-not $invOwner -and $allowedOwners) { $invOwner = $allowedOwners[0] }
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
            # If the incoming pipeline object included an Owner property, it was captured in $invOwner.
            # If the caller passed -Owner to this cmdlet, $allowedOwners contains the allowed owner(s).
            # When both are present, only install items whose owner matches one of the allowed owners.
            $itemOwner = $null
            if ($invOwner) { $itemOwner = $invOwner }
            if ($itemOwner -is [System.Array]) { $itemOwner = $itemOwner[0] }

            if ($allowedOwners -and $itemOwner) {
                if ($itemOwner -notin $allowedOwners) {
                    Write-Host "Skipping '$item' because its owner '$itemOwner' is not in the specified Owner list ($($allowedOwners -join ','))" -ForegroundColor Yellow
                    continue
                }
            }

            # For each item, build parameters for Get-ChatmodeContent. Use per-call overrides if present.
            $params = @{ ChatModeName = $item }

            # Prefer script-scoped repo owner/name when present
            if ($script:RepoOwner) { $params.Owner = $script:RepoOwner }
            if ($script:RepoName) { $params.RepoName = $script:RepoName }

            # If the pipeline object provided an owner, use it
            if ($itemOwner) { $params.Owner = $itemOwner }

            # If caller provided an Owner parameter and we still don't have an Owner to call the API with,
            # use the first allowed owner as the source repo to fetch content from.
            if (-not $params.Owner -and $allowedOwners) { $params.Owner = $allowedOwners[0] }

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
