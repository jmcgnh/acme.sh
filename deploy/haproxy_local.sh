#!/usr/bin/env sh

# Script for acme.sh to deploy certificates to haproxy
#
# The stock acme.sh deploy script for haproxy is far too complicated for me and
# does not work out-of-the-box alpine because there is no systemctl command.
# So I use this alternate version, which expects to be run as non-root user,
# and uses an established sudo hook to copy .pem file into the correct location
# with the correct permissions and to restart haproxy.
#
# We also rename the .pem to avoid asterisks in file names outside the acme folder.
#
########  Public functions #####################

#domain keyfile certfile cafile fullchain
haproxy_local_deploy() {
  _cdomain="$1"
  _ckey="$2"
  _ccert="$3"
  _cca="$4"
  _cfullchain="$5"

  _debug _cdomain "${_cdomain}"
  _debug _ckey "${_ckey}"
  _debug _ccert "${_ccert}"
  _debug _cca "${_cca}"
  _debug _cfullchain "${_cfullchain}"

## 

  PEM_DEST_PATH=`echo ~/cert`
  PEM_FILENAME="ga.jmcg.net.pem"

  _debug PEM_DEST_PATH "$PEM_DEST_PATH"
  _debug PEM_FILENAME "$PEM_FILENAME"

  _debug "combine fullchain and key into .pem file"
  eval "cat \"$_cfullchain\" \"$_ckey\" > \"$PEM_DEST_PATH\"/\"$PEM_FILENAME\""
  _ret=$?
  if [ "${_ret}" != "0" ]; then
    _err "Error code ${_ret} during cat"
    return ${_ret}
  else
    _info "combine successful"
  fi
  
  CERTCOPY_SCRIPT="/etc/haproxy/cert/certcopy"

## Here's what certcopy script looks like
##
## /usr/bin/rsync -a --no-o --no-g /home/acme/cert/. /etc/haproxy/cert/.
##
## and here is what is in /etc/sudoers.d/acme
##
## acme   ALL=(ALL) NOPASSWD: /sbin/service, /etc/haproxy/cert/certcopy
##

  _debug "run certcopy" "${CERTCOPY_SCRIPT}"
  eval "sudo $CERTCOPY_SCRIPT"
  _ret=$?
  if [ "${_ret}" != "0" ]; then
    _err "Error code ${_ret} during certcopy"
    return ${_ret}
  else
    _info "certcopy successful"
  fi
  
  RESTART_HAPROXY="sudo service haproxy restart"

# Reload HAProxy
  _debug _restart "${RESTART_HAPROXY}"
  eval "${RESTART_HAPROXY}"
  _ret=$?
  if [ "${_ret}" != "0" ]; then
    _err "Error code ${_ret} during restart"
    return ${_ret}
  else
    _info "restart successful"
  fi

  return 0
  }
