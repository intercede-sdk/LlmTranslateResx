# Copies all source resx files from the web server root into a destination folder, retaining the folder hierarchy.
# Run this on the web server to create a Translate folder that can then be moved to a Translation PC.
# The copied files also serve as a backup of the source files before translation.
# Default web server root: C:\Program Files\Intercede\MyID
# Default destination: .\Translate (a Translate subfolder in the current directory)
# Usage: .\CopyResxToTranslateFolder.ps1
# Usage: .\CopyResxToTranslateFolder.ps1 -webServerRoot "C:\Program Files\Intercede\MyID" -destination "C:\MyTranslations"
param (
	[string]$webServerRoot = "C:\Program Files\Intercede\MyID",
	[string]$destination = ".\Translate"
)

# Only process the known MyID component folders; other folders under the web server root are ignored
$targetFolders = @("rest.core", "rest.provision", "SSP", "SSRP", "web.oauth2")

$resolvedRoot = (Resolve-Path $webServerRoot).Path

# Recursively find all source resx files within the target folders:
#   - files matching *en-US.resx or *EN-US.resx (standard source files with English language code)
#   - files ending in .resx with no language code (e.g. Dictionary.resx)
$targetFolders | ForEach-Object { Join-Path $resolvedRoot $_ } | Where-Object { Test-Path $_ } | ForEach-Object {
	Get-ChildItem -Path $_ -Recurse -File
} | Where-Object {
	$_.Name -match '(?i)en-US\.resx$' -or
	($_.Name -like '*.resx' -and $_.Name -notmatch '(?i)\.[a-z]{2,3}(-[a-zA-Z]{2,4})?\.resx$')
} | ForEach-Object {
	$relativePath = $_.FullName.Substring($resolvedRoot.TrimEnd('\').Length + 1)
	$destPath = Join-Path $destination $relativePath
	$destDir = Split-Path $destPath -Parent

	if (-not (Test-Path $destDir)) {
		New-Item -ItemType Directory -Path $destDir -Force | Out-Null
	}

	Write-Host "Copying: $($_.FullName) -> $destPath"
	Copy-Item -Path $_.FullName -Destination $destPath
}

Write-Host "All files copied to $destination"
