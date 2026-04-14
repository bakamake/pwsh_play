function clangd-comletion{
param(
$path,

$linenumber,
$line = ([string[]](Get-Content -Path $path))[$linenumber-1],
$lineend = $line.TrimEnd([char]8).Length
)

clang -fsyntax-only -Xclang -code-completion-at="$($path):$($linenumber):$($lineend)" -- "$path" 2>&1 ;Get-Variable -Scope Local|? { ($_.Options -band [System.Management.Automation.ScopedItemOptions]::AllScope) -eq 0 }
}

function get-cheadfile {
	param(
	$path,
	
	$linenumber,
	$line = ([string[]](Get-Content -Path $path))[$linenumber-1],
	$lineend = $line.TrimEnd([char]8).Length
	)
} 
