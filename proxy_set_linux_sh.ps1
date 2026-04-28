#!/usr/bin/env pwsh

param(
    [Parameter(Position = 0)]
    [string]$Mode,

    [Parameter(Position = 1)]
    [string]$ProxyIP,

    [Parameter(Position = 2)]
    [int]$ProxyPort,

    [Parameter(Position = 3)]
    [string]$IgnoreHosts
)

function Set-GnomeProxy {
    param(
        [string]$Mode,
        [string]$ProxyIP,
        [int]$ProxyPort,
        [string]$IgnoreHosts
    )

    & gsettings set org.gnome.system.proxy mode $Mode

    if ($Mode -eq "manual") {
        $protocols = @("http", "https", "ftp", "socks")

        foreach ($protocol in $protocols) {
            & gsettings set "org.gnome.system.proxy.$protocol" host $ProxyIP
            & gsettings set "org.gnome.system.proxy.$protocol" port $ProxyPort
        }

        $ignoreList = @()
        if ($IgnoreHosts) {
            $ignoreList = $IgnoreHosts.Split(",") | ForEach-Object { $_.Trim() } | Where-Object { $_ }
        }

        $gsettingsList = "[" + (($ignoreList | ForEach-Object { "'$_'" }) -join ", ") + "]"
        & gsettings set org.gnome.system.proxy ignore-hosts $gsettingsList

        Write-Verbose "GNOME: Manual proxy settings applied."
        Write-Verbose "Proxy IP: $ProxyIP"
        Write-Verbose "Proxy Port: $ProxyPort"
        Write-Verbose "Ignored Hosts: $IgnoreHosts"
    }
    elseif ($Mode -eq "none") {
        Write-Error "GNOME: Proxy disabled."
    }
}

function Set-KdeProxy {
    param(
        [string]$Mode,
        [string]$ProxyIP,
        [int]$ProxyPort,
        [string]$IgnoreHosts
    )

    $kwriteconfig = if ($env:KDE_SESSION_VERSION -eq "6") { "kwriteconfig6" } else { "kwriteconfig5" }

    if (-not (Get-Command $kwriteconfig -ErrorAction SilentlyContinue)) {
        throw "Command not found: $kwriteconfig"
    }

    if ($Mode -eq "manual") {
    	$proxyUrl = "http://${ProxyIP}:${ProxyPort}"
        & $kwriteconfig --file kioslaverc --group "Proxy Settings" --key ProxyType 1
        & $kwriteconfig --file kioslaverc --group "Proxy Settings" --key httpProxy $proxyUrl
        & $kwriteconfig --file kioslaverc --group "Proxy Settings" --key httpsProxy $proxyUrl
        & $kwriteconfig --file kioslaverc --group "Proxy Settings" --key ftpProxy $proxyUrl
        & $kwriteconfig --file kioslaverc --group "Proxy Settings" --key socksProxy $proxyUrl
        & $kwriteconfig --file kioslaverc --group "Proxy Settings" --key NoProxyFor $IgnoreHosts

        Write-Verbose "KDE: Manual proxy settings applied."
        Write-Verbose "Proxy IP: $ProxyIP"
        Write-Verbose "Proxy Port: $ProxyPort"
        Write-Verbose "Ignored Hosts: $IgnoreHosts"
    }
    elseif ($Mode -eq "none") {
        & $kwriteconfig --file kioslaverc --group "Proxy Settings" --key ProxyType 0
        Write-Error "KDE: Proxy disabled."
    }

    & dbus-send --type=signal /KIO/Scheduler org.kde.KIO.Scheduler.reparseSlaveConfiguration 'string:'
}

function Get-DesktopEnvironment {
    if (($env:XDG_CURRENT_DESKTOP -like "*GNOME*") -or ($env:XDG_SESSION_DESKTOP -like "*GNOME*")) { return "gnome" }
    if (($env:XDG_CURRENT_DESKTOP -like "*XFCE*") -or ($env:XDG_SESSION_DESKTOP -like "*XFCE*")) { return "gnome" }
    if (($env:XDG_CURRENT_DESKTOP -like "*X-Cinnamon*") -or ($env:XDG_SESSION_DESKTOP -like "*cinnamon*")) { return "gnome" }
    if (($env:XDG_CURRENT_DESKTOP -like "*UKUI*") -or ($env:XDG_SESSION_DESKTOP -like "*ukui*")) { return "gnome" }
    if (($env:XDG_CURRENT_DESKTOP -like "*DDE*") -or ($env:XDG_SESSION_DESKTOP -like "*dde*")) { return "gnome" }
    if (($env:XDG_CURRENT_DESKTOP -like "*MATE*") -or ($env:XDG_SESSION_DESKTOP -like "*mate*")) { return "gnome" }

    foreach ($de in @("KDE", "plasma")) {
        if (($env:XDG_CURRENT_DESKTOP -eq $de) -or ($env:XDG_SESSION_DESKTOP -eq $de)) {
            return "kde"
        }
    }

    if (Get-Command gsettings -ErrorAction SilentlyContinue) {
        return "gnome"
    }

    return "unsupported"
}

if (-not $Mode) {
    Write-Verbose "Usage: ./proxy_set_linux.ps1 <mode> [proxy_ip proxy_port ignore_hosts]"
    Write-Verbose "  mode: 'none' or 'manual'"
    Write-Verbose "  If mode is 'manual', provide proxy IP, port, and ignore hosts."
    exit 1
}

if ($Mode -notin @("manual", "none")) {
    Write-Error "Invalid mode. Use 'none' or 'manual'."
    exit 1
}

$de = Get-DesktopEnvironment

if ($de -eq "gnome") {
    Set-GnomeProxy -Mode $Mode -ProxyIP $ProxyIP -ProxyPort $ProxyPort -IgnoreHosts $IgnoreHosts
}
elseif ($de -eq "kde") {
    Set-GnomeProxy -Mode $Mode -ProxyIP $ProxyIP -ProxyPort $ProxyPort -IgnoreHosts $IgnoreHosts
    Set-KdeProxy -Mode $Mode -ProxyIP $ProxyIP -ProxyPort $ProxyPort -IgnoreHosts $IgnoreHosts
}
else {
    Write-Error "Unsupported desktop environment: $de"
    exit 1
}
