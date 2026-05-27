function Get-AptUpdatable {
    class PackageInfo {
        [string]$Name
        [boolean]$IsAuto
    }
    $packages = aptitude search '~U' -F “%p”

    return $packages
}

if (((Get-Process pwsh).Count -eq 1) -and ($HOME -ne '/root')) {
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
          'purge' {
            sudo aptitude @fullArgs
          }
          default {
              sudo aptitude @fullArgs
          }
          }
  }
set-alias apt-get apt


function dpkg {
        [CmdletBinding()]
    param(
                [Parameter(Mandatory, Position = 0,ParameterSetName = 'Command')]
                [ValidateSet('install','unpack','record-avail','configure','search','triggers-only','remove','purge','verify','get-selections','set-selections','clear-selections','update-avail','merge-avail','clear-avail','forget-old-unavail','status','print-avail','listfiles','list','audit','yet-to-unpack','predep-package','add-architecture','remove-architecture','print-architecture','print-foreign-architectures','assert','validate','compare-versions','force-help','debug=help','help','version')]
                [string]$Command,
                [Parameter(ValueFromPipeline)]
                [object[]]$Args,
                [Parameter(ValueFromRemainingArguments)]
                [string[]]$RemainingArgs,
                [Parameter(ParameterSetName = 'Option')]
                [ValidateSet('admindir','root','instdir','pre-invoke','post-invoke','path-exclude','path-include','selected-only','skip-same-version','refuse-downgrade','auto-deconfigure','triggers','no-triggers','verify-format','no-pager','no-debsig','simulate','debug','status-fd','status-logger','log','ignore-depends','force','no-force','refuse','abort-after')]
                [string]$option
        )
    process{
        $dpkg = "/usr/bin/dpkg"
        [string[]]$sudoCommand = @('install','remove','purge')
    $sudo = ''
    if ($Command -in $sudoCommand) { $sudo = 'sudo' }
        if($option){
                $options = '--'+$option
        }
        Invoke-Expression "$sudo $dpkg --$Command $options @Args @RemainingArgs"
    }
}


















# showrecommend
# (apt show kubuntu-desktop|grep ^Recommends:).Replace("Recommends:","").Trim().Split(", ")
# showdepend
# (apt show kubuntu-desktop|grep ^Depends:).Replace("Depends:","").Trim().Split(", ")
