# Runs LlmTranslateResx on all en-US resx files in the directory, creating a language dictionary 
# .\LlmTranslateFilesInDirectory.ps1 -outputLanguageCode de --targetLanguage German --uri https://myOpenAiCompatApi --model gpt-4.1-mini --apiKey myApiKey
# if you want to reuse previous translations where possible, put the existing file in a subdirectory called "previous", eg previous/Base.de.resx 
param (
    [string]$outputLanguageCode, # 2 letter code, eg de for german. This is used for creating output filename. Note the language to translate to needs to be specified for LlmTranslateResx as well
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ArgsToPass
)

# Get all files in the current directory
Get-ChildItem -File | Where-Object {
    $_.Name -like '*en-US.resx'
} | ForEach-Object {
    $filename = $_.Name
    $prefix = $filename -replace 'en-US.resx$', ''
    $outputFileName = $prefix + $outputLanguageCode + ".resx"
    $previousFile = "previous/$outputFileName"

    $additionalArgs = @()
    if (Test-Path $previousFile) {
        $additionalArgs = @("--previousFile", $previousFile)
        Write-Host "Running: LlmTranslateResx.exe --input $filename --output $outputFileName --previousFile $previousFile (plus all supplied arguments)"
    } else {
        Write-Host "Running: LlmTranslateResx.exe --input $filename --output $outputFileName (plus all supplied arguments)"
    }

    & "cmd" "/c" "LlmTranslateResx.exe" "--input" $filename "--output" $outputFileName @additionalArgs @ArgsToPass
}

Write-Host "All files processed"