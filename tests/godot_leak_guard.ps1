param(
	[Parameter(Mandatory = $true, Position = 0)]
	[string]$Executable,
	[Parameter(ValueFromRemainingArguments = $true, Position = 1)]
	[string[]]$Arguments
)

$patterns = @(
	'RIDs of type',
	'RID allocations of type',
	'ObjectDB instances leaked at exit',
	'resources still in use at exit'
)

$outputLines = New-Object System.Collections.Generic.List[string]

& $Executable @Arguments 2>&1 | ForEach-Object {
	$line = $_.ToString()
	$outputLines.Add($line)
	Write-Output $line
}

$exitCode = $LASTEXITCODE
$leakFound = $false

foreach ($line in $outputLines) {
	foreach ($pattern in $patterns) {
		if ($line.Contains($pattern)) {
			$leakFound = $true
			break
		}
	}
	if ($leakFound) {
		break
	}
}

if ($leakFound -and $exitCode -eq 0) {
	exit 1
}

exit $exitCode
