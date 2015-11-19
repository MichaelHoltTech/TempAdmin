#!/bin/bash
key="<insert_mandrill_api_key" #your maildrill API key
username=`who | grep console | awk '{print $1}'` #from name
from_name=`finger $username | awk -F: '{ print $3 }' | head -n1 | sed 's/^ //'`
from_email="$username@example.com" #who is sending the email
reply_to="$from_email" #reply email address
to="notify@example.com"
subject="Admin Access Granted to $from_name"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
current_user=`who | grep console | awk '{print $1}'`


# Include pashua.sh to be able to use the 2 functions defined in that file
source "$MYDIR/pashua.sh"
if [ -d '/Volumes/Pashua/Pashua.app' ]
then
	# Looks like the Pashua disk image is mounted. Run from there.
	customLocation='/Volumes/Pashua'
else
	# Search for Pashua in the standard locations
	customLocation=''
fi


#Function to parse JSON if error occurs
function getJsonVal () {
    python -c "import json,sys;sys.stdout.write(json.dumps(json.load(sys.stdin)$1))";
}


#Abort if user is already an Admin
is_admin=`dsmemberutil checkmembership -U $current_user -G admin | grep "is a member"`
if [ -n "${is_admin-unset}" ]; then
  if [ -f "/var/rlcit/userToRemove" ]; then
    last_modified="$(( $(date +%s) - $(stat -f%c /var/rlcit/userToRemove) ))"
    authorized_user=`cat /var/rlcit/userToRemove`
    if [ "$current_user" == "root" ] || [ "$current_user" == "rlcadmin" ] || [ "$current_user" == "rlcproduction" ] || [ "$current_user" == "rladmin" ]; then
      if  [ "$current_user" == "$authorized_user" ]; then
        :
      else
        conf="
        # Set window title
        *.title = Admin Access Already Granted
        *.appearance = metal
        *.floating = 1

        # Introductory text
        txt.type = text
        txt.width = 350
        txt.default = You are using one of the built in admin accounts! If you believe this is an error, please contact support@example.com

        # Add a cancel button with default label
        db.type = defaultbutton
        db.label = OK
        "
        pashua_run "$conf" "$customLocation"
        exit 2
      fi
    elif [ "$current_user" == "$authorized_user" ] && [ "$last_modified" < 120 ]; then
      echo $last_modified
      conf="
      # Set window title
      *.title = Admin Access Already Granted
      *.appearance = metal
      *.floating = 1

      # Introductory text
      txt.type = text
      txt.width = 350
      txt.default = You already have Admin Access! If you believe this is an error, please try again.  If this issue continues, contact support@example.com

      # Add a cancel button with default label
      db.type = defaultbutton
      db.label = OK
      "
      pashua_run "$conf" "$customLocation"
      exit 2
    elif [ "$current_user" == "$authorized_user" ] && [ "$last_modified" > 1800 ]; then
      echo $last_modified
      /usr/sbin/dseditgroup -o edit -d $current_user -t user admin
			if [ -f "/var/rlcit/userToRemove" ]; then
				rm /var/rlcit/userToRemove
			fi
      conf="
      # Set window title
      *.title = Admin Access Already Granted
      *.appearance = metal
      *.floating = 1

      # Introductory text
      txt.type = text
      txt.width = 350
      txt.default = Your Admin Access has Expired! Please continue to the next screen in order to regain Temporary Admin Access. If you believe this is an error, please contact support@example.com

      # Add a cancel button with default label
      db.type = defaultbutton
      db.label = OK
      "
      pashua_run "$conf" "$customLocation"
    else
      #Email Settings
      from_name=`finger $current_user | awk -F: '{ print $3 }' | head -n1 | sed 's/^ //'`
      from_email="$current_user@example.com" #who is sending the email
      reply_to="$from_email" #reply email address
      subject="Unauthorized Admin $from_name revoked on $computer"
      timestamp=`date +"%Y-%m-%d %H:%M:%S"`
      msg='{ "async": false, "key": "'$key'", "message": { "from_email": "'$from_email'", "from_name": "'$from_name'", "headers": { "Reply-To": "'$reply_to'" }, "return_path_domain": null, "subject": "'$subject'", "text": "'$current_user' no longer has admin access to '$computer'\n\n\nTimestamp: '$timestamp'", "to": [ { "email": "'$to'", "type": "to" } ] } }'
      results=$(curl -A 'Mandrill-Curl/1.0' -d "$msg" 'https://mandrillapp.com/api/1.0/messages/send.json' -s 2>&1);
      /usr/sbin/dseditgroup -o edit -d $current_user -t user admin
      conf="
      # Set window title
      *.title = Unauthorized Admin
      *.appearance = metal
      *.floating = 1

      # Introductory text
      txt.type = text
      txt.width = 350
      txt.default = User $current_user is not authorized for admin access.  Please continue to the next screen in order to regain Temporary Admin Access.  If this is an error, contact support@example.com

      # Add a cancel button with default label
      db.type = defaultbutton
      db.label = OK
      "
      pashua_run "$conf" "$customLocation"
    fi
  else
    #Email Settings
    from_name=`finger $current_user | awk -F: '{ print $3 }' | head -n1 | sed 's/^ //'`
    from_email="$current_user@example.com" #who is sending the email
    reply_to="$from_email" #reply email address
    subject="Unauthorized Admin $from_name revoked on $computer"
    timestamp=`date +"%Y-%m-%d %H:%M:%S"`
    msg='{ "async": false, "key": "'$key'", "message": { "from_email": "'$from_email'", "from_name": "'$from_name'", "headers": { "Reply-To": "'$reply_to'" }, "return_path_domain": null, "subject": "'$subject'", "text": "'$current_user' no longer has admin access to '$computer'\n\n\nTimestamp: '$timestamp'", "to": [ { "email": "'$to'", "type": "to" } ] } }'
    results=$(curl -A 'Mandrill-Curl/1.0' -d "$msg" 'https://mandrillapp.com/api/1.0/messages/send.json' -s 2>&1);
    /usr/sbin/dseditgroup -o edit -d $current_user -t user admin
    conf="
    # Set window title
    *.title = Unauthorized Admin
    *.appearance = metal
    *.floating = 1

    # Introductory text
    txt.type = text
    txt.width = 350
    txt.default = User $current_user is not authorized for admin access.  Please continue to the next screen in order to regain Temporary Admin Access.  If this is an error, contact support@example.com

    # Add a cancel button with default label
    db.type = defaultbutton
    db.label = OK
    "
    echo "secondary"
    pashua_run "$conf" "$customLocation"
  fi

