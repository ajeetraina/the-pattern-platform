# docker run --name rgcluster -d -v $PWD/docker-config.sh:/cluster/config.sh -p 30001:30001 -p 30002:30002 -p 30003:30003 redislabs/rgcluster
network_name='redis_cluster_net'
docker network create $network_name
echo $network_name " created"

# docker run --name redisgraph -d --restart=unless-stopped -p 9001:6379 -v $PWD/redisgraph:/data -v $PWD/redis.conf:/usr/local/etc/redis/redis.conf -it --net $network_name redislabs/redisgraph /usr/local/etc/redis/redis.conf
# docker run --name redisgraph -d --restart=unless-stopped -p 9001:6379 -v $PWD/redisgraph:/data -v $PWD/redis.conf:/usr/local/etc/redis/redis.conf -it --net redis_cluster_net redislabs/redisgraph /usr/local/etc/redis/redis.conf
docker run --name redisgraph -d -p 9001:6379 -it --rm --net $network_name redislabs/redisgraph
hostip=`docker inspect -f '{{(index .NetworkSettings.Networks "redis_cluster_net").IPAddress}}' "redisgraph"`;
echo "IP for cluster node redisgraph is" $hostip
docker run -it -d -v $PWD/redisinsight:/db --net $network_name -p 8001:8001 redislabs/redisinsight:latest 
echo "Redis Insight on port 8001"
docker build -t rgcluster .
docker run --name rgcluster -d -v $PWD/docker-config.sh:/cluster/config.sh -p 30001:30001 -p 30002:30002 -p 30003:30003 --rm --net $network_name rgcluster:latest
hostip=`docker inspect -f '{{(index .NetworkSettings.Networks "redis_cluster_net").IPAddress}}' "rgcluster"`;
echo "IP for cluster node rgcluster is" $hostip

docker exec -it rgcluster /cluster/create-cluster call RG.CONFIGSET ExecutionMaxIdleTime 300000
docker exec -it rgcluster /cluster/create-cluster call CONFIG SET proto-max-bulk-len 2048mb
docker exec -it rgcluster /cluster/create-cluster call CONFIG SET list-compress-depth 1
docker exec -it rgcluster /cluster/create-cluster call CONFIG SET cluster-node-timeout 30000
docker logs -f rgcluster
