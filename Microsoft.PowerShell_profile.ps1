$env:EDITOR = "micro"
# 禁用终端的 bracketed paste 模式，ghostty terminal 对这个功能没有兼容标准
printf '\e[?2004l'


# 用 Set-Clipboard 代替 [Microsoft.PowerShell.PSConsoleReadLine]::Copy and Cut
# 解决旧版本 (latest released version) bug
# https://github.com/PowerShell/PowerShell/issues/26577
Remove-PSReadLineKeyHandler -Chord Escape
Remove-PSReadLineKeyHandler Ctrl+c
Set-PSReadLineKeyHandler -Key Ctrl+c -ScriptBlock {
    $start = $null
    $length = $null
    $line = $null
    $cursor = $null

    [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$start, [ref]$length)
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    if ($length -gt 0 -and $start -ne $null) {
        $selected = $line.Substring($start, $length)
        Set-Clipboard -Value $selected
        [Microsoft.PowerShell.PSConsoleReadLine]::Paste
    }
}

Remove-PSReadLineKeyHandler Ctrl+x
Set-PSReadLineKeyHandler -Key Ctrl+x -ScriptBlock {
    $start = $null
    $length = $null
    $line = $null
    $cursor = $null

    [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$start, [ref]$length)
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    if ($length -gt 0 -and $start -ne $null) {
        $selected = $line.Substring($start, $length)
        Set-Clipboard -Value $selected
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace($start, $length, '')
    }
}
# 运行辅助函数，有一些gui不想占着shell不放，懒得多开几个shell，管理器来也麻烦，用bash一些机制让他回归到systemd父进程，这样kill shell 就不会kill gui了
. ~/dev/pwsh_play/run-gui.ps1
#package manager
########################################################################

function Get-AptUpdatable {
    class PackageInfo {
        [string]$Name
        [boolean]$IsAuto
    }
    $packages = aptitude search '~U' -F “%p”

    return $packages
}
 
if ((Get-Process pwsh).Count -eq 1) {
    Get-AptUpdatable
}

function apt {
      [CmdletBinding()]
      param(
          [Parameter(Position = 0)]
          [ValidateSet('install','remove','update', 'upgrade', 
          				'list', 'search', 'show', 
          				'purge','autoremove','full-upgrade','safe-upgrade',
          				'modernize-sources',
          				'why','why-not','automark',
          				'listfiles')]
          [string]$Command,
          [Alias('y')][switch]$yes,
          [Alias('s')][switch]$simulate,
          [Alias('i')][switch]$installed,
          [Alias('u')][switch]$upgradable,
          [Alias('a')][switch]$all,
          [Alias('r')][switch]$recommend,
          [Alias('d')][switch]$depend,
          [Parameter(ValueFromRemainingArguments,ValueFromPipeline)]
          [string[]]$Arg
      )

      # 没指定 Command 时，直接透传
      if (-not $Command) {
          sudo apt @Arg
          return
      }

      # 通用处理
      $fullArgs = @($Command)

      if ($yes -and $Command -in @('install', 'remove', 'purge', 'autoremove')) {
          $fullArgs += '-y'
      }
      if ($simulate) { $fullArgs += '--simulate' }
      if ($installed) { $fullArgs += '--installed' }
      if ($upgradable) { $fullArgs += '--upgradable' }
      if ($all) { $fullArgs += '-a' }

      $fullArgs += $Arg

      # 特殊处理分支
      switch ($Command) {
          'automark' {
              Write-Host "pre" -ForegroundColor Blue
              $premanual = apt-mark showmanual
              $premanual.Count
              $action = if ($simulate) { { $_ | Select-String 'because|^[0-9]+' } } else { { $_ | Select-String 'because' | ForEach-Object -Parallel { sudo apt-mark auto (($_.Line -split ' ')[0]) } } }

              $i = 0
              for (;;) {
                  Write-Host -NoNewline "`r`e[2K $($i+1) / $($premanual.Count) : $($premanual[$i])"
                  /bin/apt why $premanual[$i++] 2>$null | & $action
              }

              Write-Host "now" -ForegroundColor Blue
              (apt-mark showmanual).count
              return
          }
          {$_ -in 'modernize-sources','autoremove'} {
          	sudo apt @fullArgs
          	return
          }
          'listfiles'{
          	dpkg @fullArgs
			return
          }
          'show'{
          	if($recommend){
          	
				(aptitude @fullArgs | sls '^(Recommends:|推荐:)').Line |
				ForEach-Object { $_ -replace '^(Recommends:|推荐:)\s*', '' } |
				ForEach-Object { $_ -split ',' } |
				ForEach-Object { $_ -split '\|' } |
				ForEach-Object { ($_ -replace '\s*\(.*?\)', '').Trim() }
          		# (/bin/apt @fullArgs |sls '推荐:').Line.Replace(' ','').Split(',').Trim()
          		return
          	}elseif($depend){
				(aptitude @fullArgs | sls '^(Depends:|依赖:|依赖于:)').Line |
				ForEach-Object { $_ -replace '^(Depends:|依赖:|依赖于:)\s*', '' } |
				ForEach-Object { $_ -split ',' } |
				ForEach-Object { $_ -split '\|' } |
				ForEach-Object { ($_ -replace '\s*\(.*?\)', '').Trim() } 
          		# (/bin/apt @fullArgs |sls '依赖:|Depends: ').Line.Replace('依赖: ','').Replace('Depends: ','').Replace('依赖于: ','').Split(',').Trim()
				return
          }else{
	          	/bin/apt @fullArgs
	          	return
          }
          }
          'search' {
			if($recommend -or $depend){
				$searchall = aptitude search '~n.'
				if($recommend){
					$names = @(apt show $Arg -recommend | Where-Object { $_.Trim() })
					$pattern = ($names | ForEach-Object { [regex]::Escape($_) }) -join '|'	
					$searchall | Select-String "^\S+(?:\s+\S+)?\s+($pattern)\s+-" -NoEmphasis
					return
				}else{
					$names = @(apt show $Arg -depend | Where-Object { $_.Trim() })
					$pattern = ($names | ForEach-Object { [regex]::Escape($_) }) -join '|'	
					$searchall | Select-String "^\S+(?:\s+\S+)?\s+($pattern)\s+-" -NoEmphasis
					return
				}
			}else{
			aptitude @fullArgs
			}
          }
          default {
              sudo aptitude @fullArgs
          }
          }
  }

