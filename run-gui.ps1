function run-gui {

    param([string]$App)
    bash -c "setsid $App &>/dev/null & disown; exit" > /dev/null 2>&1
    #有一些gui不想占着shell不放，懒得多开几个shell，管理器来也麻烦，用bash一些机制让他回归到systemd父进程，这样kill shell 就不会kill gui了

}
