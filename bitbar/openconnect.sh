#!/bin/bash
# Credit for original concept and initial work to: Jesse Jarzynka

# Updated by: Ventz Petkov (11-15-17)
#    * cleared up documentation
#    * incremented 'VPN_INTERFACE' to 'utun99' to avoid collisions with other VPNs

# Updated by: Ventz Petkov (9-28-17)
#    * fixed for Mac OS X High Sierra (10.13)

# Updated by: Ventz Petkov (7-24-17)
#    * fixed openconnect (did not work with new 2nd password prompt)
#    * added ability to work with "Duo" 2-factor auth
#    * changed icons

# <bitbar.title>VPN Status</bitbar.title>
# <bitbar.version>v1.1</bitbar.version>
# <bitbar.author>Ventz Petkov</bitbar.author>
# <bitbar.author.github>ventz</bitbar.author.github>
# <bitbar.desc>Connect/Disconnect OpenConnect + show status</bitbar.desc>
# <bitbar.image></bitbar.image>

#########################################################
# USER CHANGES #
#########################################################

# 1.) Updated your sudo config with (edit "osx-username" with your username):
#osx-username ALL=(ALL) NOPASSWD: /usr/local/bin/openconnect
#osx-username ALL=(ALL) NOPASSWD: /usr/bin/killall -2 openconnect


# 2.) Make sure openconnect binary is located here:
#     (If you don't have it installed: "brew install openconnect")
VPN_EXECUTABLE=/usr/local/bin/openconnect


# 3.) Update your AnyConnect VPN host
VPN_HOST="vpn2.grouponinc.net"

# 4.) Update your AnyConnect username + tunnel (for Duo)
VPN_USERNAME="dtaylor"

# 5.) Create an encrypted password entry in your OS X Keychain:
#      a.) Open "Keychain Access" and 
#      b.) Click on "login" keychain (top left corner)
#      c.) Click on "Passwords" category (bottom left corner)
#      d.) From the "File" menu, select -> "New Password Item..."
#      e.) For "Keychain Item Name" and "Account Name" use the value for "VPN_HOST" and "VPN_USERNAME" respectively
#      f.) For "Password" enter your VPN AnyConnect password.

# This will retrieve that password securely at run time when you connect, and feed it to openconnect
# No storing passwords unenin plain text files! :)
GET_VPN_PASSWORD="security find-generic-password -wl $VPN_HOST"

# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
# END-OF-USER-SETTINGS #
#########################################################

VPN_INTERFACE="utun99"

# Command to determine if VPN is connected or disconnected
VPN_CONNECTED="/sbin/ifconfig | grep -A3 $VPN_INTERFACE | grep inet"
# Command to run to disconnect VPN
VPN_DISCONNECT_CMD="sudo killall -2 openconnect"

# For groupon we need this:
VPN_OTHER="--protocol nc"

case "$1" in
    connect)
        VPN_PASSWORD=$(eval "$GET_VPN_PASSWORD")
        # VPN connection command, should eventually result in $VPN_CONNECTED,
        # may need to be modified for VPN clients other than openconnect

        # The "push" is for Duo - to push to your phone. You could use "sms" or "phone"
        # For anything else (non-duo) - you would provide your token (see: stoken)
        echo -e "${VPN_PASSWORD}\npush\n" | sudo "$VPN_EXECUTABLE" -u "$VPN_USERNAME" -i "$VPN_INTERFACE" ${VPN_OTHER} "$VPN_HOST" &> /dev/null &

        # Wait for connection so menu item refreshes instantly
        until eval "$VPN_CONNECTED"; do sleep 1; done
        ;;
    disconnect)
        eval "$VPN_DISCONNECT_CMD"
        # Wait for disconnection so menu item refreshes instantly
        until [ -z "$(eval "$VPN_CONNECTED")" ]; do sleep 1; done
        ;;
esac


if [ -n "$(eval "$VPN_CONNECTED")" ]; then
    echo "🔗✅"
    echo '---'
    echo "Disconnect VPN | bash='$0' param1=disconnect terminal=false refresh=true"
    exit
else
    echo "🔗⛔️"
    # Alternative icon -> but too similar to "connected"
    #echo "VPN 🔓"
    echo '---'
    echo "Connect VPN | bash='$0' param1=connect terminal=false refresh=true"
    # For debugging!
    #echo "Connect VPN | bash='$0' param1=connect terminal=true refresh=true"
    exit
fi


# from https://gist.github.com/moklett/3170636
#vpnsetup() {
    #sudo sh -c 'echo "%admin ALL=(ALL) NOPASSWD: /usr/local/bin/openconnect, /bin/kill" > /etc/sudoers.d/openconnect'
#}
#
#vpnstart() {
    #cat ~/.work_password | sudo openconnect \
        #--background \
        #--pid-file="$HOME/.openconnect.pid" \
        #--juniper \
        #--user=$USERNAME \
        #--authgroup=$AUTHGROUP $ADDRESS \
        #--passwd-on-stdin
#}
#
#vpnstop() {
    #if [[ -f "$HOME/.openconnect.pid" ]]; then
        #sudo kill -2 $(cat "$HOME/.openconnect.pid") && rm -f "$HOME/.openconnect.pid"
    #else
        #echo "openconnect pid file does not exist, probably not running"
    #fi
#}