function dpkg{
	[CmdletBinding()]
    param(
		[Parameter(Mandatory, Position = 0,ParameterSetName = 'Command')]
		[ValidateSet('install','unpack','record-avail','configure','search','triggers-only','remove','purge','verify','get-selections','set-selections','clear-selections','update-avail','merge-avail','clear-avail','forget-old-unavail','status','print-avail','listfiles','list','audit','yet-to-unpack','predep-package','add-architecture','remove-architecture','print-architecture','print-foreign-architectures','assert','validate','compare-versions','force-help','debug=help','help','version')]
		[string]$Command,
		[Parameter(ValueFromPipeline = $true,ValueFromRemainingArguments = $true, ParameterSetName = 'Command')]
		[object[]]$Args,
		[Parameter(ParameterSetName = 'Option')]
		[ValidateSet('admindir','root','instdir','pre-invoke','post-invoke','path-exclude','path-include','selected-only','skip-same-version','refuse-downgrade','auto-deconfigure','triggers','no-triggers','verify-format','no-pager','no-debsig','simulate','debug','status-fd','status-logger','log','ignore-depends','force','no-force','refuse','abort-after')]
    		[string]$option
	)
    # $dpkg = "/usr/bin/dpkg" 
	[string[]]$sudoCommand = @('install','remove','purge')
    $cmd = if ($Command -in $sudoCommand) { 'sudo' , "/usr/bin/dpkg"} else {"/usr/bin/dpkg"}
	if($option){
		$options = '--'+$option
	}
	& @cmd --$Command $options @Args
}

function search-ico { fdfind -a -HI -t f -e desktop . /usr/share/applications ~/.local/share/applications /var/lib/flatpak/exports/share/applications ~/.local/share/flatpak/exports/share/applications 2>$null|Get-Item|sls $args}

# package manager end
#####################################
# dotnet env manager

function get-namespace{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory , Position = 0 , ParameterSetName = 'ByNamespace')]
		[string]$namespace
	)
	 [System.AppDomain]::CurrentDomain.GetAssemblies() |
      ForEach-Object -Parallel { $_.GetTypes() } |
      Where-Object { $_.Namespace -eq $namespace } |
      Select-Object Name|Sort-Object Name
}


######################################################

