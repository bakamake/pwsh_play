function Get-Translate {
    param
    (
        [Parameter(ValueFromPipeline=$true)]
        $string,
        [string]$To = "zh"
    )

   $lang = @{ zh = "中文"; en = "英文"; ja = "日文"; ko = "韩文" }[$To]
   $result = claude -p "把以下内容翻译成$lang： $string"
   $result
}
