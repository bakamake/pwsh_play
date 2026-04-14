function get-notbincontent{ $input| Where-Object {
      $isBinary = $false
      $stream = [System.IO.File]::OpenRead($_.FullName)
      $buffer = New-Object byte[] 8192
      while ($stream.Read($buffer, 0, $buffer.Length) -gt 0) {
          if ($buffer -contains 0) {
              $isBinary = $true
              break
          }
      }
      $stream.Close()
      -not $isBinary
  } }
