function Invoke-NodeBuild {
    <#
    .SYNOPSIS
    Builds Acumatica FrontendSources using the build-dev npm script.
    
    .DESCRIPTION
    The Invoke-NodeBuild cmdlet builds Acumatica FrontendSources for specified pages and/or modules.
    It reads the Node.js path from the site's Web.config and executes the build-dev npm script in the
    FrontendSources directory. The cmdlet supports filtering by page IDs, modules, and can optionally
    use a custom development folder.
    
    .PARAMETER Pages
    Space-separated or comma-separated list of page IDs to build.
    Example: "AR303000" or "AR303000 AR304000"
    
    .PARAMETER Modules
    Space-separated or comma-separated list of modules to build.
    Example: "AR" or "AR AP GL"
    
    .PARAMETER Development
    When specified, adds the customFolder=development flag to the build command.
    
    .PARAMETER SiteDirectory
    Path to the Acumatica site directory containing Web.config.
    Defaults to the current directory.
    
    .EXAMPLE
    Invoke-NodeBuild
    Builds all pages without any filters.
    
    .EXAMPLE
    Invoke-NodeBuild -Pages "AR303000"
    Builds only the AR303000 page.
    
    .EXAMPLE
    Invoke-NodeBuild -Pages "AR303000 AR304000"
    Builds multiple pages (AR303000 and AR304000).
    
    .EXAMPLE
    Invoke-NodeBuild -Modules "AR AP"
    Builds all pages in the AR and AP modules.
    
    .EXAMPLE
    Invoke-NodeBuild -Pages "AR303000" -Development
    Builds AR303000 page with customFolder=development flag.
    
    .EXAMPLE
    Invoke-NodeBuild -Pages "AR303000" -Modules "AR" -Development
    Builds AR303000 page and AR module with development flag.
    
    .EXAMPLE
    Invoke-NodeBuild -Pages "AR303000" -SiteDirectory "C:\inetpub\Acumatica\MySite"
    Builds from a specific site directory.
    
    .OUTPUTS
    System.Boolean
    Returns $true if the build succeeds, $false otherwise.
    
    .NOTES
    The cmdlet requires:
    - Web.config with NodeJs:NodeJsPath app setting
    - FrontendSources directory in the site root
    - npm.cmd in the Node.js installation path
    
    .LINK
    Invoke-NodeWatch
    Invoke-NodeGetModules
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [ValidateScript({
                if ($_ -match '^--') {
                    throw "Invalid value '$_'. Did you mean to use '-Modules' or '-Pages' parameter?"
                }
                $true
            })]
        [string]$Pages = "",
        
        [Parameter(Position = 1)]
        [ValidateScript({
                if ($_ -match '^--') {
                    throw "Invalid value '$_'. Did you mean to use a parameter name with single dash (-)?"
                }
                $true
            })]
        [string]$Modules = "",
        
        [Parameter()]
        [switch]$Development,
        
        [Parameter()]
        [string]$SiteDirectory = "."
    )
    
    try {
        $env = Get-NodeEnvironment -SiteDirectory $SiteDirectory
        if ($null -eq $env) {
            return $false
        }
        
        # Build script arguments
        $scriptArgs = @{}
        $paramOrder = @()
        
        if (-not [string]::IsNullOrWhiteSpace($Pages)) {
            # Convert space-separated to comma-separated
            $scriptArgs['pageIds'] = $Pages -replace '\s+', ','
            $paramOrder += 'pageIds'
        }
        
        if (-not [string]::IsNullOrWhiteSpace($Modules)) {
            # Convert space-separated to comma-separated
            $scriptArgs['modules'] = $Modules -replace '\s+', ','
            $paramOrder += 'modules'
        }
        
        # Add customFolder last
        if ($Development) {
            $scriptArgs['customFolder'] = 'development'
            $paramOrder += 'customFolder'
        }
        
        # Build action message
        $messageParts = @()
        if ($scriptArgs.ContainsKey('pageIds')) {
            $messageParts += "pageIds '$($scriptArgs['pageIds'])'"
        }
        if ($scriptArgs.ContainsKey('modules')) {
            $messageParts += "modules '$($scriptArgs['modules'])'"
        }
        if ($Development) {
            $messageParts += "customFolder 'development'"
        }
        
        $actionMessage = if ($messageParts.Count -gt 0) {
            "Building node pages with $($messageParts -join ', ')"
        }
        else {
            "Building node pages"
        }
        
        return Invoke-NpmCommand -Environment $env -Script "build-dev" `
            -ScriptArguments $scriptArgs `
            -ParameterOrder $paramOrder `
            -UseTripleDash `
            -SuccessMessage "Successfully built node pages" `
            -ActionMessage $actionMessage
    }
    catch {
        Write-Error "Error building node pages: $($_.Exception.Message)"
        return $false
    }
}

function Invoke-NodeWatch {
    <#
    .SYNOPSIS
    Starts watch mode for automatic rebuilding of Acumatica FrontendSources.
    
    .DESCRIPTION
    The Invoke-NodeWatch cmdlet starts a file watcher that automatically rebuilds FrontendSources
    when source files are modified and saved. This is useful during Modern UI development to see
    changes immediately without manual rebuilds. The watch mode continues running until stopped
    with Ctrl+C.
    
    At least one of -ScreenIds or -Modules must be specified. Running watch without parameters
    may behave in an unstable manner.
    
    .PARAMETER ScreenIds
    Space-separated or comma-separated list of screen IDs to watch.
    Example: "SO301000" or "SO301000 FS305100"
    This parameter is mandatory (either this or Modules must be provided).
    
    .PARAMETER Modules
    Space-separated or comma-separated list of modules to watch.
    Example: "AR" or "AR AP GL"
    
    .PARAMETER SiteDirectory
    Path to the Acumatica site directory containing Web.config.
    Defaults to the current directory.
    
    .EXAMPLE
    Invoke-NodeWatch -ScreenIds "SO301000"
    Watches the Sales Orders (SO301000) form for changes.
    
    .EXAMPLE
    Invoke-NodeWatch -ScreenIds "SO301000 FS305100"
    Watches multiple forms (SO301000 and FS305100) for changes.
    
    .EXAMPLE
    Invoke-NodeWatch -Modules "AR AP GL"
    Watches all forms in the AR, AP, and GL modules for changes.
    
    .EXAMPLE
    Invoke-NodeWatch -ScreenIds "SO301000" -Modules "AR"
    Watches specific screen and module for changes.
    
    .EXAMPLE
    Invoke-NodeWatch "SO301000"
    Uses positional parameter to watch SO301000.
    
    .OUTPUTS
    System.Boolean
    Returns $true if watch mode starts successfully, $false otherwise.
    
    .NOTES
    - Press Ctrl+C to stop watch mode
    - The cmdlet requires at least one of -ScreenIds or -Modules to be specified
    - Running without parameters may cause unstable behavior
    - The watch command uses --prefix to target FrontendSources\screen directory
    - The cmdlet requires:
      * Web.config with NodeJs:NodeJsPath app setting
      * FrontendSources\screen directory in the site root
      * npm.cmd in the Node.js installation path
    
    .LINK
    Invoke-NodeBuild
    Invoke-NodeGetModules
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory)]
        [ValidateScript({
                if ($_ -match '^--') {
                    throw "Invalid value '$_'. Did you mean to use '-Modules' or '-ScreenIds' parameter?"
                }
                $true
            })]
        [string]$ScreenIds = "",
        
        [Parameter(Position = 1)]
        [ValidateScript({
                if ($_ -match '^--') {
                    throw "Invalid value '$_'. Did you mean to use a parameter name with single dash (-)?"
                }
                $true
            })]
        [string]$Modules = "",
        
        [Parameter()]
        [string]$SiteDirectory = "."
    )
    
    # Validate that at least one parameter is provided
    if ([string]::IsNullOrWhiteSpace($ScreenIds) -and [string]::IsNullOrWhiteSpace($Modules)) {
        Write-Error "You must specify either -ScreenIds or -Modules parameter. Running watch without parameters may behave in an unstable manner."
        return $false
    }
    
    try {
        $env = Get-NodeEnvironment -SiteDirectory $SiteDirectory
        if ($null -eq $env) {
            return $false
        }
        
        # Validate FrontendSources\screen directory exists
        $screenDirectory = Join-Path $env.FrontendSources "screen"
        if (-not (Test-Path $screenDirectory)) {
            throw "FrontendSources\screen directory not found at: $screenDirectory"
        }
        
        # Build script arguments
        $scriptArgs = @{}
        $paramOrder = @()
        
        if (-not [string]::IsNullOrWhiteSpace($ScreenIds)) {
            # Convert space-separated to comma-separated
            $scriptArgs['screenIds'] = $ScreenIds -replace '\s+', ','
            $paramOrder += 'screenIds'
        }
        
        if (-not [string]::IsNullOrWhiteSpace($Modules)) {
            # Convert space-separated to comma-separated
            $scriptArgs['modules'] = $Modules -replace '\s+', ','
            $paramOrder += 'modules'
        }
        
        # Build action message
        $messageParts = @()
        if ($scriptArgs.ContainsKey('screenIds')) {
            $messageParts += "screenIds '$($scriptArgs['screenIds'])'"
        }
        if ($scriptArgs.ContainsKey('modules')) {
            $messageParts += "modules '$($scriptArgs['modules'])'"
        }
        
        $actionMessage = "Starting watch mode with $($messageParts -join ', '). Press Ctrl+C to stop."
        
        return Invoke-NpmCommand -Environment $env -Script "watch" `
            -ScriptArguments $scriptArgs `
            -ParameterOrder $paramOrder `
            -UsePrefix ".\FrontendSources\screen\" `
            -UseTripleDash `
            -SuccessMessage "Watch mode ended" `
            -ActionMessage $actionMessage
    }
    catch {
        Write-Error "Error starting watch mode: $($_.Exception.Message)"
        return $false
    }
}
function Invoke-NodeGetModules {
    <#
    .SYNOPSIS
    Retrieves node modules for the Acumatica site.
    
    .DESCRIPTION
    The Invoke-NodeGetModules cmdlet executes the getmodules npm script to retrieve
    and install necessary node modules for the Acumatica FrontendSources.
    
    .PARAMETER SiteDirectory
    Path to the Acumatica site directory containing Web.config.
    Defaults to the current directory.
    
    .EXAMPLE
    Invoke-NodeGetModules
    Retrieves node modules from the current directory.
    
    .EXAMPLE
    Invoke-NodeGetModules -SiteDirectory "C:\inetpub\Acumatica\MySite"
    Retrieves node modules from a specific site directory.
    
    .OUTPUTS
    System.Boolean
    Returns $true if the operation succeeds, $false otherwise.
    
    .NOTES
    The cmdlet requires:
    - Web.config with NodeJs:NodeJsPath app setting
    - FrontendSources directory in the site root
    - npm.cmd in the Node.js installation path
    - getmodules script defined in FrontendSources/package.json
    
    .LINK
    Invoke-NodeBuild
    Invoke-NodeWatch
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$SiteDirectory = "."
    )
    
    try {
        $env = Get-NodeEnvironment -SiteDirectory $SiteDirectory
        if ($null -eq $env) {
            return $false
        }
        
        return Invoke-NpmCommand -Environment $env -Script "getmodules" `
            -SuccessMessage "Successfully retrieved node modules" `
            -ActionMessage "Getting node modules..."
    }
    catch {
        Write-Error "Error getting node modules: $($_.Exception.Message)"
        return $false
    }
}

