function Get-dotnetapi {
    param($url = "https://api.github.com/repos/dotnet/dotnet-api-docs/contents/xml?ref=main")
$status = ([string](gh auth status) -contains "true")
if($status){}else{}
    $items = (gh api $url | ConvertFrom-Json)
    foreach($item in $items) {
        if($item.type -eq "dir") {
            Get-dotnetapi -url $item.url
        } else {
            $item.name
        }
    }
}
