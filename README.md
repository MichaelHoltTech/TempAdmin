# TempAdmin
This script gives a user Temporary Admin Access when installed using Munki's OnDemand feature using Mandrill's API to generate an email.

I owe more information on setup but heres the basics:

Package is built using [Packages](http://s.sudre.free.fr/Software/Packages/about.html)

This script will grant a user temporary admin and revoke after 30 minutes.  It will automatically revoke any localadmin that is not included as an exception in remove_tempadmin.sh

You need to configure some variables in remove_tempadmin.sh and add_tempadmin.sh

Look for anything that has example.com in the file and make sure to replace insert_mandrill_api_key with your API Key

there are some unused files in here that I will clean up when time permits.
