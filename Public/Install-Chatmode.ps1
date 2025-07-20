function Install-Chatmode {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [string]$ChatModeName,
        [string]$Destination = ".github/chatmodes"
    )

    begin {
        if (-not (Test-Path $Destination)) {
            New-Item -ItemType Directory -Path $Destination -Force | Out-Null
        }
    }
    process {
        if (-not $ChatModeName) {
            Write-Error 'You must specify a ChatModeName.'
            return
        }
        # Use Get-ChatmodeContent to fetch the content
        $content = Get-ChatmodeContent -ChatModeName $ChatModeName
        if ($content) {
            # Determine file extension
            $fileName = if ($ChatModeName -notmatch '\.(md|chatmode)$') { "$ChatModeName.md" } else { $ChatModeName }
            $filePath = Join-Path $Destination $fileName
            Set-Content -Path $filePath -Value $content -Force
            Write-Host "Installed $fileName to $Destination" -ForegroundColor Green
        }
        else {
            Write-Host "No content found for $ChatModeName, nothing installed." -ForegroundColor Yellow
        }
    }
}

# Example usage:
# Get-Chatmode | Install-Chatmode
# Install-Chatmode -ChatModeName 'sql-expert'
