
_kmpkg_completions()
{
  local kmpkg_executable=${COMP_WORDS[0]}
  local remaining_command_line=${COMP_LINE:(${#kmpkg_executable}+1)}
  COMPREPLY=($(${kmpkg_executable} autocomplete "${remaining_command_line}" -- 2>/dev/null))
}

complete -F _kmpkg_completions kmpkg
