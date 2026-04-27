#!/bin/bash
# shellcheck shell=bash
#
#% NAME
#%    template.sh - a neat shell script template that outputs man-like help
#%
#% SYNOPSIS
#+    ${script_name} [-h|--option] FILE...
#+    ${script_name} FILE... | less
#%
#% DESCRIPTION
#%    Some wordy description that can be really really long and span
#%    multiple
#%    lines
#%
#%    I didn't write this by the way and I can't find the Stack Overflow
#%    post I lifted this from.
#%    (I *don't* think it was @michel-vongvilay-uxora-com ...)
#%
#% PARAMETERS
#%    --option
#%        You sure specified an option.
#%
#% REMARKS
#%    Any header line with a '%' gets included
#%
#  DEVELOPER NOTES
#     You can also omit a line at the start to leave notes for people
#     who read scripts before they run it (as they should).
#
#- IMPLEMENTATION
#-    revision   1
#-    author     valdeza
#-
# END_OF_HEADER

set -o errexit
set -o pipefail
set -o nounset

script_headsize=$(head -80 "$0" |grep -n "^# END_OF_HEADER" | cut -f1 -d:)
script_name="$(basename "$0")"
script_pid=$$

usage() { printf "usage:\n"; head "-${script_headsize:-99}" "$0" | grep -e "^#+" | sed -e "s/^#+[ ]*//g" -e "s/\${script_name}/${script_name}/g" ; }
usagefull() { head "-${script_headsize:-99}" "$0" | grep -e "^#[%+-]" | sed -e "s/^#[%+-]//g" -e "s/\${script_name}/${script_name}/g" ; }
scriptinfo() { head "-${script_headsize:-99}" "$0" | grep -e "^#-" | sed -e "s/^#-//g" -e "s/\${script_name}/${script_name}/g"; }

# usage: die exit_status message
die() {
  rc=$1
  shift
  printf '%s\n' "$*" >&2
  exit "$rc"
}

# basic prerequisites check
[[ $# -lt 1 ]] && usage && exit 1

if ! getopt_params=$(getopt -o 'h' --long 'help,print' -n "$script_name" -- "$@"); then
  die 1 'getopt parse error'
fi
eval set -- "$getopt_params"
unset getopt_params

f_opt=false
while true; do
  case "$1" in
    '-h')
      usage
      exit 0
      ;;
    '--help')
      usagefull
      exit 0
      ;;
    '--option')
      f_opt=true
      shift
      ;;
    --)
      shift
      break
      ;;
    *)
      echo 'getopt internal error occurred' >&2
      exit 1
      ;;
  esac
done
