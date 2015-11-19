#!/bin/bash
current_user=`who | grep console | awk '{print $1}'`
is_admin=`dsmemberutil checkmembership -U $current_user -G admin | grep "is a member"`
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Include pashua.sh to be able to use the 2 functions defined in that file
source "$MYDIR/pashua.sh"
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

if [ -d '/Volumes/Pashua/Pashua.app' ]
then
  # Looks like the Pashua disk image is mounted. Run from there.
  customLocation='/Volumes/Pashua'
else
  # Search for Pashua in the standard locations
  customLocation=''
fi
if [ -n "${is_admin-unset}" ]; then
  pashua_run "$conf" "$customLocation"
  exit 2
fi
if [ -f "/var/rlcit/userToRemove" ]; then
  rm /var/rlcit/userToRemove
  echo "File Exists but user is not an admin, removing file"
fi
