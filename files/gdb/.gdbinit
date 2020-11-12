set history save on
set history size 1000
set history filename ~/.gdb_history
define qquit
  set confirm off
  quit
end
document qquit
Quit without asking for confirmation.
end

# Set the focus on the commandline (if tui mode was on)
focus cmd
