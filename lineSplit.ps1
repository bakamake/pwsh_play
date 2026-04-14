"a,,b,,c".Split(',', [StringSplitOptions]::RemoveEmptyEntries) -join ','
$swap = "admindir,root,instdir,pre-invoke,post-invoke,path-exclude,path-include,selected-only,skip-same-version,refuse-downgrade,auto-deconfigure,triggers,no-triggers,verify-format,no-pager,no-debsig,simulate,debug,status-fd,status-logger,log,ignore-depends,force,no-force,refuse,abort-after"
$swap.ToCharArray()
($swap -eq ',').Count
($swap.ToCharArray()| Group-Object | Where-Object{$_.name -eq ','}).Count
"hello,,world" -('\b') -join ' '
$swap = "admindir,root,instdir,pre-invoke,post-invoke,path-exclude,path-include,selected-only,skip-same-version,refuse-downgrade,auto-deconfigure,triggers,no-triggers,verify-format,no-pager,no-debsig,simulate,debug,status-fd,status-logger,log,ignore-depends,force,no-force,refuse,abort-after" 
$swap -split ',' -join "','"
[int]'A'
[int]([char]'A')
[char]65
65..90 | ForEach-Object { [char]$_+':'+ $_ }
