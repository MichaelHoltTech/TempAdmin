#!/bin/bash
if [ -f "/var/rlcit/userToRemove" ]; then
  authorized_user=`cat /var/rlcit/userToRemove`
fi
#echo "Last modified $last_modified seconds ago"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

key="<insert_mandrill_api_key" #your maildrill API key
to="notify@example.com"
computer=`hostname | cut -d. -f1`
# Include pashua.sh to be able to use the 2 functions defined in that file
source "$MYDIR/pashua.sh"
conf="
# Set window title
*.title = Temporary Admin Agreement
*.appearance = metal
*.floating = 1

# Introductory text
txt.type = text
txt.width = 350
txt.default = Your Admin Access has Expired!

# Add a cancel button with default label
db.type = defaultbutton
db.label = OK
"

if [ -d '/Volumes/Pashua/Pashua.app' ]
then
	# Looks like the Pashua disk image is mounted. Run from there.
	customLocation='/Volumes/Pashua'
else
	# Search for Pashua in the standard locations
	customLocation=''
fi
if [ -f "/var/rlcit/userToRemove" ]; then
  last_modified="$(( $(date +%s) - $(stat -f%c /var/rlcit/userToRemove) ))"
  echo $last_modified
  if ((last_modified > 2*60)); then
    echo "Older than 30 minutes!!"
    username=`cat /var/rlcit/userToRemove`
    /usr/sbin/dseditgroup -o edit -d $username -t user admin
    echo $username "has been removed from admin group"
    rm /var/rlcit/userToRemove
    pashua_run "$conf" "$customLocation"
    exit 2
  fi
fi
exec dscl . -list /Users \
  | while read each_username
  do
    if [ "$each_username" == "rlcadmin" ]; then
      :
    elif [ "$each_username" == "rladmin" ]; then
      :
    elif [ "$each_username" == "rlcproduction" ]; then
      :
    elif [ "$each_username" == "root" ]; then
      :
    #elif [ "$each_username" == "mholt" ]; then
    #  :
    elif [ "$each_username" == "$authorized_user" ]; then
      :
    else
      is_admin=`dsmemberutil checkmembership -U $each_username -G admin | grep "is a member"`
      if [ -n "${is_admin-set}" ]; then
        #Email Settings
        from_name=`finger $each_username | awk -F: '{ print $3 }' | head -n1 | sed 's/^ //'`
        from_email="$each_username@example.com" #who is sending the email
        reply_to="$from_email" #reply email address
        subject="Unauthorized Admin $from_name revoked on $computer"
      	timestamp=`date +"%Y-%m-%d %H:%M:%S"`
      	msg='{ "async": false, "key": "'$key'", "message": { "from_email": "'$from_email'", "from_name": "'$from_name'", "headers": { "Reply-To": "'$reply_to'" }, "return_path_domain": null, "subject": "'$subject'", "text": "'$each_username' no longer has admin access to '$computer'\n\n\nTimestamp: '$timestamp'", "to": [ { "email": "'$to'", "type": "to" } ] } }'
      	results=$(curl -A 'Mandrill-Curl/1.0' -d "$msg" 'https://mandrillapp.com/api/1.0/messages/send.json' -s 2>&1);
        /usr/sbin/dseditgroup -o edit -d $each_username -t user admin
        conf="
        # Set window title
        *.title = Unauthorized Admin
        *.appearance = metal
        *.floating = 1

        # Introductory text
        txt.type = text
        txt.width = 350
        txt.default = User $each_username is not authorized for admin access.  If this is an error, contact support@example.com

        # Add a cancel button with default label
        db.type = defaultbutton
        db.label = OK
        "
        pashua_run "$conf" "$customLocation"
        touch /var/rlcit/adminremoved

      fi
    fi
  done



if [ ! -f "/var/rlcit/userToRemove" ] && [ ! -f "/var/rlcit/adminremoved" ]; then
  rm -Rf /var/rlcit
  rm -Rf /usr/local/tempadmin
  defaults write /Library/LaunchDaemons/org.reallifechurch.adminremove.plist disabled -bool true
  launchctl unload -w /Library/LaunchDaemons/org.reallifechurch.adminremove.plist
  rm -f /Library/LaunchDaemons/org.reallifechurch.adminremove.plist
fi
if [ -f "/var/rlcit/adminremoved" ]; then
  rm /var/rlcit/adminremoved
fi
