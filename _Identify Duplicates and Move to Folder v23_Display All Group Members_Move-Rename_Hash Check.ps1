$sourceDir = $PSScriptRoot
$thisDrive = (Split-Path -Path $sourceDir -Qualifier) + "\"
$targetPath = "_Duplicates\"
$coldStorage = "_COLD_STORAGE"
$whereTo = $thisDrive + $targetPath
$targetDir = $sourceDir.Replace($thisDrive,$whereTo)

If ($sourceDir -eq $thisDrive)
	{
	$thisFolderName = "ROOT";
	} else {
	$thisFolderName = (Split-Path -Path $sourceDir -Leaf)
	}

$todaysDate = Get-Date -Format "yyyy-MM-dd"
$newFileName = "_Duplicate Identification Log_" + $thisFolderName + "_$todaysDate" + ".txt"
$logFolder = $thisDrive + "___LOGS\"

$outputFile = ($logFolder + $newFileName).Replace("\\","\")

function CHECKOUTPUT
{
	Write-Host "Assessing if OUTPUTFILE exists, please wait..." -NoNewLine
	if (Test-Path $outputFile) {
		Write-Host "file found, removing existing file.`n"
		Remove-Item $outputFile -Force -Verbose
		} else {
		Write-Host "file not found, delete operation aborted."
		Write-Host "Assessing if LOGFOLDER exists, please wait..." -NoNewLine
		If(!(test-path $logFolder))
		{
			Write-Host "directory not found. Creating..." -ForegroundColor Yellow -NoNewLine
			New-Item -ItemType Directory -Force -Path $logFolder | Out-Null
			Write-Host "directory creation successful." -ForegroundColor Cyan
		} else {
			Write-Host "directory found, aborting CREATEDIR." -ForegroundColor Yellow
		}
		Write-Host " "
	}
}

function MOVEITEM
{
	$fileName = $fileName = (Split-Path -Path $_.Path -Leaf)
	$moveFrom = ((Split-Path -Parent $_.Path) + "\")
	$moveTo = ((Split-Path -Parent $nextName) + "\").Replace("\\","\")
	$fileBaseName = [io.path]::GetFileNameWithoutExtension($_.Path)
	$fileExtension = [System.IO.Path]::GetExtension($_.Path)

	If(Test-Path -Path $nextName) {
		Write-Host "TARGETFILE found, proceeding with operation GET-HASH.`n" -ForegroundColor Yellow
		$hash1 = (Get-FileHash $_.Path).Hash
		$hash2 = (Get-FileHash $nextName).Hash
		Write-Host "HASH1:" -BackgroundColor DarkGreen -ForegroundColor White
		Write-Host $hash1 -ForegroundColor Yellow
		Write-Host "HASH2:" -BackgroundColor DarkGreen -ForegroundColor White
		Write-Host $hash2 -ForegroundColor Yellow
		If ($hash1 -eq $hash2) {
			Write-Host "`nFile hashes match. Proceeding with operation REMOVE-ITEM." -BackgroundColor DarkRed -ForegroundColor White
			$_.Path | Remove-Item -Force -Verbose
			$fileDeleted = "y";
			} else {
			Write-Host "`nFile hashes don't match. Proceeding with operation RENAME-ITEM." -BackgroundColor Cyan
			$num = 1
				while(Test-Path -Path $nextName)
					{
					$nextName = Join-path $moveTo ($fileBaseName + "_$num" + $fileExtension)
					$num += 1   
					}
			}
		} else {
		Write-Host " "
		}
	if ($fileDeleted -ne "y") {
		$folderToMake = (Split-Path -Path $nextName -Parent);

		If(!(test-path $folderToMake))
		{
			New-Item -ItemType Directory -Force -Path $folderToMake | Out-Null
		}
		$_.Path | Move-Item -Destination $nextName -Force -Verbose
	}
}

function HOLDONE
{
	if ($makeOutput -eq "Y") {
	$operationDescription | add-content -path $outputFile -Force
#	Start-Sleep -Seconds 0.5
	}
}

#==========================================================================================================

Write-Host "OPERATION: Identify Duplicates and Move to TARGETDIR (One Original Stays in SOURCEDIR)" -ForegroundColor White -BackgroundColor DarkRed;
Write-Host "SOURCEDIR: " -NoNewline;
Write-Host "'$sourceDir'" -ForegroundColor Yellow;
Write-Host "TARGETDIR: " -NoNewline;
Write-Host "'$targetDir'" -ForegroundColor Yellow;
Write-Host "LOGFOLDER: " -NoNewline;
Write-Host "'$logFolder'" -ForegroundColor Yellow;
if ($makeOutput -eq "Y") {
Write-Host "OUTPUTFILE: " -NoNewline;
Write-Host "'$outputFile'" -ForegroundColor Yellow;
}
Write-Host " "

if ($makeOutput -eq "Y") {
	CHECKOUTPUT
}

$operationDescription = "SOURCEDIR: $sourceDir`n"
HOLDONE

$startFulltime = (Get-Date)
Write-Host " "
Write-Host "Operation " -NoNewLine
Write-Host "GET-CHILDITEM" -ForegroundColor Yellow -NoNewLine
Write-Host " started at: " -NoNewLine
Write-Host "$startFulltime" -ForegroundColor Yellow

$operationDescription = "Operation GET-CHILDITEM started at $startFullTime"
HOLDONE

#Assess Folder Contents ==============================================================================

$i = 1
$groupNumber = 1

[System.Collections.ArrayList]$MyFiles = @()
($allFiles = Get-ChildItem -LiteralPath $sourceDir -File -Force -Recurse -ErrorAction SilentlyContinue | ? { ($_.Extension -notlike ".ps1") -and ($_.Extension -notlike ".bat") -and ($_.fullname -notlike "$targetDir*") -and ($_.FullName -notlike "*$coldStorage*") }) | % {
	[void]$MyFiles.Add($_)
	Write-Progress -Activity "Assessing file load, please wait..." -PercentComplete -1 -Status $_.Name
}

Write-Progress -Completed ' '

$endTime = (Get-Date)
Write-Host " "
Write-Host "Operation completed at " -NoNewLine
Write-Host $endTime -ForegroundColor Yellow

#Display Stats - All Files ==============================================================================

$numFiles = ($allFiles | Measure-Object).count
$displayNumber = ('{0:N0}' -f $numFiles)
Write-Host " "
Write-Host "Total Files Found:		" -NoNewLine
Write-Host $displayNumber -ForegroundColor Yellow -NoNewLine
Write-Host " files."
Write-Host " "

If ($numFiles -eq 0) {
	Write-Host " "
	Write-Host "No files found. Operation aborted." -ForegroundColor Yellow
	$operationDescription = "`nNo files found. Operation aborted."
	HOLDONE
	PAUSE
	BREAK
}

$numBytes = ($allFiles | Measure-Object -Property Length -sum).sum

Write-Host "ALLFILES.SUMMARY:" -ForegroundColor Yellow -BackgroundColor DarkGreen;
Write-Host "ALLFILES.SIZE:			" -NoNewLine
$displayNumber = ('{0:N0}' -f $numBytes)
Write-Host $displayNumber -ForegroundColor Yellow -NoNewLine
Write-Host  " Bytes"

Write-Host "ALLFILES.SIZE.KB:		" -NoNewLine
$displayNumber = ([math]::Round(($numBytes/1KB),2)).ToString("N2");
Write-Host $displayNumber -ForegroundColor Yellow -NoNewLine
Write-Host  " KB"

Write-Host "ALLFILES.SIZE.MB:		" -NoNewLine
$displayNumber = ([math]::Round(($numBytes/1MB),2)).ToString("N2");
Write-Host $displayNumber -ForegroundColor Yellow -NoNewLine
Write-Host  " MB"

Write-Host "ALLFILES.SIZE.GB:		" -NoNewLine
$displayNumber = ([math]::Round(($numBytes/1GB),2)).ToString("N2");
Write-Host $displayNumber -ForegroundColor Yellow -NoNewLine
Write-Host  " GB"

Write-Host "ALLFILES.SIZE.TB:		" -NoNewLine
$displayNumber = ([math]::Round(($numBytes/1TB),2)).ToString("N2");
Write-Host $displayNumber -ForegroundColor Yellow -NoNewLine
Write-Host  " TB"

$analysisTime = $endTime - $startFullTime;
$displayTime = $analysisTime.ToString("hh\:mm\:ss")

$timePerFile = $analysisTime.TotalSeconds/$numFiles;
$ts = [timespan]::fromseconds($timePerFile)

Write-Host "Time required for analysis:	" -NoNewLine
Write-Host $displayTime -ForegroundColor Yellow 
Write-Host "Time per file (SS):		" -NoNewLine
Write-Host $timePerfile -ForegroundColor Yellow -NoNewLine
Write-Host " seconds"
Write-Host "Time per file (HH:MM:SS):	" -NoNewLine
Write-Host $ts.ToString("hh\:mm\:ss") -ForegroundColor Yellow

$operationDescription = "`nOperation GET-CHILDITEM completed at $endTime`nTotal files found: $displayNumber`nTime required for analysis:	$analysisTime`nTime per file (SS):		$timePerfile seconds`nTime per file (HH:MM:SS):	$ts`n"
HOLDONE

#Identify Duplicates ==============================================================================

$startTime = (Get-Date);
Write-Host " "
Write-Host "Duplicate file identification begun at " -NoNewLine
Write-Host $startTime -ForegroundColor Yellow -NoNewLine
Write-Host "."

$i = 0;
$allFiles | Group-Object -Property Length | Where-Object {$_.Count -gt 1} | ForEach-Object { $_.Group | Get-FileHash | Group-Object -Property Hash | Where-Object {$_.Count -gt 1} | ForEach-Object {

	$displayGroup = ('{0:N0}' -f $groupNumber);
	$thisHash1 = $($_.Name);

	$notMoved = $_.Group[0].Path;
	$checkFile = Get-Item $notMoved
	$fileSize = $checkFile.Length

	if ($fileSize -lt 1KB) {
		$displaySize = ('{0:N0}' -f $fileSize) + " Bytes"
	}

	if (($fileSize -ge 1KB) -and ($fileSize -lt 1MB)) {
		$displaySize = ([math]::Round(($fileSize/1KB),2)).ToString("N2") + "KB"
	}

	if (($fileSize -ge 1MB) -and ($fileSize -lt 1GB)) {
		$displaySize = ([math]::Round(($fileSize/1MB),2)).ToString("N2") + "MB"
	}

	if (($fileSize -ge 1GB) -and ($fileSize -lt 1TB)) {
		$displaySize = ([math]::Round(($fileSize/1GB),2)).ToString("N2") + "GB"
	}

	if ($fileSize -ge 1TB) {
		$displaySize = ([math]::Round(($fileSize/1TB),2)).ToString("N2") + "TB"
	}

	$operationDescription = "FILE_GROUP: $displayGroup // HASH: $($_.Name) // SIZE: $displaySize"
	HOLDONE

	Write-Host "=============================================================================================================================" -ForegroundColor Cyan
	Write-Host "FILE_GROUP: " -ForegroundColor Yellow -BackgroundColor DarkGreen -NoNewLine;
	Write-Host $displayGroup -ForegroundColor White -BackgroundColor DarkGreen -NoNewLine;
	Write-Host " // HASH: " -ForegroundColor Yellow -BackgroundColor DarkGreen -NoNewLine;
	Write-Host $thisHash1 -ForegroundColor White -BackgroundColor DarkGreen -NoNewLine;
	Write-Host " // SIZE: " -ForegroundColor Yellow -BackgroundColor DarkGreen -NoNewLine;
	Write-Host $fileSize -ForegroundColor White -BackgroundColor DarkGreen;

	$_.Group | Select -ExpandProperty Path | ForEach-Object {
		Write-Host $_ -ForegroundColor White;
		$operationDescription = $_;
		HOLDONE
	}

	$operationDescription = "`nFile to be preserved:`n$notMoved`n"
	HOLDONE

	Write-Host " "
	Write-Host "File to be preserved:" -BackgroundColor DarkBlue -ForegroundColor White;
	Write-Host $notMoved -ForegroundColor Yellow;
	Write-Host " ";
	Write-Host "All others will be moved to _DUPLICATES." -BackgroundColor DarkRed -ForegroundColor Yellow;
	Write-Host " "
#	PAUSE
	$_.Group | ForEach-Object {
		if ($_.Path -ne $notMoved) {
			$relativePath = $_.Path.Substring($sourceDir.Length)
			$nextName = Join-Path -Path $targetDir -ChildPath $relativePath
			MOVEITEM
			$i += 1;
		}
	}
	Write-Host "`nEnd of Group $displayGroup" -ForegroundColor  Green
	$groupNumber++
	}
}

$displayNumber = ('{0:N0}' -f $i)

$endTime = (Get-Date)
Write-Host " "
Write-Host "Operation completed at " -NoNewLine
Write-Host $endTime -ForegroundColor Yellow
$duplicateTime = $endTime - $startTime;

#Display Stats - Duplicate Files ==============================================================================

$numFilesDuplicates = $i;
$displayNumber = ('{0:N0}' -f $numFilesDuplicates)

Write-Host " "
Write-Host "$displayNumber" -ForegroundColor Yellow -NoNewLine
Write-Host " duplicate files identified and moved."

$timePerDuplicate = $duplicateTime.TotalSeconds/$numFiles;
$ts =  [timespan]::fromseconds($timePerDuplicate)

Write-Host " "
Write-Host "Time required for duplicate handling:	" -NoNewLine
Write-Host $duplicateTime.ToString("hh\:mm\:ss") -ForegroundColor Yellow 
Write-Host "Time per file (SS):			" -NoNewLine
Write-Host $timePerDuplicate -ForegroundColor Yellow -NoNewLine
Write-Host " seconds"
Write-Host "Time per file (HH:MM:SS):		" -NoNewLine
Write-Host $ts.ToString("hh\:mm\:ss") -ForegroundColor Yellow

$displayTime1 = $duplicateTime.ToString('hh\:mm\:ss');
$displayTime2 = $ts.ToString('hh\:mm\:ss');

$operationDescription = "`nOperation IDENTIFY-DUPLICATES completed at $endTime`nTotal files found: $displayNumber`nTime required for analysis:	$displayTime1`nTime per file (SS):		$timePerDuplicate seconds`nTime per file (HH:MM:SS):	$displayTime2`n"
HOLDONE

Write-Host " "
Write-Host "Clearing empty folders, please wait..."

while($empties=Get-ChildItem $sourceDir -recurse -Directory -Force -ErrorAction SilentlyContinue |
	 Where{$_.GetFiles().Count -eq 0 -and $_.GetDirectories().Count -eq 0 }){ $empties | Remove-Item -Force -Verbose   
	 }

#Compile and Display Runtime ==============================================================================

$endFulltime = (Get-Date)

Write-Host " "
Write-Host "All processes completed:	" -NoNewLine
Write-Host $endFulltime -ForegroundColor Yellow
$elapsedTime = $endFulltime - $startFulltime
$operationDescription = "Total time elapsed: $($elapsedTime.Hours) hours $($elapsedTime.Minutes) minutes and $($elapsedTime.Seconds) seconds."
Write-Host "Total time elapsed:		" -NoNewLine
Write-Host "$($elapsedTime.Hours)" -ForegroundColor Yellow -NoNewLine
Write-Host " hours " -NoNewLine
Write-Host "$($elapsedTime.Minutes)" -ForegroundColor Yellow -NoNewLine
Write-Host " minutes and " -NoNewLine
Write-Host "$($elapsedTime.Seconds)" -ForegroundColor Yellow -NoNewLine
Write-Host " seconds."

$operationDescription = "`nAll processes completed at $endFullTime`nTotal time elapsed: $($elapsedTime.Hours) hours $($elapsedTime.Minutes) minutes and $($elapsedTime.Seconds) seconds."
HOLDONE

#$thisScript = & { $myInvocation.ScriptName }
#$thisScript | Remove-Item -Force -Verbose

Write-Host " "
Invoke-Item $outputFile

PAUSE