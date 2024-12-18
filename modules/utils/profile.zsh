function demomode {
  export PS1="λ "
  clear
  echo demo mode activated
  sleep .5
  clear
}

function psgrep () {
  local PIDS
  PIDS=$(pgrep "$1" | paste -sd ',' -)
  if [[ $PIDS == "" ]]; then
    echo no processes match $1
    return 1
  fi
  ps u -p "$PIDS"
}
alias psg="psgrep"

alias pstop="ps ux | sort -nrk3 | head -n 10"
alias pst="pstop"

function cdl () {
  cd $1
  ls
}

# function whichVersion() {
#   which $1
#   $1 --version
# }
# alias wv=whichVersion

# function secret () {
#   case $1 in
#     get)
#       NAME="$2"
#       KEYCHAIN="${3:-$HOME/Library/Keychains/login.keychain-db}"
#       SECRET=$(security find-generic-password -w -s "$2" "$KEYCHAIN" 2> /dev/null)
#       if [[ $SECRET == "" ]]; then
#         echo Could not read secret: $NAME
#         return 1
#       fi
#       echo $SECRET
#       ;;
#     help)
#       echo 'secret get <name> <keychain?>'
#       ;;
#     *)
#       echo invalid command $1, see "'secret help'"
#       return 1
#     esac
# }

function xin () {
  if [[ $1  == "-p" ]]; then
    PARALLEL="-P20"
    shift
  fi
  # cat - | xargs -n1 $PARALLEL -t (cd "$(dirname {})"; '"$@"'
  cat - | xargs -n1 $PARALLEL -I{} sh -c 'cd $(dirname {}); '"$@"
}


# open a tweet from the url:
# tw https://twitter.com/Interior/status/463440424141459456
function tw () {
  if [[ $1 == https://twitter.com/* ]]; then
    curl "https://publish.twitter.com/oembed?url=${1}" | jq -r .html > ${TMPDIR}tweet.html && open ${TMPDIR}tweet.html
  else
    echo usage:
    echo "  tw https://twitter.com/Interior/status/463440424141459456"
  fi
}

# prints a QR code of the input (e.g. a url) to the terminal
function qr () {
  local data=$1
  while [[ $data == '' ]]; do
    vared -p 'Data for QR code: ' data
  done

  npx qrcode-terminal $data
}
