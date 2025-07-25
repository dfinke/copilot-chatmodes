# Copilot ChatModes PowerShell Module

A PowerShell module for interacting with GitHub Copilot chat modes, providing easy discovery, installation, and analysis of chat mode configurations.

## Overview

This module allows you to:
- **Discover** available chat modes from the [github/awesome-copilot](https://github.com/github/awesome-copilot) repository
- **Install** chat modes to your local `.github/chatmodes` directory
- **Analyze** tools and capabilities across different chat modes
- **Search** for specific tools or chat modes using wildcards

## Installation

### From Source
```powershell
# Clone the repository
git clone https://github.com/dfinke/copilot-chatmodes.git
cd copilot-chatmodes

# Import the module
Import-Module .\copilot-chatmodes.psd1
```

### Requirements
- PowerShell 5.1 or higher
- Internet connection for GitHub API access
- Optional: `GITHUB_TOKEN` environment variable for higher API rate limits

## Functions

### Aliases

The module provides convenient aliases for commonly used functions:
- `gcmt` → `Get-ChatmodeTool` - Quick access to tool analysis and search


### Get-Chatmode
Discovers available chat modes from the GitHub repository.

#### New: Multiple ChatModeName Support
You can now pass multiple names or patterns to `Get-Chatmode` (as separate arguments, not as an array). This allows you to search for several chat modes in a single call.

```powershell
# Get all available chat modes
Get-Chatmode

# Search for specific chat modes (supports wildcards)
Get-Chatmode "*azure*"
Get-Chatmode "python*"

# Search for multiple patterns at once (comma-separated, no quotes needed)
Get-Chatmode *azure*,python*,bicep*
```

**Output Example:**
```
Files in 'chatmodes' directory of github/awesome-copilot matching '*azure*':
azure-architect.md
azure-developer.md
Files in 'chatmodes' directory of github/awesome-copilot matching 'python*':
python-expert.md
```

### Get-ChatmodeContent
Retrieves the content of a specific chat mode.

```powershell
# Get content of a specific chat mode
Get-ChatmodeContent -ChatModeName "azure-architect"

# View the raw markdown content
Get-ChatmodeContent "python-expert" | Out-String
```

### Install-Chatmode
Downloads and installs chat modes to your local `.github/chatmodes` directory.

```powershell
# Install a specific chat mode
Install-Chatmode -ChatModeName "azure-architect"

# Install to a custom directory
Install-Chatmode -ChatModeName "python-expert" -Destination ".\my-chatmodes"

# Install multiple chat modes via pipeline
Get-Chatmode "*azure*" | Install-Chatmode
```


### Get-ChatmodeTool

Analyzes and searches tools across chat modes with multiple operation modes.

**Alias:** `gcmt` (shorthand for Get-ChatmodeTool)

#### Enhanced: Multiple Patterns for Name and Mode
You can now pass multiple tool names or patterns to the `-Name` parameter, and multiple chat mode patterns to the `-Mode` parameter. Both parameters accept:
- Multiple arguments (space-separated)
- Comma-separated values (e.g. `editFiles,run*`)
- Wildcards (`*` and `?`)

This allows you to search for several tools or chat modes in a single call, with flexible pattern matching.

```powershell
# Use the full function name
Get-ChatmodeTool

# Or use the convenient alias
gcmt

# Both work the same way
gcmt *azure*
Get-ChatmodeTool *azure*

# Pass multiple tool names or patterns (space or comma separated)
Get-ChatmodeTool -Name editFiles run* *azure*
Get-ChatmodeTool -Name editFiles,run*,*azure*
gcmt -Name editFiles run* *azure*
gcmt -Name editFiles,run*

# Combine with Mode filtering (also supports multiple/comma-separated patterns)
Get-ChatmodeTool -Name editFiles run* -Mode *bicep*,azure-*
gcmt -Name editFiles,run* -Mode *bicep*,azure-*
```

#### List All Chat Modes (Default)
```powershell
Get-ChatmodeTool
# Or use the alias
gcmt
```
**Output:**
```
Filename                                  Tools
--------                                  -----
azure-principal-architect.chatmode        {changes, codebase, editFiles, extensions...}
azure-saas-architect.chatmode             {changes, codebase, editFiles, extensions...}
```

#### Search Tools by Name
```powershell
# Find tools starting with "edit"
Get-ChatmodeTool edit*
# Or using the alias
gcmt edit*

# Find tools containing "azure"
gcmt *azure*

# Find exact tool match
gcmt "microsoft.docs.mcp"
```
**Output:**
```
Type     Name      Source
----     ----      ------
Chatmode editFiles azure-principal-architect.chatmode
Chatmode editFiles azure-saas-architect.chatmode
```

#### List Tools by Chat Mode
```powershell
# Get all tools from a specific chat mode
Get-ChatmodeTool -Mode azure-saas-architect.chatmode

# Get tools from multiple chat modes using wildcards
Get-ChatmodeTool -Mode *bicep*
Get-ChatmodeTool -Mode azure-verified*
```
**Output:**
```
Type     Name                                Source
----     ----                                ------
Chatmode changes                             azure-saas-architect.chatmode
Chatmode codebase                            azure-saas-architect.chatmode
Chatmode editFiles                           azure-saas-architect.chatmode
...
```

#### Combined Search (Name + Mode)
Search for specific tools within specific chat modes by combining both parameters:

```powershell
# Find "run" tools in bicep-related chat modes
Get-ChatmodeTool run* -Mode *bicep*

# Find Azure tools in terraform chat modes  
Get-ChatmodeTool -Mode *terraform* azure*

# Find edit tools in SaaS architect chat mode
Get-ChatmodeTool edit* -Mode azure-saas*
```
**Output:**
```
Type     Name        Source
----     ----        ------
Chatmode runCommands azure-verified-modules-bicep.chatmode
Chatmode runTasks    azure-verified-modules-bicep.chatmode
Chatmode runTests    azure-verified-modules-bicep.chatmode
```

## Advanced Search Capabilities

The `Get-ChatmodeTool` function provides powerful search capabilities with four distinct modes:

### 1. List Mode (No Parameters)
Returns overview of all chat modes with their tool collections:
```powershell
Get-ChatmodeTool
```


### 2. Tool Search (Name Parameter)
Search for tools across all chat modes. The `Name` parameter now accepts one or more strings or comma-separated patterns:
```powershell
# Single pattern or name
Get-ChatmodeTool run*          # Find all tools starting with "run"
Get-ChatmodeTool *azure*       # Find all tools containing "azure"
Get-ChatmodeTool editFiles     # Find exact tool matches

# Multiple patterns/names (space or comma separated)
Get-ChatmodeTool -Name editFiles run* *azure*
Get-ChatmodeTool -Name editFiles,run*,*azure*
```

### 3. Chat Mode Filter (Mode Parameter)
List all tools from specific chat modes. The `-Mode` parameter also supports multiple or comma-separated patterns:
```powershell
Get-ChatmodeTool -Mode *bicep*                    # All tools from bicep chat modes
Get-ChatmodeTool -Mode azure-saas-architect       # All tools from specific mode
Get-ChatmodeTool -Mode azure-verified*            # All tools from matching modes
Get-ChatmodeTool -Mode azure-verified*,*bicep*    # Multiple patterns (comma separated)
```

### 4. Combined Search (Both Parameters)
The most powerful feature - search for specific tools within specific chat modes. Both parameters accept multiple/comma-separated patterns:
```powershell
Get-ChatmodeTool run* -Mode *bicep*                       # Run tools in bicep modes
Get-ChatmodeTool -Mode *terraform* azure*                 # Azure tools in terraform modes
Get-ChatmodeTool microsoft* -Mode *architect*             # Microsoft tools in architect modes
Get-ChatmodeTool -Name run*,editFiles -Mode *bicep*,*terraform*  # Multiple tool and mode patterns
```

**Key Benefits:**
- **Precision**: Find exactly what you need with targeted searches
- **Flexibility**: Parameters work in any order and combination
- **Wildcards**: Full wildcard support for both tool names and chat mode names
- **Consistency**: Same output format regardless of search complexity

## Usage Examples

### Discover and Install Azure-Related Chat Modes
```powershell
# Find all Azure-related chat modes
Get-Chatmode "*azure*"

# Install all Azure chat modes
Get-Chatmode "*azure*" | Install-Chatmode

# Verify installation
Get-ChildItem .\.github\chatmodes\
```

### Analyze Tool Usage Across Chat Modes
```powershell
# Find which chat modes use specific tools
gcmt "azure_design_architecture"

# Count tools per chat mode
gcmt | ForEach-Object { "$($_.Filename): $($_.Tools.Count) tools" }

# Get unique tools across all chat modes
gcmt -Mode "*" | Select-Object Name -Unique | Sort-Object Name
```

### Find Chat Modes with Specific Capabilities
```powershell
# Find chat modes that can edit files
gcmt editFiles

# Find chat modes with Azure-specific tools
gcmt *azure* | Group-Object Source

# Explore tools in bicep-related chat modes
gcmt -Mode *bicep*

# Find specific tools in specific chat modes
gcmt run* -Mode *terraform*
gcmt microsoft* -Mode azure-saas*
```

## Authentication

For better performance and higher API rate limits, set your GitHub token:

```powershell
# Set GitHub token (optional but recommended)
$env:GITHUB_TOKEN = "your-github-token-here"

# Or set it permanently in your PowerShell profile
Add-Content $PROFILE '$env:GITHUB_TOKEN = "your-github-token-here"'
```

## Directory Structure

When you install chat modes, they are organized as follows:

```
.github/
└── chatmodes/
    ├── azure-architect.md
    ├── python-expert.chatmode.md
    └── other-chatmode.md
```

## Advanced Usage

### Pipeline Operations
```powershell
# Chain operations together
Get-Chatmode "*python*" | 
    Install-Chatmode | 
    ForEach-Object { Get-ChatmodeTool -Mode $_.Name }

# Find and analyze specific tool patterns
Get-ChatmodeTool *test* | 
    Group-Object Source | 
    Sort-Object Count -Descending

# Advanced combined searches
Get-ChatmodeTool azure* -Mode *architect* | 
    Group-Object Name | 
    Sort-Object Count -Descending
```

### Filtering and Analysis
```powershell
# Find chat modes with the most tools
Get-ChatmodeTool | 
    Sort-Object { $_.Tools.Count } -Descending | 
    Select-Object -First 5

# Export tool analysis to CSV
Get-ChatmodeTool -Mode "*" | 
    Export-Csv -Path "chatmode-tools.csv" -NoTypeInformation

# Compare tools between specific chat mode types
Get-ChatmodeTool azure* -Mode *bicep* | Select-Object Name
Get-ChatmodeTool azure* -Mode *terraform* | Select-Object Name

# Find common tools across multiple chat modes
$bicepTools = Get-ChatmodeTool -Mode *bicep* | Select-Object -ExpandProperty Name
$terraformTools = Get-ChatmodeTool -Mode *terraform* | Select-Object -ExpandProperty Name
$bicepTools | Where-Object { $_ -in $terraformTools }
```

## Troubleshooting

### Common Issues

1. **Rate Limit Exceeded**: Set the `GITHUB_TOKEN` environment variable
2. **Network Connectivity**: Ensure internet access to api.github.com
3. **Permission Issues**: Run PowerShell as Administrator if directory creation fails

### Verbose Output
```powershell
# Enable verbose output for debugging
Get-Chatmode -Verbose
Get-ChatmodeTool -Verbose -Mode "*azure*"
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## Module Information

- **Version**: 0.1.0
- **Author**: Doug Finke
- **PowerShell Version**: 5.1+
- **Dependencies**: None (uses built-in cmdlets)

## Related Resources

- [GitHub Copilot Documentation](https://docs.github.com/en/copilot)
- [Awesome Copilot Repository](https://github.com/github/awesome-copilot)
- [Chat Modes Documentation](https://github.com/github/awesome-copilot/tree/main/chatmodes)

## License

This project is licensed under the terms specified in the LICENSE file.

---

**Happy coding with GitHub Copilot chat modes! 🚀**
