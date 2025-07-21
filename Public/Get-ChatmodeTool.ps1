function Get-ChatmodeTool {
    <#
    .SYNOPSIS
        Extracts and searches tools from chatmode files.
    
    .DESCRIPTION
        Reads all .chatmode.md files in the .github/chatmodes directory, parses the tools 
        definition from the YAML front matter, and optionally filters by tool name or chatmode filename.
        
        When no parameters are provided, returns one PSCustomObject per file with all tools.
        When Name parameter is provided (supports wildcards), returns individual tools matching the pattern.
        When Mode parameter is provided (supports wildcards), returns all tools from matching chatmode files.
    
    .PARAMETER Name
        Optional pattern to filter tools by name. Supports wildcards (* and ?).
        When provided, returns individual tools that match the pattern.
        
    .PARAMETER Mode
        Optional pattern to filter by chatmode filename. Supports wildcards (* and ?).
        When provided, returns all tools from matching chatmode files, one tool per line.
    
    .EXAMPLE
        Get-ChatmodeTool
        
        Returns all chatmode files with their complete tool arrays.
        
        Filename                                    Tools
        --------                                    -----
        azure-verified-modules-terraform.chatmode  {changes, codebase, editFiles, extensions...}
        
    .EXAMPLE
        Get-ChatmodeTool edit*
        
        Returns all tools starting with "edit" from all chatmode files.
        
        Type       Name        Source
        ----       ----        ------
        Chatmode   editFiles   azure-principal-architect.chatmode
        Chatmode   editFiles   azure-saas-architect.chatmode
        
    .EXAMPLE
        Get-ChatmodeTool -Mode azure-saas-architect
        
        Returns all tools from the azure-saas-architect chatmode file, one per line.
        
        Type       Name                                Source
        ----       ----                                ------
        Chatmode   changes                             azure-saas-architect.chatmode
        Chatmode   codebase                            azure-saas-architect.chatmode
        ...
        
    .EXAMPLE
        Get-ChatmodeTool -Mode *bicep*
        
        Returns all tools from chatmode files containing "bicep" in the filename.
        
    .EXAMPLE
        Get-ChatmodeTool run* -Mode *bicep*
        
        Returns tools starting with "run" from chatmode files containing "bicep".
        
    .EXAMPLE
        Get-ChatmodeTool -Mode *terraform* azure*
        
        Returns tools starting with "azure" from chatmode files containing "terraform".
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string[]]$Name,
        
        [Parameter()]
        [string]$Mode
    )
    
    # Define the chatmodes directory path relative to the current working directory
    $chatmodesPath = Join-Path (Get-Location) ".github\chatmodes"
    
    # Check if the chatmodes directory exists
    if (-not (Test-Path $chatmodesPath)) {
        Write-Warning "Chatmodes directory not found: $chatmodesPath"
        return
    }
    
    # Get all .chatmode.md files
    $chatmodeFiles = Get-ChildItem -Path $chatmodesPath -Filter "*.chatmode.md" -File
    
    if (-not $chatmodeFiles) {
        Write-Warning "No .chatmode.md files found in: $chatmodesPath"
        return
    }
    
    $allResults = @()

    # Expand comma-separated patterns in $Name
    $namePatterns = @()
    if ($Name) {
        foreach ($n in $Name) {
            $namePatterns += ($n -split ',') | ForEach-Object { $_.Trim() } | Where-Object { $_ }
        }
    }

    foreach ($file in $chatmodeFiles) {
        Write-Verbose "Processing file: $($file.Name)"

        try {
            # Read the file content
            $content = Get-Content -Path $file.FullName -Raw

            # Extract the YAML front matter
            if ($content -match '(?s)^---\s*\r?\n(.*?)\r?\n---') {
                $yamlContent = $matches[1]

                # Parse the tools line using regex
                if ($yamlContent -match "tools:\s*\[(.*?)\]") {
                    $toolsString = $matches[1]

                    # Split the tools string and clean up each tool name
                    $tools = $toolsString -split ',' | ForEach-Object {
                        $_.Trim().Trim("'").Trim('"')
                    } | Where-Object { $_ -ne '' }

                    # Get the filename without extension
                    $filename = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)

                    if ($Mode) {
                        # Mode filter: check if filename matches mode pattern
                        if ($filename -like $Mode) {
                            if ($namePatterns.Count) {
                                # Both Mode and Name: return tools matching any name pattern from matching files
                                foreach ($tool in $tools) {
                                    foreach ($pattern in $namePatterns) {
                                        if ($tool -like $pattern) {
                                            $allResults += [PSCustomObject]@{
                                                Type   = 'Chatmode'
                                                Name   = $tool
                                                Source = $filename
                                            }
                                            break
                                        }
                                    }
                                }
                            }
                            else {
                                # Mode only: return all tools from matching files
                                foreach ($tool in $tools) {
                                    $allResults += [PSCustomObject]@{
                                        Type   = 'Chatmode'
                                        Name   = $tool
                                        Source = $filename
                                    }
                                }
                            }
                        }
                    }
                    elseif ($namePatterns.Count) {
                        # Name filter only: return individual tools matching any pattern from all files
                        foreach ($tool in $tools) {
                            foreach ($pattern in $namePatterns) {
                                if ($tool -like $pattern) {
                                    $allResults += [PSCustomObject]@{
                                        Type   = 'Chatmode'
                                        Name   = $tool
                                        Source = $filename
                                    }
                                    break
                                }
                            }
                        }
                    }
                    else {
                        # List mode: return one object per file with all tools
                        $allResults += [PSCustomObject]@{
                            Filename = $filename
                            Tools    = $tools
                        }
                    }
                }
                else {
                    Write-Warning "No tools definition found in $($file.Name)"
                }
            }
            else {
                Write-Warning "No YAML front matter found in $($file.Name)"
            }
        }
        catch {
            Write-Error "Error processing file $($file.Name): $($_.Exception.Message)"
        }
    }

    return $allResults
}
