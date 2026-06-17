# Runs LlmTranslateResx on all source resx files recursively from the web server root folder
# Default web server root: C:\Program Files\Intercede\MyID
# Usage: .\LlmTranslateWebServerFiles.ps1 -outputLanguageCode de --targetLanguage German --uri https://myOpenAiCompatApi --model gpt-4.1-mini --apiKey myApiKey
# If you want to reuse previous translations where possible, put the existing translated file in a "previous" subfolder
# within each source folder, e.g. rest.core\Dictionaries\previous\Base.de.resx
param (
	[string]$outputLanguageCode, # 2 letter code, e.g. de for German. Used for creating the output filename. Note the language to translate to also needs to be specified for LlmTranslateResx.
	[string]$webServerRoot = "C:\Program Files\Intercede\MyID",
	[Parameter(ValueFromRemainingArguments = $true)]
	[string[]]$ArgsToPass
)

# Only process the known MyID component folders; other folders under the web server root are ignored
$targetFolders = @("rest.core", "rest.provision", "SSP", "SSRP", "web.oauth2")

# Recursively find all source resx files within the target folders:
#   - files matching *en-US.resx or *EN-US.resx (standard source files with English language code)
#   - files ending in .resx with no language code (e.g. Dictionary.resx)
$targetFolders | ForEach-Object { Join-Path $webServerRoot $_ } | Where-Object { Test-Path $_ } | ForEach-Object {
    Get-ChildItem -Path $_ -Recurse -File
} | Where-Object {
	($_.Name -match '(?i)en-US\.resx$' -or
	($_.Name -like '*.resx' -and $_.Name -notmatch '(?i)\.[a-z]{2,3}(-[a-zA-Z]{2,4})?\.resx$')) -and
	$_.FullName -notlike "*\SSP\MyIDProcessDriver\Language\*"
} | ForEach-Object {
	$file = $_
	$dir = $file.DirectoryName
	$filename = $file.Name

	if ($filename -match '(?i)en-US\.resx$') {
		$outputFileName = $filename -replace '(?i)en-US\.resx$', "$outputLanguageCode.resx"
	} else {
		# Plain .resx with no language code (e.g. Dictionary.resx -> Dictionary.de.resx)
		$outputFileName = $filename -replace '\.resx$', ".$outputLanguageCode.resx"
	}

	$inputPath = $file.FullName
	$outputPath = Join-Path $dir $outputFileName
	$previousFile = Join-Path $dir "previous\$outputFileName"

	$additionalArgs = @()
	if (Test-Path $previousFile) {
		$additionalArgs = @("--previousFile", $previousFile)
		Write-Host "Running: LlmTranslateResx.exe --input $inputPath --output $outputPath --previousFile $previousFile (plus all supplied arguments)"
	} else {
		Write-Host "Running: LlmTranslateResx.exe --input $inputPath --output $outputPath (plus all supplied arguments)"
	}

	& "cmd" "/c" "LlmTranslateResx.exe" "--input" $inputPath "--output" $outputPath @additionalArgs @ArgsToPass
}

# MyIDDataSource and MyIDProcessDriver have identical translation files; copy translations across rather than translating twice.
$myIDDataSourceLang = Join-Path $webServerRoot "SSP\MyIDDataSource\Language"
$myIDProcessDriverLang = Join-Path $webServerRoot "SSP\MyIDProcessDriver\Language"
if ((Test-Path $myIDDataSourceLang) -and (Test-Path $myIDProcessDriverLang)) {
    Get-ChildItem -Path $myIDDataSourceLang -File | Where-Object {
        $_.Name -like "*.$outputLanguageCode.resx"
    } | ForEach-Object {
        $destPath = Join-Path $myIDProcessDriverLang $_.Name
        Write-Host "Copying $($_.FullName) to $destPath"
        Copy-Item -Path $_.FullName -Destination $destPath -Force
    }
}

Write-Host "All files processed"
