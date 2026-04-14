function Get-Speak {
	param(
	[Parameter(ValueFromPipeline=$true)]
	[string]$Text
	)
	process {
	$file = New-TemporaryFile
	gtts-cli $Text -o $file
	ffplay -nodisp -autoexit $file 2>$null
	rm $file
	}
}

