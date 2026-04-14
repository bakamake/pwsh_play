  function export {
      $args | ForEach-Object {
          $parts = $_.split('=', 2)
          if ($parts.Count -eq 2) {
              Set-Item -Path "env:$($parts[0])" -Value $parts[1]
          }
      }
  }
