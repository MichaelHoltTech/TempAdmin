echo "$(( $(date +%s) - $(stat -f%c /var/rlcit/userToRemove) ))"
