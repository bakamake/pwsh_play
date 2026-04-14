function Get-ChildNamespaces {

    param(
      [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Namespace,
        [switch]$all
    )
process{
        [System.AppDomain]::CurrentDomain.GetAssemblies() |
            ForEach-Object { try { $_.GetExportedTypes() } catch { } } |
            Where-Object {
                if ($All) {  $_.Namespace -like "$Namespace*"  }
                else { $_.Namespace -match "$Namespace*\b" }
            } |
            Select-Object -ExpandProperty Namespace -Unique
}

}
function Get-Childtypes {

param(
    [Parameter(Mandatory, ValueFromRemainingArguments, ValueFromPipeline)]
    [string[]]$Names,
    [switch]$all
)
begin{ $swap = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)}
process {


    foreach ($name in $Names) {
        [system.AppDomain]::CurrentDomain.GetAssemblies().GetExportedTypes() |
        Where-Object {
            if ($All) { $_.fullname -like "$name*" }
            else { $_.fullname -match "^$name\b" -or $_.fullname -match "^$name" }
        } | ForEach-Object {
            $swap.Add($_.fullname) | Out-Null
        }
    }
}
end{$swap | ForEach-Object { [PSCustomObject]@{ Name = $_ } }}

}


function Get-Childmembers {

    param(
          [Parameter(Mandatory, ValueFromPipeline)]
        [string]$type,
        [switch]$all
    )
        if($type -as [type])
        {$typetype = $type -as [type]}
        elseif ($type.StartsWith('[') -and $type.EndsWith(']')) 
        {$typetype = $type.Substring(1, $type.Length - 2) -as [type]}
        elseif($type.name -as [type])
        {$typetype = [type]($type.name) }
        elseif($type.fullname -as [type])
        {$typetype = [type]($type.fullname)}

        $typename = $typetype.fullname
        Write-host "$typename"
        $typetype.getmembers([System.Reflection.BindingFlags]::Public -bor
        [System.Reflection.BindingFlags]::Instance -bor
        [System.Reflection.BindingFlags]::DeclaredOnly
        )|
        ? { 
        		(-not $_.MemberType.hasflag([System.Reflection.MemberTypes]::Method) -and -not $_.MemberType.hasflag([System.Reflection.MemberTypes]::Constructor)) -or
        		($_.MemberType.hasflag([System.Reflection.MemberTypes]::Method) -and -not $_.Attributes.hasflag([System.Reflection.MethodAttributes]::SpecialName))

        }|
        select-object name,MemberType,Attributes
}
