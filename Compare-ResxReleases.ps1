# Generates .resx dictionary tags differences files 

 param(
    [Parameter(Mandatory = $true)]
    [String]$RelA,

    [Parameter(Mandatory = $true)]
    [String]$RelB,

    [string]$workspacePath = ".\samples"
)

# Function to load a .resx file into a hashtable
function Load-Resx {
    param([string]$Path)

    if (-not (Test-Path $Path)) { return $null }

    [xml]$xml = Get-Content $Path

    $items = @{}
    foreach ($data in $xml.root.data) {
        $key = $data.name
        $value = $data.value
        $items[$key] = $value
    }

    return $items
}


function Get-FolderComparison {
	
	param(
    [Parameter(Mandatory = $true)]
    [string]$FolderA,

    [Parameter(Mandatory = $true)]
    [string]$FolderB,

    [Parameter(Mandatory = $true)]
    [string]$ReleaseA,
    
    [Parameter(Mandatory = $true)]
    [string]$ReleaseB, 

    [Parameter(Mandatory = $true)]
    [string]$Component,
	
	[Parameter(Mandatory = $true)]
    [string]$workspacePath
	)

	$FolderAFormatted = $FolderA
	$FolderBFormatted = $FolderB
    $list = New-Object System.Collections.Generic.List[System.Object];
	$list.Add( "$Component`n")
	$list.Add( "`nComparing folders:")
	$list.Add( " A = $FolderAFormatted")
	$list.Add( " B = $FolderBFormatted`n")

	# Get all .resx files, excluding "de" translation files
	$resxA = Get-ChildItem -Path $FolderA -Filter "*.resx" | Where-Object { $_.Name -notmatch '\.de\.resx$' }
	$resxB = Get-ChildItem -Path $FolderB -Filter "*.resx" | Where-Object { $_.Name -notmatch '\.de\.resx$' }

	# Index by filename (not full path)
	$mapA = $resxA | Group-Object { $_.Name } -AsHashTable
	$mapB = $resxB | Group-Object { $_.Name } -AsHashTable

	# Get combined file list
	$allFiles = ($mapA.Keys + $mapB.Keys) | Sort-Object -Unique


    $list | Out-File -Width 1000 "$workspacePath\$($Component)_diffs.txt"

	foreach ($fileName in $allFiles) {
		"`n===== Comparing $fileName =====" | Out-File -Width 1000 "$workspacePath\$($Component)_diffs.txt" -append

		$existsA = ($mapA.GetEnumerator().Name).Contains($fileName)
		$existsB = ($mapB.GetEnumerator().Name).Contains($fileName)

		if (-not $existsA) {
			$list.Add( "⚠ Missing in $($ReleaseA): $fileName")
			continue
		}

		if (-not $existsB) {
			$list.Add( "⚠ Missing in $($ReleaseB): $fileName")
			continue
		}

		# Load key/value data
        $pathA = (($mapA.GetEnumerator()) | Where-Object {$_.Name -eq $fileName}).Value.FullName
        $pathB = (($mapB.GetEnumerator()) | Where-Object {$_.Name -eq $fileName}).Value.FullName

		$hashA = Load-Resx $pathA
		$hashB = Load-Resx $pathB

		if ($hashA -eq $null -or $hashB -eq $null) {
			$list.Add( "❌ Failed to read file(s)")
			continue
		}
# $hashA | select *
# break
		$results = @()

		# Missing keys & changed values
		foreach ($key in $hashA.Keys) {
			if (-not $hashB.ContainsKey($key)) {
				$results += [pscustomobject]@{
                    Status  = "New tag in $($ReleaseA)"
					# File    = $fileName
					Key     = $key
                    Value   = $hashA[$key]
					
				}
			}
			elseif ($hashA[$key] -ne $hashB[$key]) {
				$results += [pscustomobject]@{
                    Status  = "Value differs"
					# File    = $fileName
					Key     = $key
                    Value   = $hashA[$key]
					
				}
			}
		}

		# Keys missing in A
		foreach ($key in $hashB.Keys) {
			if (-not $hashA.ContainsKey($key)) {
				$results += [pscustomobject]@{
                    Status  = "tag removed from $($ReleaseA)" 
					# File    = $fileName
					Key     = $key
                    Value   = $hashB[$key]
				}
			}
		}

		if ($results.Count -eq 0) {
			 "✔ No differences found" | Out-File -Width 1000 "$workspacePath\$($Component)_diffs.txt" -append
		}
		else {
			$results | Sort-Object Key | Format-Table -AutoSize | Out-File -Width 1000 "$workspacePath\$($Component)_diffs.txt" -append
		}
	}

    "`nComparison complete.`n" | Out-File -Width 1000 "$workspacePath\$($Component)_diffs.txt" -append

}


# $RelA = "12.18"
# $RelB = "2026.1"

$RootA = "$workspacePath\MyID-$RelA"
$RootB = "$workspacePath\MyID-$RelB"
$outputPath = "$workspacePath\diffs\MyID-$($RelA)_vs_$($RelB)"

if (-not (Test-Path $outputPath)) { New-Item -ItemType Directory -Path $outputPath | Out-Null }

# REST components
foreach ($Component in @("rest.core", "rest.provision", "web.oauth2")) {
    $FolderA = "$RootA\$Component\Dictionaries"
    $FolderB = "$RootB\$Component\Dictionaries"
    Get-FolderComparison $FolderA $FolderB $RelA $RelB $Component $outputPath
}


# SSRP components
$Component = "SSRP"
foreach ($SubComponent in @("SSRP", "SSRPOID", "Start", "StartPage")) {
    $FolderA = "$RootA\$Component\$SubComponent\App_GlobalResources"
    $FolderB = "$RootB\$Component\$SubComponent\App_GlobalResources"
    Get-FolderComparison $FolderA $FolderB $RelA $RelB "$($Component)_$($SubComponent)" $outputPath
}

# MWS components
$Component = "SSP"
foreach ($SubComponent in @("MyIDDataSource", "MyIDProcessDriver")) {
    $FolderA = "$RootA\$Component\$SubComponent\Language"
    $FolderB = "$RootB\$Component\$SubComponent\Language"
    Get-FolderComparison $FolderA $FolderB $RelA $RelB "$($Component)_$($SubComponent)" $outputPath
}


