function Convert-hextobin {
	param($hex)
	[Convert]::ToString([int]$hex, 2).PadLeft(8,'0')
}
function convert-bintohex {
	param($bin)
	[Convert]::ToInt64($bin, 2).ToString('X2')
}
