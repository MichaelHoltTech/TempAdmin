#!/bin/bash
current_user=`who | grep console | awk '{print $1}'`
is_admin=`dsmemberutil checkmembership -U $current_user -G admin | grep "is a member"`

key="<insert_mandrill_api_key" #your maildrill API key
to="notify@example.com"
computer=`hostname | cut -d. -f1`



MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Include pashua.sh to be able to use the 2 functions defined in that file
source "$MYDIR/pashua.sh"
if [ -f "/var/rlcit/userToRemove" ]; then
  authorized_user=`cat /var/rlcit/userToRemove`
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
    elif [ "$each_username" == "mholt" ]; then
      :
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
      	echo "$results" | grep "sent" -q;
        /usr/sbin/dseditgroup -o edit -d $each_username -t user admin
        conf="
        # Set window title
        *.title = Unauthorized Admin
        *.appearance = metal
        *.floating = 1

        # Introductory text
        txt.type = text
        txt.default = User $each_username is not authorized for admin access.  If this is an error, contact support@example.com

        # Add a cancel button with default label
        db.type = defaultbutton
        db.label = OK
        "
        pashua_run "$conf" "$customLocation"
      fi
    fi
  done
