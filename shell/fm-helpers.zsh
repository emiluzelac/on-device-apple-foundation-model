# Shell helpers for fm, Apple's on-device model on macOS 27.
#
# Install: add this line to ~/.zshrc, then open a new Terminal window:
#   source /path/to/fm-helpers.zsh
#
#   ask "question"          ask anything (no question: open fm chat)
#   … | ask "question"      ask about piped text
#   brief [file …]          three-bullet summary of files or piped text
#   clipbrief               three-bullet summary of the clipboard
#   polish [style]          rewrite the clipboard (or piped text) and copy the result
#   tags [file …]           comma-separated topic tags
#   … 2>&1 | explain        explain an error message and suggest a fix

# Input over this many tokens is refused up front; the model's window is 8,192
# and quality drops well before that.
: ${FM_MAX_INPUT_TOKENS:=6000}

# Read files named as arguments, or stdin when there are none. Exit status 2
# means there was no input at all, so callers can print their usage line.
_fm_read() {
  if (( $# )); then
    cat -- "$@"
  elif [[ ! -t 0 ]]; then
    cat
  else
    return 2
  fi
}

_fm_check() {
  local text=$1 n
  if [[ -z ${text//[[:space:]]/} ]]; then
    print -u2 "fm: nothing to read"
    return 1
  fi
  n=$(fm count-tokens -q "$text") || return 1
  if (( n > FM_MAX_INPUT_TOKENS )); then
    print -u2 "fm: input is $n tokens; the limit here is $FM_MAX_INPUT_TOKENS (FM_MAX_INPUT_TOKENS). Split it up."
    return 1
  fi
}

ask() {
  local text
  [[ ! -t 0 ]] && text=$(cat)
  if [[ -n ${text//[[:space:]]/} ]]; then
    _fm_check "$text" || return 1
    fm respond -i "Answer from the text provided." --text "$text" "${*:-Summarize this.}"
  elif (( $# )); then
    fm respond "$*"
  else
    fm chat
  fi
}

brief() {
  local text
  text=$(_fm_read "$@")
  case $? in 0) ;; 2) print -u2 "usage: brief file …   or   … | brief"; return 1 ;; *) return 1 ;; esac
  _fm_check "$text" || return 1
  fm respond -i "Summarize the text in exactly three short bullet points. Use only facts in the text." \
    --text "$text" "Summarize this."
}

clipbrief() {
  pbpaste | brief
}

polish() {
  local text from_clipboard=0 out
  local style=${*:-clear, friendly and concise}
  [[ ! -t 0 ]] && text=$(cat)
  if [[ -z ${text//[[:space:]]/} ]]; then
    text=$(pbpaste)
    from_clipboard=1
  fi
  _fm_check "$text" || return 1
  out=$(fm respond --no-stream -i "Rewrite the text so it is $style. Keep the meaning and the facts. Reply with the rewritten text only." \
    --text "$text" "Rewrite this.") || return 1
  print -r -- "$out"
  if (( from_clipboard )); then
    print -rn -- "$out" | pbcopy
    print -u2 "(copied to clipboard)"
  fi
}

tags() {
  local text
  text=$(_fm_read "$@")
  case $? in 0) ;; 2) print -u2 "usage: tags file …   or   … | tags"; return 1 ;; *) return 1 ;; esac
  _fm_check "$text" || return 1
  fm respond --no-stream --use-case content-tagging "$text"
}

explain() {
  local text
  text=$(_fm_read "$@")
  case $? in 0) ;; 2) print -u2 "usage: some-command 2>&1 | explain"; return 1 ;; *) return 1 ;; esac
  _fm_check "$text" || return 1
  fm respond -i "This is output from a terminal command. In plain words, say what went wrong in one or two sentences, then give the most likely fix." \
    --text "$text" "What went wrong?"
}
