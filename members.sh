#bin/bash
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Include pashua.sh to be able to use the 2 functions defined in that file
source "$MYDIR/pashua.sh"

exec dscl . -list /Users \
  | while read each_username
  do
    if [ "$each_username" == "rlcadmin" ]; then
      :
    elif [ "$each_username" == "rladmin" ]; then
      :
    elif [ "$each_username" == "rlcproduction" ]; then
      :
    elif [ "$each_username" == "mholt" ]; then
      :
    elif [ "$each_username" == "root" ]; then
      :
    else
      is_admin=`dsmemberutil checkmembership -U $each_username -G admin | grep "is a member"`
      if [ -n "${is_admin-set}" ]; then
        /usr/sbin/dseditgroup -o edit -d $each_username -t user admin
        conf="
        # Set window title
        *.title = UnAuthorized Admin
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
