## Imports
Import-Module .\DemoFunctions.psm1

## Variables
$Script:ColumnRecall = 0
$Script:NewLineState = $True
$Script:LogCache = ""
$Script:MakeOutput = $True 
$Script:sourceDir = $PSScriptRoot
$Script:thisDrive = (Split-Path -Path $sourceDir -Qualifier) + "\"
$Script:targetPath = "_Duplicates\"
$Script:coldStorage = "_COLD_STORAGE"
$Script:whereTo = $thisDrive + $targetPath
$Script:targetDir = $sourceDir.Replace($thisDrive, $whereTo)
$Script:thisFolderName = ""
$Script:SkipFileTypes = @('.ps1', '.bat')

If ($sourceDir -eq $thisDrive) {
	$Script:thisFolderName = "ROOT";
}
else {
	$Script:thisFolderName = (Split-Path -Path $sourceDir -Leaf)
}

$newFileName = "_Duplicate Identification Log_$thisFolderName_$(Get-Date -Format "yyyyMMdd").txt"
$Script:LogFolder = $thisDrive + "___LOGS\"
$Script:LogFile = ($Script:LogFolder + $newFileName).Replace("\\", "\")

## Logic
#==========================================================================================================
Write-Message -Preamble "OPERATION:" -Message "Identify Duplicates and Move to TARGETDIR (One Original Stays in SOURCEDIR)" -BgColor DarkRed
Write-Message -Preamble "SOURCEDIR:" -Message "'$sourceDir'" -Log $True -LogFile $Script:LogFile
Write-Message -Preamble "TARGETDIR:" -Message "'$targetDir'"
Write-Message -Preamble "LOGFOLDER:" -Message "'$Script:LogFolder'"

if ($Script:MakeOutput) {
	Write-Message -Preamble "OUTPUTFILE:" -Message "'$Script:LogFile'"
	Write-Host " "
	CHECKOUTPUT -LogFile $Script:LogFile -LogFolder $Script:LogFolder
}

Write-Host " "

$startFulltime = Get-Date
Write-Host " "

Write-Message -Preamble "Operation" -Message "GET-CHILDITEM" -NewLine $False -Log $True -LogFile $Script:LogFile
Write-Message -Preamble " started at:" -Message "$startFulltime" -Log $True -LogFile $Script:LogFile 

#Assess Folder Contents ==============================================================================
[System.Collections.ArrayList]$MyFiles = @()
$allFiles = Get-ChildItem -LiteralPath $sourceDir -File -Force -Recurse -ErrorAction SilentlyContinue
$targetFiles = $allFiles | Where-Object { 
	($_.Extension -notin $Script:SkipFileTypes) -and 
	($_.fullname -notlike "$targetDir*") -and 
	($_.FullName -notlike "*$coldStorage*")
}

$targetFiles | ForEach-Object {
	$MyFiles += $_
	Write-Progress -Activity "Assessing file load, please wait..." -PercentComplete -1 -Status $_.Name
}

Write-Progress -Completed ' '

$endTime = (Get-Date)
Write-Host " "
Write-Message -Preamble "Operation completed at" -Message $endTime

#Display Stats - All Files ==============================================================================

Write-Host " "
Write-Message -Preamble "Total Files Found:      " -Message $MyFiles.Count -NewLine $false -LogFile $Script:LogFile -Log $True
Write-Message -Message "files." -MessageColor "White" -Log $True -LogFile $Script:LogFile 

Write-Host " "

If ($MyFiles.Count -eq 0) {
	Write-Message -Message "No files found. Operation aborted." -Log $True -LogFile $Script:LogFile
	PAUSE
	BREAK
}

$numBytes = ($MyFiles | Measure-Object -Property Length -sum).sum
$displayBytes = ('{0:N0}' -f $numBytes)
$displayKBytes = ([math]::Round(($numBytes / 1KB), 2)).ToString("N2");
$displayMBytes = ([math]::Round(($numBytes / 1MB), 2)).ToString("N2");
$displayGBytes = ([math]::Round(($numBytes / 1GB), 2)).ToString("N2");
$displayTBytes = ([math]::Round(($numBytes / 1TB), 2)).ToString("N2");

Write-Message -Message "ALLFILES.SUMMARY" -BgColor "DarkGreen"
Write-Message -Preamble "ALLFILES.SIZE          " -Message "$displayBytes" -NewLine $False
Write-Message -Message " Bytes" -MessageColor "White"

Write-Message -Preamble "ALLFILES.SIZE.KB:      " -Message $displayKBytes -NewLine $False
Write-Message -Message " KB" -MessageColor "White"

Write-Message -Preamble "ALLFILES.SIZE.MB:      " -Message $displayMBytes -NewLine $False
Write-Message -Message " MB" -MessageColor "White"

Write-Message -Preamble "ALLFILES.SIZE.GB:      " -Message $displayGBytes -NewLine $False
Write-Message -Message " GB" -MessageColor "White"

Write-Message -Preamble "ALLFILES.SIZE.TB:      " -Message $displayTBytes -NewLine $False
Write-Message -Message " TB" -MessageColor "White"

$analysisTime = $endTime - $startFullTime;
$displayTime = $analysisTime.ToString("hh\:mm\:ss")

$timePerFile = $analysisTime.TotalSeconds / $MyFiles.count;
$ts = [timespan]::fromseconds($timePerFile)

Write-Message -Preamble "Time required for analysis:     " -Message $displayTime -Log $True -LogFile $Script:LogFile 
Write-Message -Preamble "Time per file (SS):        " -Message $timePerfile -NewLine $False -Log $True -LogFile $Script:LogFile 
Write-Message -Message "seconds" -MessageColor "White" -Log $True -LogFile $Script:LogFile 
Write-Message -Preamble "Time per file (HH:MM:SS):  " -Message $ts.ToString("hh\:mm\:ss") -Log $True -LogFile $Script:LogFile 

#Identify Duplicates ==============================================================================

$startTime = (Get-Date);
Write-Host " "
Write-Message -Preamble "Duplicate file identification begun at " -Message $startTime -NewLine $False 
Write-Message -Message "." -MessageColor "White"

$DuplicateFiles = 0
$groupNumber = 0
$FileGroups = $MyFiles | Group-Object -Property Length | Where-Object { $_.Count -gt 1}
ForEach($Group in $FileGroups) {
	$HashGroups = $Group.Group | Get-FileHash | Group-Object -Property Hash | Where-Object { $_.Count -gt 1 }
	ForEach($File in $HashGroups) {
		$displayGroup = ('{0:N0}' -f $groupNumber);
		$thisHash1 = $($File.Name);

		$notMoved = $File.Group[0].Path;
		$checkFile = Get-Item $notMoved
		$displaySize = switch ($checkFile.Length) {
			{ $_ -lt 1KB }
				{ ('{0:N0}' -f $_) + " Bytes"; break }
		    { $_ -lt 1MB } 
				{ ([math]::Round(($_ / 1KB), 2)).ToString("N2") + "KB"; break }
			{ $_ -lt 1GB}
				{([math]::Round(($_ / 1MB), 2)).ToString("N2") + "MB"; break }
			{ $_ -lt 1TB } 
				{([math]::Round(($_ / 1GB), 2)).ToString("N2") + "GB"; break}
			{ $_ -ge 1TB }
				{ ([math]::Round(($_ / 1TB), 2)).ToString("N2") + "TB"; break}
		}
		

		Write-Host "=============================================================================================================================" -ForegroundColor Cyan
		Write-Message -Preamble "FILE_GROUP" -PreambleColor "Yellow" -Message $displayGroup -MessageColor White -NewLine $False -BGColor "DarkGreen" 
		Write-Message -Preamble " // HASH:" -PreambleColor "Yellow" -Message $thisHash1 -MessageColor White -NewLine $False
		Write-Message -Preamble " // SIZE:" -PreambleColor "Yellow" -Message $displaySize -MessageColor White 

		$File.Group | ForEach-Object {
			Write-Message -Message $_.Path -MessageColor "White" -Log $True -LogFile $Script:LogFile
		}

		Write-Host " "
		Write-Message -Message "File to be preserved:" -BGColor DarkBlue -MessageColor White -Log $True -LogFile $Script:LogFile
		Write-Message -Message $notMoved -Log $True -LogFile $Script:LogFile

		Write-Host " ";
		Write-Message -Message "All others will be moved to _DUPLICATES." -BgColor DarkRed
		Write-Host " "

		$File.Group[1..($File.Group.count - 1)] | ForEach-Object {
				$TargetPath = $_.Path.Substring($sourceDir.Length)
				$TargetName = Join-Path -Path $Script:targetDir -ChildPath $TargetPath
				MOVEITEM -Source $_ -Target $TargetName
				$DuplicateFiles += 1;
		}

		Write-Message -Message "`nEnd of Group $displayGroup" -MessageColor Green
		$groupNumber++
	}
}

$displayNumber = ('{0:N0}' -f $DuplicateFiles)

$endTime = (Get-Date)
Write-Host " "
Write-Message -Preamble "Operation completed at " -Message $endTime -Log $True -LogFile $Script:LogFile
$duplicateTime = $endTime - $startTime;

#Display Stats - Duplicate Files ==============================================================================

$numFilesDuplicates = $DuplicateFiles;
$displayNumber = ('{0:N0}' -f $numFilesDuplicates)

Write-Host " "
Write-Message -Preamble "$displayNumber" -Message " duplicate files identified and moved." -MessageColor "White" -Log $True -LogFile $Script:LogFile

$timePerDuplicate = $duplicateTime.TotalSeconds / $numFilesDuplicates;
$ts = [timespan]::fromseconds($timePerDuplicate)

Write-Host " "
Write-Message -Preamble "Time required for duplicate handling: " -Message $duplicateTime.ToString("hh\:mm\:ss") -Log $True -LogFile $Script:LogFile

Write-Message -Preamble "Time per file (SS):                   " -Message $timePerDuplicate -NewLine $False -Log $True -LogFile $Script:LogFile
Write-Message -Message " seconds" -MessageColor "White" -Log $True -LogFile $Script:LogFile

Write-Message "Time per file (HH:MM:SS):        " -Message $ts.ToString("hh\:mm\:ss") -Log $True -LogFile $Script:LogFile

Write-Host " "
Write-Message -Message "Clearing empty folders, please wait..." -MessageColor "White"

$Directories = Get-ChildItem $sourceDir -Recurse -Directory -Force -ErrorAction SilentlyContinue
$Directories | Where-Object { $_.GetFiles().Count -eq 0 -and $_.GetDirectories().Count -eq 0 } | ForEach-Object {
	$_ | Remove-Item -Force -Verbose
}

#Compile and Display Runtime ==============================================================================

$endFulltime = (Get-Date)
$elapsedTime = $endFulltime - $startFulltime
Write-Host " "
Write-Message -Preamble "All processes completed:   " -Message $endFulltime -Log $True -LogFile $Script:LogFile
Write-Message -Preamble "Total time elapsed:        " -Message "$($elapsedTime.Hours)" -NewLine $False -Log $True -LogFile $Script:LogFile
Write-Message -Preamble " hours " -Message "$($elapsedTime.Minutes)" -NewLine $False -Log $True -LogFile $Script:LogFile
Write-Message -Preamble " minutes and " -Message $($elapsedTime.Seconds) -NewLine $False -Log $True -LogFile $Script:LogFile
Write-Message -Message " seconds." -MessageColor "White" -Log $True -LogFile $Script:LogFile

#$thisScript = & { $myInvocation.ScriptName }
#$thisScript | Remove-Item -Force -Verbose

Write-Host " "
Invoke-Item $Script:LogFile

PAUSE