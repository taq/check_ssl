#!/bin/bash
#
# check_ssl.sh - check remote SSL dates
#
# Copyright (C) 2021 Eustáquio Rangel
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

EXPIRING=()

header() {
   echo "check_ssl.sh - Checking SSL dates"
   echo "---------------------------------"
}

cert_date() {
   local DATE=$(echo | openssl s_client -showcerts -servername $1 -connect $1:443 2>/dev/null | openssl x509 -inform pem -noout -text 2>/dev/null | grep -i "not after" | cut -f2- -d:)
   date --date="$DATE" +"%Y%m%d"
}

comp_date() {
   echo $(date --date="$1" +"%Y%m%d")
}

check_config() {
   if [ ! -f $1 ]; then
      1>&2 echo "Config file not found!"
      exit 1
   fi
}

validate() {
   while read HOST
   do
      if [ "${HOST}" == "" -o "${HOST:0:1}" == "#" ]; then
         continue
      fi

      echo -e "\nChecking $HOST .. ..."
      CERT_DATE=$(cert_date "$HOST")
      COMP_DATE=$(comp_date "$1")

      if [[ "$CERT_DATE" -le "$COMP_DATE" ]]; then
         echo "Certificate will expire or not found!"
         EXPIRING+=("$HOST")
      else
         echo "Certificate is ok."
      fi
   done <<< "$(cat $2)"
}

check_expiring() {
   local SIZE=${#EXPIRING[@]}

   if [ $SIZE -le 0 ]; then
      echo -e "\nAll certificates are ok."
      return
   fi

   echo -e "\nFound expiring/expired certificates: ${EXPIRING}"
   local LIST=$(IFS=, ; echo "${EXPIRING[*]}")
   send_mail "$LIST"
}

send_mail() {
   echo -e "Sending email ..."
   # fill here with your email software and configurations
   echo "Done."
}

header

# here we configure how many days ahead from today we'll check
DAYS=15
LIMIT=$(date --date="+$DAYS days" +"%Y%m%d")

SCRIPTPATH="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P)"

# loading hosts, put each host on one line
HOSTS="${SCRIPTPATH}/check_ssl.cfg"

check_config "$HOSTS"
validate "$LIMIT" "$HOSTS"
check_expiring
