function Set-WlClipboard {
    param([string]$Text)
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName               = 'wl-copy'
    $psi.RedirectStandardInput  = $true
    $psi.UseShellExecute        = $false
    $psi.CreateNoWindow         = $true
    $p = [System.Diagnostics.Process]::Start($psi)
    try {
        $p.StandardInput.Write($Text)
        $p.StandardInput.Close()
        if (-not $p.WaitForExit(10000)) {
            $p.Kill()
            Write-Warning 'wl-copy Timeout'
        }
    } finally {
        $p.Dispose()
    }
}
Set-PSReadLineKeyHandler -Key Ctrl+x -ScriptBlock {
    $start  = $null
    $length = $null
    $line   = $null
    $cursor = $null

    [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$start, [ref]$length)
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

        if ($length -gt -1 -and $start -ne -1) {
    $selected = $line.Substring($start, $length)
    Set-WlClipboard $selected
    [Microsoft.PowerShell.PSConsoleReadLine]::Replace($start, $length, '')
}
}
Set-PSReadLineKeyHandler -Key Ctrl+c -ScriptBlock {
    $start  = $null
    $length = $null
    $line   = $null
    $cursor = $null

    [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$start, [ref]$length)
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

        if ($length -gt -1 -and $start -ne -1) {
    $selected = $line.Substring($start, $length)
    Set-WlClipboard $selected
    [Microsoft.PowerShell.PSConsoleReadLine]::Replace($start, $length, $selected)
}
}
function Get-WlClipboard {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName                = 'wl-paste'
    $psi.Arguments               = '--no-newline'
    $psi.RedirectStandardOutput  = $true
    $psi.UseShellExecute         = $false
    $psi.CreateNoWindow          = $true

    $p = [System.Diagnostics.Process]::Start($psi)
    try {
        $text = $p.StandardOutput.ReadToEnd()
        $p.StandardOutput.Close()
        if (-not $p.WaitForExit(2000)) {
            $p.Kill()
            Write-Warning 'wl-paste Timeout'
        }
        return $text
    } finally {
        $p.Dispose()
    }
}
Set-PSReadLineKeyHandler -Key Ctrl+v -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert((Get-WlClipboard))
}