# 使用 VS Code PowerShell Light+ 语法高亮配色，浅色主题适用
$PSReadLineOptions = @{
	EditMode = "Windows"
	ContinuationPrompt = ' '
	Colors = @{
	    Keyword                = $PSStyle.Foreground.FromRGB(0x795E26)  # 棕色
	    String                 = $PSStyle.Foreground.FromRGB(0xA31515)  # 深红
	    Command                = $PSStyle.Foreground.FromRGB(0x001EDD)  # 蓝色
	    Parameter              = $PSStyle.Foreground.FromRGB(0x9A9A9A)  # 灰色
	    Variable               = $PSStyle.Foreground.FromRGB(0x0451A5)  # 深蓝
	    Number                 = $PSStyle.Foreground.FromRGB(0x098658)  # 绿色
	    Member                 = $PSStyle.Foreground.FromRGB(0x567A46)  # 橄榄绿
	    Type                   = $PSStyle.Foreground.FromRGB(0x267F99)  # 青色
	    Comment                = $PSStyle.Foreground.FromRGB(0x5A9D4B)  # 绿色注释
	    Default                = $PSStyle.Foreground.FromRGB(0x000000)
	    ListPredictionSelected = $PSStyle.Background.FromRGB(0x3A3A3A)
	    ListPredictionTooltip  = $PSStyle.Foreground.FromRGB(0x888888)
	    InlinePrediction       = $PSStyle.Foreground.FromRGB(0x888888)
	    ContinuationPrompt     = $PSStyle.Foreground.FromRGB(0xAAAAAA)
	    Emphasis               = $PSStyle.Foreground.FromRGB(0x795E26)
		Error                     = $PSStyle.Foreground.FromRGB(0xFF0000)  # 红色错误
        Selection                 = $PSStyle.Background.FromRGB(0xADD8E6)  # 浅蓝选中
        Operator                  = $PSStyle.Foreground.FromRGB(0x808080)  # 灰色操作符
	}
}
Set-PSReadLineOption @PSReadLineOptions

########################################################################################
#网络
if (!(Get-Process v2rayN -ErrorAction SilentlyContinue) -or (Get-Process mihomo -ErrorAction SilentlyContinue)) {
    Get-ChildItem Env: | Where-Object { $_.Name -like "*proxy*" } | Remove-Item
    Get-ChildItem Env: | Where-Object { $_.Name -like "*proxy*" }
}else{
	$env:http_proxy='http://127.0.0.1:10808'
	$env:https_proxy='http://127.0.0.1:10808'
	$env:all_proxy='socks5://127.0.0.1:10808'
	$env:HTTP_PROXY='http://127.0.0.1:10808'
	$env:HTTPS_PROXY='http://127.0.0.1:10808'
	$env:ALL_PROXY='socks5://127.0.0.1:10808'
}

# 校园网内网登陆跳转地址查询
  try {
      $r = Invoke-WebRequest google.com -TimeoutSec 2 -Proxy $null -ErrorAction Stop 
  } catch {
      Write-Host "网络不通，需要登录校园网"
      # 获取跳转地址
      $req = [Net.HttpWebRequest]::Create("http://10.26.192.3")
      $req.Timeout = 1000
      $req.Proxy = $null
      $req.AllowAutoRedirect = $false
      $resp = $req.GetResponse()
      if ($resp.Headers["Location"]) {
          xdg-open "http://baidu.com" &
      }
      $resp.Close()
  }
# 配置代理
~/dev/pwsh_play/proxy_set_linux_sh.ps1 manual 127.0.0.1 10808 "localhost,127.0.0.1,::1"

function claude {
    & {
        # 查找真实的程序路径
        $realClaude = Get-Command -Name "claude" -CommandType Application -ErrorAction SilentlyContinue

        if ($realClaude) {
            # 内部直接用 @args，因为它现在接收到了外部传进来的值
            & $realClaude @args
        }
        else {
            Write-Error "找不到 claude 可执行程序。"
        }
    } @args
    printf '\e[?2004l'
}

function Get-CommandParameters {
    (Get-Command @args).Parameters.Keys
}

