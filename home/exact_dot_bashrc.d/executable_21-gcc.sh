#!/usr/bin/env bash

# GCC coloring (by having this clang coloring is also enabled)
export GCC_COLORS
GCC_COLORS="error=$(print_ansi_escape_sequence red)"
GCC_COLORS+=":warning=$(print_ansi_escape_sequence magenta)"
GCC_COLORS+=":note=$(print_ansi_escape_sequence cyan)"
GCC_COLORS+=":caret=$(print_ansi_escape_sequence green)"
GCC_COLORS+=":locus=\033["
GCC_COLORS+=":quote=\033["
