#!/bin/zsh +x
zmodload zsh/datetime
source $DOTFILES/modules/main_profile/preamble.zsh

TOKEN=$TMPDIR.aqitoken
CACHE=$TMPDIR.aqidata
MAXAGE=86400 # 1 day in seconds
MAXRETRY=2
DOMAIN=map.purpleair.com
source $DOTFILES/modules/aqi/loc.env

# TODO get fancy and abstract

C_OK=0
C_NONE=101
C_EXPIRED=102
C_AUTH=401
C_RETRY_LIMIT=111

function log() {
  # echo "$@" >&2
}

function getCacheState() {
  local file=$1;
  local maxage=${2:-$MAXAGE}

  if ! [[ -s $file ]]; then
    # not file exists or is empty
    return $C_NONE
  fi

  local age;
  local mtime;
  mtime=$(stat -f'%m' $file)
  (( age = $EPOCHSECONDS - mtime ))
  log cache hit $file age $age max $maxage
  if [[ $age -gt $maxage ]]; then
    log EXPIRED age: $age max: $maxage
    return $C_EXPIRED
  fi
}

function cacheFile() {
  local key=$1;
  print "${TMPDIR}.aqi$key"
}

# usage: readThruCache "key" "refreshFn" "maxage"
#  refreshFn is a function that prints the new value, called if needed
#  maxage (optional) is seconds ttl to cache
#  prints the value or returns non-zero
function readThruCache() {
  local key=$1;
  local refreshFn=$2
  local maxage=$3
  local file="${TMPDIR}.aqi$key"

  getCacheState $file $maxage
  local state=$?
  log
  log "read $key ($file) -> $state"

  case $state in
    $C_OK)
      cat $file
      return $?
      ;;
    $C_EXPIRED)
      ;&
    $C_NONE)
      if [[ $MAXRETRY -gt 0 ]]; then
        (( MAXRETRY = $MAXRETRY - 1 ))
        log "  trying $refreshFn ($MAXRETRY)"
        local out
        out=$($refreshFn)
        local ret=$?
        # TODO need to be able to handle a new state here eg for auth
        print $out > $file
        readThruCache $key $refreshFn
        return $?
      else
        log out of retries
        return $C_RETRY_LIMIT
      fi
      ;;
    esac
    return 1
}

function getToken() {
  readThruCache "token" "refreshToken" 86400 # 1 day in seconds
}

function refreshToken() {
  log refreshToken
  local newToken;
  newToken=$(curl "https://$DOMAIN/token?version=2.0.11" \
    -H "authority: $DOMAIN" \
    -H 'accept: text/plain' \
    -H "referer: https://$DOMAIN/1/mAQI/a10/p604800/cC0" \
    -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.0.0 Safari/537.36' \
    --compressed 2>/dev/null)

    MARK aqi.refreshtoken
    print $newToken
}

function getRawData() {
  log "  getRawData"
  # readThruCache "rawdata" "refreshRawData" 86400 # 1 day in seconds
  refreshRawData
  return $?
}
function refreshRawData() {
  log refreshing raw data
  local token;
  local ret=$?
  log "ret $ret"
  token=$(getToken) || return $ret
  log n3 $token

# location_type=0 : outdoors
# channel_flag=0 : normal

  local res;
  res=$(curl --get  https://${DOMAIN:-0.0.0.0:8080}/v1/sensors \
  --data-urlencode "token=${token}" \
  -d "fields=latitude,longitude,confidence,pm2.5_10minute,pm2.5_60minute,humidity" \
  -d "max_age=3600" \
  -d "nwlat=$nwlat" \
  -d "selat=$selat" \
  -d "nwlng=$nwlng" \
  -d "selng=$selng" \
  -d "location_type=0" \
  -d "channel_flag=0" 2>/dev/null)

  log res: $res

  local err;
  local ret;
  err=$(print $res | jq .error)
  ret=$?
  if [[ $? -gt 0 ]]; then
    log invalid json response from raw data: $res
  elif [[ err == "InvalidTokenError" ]]; then
    log err $err
    # invalidate token
    rm -f $(cacheFile "token")
    ret=$C_AUTH
  fi


  log read raw data ok
  print $res > $(cacheFile "rawdata")
  print $res
  ret=$C_OK
  MARK aqi.refreshrawdata -c $ret
  log marked
  return $ret
}

function getData(){
  local ret;
  readThruCache "data" "refreshData" "300" # 5 minutes in seconds
  ret=$?
  log gotdata $(cat $(cacheFile data))
  return $ret
}
function refreshData() {
  local raw;
  local ret
  raw=$(getRawData)
  # raw=$(cat $(cacheFile rawdata))
  ret=$?
  log raw: $raw code: $ret
  if [[ $ret != 0 ]]; then
    log bailing on refreshData
    return $ret
  fi

  jq -f $DOTFILES/modules/aqi/aqi.jq $(cacheFile rawdata)
  ret=$?

  return $ret
}

getData