# function Get-AptManualButDependedWhy {$packagesinfo = (aptitude search "~i !~M ~R~i");foreach($packageinfo in $packagesinfo ){ $pkg = ($packageinfo -split "\s+")[1];"$pkg";$pkgwhys = apt why -R $pkg;for ($i=0; $i -lt $pkgwhys.Count; $i++) {
# 
#     if ($i -eq $pkgwhys.Count-1) {
#         "└── $(([string[]]$pkgwhys)[$i])"
#     }
#     else {
#         "├── $(([string[]]$pkgwhys)[$i])"
#     }
# }}}
function Get-AptManualButDependedWhy {$packages = (aptitude search "~i !~M ~R~i" -F "%p");
	foreach($package in $packages ){ 
		$pkgwhys = aptitude search "~i ~D$package" -F "%p"
		for ($i=0; $i -lt $pkgwhys.Count; $i++){ 
		$pkgwhy = $pkgwhys[$i]
		"$package -> $pkgwhy"
		}
}}
function Get-AptManualButDepended {$packagesinfo = (aptitude search "~i !~M ~R~i");foreach($packageinfo in $packagesinfo ){ ($packageinfo -split "\s+")[1]}}
