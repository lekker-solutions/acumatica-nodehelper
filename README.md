# Acumatica Node Build PowerShell Module

A PowerShell module for automating Acumatica FrontendSources build and watch tasks using npm scripts configured in your site's Web.config.

## Table of Contents

- [Installation](#installation)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Commands](#commands)
  - [Invoke-NodeBuild](#invoke-nodebuild)
  - [Invoke-NodeWatch](#invoke-nodewatch)
  - [Invoke-NodeGetModules](#invoke-nodegetmodules)
  - [Get-NodeEnvironment](#get-nodeenvironment)
- [Usage Examples](#usage-examples)
- [Troubleshooting](#troubleshooting)
- [Requirements](#requirements)
- [Help Documentation](#help-documentation)

---

## Installation

### Prerequisites
- PowerShell 5.1 or higher
- Acumatica instance with FrontendSources directory
- Node.js path configured in Web.config (`NodeJs:NodeJsPath` app setting)

### Install the Module

1. **Find your PowerShell modules directory:**
```powershell
   $env:PSModulePath -split ';'
```
   Common locations:
   - `C:\Users\<username>\Documents\PowerShell\Modules` (PowerShell 7+)
   - `C:\Users\<username>\Documents\WindowsPowerShell\Modules` (PowerShell 5.1)

2. **Create the module directory:**
```powershell
   $modulePath = "$HOME\Documents\WindowsPowerShell\Modules\AcumaticaNode"
   New-Item -ItemType Directory -Path $modulePath -Force
```

3. **Copy the module files:**
   - Save the module script as `AcumaticaNode.psm1` in the module directory
   - Create a module manifest (optional but recommended):
```powershell
   New-ModuleManifest -Path "$modulePath\AcumaticaNode.psd1" `
       -RootModule "AcumaticaNode.psm1" `
       -ModuleVersion "1.0.0" `
       -Author "Your Name" `
       -Description "Acumatica Node.js build automation tools" `
       -PowerShellVersion "5.1" `
       -FunctionsToExport @('Invoke-NodeBuild', 'Invoke-NodeWatch', 'Invoke-NodeGetModules', 'Get-NodeEnvironment')
```

4. **Import the module:**
```powershell
   Import-Module AcumaticaNode
```

5. **Verify installation:**
```powershell
   Get-Command -Module AcumaticaNode
```

### Auto-load on Startup (Optional)

Add to your PowerShell profile to auto-load the module:
```powershell
# Open your profile
notepad $PROFILE

# Add this line
Import-Module AcumaticaNode
```

---

## Quick Start
```powershell
# Navigate to your Acumatica site directory
cd C:\inetpub\Acumatica\MySite

# Build a specific page
Invoke-NodeBuild -Pages "AR303000"

# Build with development flag
Invoke-NodeBuild -Pages "AR303000" -Development

# Start watch mode for a page
Invoke-NodeWatch -ScreenIds "AR303000"

# Get node modules
Invoke-NodeGetModules
```

---

## Commands

### Invoke-NodeBuild

Builds Acumatica FrontendSources using the `build-dev` npm script.

#### Syntax
```powershell
Invoke-NodeBuild [[-Pages] <string>] [[-Modules] <string>] [-Development] [-SiteDirectory <string>]
```

#### Parameters

- **`-Pages`** (Position 0, Optional)  
  Space-separated or comma-separated list of page IDs to build  
  Example: `"AR303000"` or `"AR303000 AR304000"`

- **`-Modules`** (Position 1, Optional)  
  Space-separated or comma-separated list of modules to build  
  Example: `"AR"` or `"AR AP"`

- **`-Development`** (Switch, Optional)  
  Adds `customFolder=development` flag to the build command

- **`-SiteDirectory`** (Optional, Default: `"."`)  
  Path to the Acumatica site directory containing Web.config

#### Examples

**Build all pages:**
```powershell
Invoke-NodeBuild
```
Executes: `npm run build-dev`

**Build specific page:**
```powershell
Invoke-NodeBuild -Pages "AR303000"
```
Executes: `npm run build-dev --- --env pageIds=AR303000`

**Build multiple pages:**
```powershell
Invoke-NodeBuild -Pages "AR303000 AR304000"
```
Executes: `npm run build-dev --- --env pageIds=AR303000,AR304000`

**Build with modules:**
```powershell
Invoke-NodeBuild -Modules "AR AP"
```
Executes: `npm run build-dev --- --env modules=AR,AP`

**Build with development flag:**
```powershell
Invoke-NodeBuild -Pages "AR303000" -Development
```
Executes: `npm run build-dev --- --env pageIds=AR303000,customFolder=development`

**Build with all options:**
```powershell
Invoke-NodeBuild -Pages "AR303000 AR304000" -Modules "AR" -Development
```
Executes: `npm run build-dev --- --env pageIds=AR303000,AR304000,modules=AR,customFolder=development`

**Build from specific directory:**
```powershell
Invoke-NodeBuild -Pages "AR303000" -SiteDirectory "C:\inetpub\Acumatica\MySite"
```

**Using positional parameters:**
```powershell
Invoke-NodeBuild "AR303000" "AR"
```
Executes: `npm run build-dev --- --env pageIds=AR303000,modules=AR`

#### Return Value
Returns `$true` on success, `$false` on failure.

---

### Invoke-NodeWatch

Starts watch mode for automatic rebuilding when source files change.

#### Syntax
```powershell
Invoke-NodeWatch [-ScreenIds] <string> [[-Modules] <string>] [-SiteDirectory <string>]
```

#### Parameters

- **`-ScreenIds`** (Position 0, Mandatory)  
  Space-separated or comma-separated list of screen IDs to watch  
  Example: `"SO301000"` or `"SO301000 FS305100"`

- **`-Modules`** (Position 1, Optional)  
  Space-separated or comma-separated list of modules to watch  
  Example: `"AR"` or `"AR AP GL"`

- **`-SiteDirectory`** (Optional, Default: `"."`)  
  Path to the Acumatica site directory containing Web.config

#### Important Notes

- **At least one of `-ScreenIds` or `-Modules` must be specified**
- Running watch without parameters may cause unstable behavior
- Press **Ctrl+C** to stop watch mode
- Watch mode runs continuously until manually stopped

#### Examples

**Watch specific screen:**
```powershell
Invoke-NodeWatch -ScreenIds "SO301000"
```
Executes: `npm run watch --- --env screenIds=SO301000`

**Watch multiple screens:**
```powershell
Invoke-NodeWatch -ScreenIds "SO301000 FS305100"
```
Executes: `npm run watch --- --env screenIds=SO301000,FS305100`

**Watch specific modules:**
```powershell
Invoke-NodeWatch -Modules "AR AP GL"
```
Executes: `npm run watch --- --env modules=AR,AP,GL`

**Watch screens and modules:**
```powershell
Invoke-NodeWatch -ScreenIds "SO301000" -Modules "AR"
```
Executes: `npm run watch --- --env screenIds=SO301000,modules=AR`

**Watch from specific directory:**
```powershell
Invoke-NodeWatch -ScreenIds "SO301000" -SiteDirectory "C:\inetpub\Acumatica\MySite"
```

**Using positional parameters:**
```powershell
Invoke-NodeWatch "SO301000"
```

#### Return Value
Returns `$true` on success, `$false` on failure.

---

### Invoke-NodeGetModules

Retrieves node modules for the Acumatica site using the `getmodules` npm script.

#### Syntax
```powershell
Invoke-NodeGetModules [-SiteDirectory <string>]
```

#### Parameters

- **`-SiteDirectory`** (Optional, Default: `"."`)  
  Path to the Acumatica site directory containing Web.config

#### Examples

**Get modules from current directory:**
```powershell
Invoke-NodeGetModules
```
Executes: `npm run getmodules`

**Get modules from specific directory:**
```powershell
Invoke-NodeGetModules -SiteDirectory "C:\inetpub\Acumatica\MySite"
```

#### Return Value
Returns `$true` on success, `$false` on failure.

---

### Get-NodeEnvironment

Gets the Node.js environment configuration from the Acumatica site's Web.config. This is primarily used internally by other functions but can be useful for troubleshooting.

#### Syntax
```powershell
Get-NodeEnvironment -SiteDirectory <string>
```

#### Parameters

- **`-SiteDirectory`** (Required)  
  Path to the Acumatica site directory containing Web.config

#### Examples

**Get environment configuration:**
```powershell
$env = Get-NodeEnvironment -SiteDirectory "."
$env.NodeJsPath
$env.NpmPath
$env.FrontendSources
$env.SiteRoot
```

**Check if environment is valid:**
```powershell
$env = Get-NodeEnvironment -SiteDirectory "."
if ($null -ne $env) {
    Write-Host "Environment is valid"
    Write-Host "Node.js Path: $($env.NodeJsPath)"
    Write-Host "npm Path: $($env.NpmPath)"
}
```

#### Return Value
Returns a hashtable with the following keys:
- `SiteRoot` - Full path to the site root
- `NodeJsPath` - Path to Node.js installation from Web.config
- `FrontendSources` - Path to FrontendSources directory
- `NpmPath` - Full path to npm.cmd

Returns `$null` on failure.

---

## Usage Examples

### Common Workflows

#### Development Workflow
```powershell
# 1. Navigate to site
cd C:\inetpub\Acumatica\MySite

# 2. Get latest modules
Invoke-NodeGetModules

# 3. Start watch mode for your working page
Invoke-NodeWatch -ScreenIds "AR303000"

# 4. Make changes to source files in FrontendSources\screen
# Watch mode will automatically rebuild on save

# 5. Press Ctrl+C to stop watch when done
```

#### Production Build Workflow
```powershell
# Build all pages for production
Invoke-NodeBuild

# Or build specific modules for production
Invoke-NodeBuild -Modules "AR AP GL"
```

#### Development Build Workflow
```powershell
# Build with development flag for faster builds
Invoke-NodeBuild -Pages "AR303000" -Development

# Build multiple pages with development flag
Invoke-NodeBuild -Pages "AR303000 AR304000" -Development
```

#### Multi-Site Management
```powershell
# Define site paths
$site1 = "C:\inetpub\Acumatica\Site1"
$site2 = "C:\inetpub\Acumatica\Site2"

# Build same page on multiple sites
Invoke-NodeBuild -Pages "AR303000" -SiteDirectory $site1
Invoke-NodeBuild -Pages "AR303000" -SiteDirectory $site2
```

---

## Troubleshooting

### Common Issues

**"Web.config not found"**
- Ensure you're running the command from the Acumatica site directory, or use `-SiteDirectory` parameter
- Verify the path is correct

**"NodeJs:NodeJsPath not found in web.config"**
- Verify your Web.config has the `NodeJs:NodeJsPath` app setting configured
- Check the XML structure:
```xml
  <configuration>
    <appSettings>
      <add key="NodeJs:NodeJsPath" value="C:\Program Files\nodejs\" />
    </appSettings>
  </configuration>
```

**"FrontendSources directory not found"**
- Ensure the FrontendSources directory exists in your Acumatica site
- This is typically created during Acumatica installation

**"npm.cmd not found"**
- Verify the Node.js path in Web.config points to a valid Node.js installation
- Check that npm.cmd exists in the specified directory
- You may need to reinstall Node.js

**"npm command failed with exit code"**
- Check that npm dependencies are installed (run `npm install` in FrontendSources)
- Review the npm output for specific error messages
- Ensure the npm script exists in FrontendSources/package.json
- Verify you have sufficient permissions

**"Task never defined" error in gulp**
- This usually means the arguments aren't being parsed correctly
- Ensure you're using the correct parameter format
- The module automatically formats arguments correctly

**Watch mode behaves unstably**
- Always specify either `-ScreenIds` or `-Modules` parameter
- Don't run watch mode without parameters
- If issues persist, stop watch mode (Ctrl+C) and restart

### Debug Mode

Run commands with `-Verbose` to see detailed execution information:
```powershell
Invoke-NodeBuild -Pages "AR303000" -Verbose
```

### Testing Environment Configuration
```powershell
# Test if environment is configured correctly
$env = Get-NodeEnvironment -SiteDirectory "."
if ($null -eq $env) {
    Write-Host "Environment configuration failed" -ForegroundColor Red
} else {
    Write-Host "Environment is valid:" -ForegroundColor Green
    Write-Host "  Site Root: $($env.SiteRoot)"
    Write-Host "  Node.js: $($env.NodeJsPath)"
    Write-Host "  npm: $($env.NpmPath)"
    Write-Host "  FrontendSources: $($env.FrontendSources)"
}
```

---

## Requirements

### Web.config Structure

The module requires the following structure in your Acumatica Web.config:
```xml
<configuration>
  <appSettings>
    <add key="NodeJs:NodeJsPath" value="C:\Program Files\nodejs\" />
  </appSettings>
</configuration>
```

### package.json Scripts

Your FrontendSources/package.json must define the following npm scripts:
```json
{
  "scripts": {
    "build-dev": "gulp buildDev",
    "watch": "gulp watch",
    "getmodules": "node scripts/getmodules.js"
  }
}
```

### gulp Configuration

The gulp tasks must support the `--env` flag with comma-separated key=value pairs:
```javascript
// Example gulp configuration
gulp.task('buildDev', () => {
  const env = parseEnvArgs(); // { pageIds: 'AR303000', customFolder: 'development' }
  // Build logic here
});
```

---

## Help Documentation

All cmdlets include comprehensive built-in help documentation accessible via PowerShell's help system:
```powershell
# Get basic help
Get-Help Invoke-NodeBuild

# Get detailed help with parameter descriptions
Get-Help Invoke-NodeBuild -Detailed

# Get full help including technical details
Get-Help Invoke-NodeBuild -Full

# Get only examples
Get-Help Invoke-NodeBuild -Examples

# Get help for other cmdlets
Get-Help Invoke-NodeWatch -Examples
Get-Help Invoke-NodeGetModules -Full
Get-Help Get-NodeEnvironment -Detailed
```

### Available Help Topics

Each cmdlet includes:
- **Synopsis**: Brief description of the cmdlet
- **Description**: Detailed explanation of functionality
- **Parameters**: Description of each parameter with examples
- **Examples**: Multiple real-world usage examples
- **Outputs**: What the cmdlet returns
- **Notes**: Important information and requirements
- **Related Links**: Links to related cmdlets

---

## Advanced Usage

### Parameter Order Control

The module ensures parameters are passed to npm in the correct order (pages/screens → modules → customFolder):
```powershell
# This command
Invoke-NodeBuild -Pages "AR303000" -Modules "AR" -Development

# Generates this npm command (note the order)
npm run build-dev --- --env pageIds=AR303000,modules=AR,customFolder=development
```

### Space vs Comma Separation

The module accepts both space-separated and comma-separated lists:
```powershell
# These are equivalent
Invoke-NodeBuild -Pages "AR303000 AR304000"
Invoke-NodeBuild -Pages "AR303000,AR304000"

# Mixed spacing is handled correctly
Invoke-NodeBuild -Pages "AR303000,  AR304000   AR305000"
# Results in: pageIds=AR303000,AR304000,AR305000
```

### Error Handling

All cmdlets return boolean values for easy integration with scripts:
```powershell
if (Invoke-NodeBuild -Pages "AR303000") {
    Write-Host "Build succeeded, deploying..."
    # Deployment logic
} else {
    Write-Host "Build failed, aborting deployment"
    exit 1
}
```

### Batch Operations
```powershell
# Build multiple pages in sequence
$pages = @("AR303000", "AR304000", "AR305000")
foreach ($page in $pages) {
    Write-Host "Building $page..." -ForegroundColor Yellow
    if (-not (Invoke-NodeBuild -Pages $page -Development)) {
        Write-Error "Failed to build $page"
        break
    }
}
```

---

## Best Practices

1. **Use watch mode during development** - It saves time by automatically rebuilding on file changes
2. **Specify screens/modules in watch mode** - Don't run watch without parameters
3. **Use `-Development` flag during development** - Faster builds with development configurations
4. **Build without flags for production** - Ensures optimized builds
5. **Run `Invoke-NodeGetModules` after updating** - Ensures you have the latest dependencies
6. **Use `-SiteDirectory` for multi-site setups** - Makes it clear which site you're targeting

---

## Module Structure
```
AcumaticaNode/
├── AcumaticaNode.psm1      # Main module file with all functions
├── AcumaticaNode.psd1      # Module manifest (optional)
└── README.md               # This file
```

---
