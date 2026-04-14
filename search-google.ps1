  function search-google {
      param(
          [Parameter(ValueFromPipeline=$true)]
          [string[]]$searchkey,
          [int]$Delay = 500
      )
      process {
          foreach ($key in $searchkey) {
              if ($key) {
                  # Linux: xdg-open 打开浏览器，进程独立
                  xdg-open "https://www.google.com/search?q=$key">/dev/null
                  Start-Sleep -Milliseconds $Delay
              }
          }
          
      }
  }
set-alias -name google -value search-google
