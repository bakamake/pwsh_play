function _quote-bash {
    param([string]$s)
    "'" + ($s -replace "'", "'\\''") + "'"
}

function run-gui {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$App,
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Args
    )

    $quoted = @($App) + $Args | ForEach-Object { _quote-bash $_ }
    $line   = 'setsid ' + ($quoted -join ' ') + ' </dev/null >/dev/null 2>&1 & disown; exit'

    bash -c $line > /dev/null 2>&1
}

function exp {
    xdg-open @args > /dev/null 2>&1
}
