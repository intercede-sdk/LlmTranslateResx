# Populates a "previous" folder structure for a new version of MyID CMS Enterprise from a pre-existing sample folder.
# For every translated resx file in the sample folder (e.g. Base.de.resx) a copy is placed in a "previous" subfolder,
# mirroring the sample's folder hierarchy, so LlmTranslateWebServerFiles.ps1 (or LlmTranslateFilesInDirectory.ps1)
# can reuse the existing translation where a string has not changed between versions.
#
# Example result (destination = .\Translate):
#   .\Translate\rest.core\Dictionaries\Base.en-US.resx           <- source file to translate (already present)
#   .\Translate\rest.core\Dictionaries\previous\Base.de.resx     <- previous translation copied from the sample folder
#
# Choose the closest previous version's sample folder for best reuse (fewer changed strings).
# Usage: .\CopyPreviousTranslationsFromSample.ps1 -sampleFolder .\samples\MyID-12.18
# Usage: .\CopyPreviousTranslationsFromSample.ps1 -sampleFolder .\samples\MyID-12.18 -destination .\Translate -outputLanguageCode de
# Usage: .\CopyPreviousTranslationsFromSample.ps1 -sampleFolder .\samples\MyID-12.18 -onlyWhereSourceExists
param (
	[Parameter(Mandatory = $true)]
	[string]$sampleFolder,                 # Pre-existing sample folder for the closest previous version, e.g. .\samples\MyID-12.18
	[string]$destination = ".\Translate",  # New version's folder to populate (the Translate folder, or a web server root)
	[string]$outputLanguageCode = "de",    # Language code of the translated files to copy as previous, e.g. de for German
	[switch]$onlyWhereSourceExists         # Only create a previous file where a matching source file exists in the destination
)

if (-not (Test-Path $sampleFolder)) {
	Write-Error "Sample folder not found: $sampleFolder"
	exit 1
}

$resolvedSample = (Resolve-Path $sampleFolder).Path

# Translated files are named <prefix>.<languageCode>.resx (e.g. Base.de.resx).
# English source files (*.en-US.resx or plain *.resx) are ignored.
$previousFiles = Get-ChildItem -Path $resolvedSample -Recurse -File | Where-Object {
	$_.Name -like "*.$outputLanguageCode.resx"
}

if (-not $previousFiles) {
	Write-Host "No '*.$outputLanguageCode.resx' translation files found in $resolvedSample"
	return
}

$copied = 0
$skipped = 0

foreach ($file in $previousFiles) {
	$relativeDir = $file.DirectoryName.Substring($resolvedSample.TrimEnd('\').Length).TrimStart('\')
	$componentDir = Join-Path $destination $relativeDir

	if ($onlyWhereSourceExists) {
		# Map the translation name back to its source, e.g. Base.de.resx -> Base (then look for Base.en-US.resx or Base.resx)
		$prefix = $file.Name -replace "\.$([regex]::Escape($outputLanguageCode))\.resx$", ''
		$sourceExists = (
			(Test-Path (Join-Path $componentDir "$prefix.en-US.resx")) -or
			(Test-Path (Join-Path $componentDir "$prefix.EN-US.resx")) -or
			(Test-Path (Join-Path $componentDir "$prefix.resx"))
		)
		if (-not $sourceExists) {
			Write-Host "Skipping (no matching source in destination): $relativeDir\$($file.Name)"
			$skipped++
			continue
		}
	}

	$previousDir = Join-Path $componentDir "previous"
	$destPath = Join-Path $previousDir $file.Name

	if (-not (Test-Path $previousDir)) {
		New-Item -ItemType Directory -Path $previousDir -Force | Out-Null
	}

	Write-Host "Copying: $($file.FullName) -> $destPath"
	Copy-Item -Path $file.FullName -Destination $destPath -Force
	$copied++
}

Write-Host "Done. Copied $copied previous translation file(s) to $destination (skipped $skipped)."
