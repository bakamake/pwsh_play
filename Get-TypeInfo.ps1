function Get-TypeInfo {
       param(
           [Parameter(ValueFromPipeline=$true)]
           [string]$String
       )

       process {
         if ([string]::IsNullOrEmpty($String)) { return }
    
           # 尝试解析成 type
           $type = $String -as [type]
           if (-not $type) {          
           $type = ($String -as [object]).GetType()
           }
           [PSCustomObject]@{
               TypeName = $type.FullName
               Name = $type.Name
               Namespace = $type.Namespace
               IsClass = $type.IsClass
               IsAbstract = $type.IsAbstract
               IsSealed = $type.IsSealed
               IsStatic = $type.IsStatic
               IsValueType = $type.IsValueType
               IsPrimitive = $type.IsPrimitive
               BaseType = $type.BaseType.FullName
               CanCreate = -not ($type.IsAbstract -or ($type.IsSealed -and $type.IsStatic))
           }
       }

   }
