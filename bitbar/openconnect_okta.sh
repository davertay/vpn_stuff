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
VPN_URL="https://vpn-sac.groupondev.com/saml"

# 4.) Update your AnyConnect username + tunnel (for Duo)
VPN_USERNAME="dtaylor"

# This will authenticate and retrieve a session DSID cookie
# make sure this is in your path somewhere
GET_DSID="oktadsid.py"

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
        VPN_DSID=$(eval "$GET_DSID")
        if [ $? -ne 0 ] ; then exit 1; fi

        # VPN connection command, should eventually result in $VPN_CONNECTED,
        # may need to be modified for VPN clients other than openconnect
        sudo "$VPN_EXECUTABLE" -C "$VPN_DSID" -u "$VPN_USERNAME" -i "$VPN_INTERFACE" ${VPN_OTHER} "$VPN_URL" &> /dev/null &

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

