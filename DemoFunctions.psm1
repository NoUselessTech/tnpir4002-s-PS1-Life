
function Write-Message {
	param(
		[Parameter(Mandatory = $False)]
		[String]$Preamble,

		[Parameter(Mandatory = $False)]
		[String]$PreambleColor = "White",

		[Parameter(Mandatory = $True)]
		[String]$Message,

		[Parameter(Mandatory = $False)]
		[String]$MessageColor = "Yellow",

		[Parameter(Mandatory = $False)]
		[PSDefaultValue(value = "Clear")]
		[String]$BgColor = "Clear",

		[Parameter(Mandatory = $False)]
		[Boolean]$NewLine = $True,

		[Parameter(Mandatory = $False)]
		[Boolean]$Log = $False,
		
		[Parameter(Mandatory = $False)]
		[String]$LogFile = "" 
	)

	$FGColors = @{
		DarkBlack   = "`e[30m"
		DarkRed     = "`e[31m"
		DarkGreen   = "`e[32m"
		DarkYellow  = "`e[33m"
		DarkBlue    = "`e[34m"
		DarkMagenta	= "`e[35m"
		DarkCyan    = "`e[36m"
		White       = "`e[37m"
		Black       = "`e[90m"
		Red         = "`e[91m"
		Green       = "`e[92m"
		Yellow      = "`e[93m"
		Blue        = "`e[94m"
		Magenta     = "`e[95m"
		Cyan        = "`e[96m"
	}

	$BGColors = @{
		Clear       = "`e[0m"
		DarkBlack   = "`e[40m"
		DarkRed     = "`e[41m"
		DarkGreen   = "`e[42m"
		DarkYellow  = "`e[43m"
		DarkBlue    = "`e[44m"
		DarkMagenta	= "`e[45m"
		DarkCyan    = "`e[46m"
		White       = "`e[47m"
		Black       = "`e[100m"
		Red         = "`e[101m"
		Green       = "`e[102m"
		Yellow      = "`e[103m"
		Blue        = "`e[104m"
		Magenta     = "`e[105m"
		Cyan        = "`e[106m"
	}

	$Output = ""

	# If the newline state is set to false
	# move the cursor up to the end of the previous line
	# otherwise, treat like a new line
	if ($Script:NewLineState -eq $False) {
		$Output += "`e[1A`e[$($Script:ColumnRecall)C"
		$Script:NewlineState = $True
		if ($NewLine -eq $True) {
			$Script:ColumnRecall = 0
		}
	} else {
		$Output += $BGColors[$BgColor]
	}
		
	$Output += "$($FGColors[$PreambleColor])$Preamble $($FGColors[$MessageColor])$Message"

	# If new line is indicated, time to set the script variables for the next call.
	if ($NewLine -eq $False) {
		$str = "$Preamble $Message"
		$Script:NewLineState = $False
		$Script:ColumnRecall += $str.Length
	} else {
		$Output += "`e[0m"
	}

	# Handle Logging
	if ($Log) {
		if ($NewLine -eq $False) {
			$Script:LogCache += "$Preamble $Message "
		} else {
			"$Script:LogCache $Preamble $Message" | Out-File -Append $LogFile
			$Script:LogCache = ""
		}
	}

	Write-Output $Output
}

function CHECKOUTPUT {
	param(
		$LogFile,
		$LogFolder
	)

	# Folder check
	if (!(Test-Path $LogFolder)) {
		Write-Host "Logging directory not found. Creating..." -ForegroundColor Yellow -NewLine $False
		New-Item -ItemType Directory -Force -Path $logFolder | Out-Null
		Write-Host "directory creation successful." -ForegroundColor Cyan
	}

	# File Check
	Write-Host "Assessing if OUTPUTFILE exists, please wait..." -NewLine $False
	if (Test-Path $LogFile) {
		Write-Host "file found, removing existing file.`n"
		Remove-Item $LogFile -Force -Verbose
	}
}

function MOVEITEM {
	param(
		$Source,
		$Target
	)
	$moveTo = ((Split-Path -Parent $Target) + "\").Replace("\\", "\")
	$fileBaseName = [io.path]::GetFileNameWithoutExtension($Source.Path)
	$fileExtension = [System.IO.Path]::GetExtension($Source.Path)

	If (Test-Path -Path $Target) {
		Write-Message -Message "TARGETFILE found, proceeding with operation GET-HASH.`n"
		$hash1 = (Get-FileHash $Source.Path).Hash
		$hash2 = (Get-FileHash $Target).Hash
		Write-Message -Preamble "HASH1:" -BGColor "DarkGreen" -Message $hash1 
		Write-Message -Preamble "HASH2:" -BGColor "DarkGreen" -Message $hash2 
		
		If ($hash1 -eq $hash2) {
			Write-Host "`nFile hashes match. Proceeding with operation REMOVE-ITEM." -BackgroundColor DarkRed -ForegroundColor White
			$Source.Path | Remove-Item -Force -Verbose
		} else {
			Write-Host "`nFile hashes don't match. Proceeding with operation RENAME-ITEM." -BackgroundColor Cyan
			if (Test-Path -Path $Target) {
				$Target = Join-path $moveTo ($fileBaseName + "1" + $fileExtension)
			}
		}
	} 

	$folderToMake = (Split-Path -Path $Target -Parent);

	If(!(test-path $folderToMake))
	{
		New-Item -ItemType Directory -Force -Path $folderToMake | Out-Null
	}
	$Source.Path | Move-Item -Destination $Target -Force -Verbose
}