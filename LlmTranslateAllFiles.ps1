# Runs LlmTranslateResx on all en-US resx files in the directory, creating a language dictionary 
# LlmTranslateAllFiles -outputLanguageCode de --targetLanguage German --uri https://myOpenAiCompatApi --model gpt-4.1-mini --apiKey myApiKey
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
    Write-Host "Running: LlmTranslateResx.exe --input $filename --output $outputFileName (plus all supplied arguments)"
    & "cmd" "/c" "LlmTranslateResx.exe" "--input" $filename "--output" $outputFileName @ArgsToPass
}

Write-Host "All files processed"