function Get-NodeEnvironment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SiteDirectory
    )
    
    try {
        # Get current directory as site root
        $siteRoot = Resolve-Path $SiteDirectory -ErrorAction Stop
        
        # Find Web.config
        $webConfigPath = Join-Path $siteRoot "Web.config"
        if (-not (Test-Path $webConfigPath)) {
            throw "Web.config not found at: $webConfigPath"
        }
        
        # Extract NodeJS path from Web.config
        [xml]$webConfig = Get-Content $webConfigPath
        $nodeJsPath = $webConfig.configuration.appSettings.add | 
        Where-Object { $_.key -eq "NodeJs:NodeJsPath" } | 
        Select-Object -ExpandProperty value
            
        if ([string]::IsNullOrEmpty($nodeJsPath)) {
            throw "NodeJs:NodeJsPath not found in web.config"
        }
        
        Write-Host "Found NodeJs:NodeJsPath: $nodeJsPath in web.config" -ForegroundColor Green
        
        # Validate paths
        $frontendSources = Join-Path $siteRoot "FrontendSources"
        if (-not (Test-Path $frontendSources)) {
            throw "FrontendSources directory not found at: $frontendSources"
        }
        
        $npmPath = Join-Path $nodeJsPath "npm.cmd"
        if (-not (Test-Path $npmPath)) {
            throw "npm.cmd not found at: $npmPath"
        }
        
        return @{
            SiteRoot        = $siteRoot
            NodeJsPath      = $nodeJsPath
            FrontendSources = $frontendSources
            NpmPath         = $npmPath
        }
    }
    catch {
        Write-Error $_.Exception.Message
        return $null
    }
}

