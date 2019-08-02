#!/bin/bash

#Here is a script to deploy cert to ESXi

#returns 0 means success, otherwise error.

# Depends on public-key-enabled ssh login on the target with credentials for the current "acme" account
# certs must be deployed manually if old cert expires before new one put in place

# Tested on ESXi 5.5
# 2019-03-02    -- jmcg
# More testing 2019-08-2 - corrected bad assumption about working directory when running

########  Public functions #####################

#domain keyfile certfile cafile fullchain
ESXi_deploy() {
  _cdomain="$1"
  _ckey="$2"
  _ccert="$3"
  _cca="$4"
  _cfullchain="$5"

  _debug _cdomain "$_cdomain"
  _debug _ckey "$_ckey"
  _debug _ccert "$_ccert"
  _debug _cca "$_cca"
  _debug _cfullchain "$_cfullchain"


  TIMESTAMP=`date --utc +%Y-%m-%d_%H:%M:%s`
  
    _info "backup old key"
  BACKUPKEY=`ssh root@"$_cdomain" "/bin/cp -f /etc/vmware/ssl/rui.key /etc/vmware/ssl/rui.key_from_$TIMESTAMP"`
  _info "backup old cert"
  BACKUPCERT=`ssh root@"$_cdomain" "/bin/cp -f /etc/vmware/ssl/rui.crt /etc/vmware/ssl/rui.crt_from_$TIMESTAMP"`
  _info "upload key"
  KEYRESULT=`scp -q "$_ckey" root@"$_cdomain":/etc/vmware/ssl/rui.key || echo key upload failed`
  if [[ "$KEYRESULT" =~ "failed" ]]; then
      _info "$KEYRESULT"
      return 1
  fi
  _info "upload cert"
  CERTRESULT=`scp -q "$_ccert" root@"$_cdomain":/etc/vmware/ssl/rui.crt || echo cert upload failed`
  if [[ "$CERTRESULT" =~ "failed" ]]; then
      _info "$CERTRESULT"
      return 1
  fi
  MODESETKEY=`ssh root@"$_cdomain" "chmod 1400 /etc/vmware/ssl/rui.key"`
  MODESETCRT=`ssh root@"$_cdomain" "chmod 1644 /etc/vmware/ssl/rui.crt"`
  _info "restarting services"
  RESTARTRESULT=`ssh root@"$_cdomain" "/sbin/services.sh restart"`
  _debug "$RESTARTRESULT"
  # this script reports some errors, but seems to do whatever is necessary to make the cert effective
  # at this point, we don't care too much what result it gives

  return 0
}

