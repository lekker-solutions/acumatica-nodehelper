
Write-Host " ----------------------------- "
Write-Host "      INITIAL REPO RENAMER     "
Write-Host " ----------------------------- "
Write-Host
Write-Host
Write-Host
Write-Host " ----------------------------- "
Write-Host "    Provide the Module Name   "
Write-Host " ----------------------------- "
$moduleName = Read-Host

Write-Host
Write-Host
Write-Host
Write-Host " ----------------------------- "
Write-Host "    Provide the Generator Name    "
Write-Host " ----------------------------- "
$generatorName = Read-Host
$generatedOn = Get-Date -Format "yyyy-MM-dd"

$curDir = Get-Location
[RegEx]$generatorNameSearch = '{{GeneratedBy}}'
[RegEx]$generatedOnSearch = '{{Today}}'
[RegEx]$moduleNameSearch = 'ModuleName'


Write-Host 
Write-Host 
Write-Host "---------------------------"
Write-Host "       Renaming Files"
Write-Host "---------------------------"

# Edit Names
Get-ChildItem -Path $curDir -Recurse -Filter *$($moduleNameSearch)*  -Directory | Rename-Item -NewName {$_.name -replace $moduleNameSearch,$moduleName } 
Get-ChildItem -Path $curDir -Recurse -Filter *$($generatedOnSearch)*  -Directory | Rename-Item -NewName {$_.name -replace $generatedOnSearch,$generatedOn }
Get-ChildItem -Path $curDir -Recurse -Filter *$($generatorNameSearch)*  -Directory | Rename-Item -NewName {$_.name -replace $generatorNameSearch,$generatorName }

Get-ChildItem -Path $curDir -Recurse -File | Rename-Item -NewName {$_.fullname -replace $moduleNameSearch,$moduleName } 
Get-ChildItem -Path $curDir -Recurse -File | Rename-Item -NewName {$_.fullname -replace $generatedOnSearch,$generatedOn }
Get-ChildItem -Path $curDir -Recurse -File | Rename-Item -NewName {$_.fullname -replace $generatorNameSearch,$generatorName }



Write-Host 
Write-Host 
Write-Host "---------------------------"
Write-Host "     Renaming Content      "
Write-Host "---------------------------"

# Edit content
ForEach ($File in (Get-ChildItem -Path $curDir -Recurse -File)) {
    (Get-Content $File) -Replace $moduleNameSearch,$moduleName |
        Set-Content $File
}
ForEach ($File in (Get-ChildItem -Path $curDir -Recurse -File)) {
    (Get-Content $File) -Replace $generatedOnSearch,$generatedOn |
        Set-Content $File
}
ForEach ($File in (Get-ChildItem -Path $curDir -Recurse -File)) {
    (Get-Content $File) -Replace $generatorNameSearch,$generatorName |
        Set-Content $File
}
ForEach ($File in (Get-ChildItem -Path $curDir -Recurse -File)) {
    (Get-Content $File) -Replace '{{NEWID}}',(New-Guid) |
        Set-Content $File
}


Write-Host " ----------------------------- "
Write-Host "           COMPLETE          "
Write-Host " ----------------------------- "
