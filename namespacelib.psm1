# 属性（不用括号）
[System.Int32]::MinValue
# -2147483648

[System.Int32]::MaxValue
# 2147483647

[System.Double]::Pi
# 3.14159265358979

[System.Math]::PI
# 3.14159265358979

[System.Math]::Tau
[System.Math]::E
# 常用静态属性：

[System.Int32]::MinValue    # 最小值
[System.Int32]::MaxValue    # 最大值
[System.Double]::NaN        # 非数字
[System.DateTime]::Now     # 当前时间
[System.DateTime]::Today   # 今天日期

# 常用静态方法：

[System.Math]::Abs(-5)        # 绝对值
[System.Math]::Floor(3.14)   # 向下取整
[System.Math]::Ceiling(3.14) # 向上取整
[System.Math]::Round(3.14)   # 四舍五入
[System.Math]::Sqrt(16)       # 平方根
[System.Math]::Pow(2, 3)      # 2^3 = 8


[System.Math]::Exp(1)      # e的指数次方
[System.Math]::Log(8, 2)   # 以2为底8的对数
[System.Math]::Max(3, 5)  # 最大值
[System.Math]::Min(3, 5)  # 最小值

function log { param([double]$x) [System.Math]::Log($x) }
function log10 { param([double]$x) [System.Math]::Log10($x) }
function exp { param([double]$x) [System.Math]::Exp($x) }
function pow { param([double]$x, [double]$y) [System.Math]::Pow($x, $y) }
function sqrt { param([double]$x) [System.Math]::Sqrt($x) }
function abs { param([double]$x) [System.Math]::Abs($x) }
function round { param([double]$x) [System.Math]::Round($x) }
function floor { param([double]$x) [System.Math]::Floor($x) }
function ceiling { param([double]$x) [System.Math]::Ceiling($x) }
function max { param([double]$x, [double]$y) [System.Math]::Max($x, $y) }
function min { param([double]$x, [double]$y) [System.Math]::Min($x, $y) }
Export-ModuleMember -Function log, log10, exp, pow, sqrt, abs, round, floor, ceiling, max, min