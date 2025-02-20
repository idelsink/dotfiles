#!/usr/bin/env bash

# https://www.gnu.org/software/bash/manual/html_node/Bash-Variables.html#index-HISTSIZE
# Increase history
HISTSIZE=50000

# https://www.gnu.org/software/bash/manual/html_node/Bash-Variables.html#index-HISTCONTROL
# ignorespace - Commands starting with a space won't be saved in history.
# erasedups   - Removes older duplicate entries, keeping only the most recent one.
# Not using ignoredups as we want to save more recent commands at the top and remove (older) dups
HISTCONTROL="ignorespace:erasedups"

# HISTTIMEFORMAT setup:
# %F  - Equivalent to %Y-%m-%d (ISO-like date format: YYYY-MM-DD).
# %T  - Equivalent to %H:%M:%S (24-hour time format: HH:MM:SS).
# '-'  - Separator for better readability.
# More details: https://www.gnu.org/software/bash/manual/bash.html#index-HISTTIMEFORMAT
HISTTIMEFORMAT='%F %T - '
