# sets operator
function Compare-Except {param($First, $Second)
process{
	[System.Linq.Enumerable]::Except([object[]]$First, [object[]]$Second)
}
}
function Compare-Distinct{
param($v)
process{
	[system.Linq.Enumerable]::Distinct([string[]]([System.Linq.Enumerable]::Order([string[]]$v)))
}
}