function Invoke-NpmCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Environment,
        
        [Parameter(Mandatory)]
        [string]$Script,
        
        [Parameter()]
        [hashtable]$ScriptArguments = @{},
        
        [Parameter()]
        [string[]]$ParameterOrder = @(),
        
        [Parameter()]
        [string]$UsePrefix = "",
        
        [Parameter()]
        [switch]$UseTripleDash,
        
        [Parameter(Mandatory)]
        [string]$SuccessMessage,
        
        [Parameter(Mandatory)]
        [string]$ActionMessage
    )
    
    Write-Host $ActionMessage -ForegroundColor Yellow
    
    try {
        Push-Location $Environment.SiteRoot
        
        # Build arguments: npm run <script> [--prefix path] [---] [--env key=value,key=value,...]
        $argsList = "run $Script"
        
        # Add --prefix if specified
        if (-not [string]::IsNullOrWhiteSpace($UsePrefix)) {
            $argsList += " --prefix $UsePrefix"
        }
        
        # Add triple dash and env arguments
        if ($UseTripleDash -and $ScriptArguments.Count -gt 0) {
            # If parameter order is specified, use it; otherwise use hashtable keys
            $keysToIterate = if ($ParameterOrder.Count -gt 0) { $ParameterOrder } else { $ScriptArguments.Keys }
            
            # Build comma-separated key=value pairs
            $envPairs = @()
            foreach ($key in $keysToIterate) {
                if ($ScriptArguments.ContainsKey($key)) {
                    $envPairs += "$key=$($ScriptArguments[$key])"
                }
            }
            
            $argsList += " --- --env $($envPairs -join ',')"
        }
        
        # Log the full command being executed
        Write-Host "Executing: $($Environment.NpmPath) $argsList" -ForegroundColor Cyan
        
        $process = Start-Process -FilePath $Environment.NpmPath -ArgumentList $argsList -NoNewWindow -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Host $SuccessMessage -ForegroundColor Green
            return $true
        }
        else {
            Write-Error "npm command failed with exit code: $($process.ExitCode)"
            return $false
        }
    }
    finally {
        Pop-Location
    }
}