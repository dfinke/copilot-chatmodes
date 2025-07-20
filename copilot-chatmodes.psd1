@{
    RootModule        = 'copilot-chatmodes.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'b80563ca-98f0-43ca-923c-6a6e13bf7aef'
    Author            = 'Doug FInke'
    Description       = 'Module to interact with the chatmodes directory of github/awesome-copilot using the GitHub REST API.'
    FunctionsToExport = @(
        'Get-Chatmode'
        'Get-ChatmodeContent'
        'Get-ChatmodeTool'
        'Install-Chatmode'
    )
    AliasesToExport   = @('gcmt')
    PowerShellVersion = '5.1'
}
