#!/bin/sh -x

sa="/root/storj"
pdir="${0%/*}"
user="www"
module="StorJ"
LOGFILE="/var/log/StorJ"
BASEDIR="/root/storj_base"
STORBIN="/usr/local/www/storagenode/scripts/storagenode"
CNFFILE="/usr/local/www/storagenode/config.json"
CFGDIR="$BASEDIR/config"
YMLFILE="$CFGDIR/config.yaml"

if [ ! -d "/usr/local/www/storagenode" ]; then
  mkdir -p "/usr/local/www/storagenode"
fi;
cp -R "${pdir}/overlay/usr/local/www/storagenode" /usr/local/www/
chown -R ${user} /usr/local/www/storagenode
cp -R "${pdir}/overlay/root/storj_base" /root

touch $LOGFILE
chmod 666 $LOGFILE

echo `date` "Setup started from dir $0 => $pdir "	>> $LOGFILE
echo `date` "BASEDIR($BASEDIR)"				>> $LOGFILE
echo `date` "STORBIN($STORBIN)"				>> $LOGFILE
echo `date` "LOGFILE($LOGFILE)"				>> $LOGFILE
echo `date` "CNFFILE($CNFFILE)"				>> $LOGFILE
echo `date` "user($user)"				>> $LOGFILE
echo `date` "RUnning in context of user:" `id`		>> $LOGFILE

if [ "${1}" = "standard" ]; then    # Only cp files when installing a standard-jail

  mv /usr/local/etc/nginx/nginx.conf /tmp/nginx.conf.old 
  cp "${sa}"/overlay/usr/local/etc/nginx/nginx.conf /usr/local/etc/nginx/nginx.conf

  mv /usr/local/etc/php-fpm.d/www.conf /tmp/www.conf.old
  cp "${sa}"/overlay/usr/local/etc/php-fpm.d/www.conf /usr/local/etc/php-fpm.d/www.conf

  cp "${sa}"/overlay/etc/motd /etc/motd

fi

# Fetch storagenode binary and execute for basic content creation
curl -o $STORBIN https://alpha.transfer.sh/RGnLr/storagenode
chmod a+x $STORBIN
echo `date` "Running storagenode binary for setup" >> $LOGFILE
$STORBIN setup --config-dir $BASEDIR/config --identity-dir $BASEDIR/identity --server.revocation-dburl "bolt://$BASEDIR/config/revocations.db" --storage2.trust.cache-path "$BASEDIR/config/trust-cache.json"  >> $LOGFILE 2>&1 

ln -s /usr/local/www/storagenode/images/Storagenode_64.png /usr/local/www/storagenode/favicon.ico 

chmod a+rwx $CFGDIR
chmod a+rw $YMLFILE
chown -R ${user}:${user} $BASEDIR
chown -R ${user}:${user} $YMLFILE

find /usr/local/www/storagenode -type f -name ".htaccess" -depth -exec rm -f {} \;
find /usr/local/www/storagenode -type f -name ".empty" -depth -exec rm -f {} \;

IDENTITYDIR=/root/.local/share/storj/identity
mkdir -p ${IDENTITYDIR}/storagenode
chown -R ${user} ${IDENTITYDIR}

# Temporary fix
cp -p $CNFFILE /usr/local/www/storagenode
chown -R ${user} /usr/local/www/storagenode
chmod a+rw $CNFFILE

# Enable the service
sysrc -f /etc/rc.conf nginx_enable=YES
sysrc -f /etc/rc.conf php_fpm_enable=YES
sysrc -f /etc/rc.conf storj_enable="YES"

service nginx start  2>/dev/null
service php-fpm start  2>/dev/null

if [ "${1}" = "standard" ]; then
  v2srv_ip=$(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')

  colors () {                               # Define Some Colors for Messages
    grn=$'\e[1;32m'
    blu=$'\e[1;34m'
    cyn=$'\e[1;36m'
    end=$'\e[0m'
  }; colors

  end_report () {                 # read all about it!
    echo; echo; echo; echo
        echo " ${blu}Status Report: ${end}"; echo
        echo "    $(service nginx status)"
        echo "  $(service php-fpm status)"
    echo
        echo " ${cyn}Storj storagenode jail ui ${end}: ${grn}http://${v2srv_ip}${end}"
    echo
    echo     "PATH for Storage node binary $STORBIN "
    echo     "BASEPATH for storage node setup $BASEDIR "
    echo     "Logs for storage node app $LOGFILE "
    echo; exit
  }; end_report

fi



