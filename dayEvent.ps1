Add-Type -TypeDefinition @'
using System;

public class DayEvent {
    public string name;
    public bool state;
    public DateTime DateTime;

    public DayEvent(string name) {
        this.name = name;
        this.state = false;
        this.DateTime = DateTime.Now;
    }
}
'@
# Add-Type -TypeDefinition @'
#    using System;
#    public struct DayEvent {
#        public bool state;
# 	       public System.DateTime DateTime;
#    }
# '@
$dayredo = [System.Collections.Generic.Dictionary[string, [DayEvent]]]::new()
$daytodo = [System.Collections.Generic.Dictionary[string, [DayEvent]]]::new()
$daydone = [System.Collections.Generic.Dictionary[string, [DayEvent]]]::new()
$dayundo = $daytodo
function Add-Todo($name) {
    $daytodo[$name] = [DayEvent]::new($name)
}
# 完成（移到done）
function Done-Todo($name) {
    if ($daytodo.ContainsKey($name)) {
        $daydone[$name] = $daytodo[$name]
        $daytodo.Remove($name)
    }
}
# 撤销（done -> todo）
function Undo {
    $last = $daydone.GetEnumerator() | Select-Object -Last 1
    if ($last) {
        $daytodo[$last.Key] = $last.Value
        $daydone.Remove($last.Key)
    }
}
  function get-todoplan {
      [CmdletBinding()]
      param()

      $result = @()

      foreach ($k in $daytodo.Keys) {
          $result += [PSCustomObject]@{
              Name = $k
              Time = $daytodo[$k].DateTime.ToString("HH:mm")
              Status = "todo"
          }
      }

      foreach ($k in $daydone.Keys) {
          $result += [PSCustomObject]@{
              Name = $k
              Time = $daydone[$k].DateTime.ToString("HH:mm")
              Status = "done"
          }
      }

      $result
}
#   进行get-操作再临时构建一个对象，有利于接口的标准和稳定，以及get-操作和系统的解耦，不需要再在写整个程序时一直考虑数据的“观赏性”
#   好处：
#	1. 数据层和展示层分离 — 数据用 HashTable 高效存储，展示用 PSCustomObject 格式化
#	2. 接口稳定 — 以后想改显示格式，不用改底层数据结构
#	3. 解耦 — 写逻辑专注业务，get 专注展示
#	这是 MVC 思想的简化版：Model（HashTable）+ Controller（函数）+ View（get-todoplan）
function set-todoplan  {
	$Args  | foreach-object{Add-Todo $_}
}
set-todoplan 洗衣服 晾衣服 锻炼
#todo : (write new function set-todotime)/(contuine to write set-todoplan make plan command "plan") 
function set-todotime {
    param(
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$Args
    )

    $time = $null

    foreach ($a in $Args) {
        if ($a -match '^(\d{1,2}):(\d{2})$') {
            $time = Get-Date $a
        } elseif ($time -and $daytodo.ContainsKey($a)) {
            $e = $daytodo[$a]
            $e.DateTime = $time
            $daytodo[$a] = $e
        }
    }
}
