#!/usr/bin/env bash

# Simple wrapper around the ANSI Escape codes
# Also see: https://en.wikipedia.org/wiki/ANSI_escape_code

# Maps effect names to their respective ANSI escape code
function print_graphic_rendition_code() {
  local effect="${1}"

  function print_code() {
    echo -ne "${1}"
  }

  case "${effect}" in
    # Taken from: https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_parameters
    reset ) print_code 0 ;;
    bold|increased_intensity ) print_code 1 ;;
    faint|decreased_intensity ) print_code 2 ;;
    italic ) print_code 3 ;;
    underline ) print_code 4 ;;
    slow_blink ) print_code 5 ;;
    rapid_blink ) print_code 6 ;;
    reverse_video ) print_code 7 ;;
    conceal|hide ) print_code 8 ;;
    crossed_out|strike ) print_code 9 ;;
    primary_font|default_font ) print_code 10 ;;
    alternative_font_1 ) print_code 11 ;;
    alternative_font_2 ) print_code 12 ;;
    alternative_font_3 ) print_code 13 ;;
    alternative_font_4 ) print_code 14 ;;
    alternative_font_5 ) print_code 15 ;;
    alternative_font_6 ) print_code 16 ;;
    alternative_font_7 ) print_code 17 ;;
    alternative_font_8 ) print_code 18 ;;
    alternative_font_9 ) print_code 19 ;;
    fraktur ) print_code 20 ;;
    doubly_underline|bold_off|double_underline ) print_code 21 ;;
    normal_color|normal_intensity|not_bold|not_faint ) print_code 22 ;;
    not_italic|not_fraktur ) print_code 23;;
    underline_off|not_singly|not_doubly_underlined ) print_code 24 ;;
    blink_off ) print_code 25 ;;
    proportional_spacing ) print_code 26 ;;
    reverse_off|invert_off) print_code 27 ;;
    reveal|conceal_off ) print_code 28 ;;
    not_crossed_out ) print_code 29 ;;
    foreground_black|black ) print_code 30 ;;
    foreground_red|red ) print_code 31 ;;
    foreground_green|green ) print_code 32 ;;
    foreground_yellow|yellow ) print_code 33 ;;
    foreground_blue|blue ) print_code 34 ;;
    foreground_magenta|magenta ) print_code 35 ;;
    foreground_cyan|cyan ) print_code 36 ;;
    foreground_white|white ) print_code 37 ;;
    background_black ) print_code 40 ;;
    background_red ) print_code 41 ;;
    background_green ) print_code 42 ;;
    background_yellow ) print_code 43 ;;
    background_blue ) print_code 44 ;;
    background_magenta ) print_code 45 ;;
    background_cyan ) print_code 46 ;;
    background_white ) print_code 47 ;;

    foreground_bright_black|foreground_gray|foreground_grey|gray|grey ) print_code 90 ;;
    foreground_bright_red|bright_red ) print_code 91 ;;
    foreground_bright_green|bright_green ) print_code 92 ;;
    foreground_bright_yellow|bright_yellow ) print_code 93 ;;
    foreground_bright_blue|bright_blue ) print_code 94 ;;
    foreground_bright_magenta|bright_magenta ) print_code 95 ;;
    foreground_bright_cyan|bright_cyan ) print_code 96 ;;
    foreground_bright_white|bright_white ) print_code 97 ;;

    * )
      echo "Graphic Rendition effect '${effect}' is not defined!" >&2
      exit 1
  esac
}

function print_ansi_escape_sequence() {
  local effect="${1}"

  local control_code
  control_code="$(print_graphic_rendition_code ${effect})"

  if [ -v control_code ]; then
    echo -ne "\033[${control_code}m"
  else
    echo "Control code not specified!" >&2
    exit 1
  fi
}

function echo_effect() {
  # --effect: The ANSI effect to apply
  # -e: enable interpretation of backslash escapes
  # -n: do not output the trailing newline
  #
  # Example:
  #   echo_effect --effect red "Foo Bar"
  #   echo_effect --effect green -n -e "Foo\nBar"
  local options
  options=$(getopt --longoptions "effect:" --options "en" -- "$@")

  eval set -- "$options"

  local interpret_backslash=false;
  local output_trailing_newline=true;

  while true; do
    case $1 in
      -e)
        interpret_backslash=true
        ;;
      -n)
        output_trailing_newline=false
        ;;
      --effect)
        print_ansi_escape_sequence "${2}"
        shift
        ;;
      --)
        shift
        local opt_e=""
        local opt_n=""

        if [[ "${interpret_backslash}" == "true" ]]; then
          opt_e=" -e "
        fi
        if [[ "${output_trailing_newline}" == "false" ]]; then
          opt_n=" -n "
        fi

        echo \
          ${opt_e} \
          ${opt_n} \
          "${*}"
        break;;
    esac
    shift
  done

  # print_ansi_escape_sequence "reset"
}
