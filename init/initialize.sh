#! /bin/bash

# initialize NPAD in an MLab slice
source /etc/mlab/slice-functions
source $SLICEHOME/conf/config.sh
source $SLICEHOME/.bash_profile
cd $SLICEHOME

set -e

echo Kill any prior servers
service httpd stop          || true
$SLICEHOME/init/stop.sh     || true
# Brutal workaround for buggy daemon scripts
killall /usr/bin/python     || true
killall /usr/sbin/tcpdump   || true

echo "Install required packages and perform System Update"
# echo "Check/Install system tools"
[ -f $SLICEHOME/.yumdone2 ] || \
    (
        rm -f $SLICEHOME/.yumdone*
        yum install -y httpd gnuplot-py gnuplot
        yum install -y paris-traceroute
        yum install -y python-pip
        touch $SLICEHOME/.yumdone2
        pip install prometheus_client
    )
# make sure that everything is up to date
yum update -y

# Enable/disable VSYS based on OS version
if [[ $( uname -r ) =~ 2.6.22.* ]] ; then
    echo "Removing /etc/web100_vsys.conf"
    rm -f /etc/web100_vsys.conf
elif [[ $( uname -r ) =~ 2.6.32.* ]] ; then
    echo "Creating /etc/web100_vsys.conf"
    echo "1" > /etc/web100_vsys.conf
else
    echo "Unknown kernel version: " `uname -r`
fi

if [ ! -f .side_samples_done ]; then
   mkdir -p $SLICEHOME/VAR/www/Sample
   (cd $SLICEHOME/VAR/www/Sample; mkSample.py)
   touch .side_samples_done
fi

# create directories as the user.
pushd $SLICEHOME/VAR

    mkdir -p logs run
    chown -R $SLICENAME:slices logs run

    echo "Capture our idenity and its various attributes"
    rm -f MYADDR MYFQDN MYLOCATION MYNODE LOCATION

    # Get and check our own IP ADDRESS
    MYADDR=$( get_slice_ipv4 ) 
    if [ -z "$MYADDR" ]; then
       echo "Failed to find my address: $MYADDR"
       exit 1
    fi
    echo $MYADDR > MYADDR

    # Be aware that $HOSTNAME is the ssh interface
    # MYFQDN and MYADDR are the service name and address
    MYFQDN="npad.iupui.$HOSTNAME"
    echo $MYFQDN > MYFQDN

    # XXXX should check that MYFQDN and MYADDR agree

    # Generate some nice names
    set `echo $HOSTNAME | tr '.' ' '`
    site=`echo $2 | tr -d '[0-9]' | tr '[a-z]' '[A-Z]'`
    location=`sed -n "s/^$site[ 	][ 	]*//p" $SLICEHOME/conf/Locations.txt`
    if [ -n "$location" -a "$3" = "measurement-lab" -a "$4" = "org" ] ; then
        MYLOCATION=$location
        MYNODE=$1.$2
    else
        MYLOCATION="(unknown near $site)"
        MYNODE=`basename $HOSTNAME .measurement-lab.org`
    fi
    echo $MYLOCATION > MYLOCATION
    echo $MYNODE > MYNODE
    echo "Configured node $MYNODE at $MYFQDN ($MYADDR) in $MYLOCATION"
popd

echo "Configure httpd"
# avoid redoing things
cp -f /etc/httpd/conf/httpd.conf $SLICEHOME/conf/httpd.conf.original
sed "s/MYFQDN/$MYFQDN/" $SLICEHOME/conf/httpd.conf.npad > /etc/httpd/conf/httpd.conf
sed "s;LOCATION;$MYLOCATION;" $SLICEHOME/conf/diag_form.html > $SLICEHOME/VAR/www/index.html
chkconfig httpd on
service httpd start

# NOTE: this is forcibly over-writing a pre-existing config within the slicebase.
# A list of Google Cloud netblocks. Generated from DNS-based SPF records.  To
# regenerate this list from DNS, you can run the command:
#   nslookup -q=TXT _cloud-netblocks.googleusercontent.com  8.8.8.8 \
#    | grep text \
#    | sed -e 's/.*=spf1 //' -e 's/?all.*//' -e 's/include://g' -e 's/ /\n/g'  \
#    | while read; do nslookup -q=TXT $REPLY 8.8.8.8; done \
#    | grep 'text = ' \
#    | sed -e 's/.*spf1 //' -e 's/ ?all.*//' -e 's/ /\n/g' \
#    | grep ^ip4 \
#    | sed -e 's/ip4://' \
#    | xargs \
#    | sed -e 's/ /, /g'
GOOGLE_NETBLOCKS="8.34.208.0/20, 8.35.192.0/21, 8.35.200.0/23, 108.59.80.0/20, 108.170.192.0/20, 108.170.208.0/21, 108.170.216.0/22, 108.170.220.0/23, 108.170.222.0/24, 162.216.148.0/22, 162.222.176.0/21, 173.255.112.0/20, 192.158.28.0/22, 199.192.112.0/22, 199.223.232.0/22, 199.223.236.0/23, 23.236.48.0/20, 23.251.128.0/19, 107.167.160.0/19, 107.178.192.0/18, 146.148.2.0/23, 146.148.4.0/22, 146.148.8.0/21, 146.148.16.0/20, 146.148.32.0/19, 146.148.64.0/18, 130.211.4.0/22, 130.211.8.0/21, 130.211.16.0/20, 130.211.32.0/19, 130.211.64.0/18, 130.211.128.0/17, 104.154.0.0/15, 104.196.0.0/14, 208.68.108.0/23, 35.184.0.0/14, 35.188.0.0/16"
sed -e "s;RSYNCDIR_SS;$RSYNCDIR_SS;" \
    -e "s;RSYNCDIR_NPAD;$RSYNCDIR_NPAD;" \
    -e "s;RSYNCDIR_PTR;$RSYNCDIR_PTR;" \
    -e "s;GOOGLE_NETBLOCKS;$GOOGLE_NETBLOCKS;" \
    $SLICEHOME/conf/rsyncd.conf.in > /etc/rsyncd.conf

# Allow CIRA rsync access to the paris-traceroute module at their own sites
for site in yyz01 yyc01 yul01; do
    if [[ "$HOSTNAME" =~ "$site" ]]; then
        HOSTS_ALLOW=$(grep 'hosts allow' $SLICEHOME/conf/rsyncd.conf.in)
        echo "    ${HOSTS_ALLOW}, 192.211.124.208/28" >> /etc/rsyncd.conf
    fi
done

mkdir -p $RSYNCDIR_SS
mkdir -p $RSYNCDIR_NPAD
mkdir -p $RSYNCDIR_PTR
chown -R $SLICENAME:slices /var/spool/$SLICENAME
# NOTE: Restart, since we just modified the config.
service rsyncd restart