function mem {
    # 定义监控目标及其匹配模式
    $targets = @{
        'chrome'  = 'chrome'
        'firefox' = 'firefox'
        'wechat'  = 'wechat'
        'wine'    = 'wine|wineserver|\.exe'  # 匹配 wine 核心及所有 windows 程序
        'qemu'    = 'qemu|kvm'
        'code'    = 'code'
        'pwsh'    = 'pwsh|bash'
        'emacs'   = 'emacs'
        'claude'  = 'claude'
        'ghostty' = 'ghostty'
        'micro'   = 'micro'
    }

    $allProcs = Get-Process | Where-Object Path -ne $null

    $targets.Keys | ForEach-Object {
        $key = $_
        $pattern = $targets[$key]
        $procs = $allProcs | Where-Object {
            $_.Path -match "\b$pattern\b" -or $_.ProcessName -match $pattern
        }

        $bytes = ($procs | Measure-Object WS -Sum).Sum

        if ($bytes -gt 0) {
            [pscustomobject]@{
                Process = $key
                RawSize = $bytes
            }
        }
    } | Sort-Object RawSize -Descending | Select-Object Process, @{
        Name = 'MemoryUsage'
        Expression = {
            if ($_.RawSize -ge 1GB) {
                "{0:N2} GB" -f ($_.RawSize / 1GB)
            }
            else {
                "{0:N2} MB" -f ($_.RawSize / 1MB)
            }
        }
    } | Format-Table -AutoSize
}

function win10 {
    virsh start win10
	$cmd = 'virt-manager'
	Run-GUI $cmd 
}

function Get-SharedLibrary {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            ValueFromRemainingArguments = $true  # 关键：允许空格分隔多个路径
        )]
        [string[]]$Path
    )

    process {
        # 必须循环，以防 $Path 是作为一个数组传入的
        foreach ($singlePath in $Path) {
            # 解析路径（处理通配符和相对路径）
            $resolvedPaths = Resolve-Path $singlePath -ErrorAction SilentlyContinue

            foreach ($item in $resolvedPaths) {
                $fullPath = $item.Path
                if (Test-Path $fullPath -PathType Leaf) {

                    ldd $fullPath 2>$null | ForEach-Object {
                        # 情况 A: 正常找到库 => lib名称 => 路径
                        if ($_ -match '^\s+(?<lib>[^ ]+)\s+=>\s+(?<path>[^ ]+)') {
                            [PSCustomObject]@{
                                Binary  = Split-Path $fullPath -Leaf
                                Library = $Matches.lib
                                LibPath = $Matches.path
                                Status  = "OK"
                            }
                        }
                        # 情况 B: 库缺失 => lib名称 => not found
                        elseif ($_ -match '^\s+(?<lib>[^ ]+)\s+=>\s+not found') {
                            [PSCustomObject]@{
                                Binary  = Split-Path $fullPath -Leaf
                                Library = $Matches.lib
                                LibPath = "NOT FOUND"
                                Status  = "Missing"
                            }
                        }
                    }
                }
            }
        }
    }
}

function rm-safe { trash-put $args }
Set-Alias -Name rm -Value rm-safe -Option ReadOnly -Force
Set-Alias -Name file -Value spf -Option ReadOnly -Force
Set-Alias -Name ls -Value Get-ChildItem

function fl {
    Format-Table -AutoSize -Wrap @args
}

function exp {
    xdg-open @args > /dev/null 2>&1
    $snap = (Get-Process *dolphin*).Id
    do {
        $live = (Get-process *dolphin*).Id
    } while ($snap -bxor $live)
    Write-Host ""
}

