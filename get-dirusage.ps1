function get-dirusage{sudo du -hcxad 1  $args| sort -hr}
set-alias -name du -value get-dirusage

