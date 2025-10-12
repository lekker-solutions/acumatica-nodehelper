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
        # Get current directory as site root
        $siteRoot = Resolve-Path $SiteDirectory -ErrorAction Stop
        
        # Find Web.config
        $webConfigPath = Join-Path $siteRoot "Web.config"
        if (-not (Test-Path $webConfigPath)) {
            Write-Error "Web.config not found at: $webConfigPath"
            return $false
        }
        
        # Extract NodeJS path from Web.config
        [xml]$webConfig = Get-Content $webConfigPath
        $nodeJsPath = $webConfig.configuration.appSettings.add | 
        Where-Object { $_.key -eq "NodeJs:NodeJsPath" } | 
        Select-Object -ExpandProperty value
            
        if ([string]::IsNullOrEmpty($nodeJsPath)) {
            Write-Error "NodeJs:NodeJsPath not found in web.config"
            return $false
        }
        
        Write-Host "Found NodeJs:NodeJsPath: $nodeJsPath in web.config" -ForegroundColor Green
        
        # Build npm arguments
        $arguments = "run build-dev"
        
        $envArgs = @()
        if (-not [string]::IsNullOrWhiteSpace($Pages)) {
            if ($Pages.Contains(",")) {
                $envArgs += "pages=`"$Pages`""
            }
            else {
                $envArgs += "pages=$Pages"
            }
        }
        
        if (-not [string]::IsNullOrWhiteSpace($Modules)) {
            if ($Modules.Contains(",")) {
                $envArgs += "modules=`"$Modules`""
            }
            else {
                $envArgs += "modules=$Modules"
            }
        }
        
        if ($envArgs.Count -gt 0) {
            $arguments += " -- --env " + ($envArgs -join " ")
        }
        
        # Set working directory and PATH
        $frontendSources = Join-Path $siteRoot "FrontendSources"
        if (-not (Test-Path $frontendSources)) {
            Write-Error "FrontendSources directory not found at: $frontendSources"
            return $false
        }
        
        $npmPath = Join-Path $nodeJsPath "npm.cmd"
        if (-not (Test-Path $npmPath)) {
            Write-Error "npm.cmd not found at: $npmPath"
            return $false
        }
        
        Write-Host "Building node pages with modules '$Modules' and pages '$Pages'" -ForegroundColor Yellow
        
        # Update PATH to include NodeJS
        $originalPath = $env:PATH
        $env:PATH = "$nodeJsPath;$originalPath"
        
        try {
            # Run npm command
            Push-Location $frontendSources
            $process = Start-Process -FilePath $npmPath -ArgumentList $arguments -NoNewWindow -Wait -PassThru
            
            if ($process.ExitCode -eq 0) {
                Write-Host "Successfully built node pages" -ForegroundColor Green
                return $true
            }
            else {
                Write-Error "npm build failed with exit code: $($process.ExitCode)"
                return $false
            }
        }
        finally {
            Pop-Location
            $env:PATH = $originalPath
        }
    }
    catch {
        Write-Error "Error building node pages: $($_.Exception.Message)"
        return $false
    }
}