function Add-DirectoryToPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias("FullName")]
        [string]$path,
        [string]$variable = "PATH",

        [switch]$clear,
        [switch]$force,
        [switch]$prepend,
        [switch]$whatIf
    )

    begin {
        # normalize paths
        $count = 0
        $paths = @()

        if (-not $clear.IsPresent) {
            $environ = Invoke-Expression "`$Env:$variable"
            if ($psVersionTable.Platform -eq "Unix") {
                $environ.Split(":") | ForEach-Object {
                    if ($_.Length -gt 0) {
                        $count = $count + 1
                        $paths += $_.ToLowerInvariant()
                    }
                }
            }
            Write-Verbose "Currently $($count) entries in `$env:$variable"
        }

        function Array-Contains {
            param(
                [string[]]$array,
                [string]$item
            )

            $any = $array | Where-Object -FilterScript {
                $_ -eq $item
            }

            Write-Output ($null -ne $any)
        }
    }

    process {
        # Using [IO.Directory]::Exists() instead of Test-Path for performance purposes
        if ([IO.Directory]::Exists($path) -or $force.IsPresent) {
            $path = $path.Trim()

            $newPath = $path.ToLowerInvariant()
            if (-not (Array-Contains -Array $paths -Item $newPath)) {
                if ($whatIf.IsPresent) {
                    Write-Host $path
                }

                if ($prepend.IsPresent) { $paths = , $path + $paths }
                else { $paths += $path }

                Write-Verbose "Adding $($path) to `$env:$variable"
            }
        }
        else {
            Write-Host "Invalid entry in `$Env:$($variable): ``$path``" -ForegroundColor Yellow
        }
    }

    end {
        # re-create PATH environment variable
        $separator = [IO.Path]::PathSeparator
        $joinedPaths = [string]::Join($separator, $paths)

        if ($whatIf.IsPresent) {
            Write-Output $joinedPaths
        }
        else {
            Invoke-Expression " `$env:$variable = `"$joinedPaths`" "
        }
    }
}

function man {
    /bin/man @args | fl|grep '-'
}

function Invoke-Idf {
	if((get-item /dev/*USB*).UnixMode -ne 'crw-rw-rw-'){sudo chmod 666 /dev/ttyUSB0}
    bash -c "source /home/bakamake/dev/esp-idf/export.sh 1>&/dev/null && idf.py $args"
}
set-alias -name idf.py -value Invoke-Idf -Scope Global -Force
set-alias -name idf -value Invoke-Idf -Scope Global -Force

function Invoke-conda {
	remove-alias -name conda -Scope Global -Force	
    & "$HOME/.local/miniforge3/bin/conda" shell.powershell hook | Out-String | Invoke-Expression
    conda @args
}
set-alias -name conda -value Invoke-conda -Scope Global -Force
# 用  Get-Content 做cat ，用micro 做code 和nano
Set-Alias cat Get-Content
set-alias -name code -value micro
set-alias -name nano -value micro

npm config set prefix "~/.local/share/npm"
$env:PATH += ":" + "$HOME/.local/share/npm/bin"
$env:PATH += ":" + "$HOME/dev/lsp-bridge/python-lsp-bridge"

$env:PWSH_PLAY_PATH = Join-Path $HOME 'dev/pwsh_play'
. $env:PWSH_PLAY_PATH/get-Speak.ps1
. $env:PWSH_PLAY_PATH/get-function.ps1
. $env:PWSH_PLAY_PATH/Get-ChildNamespace.ps1
. $env:PWSH_PLAY_PATH/bash-env.ps1
# steam 启动脚本修改： 变成 系统默认终端
if(test-path /bin/steam){$terminal = Select-String xterm -path /bin/steam;if($terminal.count -ne 0){'steam 依赖于 xtrem'} }
# 
# 
# # 安卓
# # sudo apt install default-jdk
# $env:JAVA_HOME='/usr/lib/jvm/java-21-openjdk-amd64'
# # android sdk
# $env:ANDROID_HOME='~/Android/Sdk'
# $env:ANDROID_SDK_ROOT='~/Android/Sdk'
# # $env:ANDROID_USER_HOME='~/Android'# ANDROID_EMULATOR_HOME default eq ANDROID_USER_HOME  # ANDROID_AVD_HOME default eq  ANDROID_EMULATOR_HOME/avd/
# 
# $env:PATH += ":$env:JAVA_HOME/bin"
# $env:PATH += ":$env:ANDROID_HOME/emulator"
# $env:PATH += ":$env:ANDROID_USER_HOME/cmdline-tools/bin"
# 

# pwsh 终端设置
$Env:POWERSHELL_UPDATECHECK = 'Off'
$Env:POWERSHELL_TELEMETRY_OPTOUT = 1

# 最后的变量检查和去重
function set-envpathunique {
	$paths = (ls env:PATH ).value.split(":")
	$counts = @{}
	foreach ($p in $paths) {
	    $counts[$p] = ($counts[$p] ?? 0) + 1
	}
	
	foreach ($entry in $counts.GetEnumerator()) {
	    if ($entry.Value -gt 1) {
	        Write-Host "重复: $($entry.Key)"
	    }
	}
	
	
	
	$env:PATH = [system.Linq.Enumerable]::Distinct([System.Linq.Enumerable]::Order([string[]]$env:PATH.split(":"))) -join ':'
}
set-envpathunique

. ~/dev/pwsh_play/Import-Bashenv.ps1
Set-Alias -name code -value kate
Set-Alias -name vim -value micro
Set-Alias -name nano -value micro
Set-Alias -name gedit -value micro

