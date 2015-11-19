#!/bin/bash
#created by black @ LET
#MIT license, please give credit if you use this for your own projects
#depends on curl


key="<insert_mandrill_api_key" #your maildrill API key
username=`who | grep console | awk '{print $1}'` #from name
from_name=`finger $username | awk -F: '{ print $3 }' | head -n1 | sed 's/^ //'`
from_email="$username@example.com" #who is sending the email
reply_to="$from_email" #reply email address
to="notify@example.com"

if [ $# -eq 2 ]; then
	msg='{ "async": false, "key": "'$key'", "message": { "from_email": "'$from_email'", "from_name": "'$from_name'", "headers": { "Reply-To": "'$reply_to'" }, "return_path_domain": null, "subject": "'$2'", "text": "'$3'", "to": [ { "email": "'$to'", "type": "to" } ] } }'
	results=$(curl -A 'Mandrill-Curl/1.0' -d "$msg" 'https://mandrillapp.com/api/1.0/messages/send.json' -s 2>&1);
	echo "$results" | grep "sent" -q;
	if [ $? -ne 0 ]; then
		echo "An error occured: $results";
		exit 2;
	fi
else
echo "$0 requires 3 arguments - to address, subject, content";
echo "Example: ./$0 \"to-address@mail-address.com\" \"test\" \"hello this is a test message\""
exit 1;
fi
