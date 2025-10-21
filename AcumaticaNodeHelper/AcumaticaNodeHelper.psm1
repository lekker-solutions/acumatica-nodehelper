function Invoke-NodeBuild {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Pages = "",
        
        [Parameter(Position = 1)]
        [string]$Modules = "",
        
        [Parameter()]
        [string]$SiteDirectory = "."
    )
    
    try {
        $env = Get-NodeEnvironment -SiteDirectory $SiteDirectory
        if ($null -eq $env) {
            return $false
        }
        
        # Build environment variables
        $envVars = @{}
        if (-not [string]::IsNullOrWhiteSpace($Pages)) {
            $envVars['pages'] = $Pages
        }
        
        if (-not [string]::IsNullOrWhiteSpace($Modules)) {
            $envVars['modules'] = $Modules
        }
        
        return Invoke-NpmCommand -Environment $env -Script "build-dev" -EnvironmentVariables $envVars `
            -SuccessMessage "Successfully built node pages" `
            -ActionMessage "Building node pages with modules '$Modules' and pages '$Pages'"
    }
    catch {
        Write-Error "Error building node pages: $($_.Exception.Message)"
        return $false
    }
}

function Invoke-NodeGetModules {
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
        [hashtable]$EnvironmentVariables = @{},
        
        [Parameter(Mandatory)]
        [string]$SuccessMessage,
        
        [Parameter(Mandatory)]
        [string]$ActionMessage
    )
    
    Write-Host $ActionMessage -ForegroundColor Yellow
    
    # Update PATH to include NodeJS
    $originalPath = $env:PATH
    $env:PATH = "$($Environment.NodeJsPath);$originalPath"
    
    # Set environment variables
    $originalEnvVars = @{}
    foreach ($key in $EnvironmentVariables.Keys) {
        $originalEnvVars[$key] = [System.Environment]::GetEnvironmentVariable($key)
        [System.Environment]::SetEnvironmentVariable($key, $EnvironmentVariables[$key])
    }
    
    try {
        Push-Location $Environment.FrontendSources
        $process = Start-Process -FilePath $Environment.NpmPath -ArgumentList "run $Script" -NoNewWindow -Wait -PassThru
        
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
        $env:PATH = $originalPath
        
        # Restore environment variables
        foreach ($key in $originalEnvVars.Keys) {
            if ($null -eq $originalEnvVars[$key]) {
                [System.Environment]::SetEnvironmentVariable($key, $null)
            }
            else {
                [System.Environment]::SetEnvironmentVariable($key, $originalEnvVars[$key])
            }
        }
    }
}