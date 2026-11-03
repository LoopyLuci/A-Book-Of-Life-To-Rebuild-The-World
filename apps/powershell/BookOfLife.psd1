@{
    RootModule        = 'BookOfLife.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'a3f1c7d2-9b64-4e18-8c05-1d2b3f4a5e6c'
    Author            = 'Book of Life contributors'
    CompanyName       = 'Book of Life'
    Copyright         = 'MIT for the code, CC BY-SA 4.0 for the content'
    Description       = 'Core logic for the Book of Life interactive console: corpus loading, search, rendering and reader settings.'

    PowerShellVersion = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')

    FunctionsToExport = @(
        'Get-AbookRoot',
        'Get-AbookVersion',
        'ConvertFrom-AbookYaml',
        'ConvertFrom-AbookScalar',
        'ConvertTo-AbookLine',
        'ConvertFrom-AbookBlock',
        'Get-AbookDomains',
        'Import-AbookCorpus',
        'Get-AbookCorpus',
        'Search-Abook',
        'Get-AbookString',
        'Get-AbookDisclaimer',
        'Compare-AbookVersion',
        'Get-AbookSettingsPath',
        'Get-AbookSettings',
        'Save-AbookSettings',
        'Add-AbookRecent',
        'Get-AbookSupportedLanguages'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData = @{
        PSData = @{
            Tags       = @('BookOfLife', 'knowledge', 'offline', 'console')
            LicenseUri = 'https://opensource.org/licenses/MIT'
        }
    }
}
