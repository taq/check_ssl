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

header() {
   echo "check_ssl.sh - Checking SSL dates"
   echo "---------------------------------"
}

cert_date() {
   echo | openssl s_client -showcerts -servername $1 -connect $1:443 2>/dev/null | openssl x509 -inform pem -noout -text 2>/dev/null | grep -i "not after" | cut -f2- -d:
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
   for HOST in $(cat $HOSTS)
   do
      echo -e "\nChecking $HOST .. ..."
      CERT_DATE=$(cert_date "$HOST")
      COMP_DATE=$(comp_date "$CERT_DATE")

      if [[ $COMP_DATE < $LIMIT ]]; then
         echo "Certificate will expire or not found!"
         EXPIRING+=($HOST)
      else
         echo "Certificate is ok."
      fi
   done
}

check_expiring() {
   local SIZE=${#EXPIRING[@]}

   if [ $SIZE -le 0 ]; then
      echo -e "\nAll certificates are ok."
      return
   fi

   send_mail "$EXPIRING"
}

send_mail() {
   local SSMTP="eustaquiorangel@gmail.com" # of course you'll need to change this

   echo "Sending email ..."
   printf "Subject: Expiring SSL certificates\n\nThis is the list of SSLcertificates which will expire soon:\n\n$1" | ssmtp "$SSMTP"
   echo "Done."
}

header

# here we configure how many days ahead from today we'll check
DAYS=15
LIMIT=$(date --date="+$days days" +"%Y%m%d")

SCRIPTPATH="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P)"

# loading hosts, put each host on one line
HOSTS="${SCRIPTPATH}/check_ssl.cfg"
EXPIRING=()

check_config "$HOSTS"
validate "$HOSTS"
check_expiring
