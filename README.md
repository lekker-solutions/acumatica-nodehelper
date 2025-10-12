# AcumaticaNodeHelper

A PowerShell module for building Acumatica frontend resources using npm.

## Overview

This module provides the `Invoke-NodeBuild` function to automate the npm build process for Acumatica ERP customizations. It reads NodeJS configuration from the site's Web.config and executes the build-dev npm script.

## Installation

1. Copy the module files to your PowerShell modules directory
2. Import the module:

   ```powershell
   Import-Module AcumaticaNodeHelper
   ```

## Usage

### Basic Usage

```powershell
# Change directory to the root of the site
cd C:\Acumatica\MyClientSite

# Build all pages and modules
Invoke-NodeBuild

# Build specific pages
Invoke-NodeBuild -Pages "SO301000,SO303000"

# Build specific modules
Invoke-NodeBuild -Modules "LS,PX"

# Build specific pages and modules
Invoke-NodeBuild -Pages "SO301000" -Modules "LS"
```

### Parameters

- **Pages** - Comma-separated list of page IDs to build
- **Modules** - Comma-separated list of modules to build  
- **SiteDirectory** - Path to Acumatica site root (defaults to current directory)

### Requirements

- Acumatica site with Web.config containing `NodeJs:NodeJsPath` setting
- FrontendSources directory in the site root
- npm.cmd accessible in the configured NodeJS path

### Example Web.config Setting

```xml
<appSettings>
  <add key="NodeJs:NodeJsPath" value="C:\Program Files\nodejs" />
</appSettings>
```

## License

Licensed under GPL-3.0. See LICENSE file for details.

## Author

Kyle Vanderstoep  
Lekker Solutions LLC
<https://contou.com>
