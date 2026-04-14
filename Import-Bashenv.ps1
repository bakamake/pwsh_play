function Import-BashEnv {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath
    )

    # 1. 1>/dev/null 仅作用于 source 命令，吞掉脚本的 echo等输出干扰信息
    # 2. env 命令正常输出，被 PowerShell 捕获
    $rawEnv = & bash -c "source '$ScriptPath' 1>/dev/null; env"

    foreach ($line in $rawEnv) {
        if ($line -match '^([^=]+)=(.*)$') {
            [System.Environment]::SetEnvironmentVariable($Matches[1], $Matches[2], 'Process')
        }
    }
}
Set-Alias -Name source -Value Import-BashEnv
