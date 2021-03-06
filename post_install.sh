#!/bin/sh -x

sa="/root/storj"
pdir="${0%/*}"
user=storj
group=storj
uid=3000
gid=3000
PLUGIN=storj
#module="StorJ"
LOGFILE="/var/log/STORJ"
IDENTITYBINDIR="/tmp"
IDENTITYZIP="${IDENTITYBINDIR}/identity_freebsd_amd64.zip"
IDENTITYBIN="${IDENTITYBINDIR}/identity"
STORBINDIR="/usr/local/www/storagenode/scripts"
STORBIN="${STORBINDIR}/storagenode"
STORBINZIP=/tmp/storagenode_freebsd_amd64.zip
USERDATADIR=/mnt/storj_data

BASEDIR="/home/storj"
CFGDIR="$BASEDIR/config"
YMLFILE="$CFGDIR/config.yaml"
IDENTITYDIR="${BASEDIR}/identity"

# Setup the user account first 
pw groupadd -n ${group} -g ${gid}
#pw groupmod ${group} -m www
mkdir -p /home
pw useradd -n ${user} -u ${uid} -d /home/${user} -s /usr/sbin/nologin -g ${group} -m

chown -R ${user} /var/db/${PLUGIN}
sysrc "${PLUGIN}_user=${user}"
service ${PLUGIN} start

if [ ! -d "/usr/local/www/storagenode" ]; then
  mkdir -p "/usr/local/www/storagenode"
fi;
if [ ! -d ${USERDATADIR} ]; then
  mkdir -p ${USERDATADIR}
fi;
cp -R "${pdir}/overlay/usr/local/www/storagenode" /usr/local/www/
chown -R ${user}:${group} /usr/local/www/storagenode
chmod ug+rw /usr/local/www/storagenode/config.json
#cp -R "${pdir}/overlay/root/storj_base" /root
#cp -R "${pdir}/overlay/root/storj_base" /home/storj
chown -R ${user}:${group} /home/storj

touch $LOGFILE
chmod 666 $LOGFILE
chown -R ${user}:${group} $LOGFILE

echo `date` "Setup started from dir $0 => $pdir "	>> $LOGFILE
#echo `date` "BASEDIR($BASEDIR)"				>> $LOGFILE
echo `date` "STORBIN($STORBIN)"				>> $LOGFILE
echo `date` "LOGFILE($LOGFILE)"				>> $LOGFILE
echo `date` "user($user)"				>> $LOGFILE
echo `date` "group($group)"				>> $LOGFILE
echo `date` "RUnning in context of user:" `id`		>> $LOGFILE

if [ "${1}" = "standard" ]; then    # Only cp files when installing a standard-jail

  mv /usr/local/etc/nginx/nginx.conf /tmp/nginx.conf.old 
  cp "${sa}"/overlay/usr/local/etc/nginx/nginx.conf /usr/local/etc/nginx/nginx.conf

  mv /usr/local/etc/php-fpm.d/www.conf /tmp/www.conf.old
  cp "${sa}"/overlay/usr/local/etc/php-fpm.d/www.conf /usr/local/etc/php-fpm.d/www.conf

  cp "${sa}"/overlay/etc/motd /etc/motd

fi

# Fetch identity binary
curl -L --proto-redir http,https -o ${IDENTITYZIP} https://github.com/storj/storj/releases/download/v1.6.3/identity_freebsd_amd64.zip
unzip -d ${IDENTITYBINDIR} -j ${IDENTITYZIP}
chmod a+x ${IDENTITYBIN}


# Fetch storagenode binary and execute for basic content creation
curl -L --proto-redir http,https -o ${STORBINZIP} https://github.com/storj/storj/releases/download/v1.6.3/storagenode_freebsd_amd64.zip
unzip -d ${STORBINDIR} -j ${STORBINZIP}
chmod a+x ${STORBIN}

echo `date` "Running storagenode binary ${STORBIN} for setup" >> $LOGFILE
cmd="$STORBIN setup --config-dir $BASEDIR/config --identity-dir $IDENTITYDIR --server.revocation-dburl bolt://$BASEDIR/config/revocations.db --storage2.trust.cache-path $BASEDIR/config/trust-cache.json --storage2.monitor.minimum-disk-space 12GB  "
echo `date` " $cmd " >> $LOGFILE 2>&1 
$cmd >> $LOGFILE 2>&1 

ln -s /usr/local/www/storagenode/images/Storagenode_64.png /usr/local/www/storagenode/favicon.ico 

chmod a+rwx $CFGDIR
chmod a+rw $YMLFILE
chown -R ${user}:${group} $BASEDIR
chown -R ${user}:${group} $YMLFILE

find /usr/local/www/storagenode -type f -name ".htaccess" -depth -exec rm -f {} \;
find /usr/local/www/storagenode -type f -name ".empty" -depth -exec rm -f {} \;

chown -R ${user}:${group} /usr/local/www/storagenode
#find /usr/local/www/storagenode -type d -print | xargs chmod g+rx 

mkdir -p ${IDENTITYDIR}/storagenode
chown -R ${user}:${group} ${IDENTITYDIR}

# Enable the service
sysrc -f /etc/rc.conf nginx_enable=YES
sysrc -f /etc/rc.conf php_fpm_enable=YES
sysrc -f /etc/rc.conf storj_enable="YES"

service nginx start  > $LOGFILE 2>&1 
service php-fpm start > $LOGFILE  2>&1 

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

