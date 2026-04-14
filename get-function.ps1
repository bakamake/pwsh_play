# function get-function {
# param(
#     [Parameter(ValueFromPipeline)]
#     [string]$function,
#     [string]$path
# )
# process {
#     $itemobject = Get-ChildItem $path -file
#     if($itemobject.Exists){
#     $Content = Get-Content -Path $itemobject.FullName
#     $functionline = $Content |select-string "function $function"
#     $functionline.line
# 	$EOF = $Content.Count
# 
#     # for
#     $Scopes = 1
#     # {
#     # if }
#     # Scopes -1 == 0
#     # function end
#     # if {
#     # Scopes + 1 > 0
#     # function continue
#     # ..... Scopes == 0 ;function end
#     for($i=0;$Scopes -ne 0;$i++){
#     $infunction = $Content[$functionline[0].LineNumber+$i]
# 	# $infunction  -split "\b"| foreach-object{if($_ -match "\{" ){$Scopes++}elseif($_ -match "\}"){$Scopes--}}
# 	$open = $infunction.Length - $infunction.Replace('{','').Length
# 	$close = $infunction.Length - $infunction.Replace('}','').Length
# 	$Scopes += $open - $close
# 	$infunction
#     }
#     }
# }
# }
# 
# 以上使用类似波峰波谷的计数算法原理
# 以下使用get-command 的成员
function get-function {
	param(
	    [Parameter(ValueFromPipeline)]
	    [string]$function
	)
	process {
	$command = get-command $function
	if($command.commandtype -eq 'function'){return "function $function {`n" + $command.Definition +"`n}"}
	elseif($command.commandtype -eq 'Cmdlet'){return "Cmdlet $function `n" + $command.Definition }
	}
}