fi

#Admin Agreement Configuration
conf="
# Set window title
*.title = Temporary Admin Agreement
*.appearance = metal
*.floating = 1

# Introductory text
txt.type = text
txt.default = This tool will provide your account with Admin Access for 30 minutes.  An alert will pop up when your admin access has been disabled.  If you require it again, you may re-run this program.[return][return]Note: When you have local admin access your username may not show up on the login screen.  If you encounter this issue, simply click other and enter your username (without @example.com) and password.[return][return]By using this, you agree to the following:[return][return]1) This computer was set up with a standard configuration and software supported by RLC IT and that in the event of problems, this computer will be re-imaged with the standard configuration, overwriting any software I have installed or configuration changes I have made.[return][return]2) I understand that NO locally saved data on the machine will be backed up and restored by RLC IT if re-imaging is required.[return][return]3) I will only install software properly licensed for use by RLC and will not install any unlicensed software on this computer.[return][return]4) I will not attempt to disable/uninstall any software or policies that have been put into place to maintain security (i.e. automatic updates, antivirus application, etc.)[return][return]5) I will provide a brief explanation of what I am using the Admin Access for.[return][return]Failure to abide by this agreement will result in Disciplinary Action as well as loss of the ability to use this tool.[return][return][return]THIS AGREEMENT HAS NOT BEEN FINALIZED AND IS SUBJECT TO CHANGE

txt.width = 700

# Add a text field
tb.type = textbox
tb.label = Please provide a brief description of what you are doing
tb.mandatory = true
tb.width = 700

# Add a cancel button with default label
cb.type = cancelbutton
cb.label = I Disagree
db.type = defaultbutton
db.label = I Agree
"





pashua_run "$conf" "$customLocation"
#Determine if User accepted Agreement and provide access
if [[ $cb = 1 ]]; then
	echo "Client did not agree"
  exit 2
fi

if [[ $db = 1 ]]; then
	timestamp=`date +"%Y-%m-%d %H:%M:%S"`
	msg='{ "async": false, "key": "'$key'", "message": { "from_email": "'$from_email'", "from_name": "'$from_name'", "headers": { "Reply-To": "'$reply_to'" }, "return_path_domain": null, "subject": "'$subject'", "text": "Reason:\n'$tb'\n\n\nTimestamp: '$timestamp'", "to": [ { "email": "'$to'", "type": "to" } ] } }'
	results=$(curl -A 'Mandrill-Curl/1.0' -d "$msg" 'https://mandrillapp.com/api/1.0/messages/send.json' -s 2>&1);
	echo "$results" | grep "sent" -q;
	if [ $? -ne 0 ]; then
		error_code=`echo "$results" | getJsonVal "['code']"`
		error_name=`echo "$results" | getJsonVal "['name']"`
		error_message=`echo "$results" | getJsonVal "['message']"`
		conf="
		# Set window title
		*.title = Temporary Admin - $error_name
		*.appearance = metal
		*.floating = 1
		*.autoclosetime = 30

		# Introductory text
		txt.type = text
		txt.default = An Error has occured.  Please try again.  If this issue persists, contact the IT Helpdesk at support@example.com. [return][return]ERROR CODE: $error_code [return]Message:[return]$error_message
		txt.width = 310
		db.type = defaultbutton
		"
		pashua_run "$conf" "$customLocation"
		echo "An error occured: $results";
		exit 2;
	fi
  # Place launchD plist to call JSS policy to remove admin rights.
  #####
  echo "<?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
  <dict>
    <key>Label</key>
    <string>org.reallifechurch.adminremove</string>
    <key>ProgramArguments</key>
    <array>
      <string>/usr/local/tempadmin/remove_tempadmin.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StartInterval</key>
    <integer>30</integer>
  </dict>
  </plist>" > /Library/LaunchDaemons/org.reallifechurch.adminremove.plist
  #####
  chown root:wheel /Library/LaunchDaemons/org.reallifechurch.adminremove.plist
  chmod 644 /Library/LaunchDaemons/org.reallifechurch.adminremove.plist
  defaults write /Library/LaunchDaemons/org.reallifechurch.adminremove.plist disabled -bool false
  launchctl load -w /Library/LaunchDaemons/org.reallifechurch.adminremove.plist

  mkdir -p /var/rlcit/
	if [ -f "/var/rlcit/userToRemove" ]; then
		rm /var/rlcit/userToRemove
	fi
  echo $username >> /var/rlcit/userToRemove
  /usr/sbin/dseditgroup -o edit -a $username -t user admin

	conf="
	# Set window title
	*.title = Temporary Admin Access Granted
	*.appearance = metal
	*.floating = 1
	*.autoclosetime = 30

	# Introductory text
	txt.type = text
	txt.default = You have been granted Admin Access for 30 minutes.
  txt.width = 350

	db.type = defaultbutton
	"
	pashua_run "$conf" "$customLocation"
  exit 0
fi
