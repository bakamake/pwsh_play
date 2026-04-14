function jion-clipboard{
param(
    [Parameter(ValueFromPipeline)]
   	[string[]]$toclipboard
	)
process {
	[string[]]$formclipboard = Microsoft.PowerShell.Management\get-Clipboard
	$formclipboard + $toclipboard | Microsoft.PowerShell.Management\Set-Clipboard
}
}
