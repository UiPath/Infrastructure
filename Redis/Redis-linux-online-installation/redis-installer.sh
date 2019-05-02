#!/bin/bash

echo  "Installing make and gcc"
yum -y install make gcc

echo  "Downloading last redis stable release"
wget http://download.redis.io/releases/redis-4.0.11.tar.gz

echo  "Extracting redis-stable package"
tar -xzf redis-4.0.11.tar.gz

echo  "Compiling dependencies"
cd redis-4.0.11/deps
make hiredis lua jemalloc linenoise

echo  "Compiling redis source"
cd ../ && make
make install


echo  "Adding vm.overcommit_memory = 1 , net.core.somaxconn=512 and disable THB "
if grep -xq ".*vm.overcommit_memory.*" /etc/sysctl.conf; then
    sed -i.bak 's/.*vm.overcommit_memory.*/vm.overcommit_memory=1/g' /etc/sysctl.conf
else
    echo 'vm.overcommit_memory=1' >> /etc/sysctl.conf
fi
sleep 2
if grep -xq ".*net.core.somaxconn.*" /etc/sysctl.conf; then
    sed -i.bak 's/.*net.core.somaxconn.*/net.core.somaxconn=512/g' /etc/sysctl.conf
else
    echo 'net.core.somaxconn=512' >> /etc/sysctl.conf
fi
sleep 3

 cat >> /etc/rc.local <<EOF
   echo never > /sys/kernel/mm/transparent_hugepage/enabled
EOF

chmod +x /etc/rc.d/rc.local


echo  "Enabling sysctl config..."
sysctl -p

echo  "Creating required directories"
mkdir -p /etc/redis/
mkdir -p /var/run/redis/
mkdir -p /var/log/redis/
mkdir -p /var/redis/6379/
mkdir -p /var/redis/sentinel_16379/
sleep 2


echo  "Setup REDIS"
cp redis.conf redis.conf.bak
cp redis.conf /etc/redis/6379.conf

sleep 3

getIP=$(ip addr | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')


if ((${#getIP} > 15)); then

read -p "Please enter the IP address: " ipa;

else

ipa=${getIP}

fi

sed -e "s/^daemonize no$/daemonize yes/" -e "s/^bind.*$/bind ${ipa}/" -e "s/^dir \.\//dir \/var\/redis\/6379\//" -e "s/^loglevel verbose$/loglevel notice/" -e "s/^logfile.*/logfile \/var\/log\/redis\/redis_6379.log/" -e "s/^pidfile.*/pidfile \/var\/run\/redis\/redis_6379.pid/"  -e "s/^tcp-keepalive.*/tcp-keepalive 60/" -e "s/^# maxmemory-policy noeviction/maxmemory-policy noeviction/"  -e "s/^protected-mode yes/protected-mode no/" redis.conf > /etc/redis/6379.conf



echo  "Is this a single instance or multi node? Please type 1 for single node or 2 for clustered instance"
select yn in "Single" "Cluster"; do
    case $yn in
        Single ) echo "Single Redis instance (one node)"
        single=1;
        break;;
        Cluster ) echo "Multi instance - Redis cluster (multi node)"
        single=0;
        break;;
    esac
done

echo  "Setup redis-server init script"
wget https://raw.githubusercontent.com/hteo1337/Redis/master/Redis-linux-online-installation/redis-server
cp redis-server /etc/init.d/redis-server
chmod 750 /etc/init.d/redis-server

if [[ ${single} == 0 ]];then
echo  "Setup redis-sentinel init script"
wget https://raw.githubusercontent.com/hteo1337/Redis/master/Redis-linux-online-installation/redis-sentinel
cp redis-sentinel /etc/init.d/redis-sentinel
chmod 750 /etc/init.d/redis-sentinel

smhost() {
        read -p "Configure master or slave host? Select 1 for master, 2 for slave. " mshost
case $mshost in
    1) echo "Configuring Master host"
      #  read -p "Enter master host IP " mipx
 cat > /etc/redis/sentinel.conf <<EOF
        bind ${ipa}
        port 16379
        sentinel monitor redis-cluster ${ipa} 6379 2
        sentinel down-after-milliseconds redis-cluster 5000
        sentinel parallel-syncs redis-cluster 1
        sentinel failover-timeout redis-cluster 10000
        daemonize yes
        pidfile /var/run/redis/sentinel.pid
        dir /var/redis/6379
EOF
        ;;
    2) echo "Configuring Slave host"

    read -p "Enter master IP " mipx
while [[ ! "$mipx" =~ ^([0-9]{1,3})[.]([0-9]{1,3})[.]([0-9]{1,3})[.]([0-9]{1,3})$ ]]; do
    read -p "Not an IP. Re-enter: " mipx
done

         sed -i "s/.*slaveof.*$/slaveof ${mipx} 6379/g" /etc/redis/6379.conf
        #sed -i "s/.*replicaof.*$/replicaof ${mipx} 6379/g" /etc/redis/6379.conf

 cat > /etc/redis/sentinel.conf <<EOF
        bind ${ipa}
        port 16379
        sentinel monitor redis-cluster ${mipx} 6379 2
        sentinel down-after-milliseconds redis-cluster 5000
        sentinel parallel-syncs redis-cluster 1
        sentinel failover-timeout redis-cluster 10000
        daemonize yes
        pidfile /var/run/redis/sentinel.pid
        dir /var/redis/sentinel_16379
EOF
        ;;
    *) echo "You need to chose 1 or 2"
      return 1
        ;; esac
}
until smhost;do : ; done

fi


echo  "Starting Redis services and add firewall rules"
systemctl enable redis-server
service redis-server start

if [[ ${single} == 0 ]];then
systemctl enable redis-sentinel
service redis-sentinel start
fi

systemctl daemon-reload

firewall-cmd --permanent --zone=public --add-port=6379/tcp --permanent

firewall-cmd --permanent --zone=public --add-port=16379/tcp --permanent

firewall-cmd --reload
