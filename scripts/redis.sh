#!/bin/bash

# variables
redis_maxmemory_policy='allkeys-lru'
redis_conf_file='/etc/redis/redis.conf'
redis_sysctl_file='/etc/sysctl.d/60-redis-local.conf'

echo -n 'Setting up redis cache...'

# calculate memory to use for redis
sys_memory=$(free -m | grep -oP '\d+' | head -n 1)
redis_memory=$(($sys_memory / 32))
sed -i -e 's/^#\? \?\(maxmemory \).*$/\1'$redis_memory'm/' $redis_conf_file

# change the settings for maxmemory-policy
sed -i -e 's/^#\? \?\(maxmemory\-policy\).*$/\1 '$redis_maxmemory_policy'/' $redis_conf_file

# create / overwrite and append our custom values in it
echo 'vm.overcommit_memory = 1' > $redis_sysctl_file
echo 'net.core.somaxconn = 1024' >> $redis_sysctl_file

# Load settings from the redis sysctl file
sysctl -p $redis_sysctl_file

# restart redis
/bin/systemctl restart redis-server

echo ' done.'
