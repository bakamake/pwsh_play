$path=$env:PATH
function export {
    $args | ForEach-Object {
        $parts = $_.split('=', 2)
        if ($parts.Count -eq 2) {
            Set-Item -Path "env:$($parts[0])" -Value $parts[1]
        }
    }
}



function Import-BashEnv {
param(
    [Parameter(Mandatory = $true)]
    [string]$ScriptPath
)

# 传入当前的 PATH，bash 可以继承
$currentPath = $env:PATH

# 执行脚本并只获取脚本产生的新变量
$beforeEnv = @{}
[System.Environment]::GetEnvironmentVariables().GetEnumerator() | ForEach-Object {
    $beforeEnv[$_.Key] = $_.Value
}

# bash 继承当前环境
$rawEnv = & bash -c @"
export PATH='$currentPath'
source '$ScriptPath'
env
"@

    foreach ($line in $rawEnv) {
        if ($line -match '^([^=]+)=(.*)$') {
            $name = $Matches[1]
            $value = $Matches[2]

            # 只设置新增或改变的变量
            if (-not $beforeEnv.ContainsKey($name) -or $beforeEnv[$name] -ne $value) {
                [System.Environment]::SetEnvironmentVariable($name, $value, 'Process')
            }
        }
    }
}
Set-Alias source Import-BashEnv
# function source {
#
# }
