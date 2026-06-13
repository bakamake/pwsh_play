#!/usr/bin/env pwsh
# 缓存清理脚本 - 汇总报告 + 执行清理

$ErrorActionPreference = 'Stop'

$targets = @(
    @{ Name = "Trash";              Path = "$env:HOME/.local/share/Trash";   Sudo = $false }
    @{ Name = "Chromium Downloads"; Path = "$env:HOME/Downloads/chromium";   Sudo = $false }
    @{ Name = "NuGet cache";        Path = "$env:HOME/.nuget/packages";      Sudo = $false }
    @{ Name = "Gradle cache";       Path = "$env:HOME/.gradle";              Sudo = $false }
    @{ Name = "Zen cache";          Path = "$env:HOME/.cache/zen";           Sudo = $false }
    @{ Name = "JetBrains cache";    Path = "$env:HOME/.cache/JetBrains";     Sudo = $false }
)

Write-Host "=== 扫描缓存大小 ===" -ForegroundColor Cyan
$totalBefore = 0
$results = @()

foreach ($t in $targets) {
    if (Test-Path $t.Path) {
        $size = & { du -sb $t.Path 2>$null | ForEach-Object { [int64]($_ -split "\s+")[0] } } | Select-Object -First 1
        if (-not $size) { $size = 0 }
    } else {
        $size = 0
    }
    $totalBefore += $size
    $results += [PSCustomObject]@{ Name = $t.Name; Path = $t.Path; SizeBefore = $size; Exists = (Test-Path $t.Path) }
}

foreach ($r in $results) {
    $sizeStr = if ($r.SizeBefore -gt 1GB) { "{0:F1} GB" -f ($r.SizeBefore / 1GB) }
              elseif ($r.SizeBefore -gt 1MB) { "{0:F1} MB" -f ($r.SizeBefore / 1MB) }
              else { "{0} B" -f $r.SizeBefore }
    $status = if ($r.Exists) { "存在" } else { "已删除" }
    Write-Host "  $($r.Name): $sizeStr [$status]" -ForegroundColor $(if ($r.Exists) { 'Yellow' } else { 'DarkGray' })
}

if ($totalBefore -eq 0) {
    Write-Host "`n所有缓存已清理，无需操作。" -ForegroundColor Green
    exit 0
}

$totalStr = if ($totalBefore -gt 1GB) { "{0:F1} GB" -f ($totalBefore / 1GB) } else { "{0:F1} MB" -f ($totalBefore / 1MB) }
Write-Host "`n总计可回收: $totalStr" -ForegroundColor Yellow

# 执行清理
Write-Host "`n=== 执行清理 ===" -ForegroundColor Cyan
foreach ($t in $targets) {
    if (-not (Test-Path $t.Path)) { continue }
    if ($t.Sudo) {
        Write-Host "  sudo rm -rf $($t.Path)"
        sudo rm -rf $t.Path
    } else {
        Write-Host "  rm -rf $($t.Path)"
        Remove-Item -Recurse -Force $t.Path -ErrorAction Continue
    }
}

# 验证
Write-Host "`n=== 清理结果 ===" -ForegroundColor Cyan
$remaining = 0
foreach ($t in $targets) {
    if (Test-Path $t.Path) {
        $s = & { du -sb $t.Path 2>$null | ForEach-Object { [int64]($_ -split "\s+")[0] } } | Select-Object -First 1
        if ($s) { $remaining += $s }
        Write-Host "  $($t.Name): 残留" -ForegroundColor Red
    } else {
        Write-Host "  $($t.Name): 已清理" -ForegroundColor Green
    }
}

$freed = $totalBefore - $remaining
$freedStr = if ($freed -gt 1GB) { "{0:F1} GB" -f ($freed / 1GB) } else { "{0:F1} MB" -f ($freed / 1MB) }
Write-Host "`n释放: $freedStr" -ForegroundColor Green

# Podman
Write-Host "`n=== Podman 清理 ===" -ForegroundColor Cyan
$images = podman images -q 2>$null
$containers = podman ps -aq 2>$null
if ($containers) {
    Write-Host "  删除 $($containers.Count) 个停止容器..."
    podman rm $containers 2>$null
}
if ($images) {
    Write-Host "  删除 $($images.Count) 个镜像..."
    podman rmi $images 2>$null
}
Write-Host "  Podman 清理完成" -ForegroundColor Green

# APT
Write-Host "`n=== APT 缓存 ===" -ForegroundColor Cyan
sudo apt-get clean 2>$null
Write-Host "  apt-get clean 完成" -ForegroundColor Green

# 最终磁盘
Write-Host "`n=== 磁盘状态 ===" -ForegroundColor Cyan
df -h /
