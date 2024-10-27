#!/bin/bash

###
# Инициализируем бд
###

docker exec -it configSrv mongosh --port 27017 <<EOF
rs.initiate(
  {
    _id : "config_server",
       configsvr: true,
    members: [
      { _id : 0, host : "configSrv:27017" }
    ]
  }
);
EOF

docker exec -it shard1-r1 mongosh --port 27028 <<EOF
rs.initiate(
    {
      _id : "r0",
      members: [
        { _id : 0, host : "shard1-r1:27028" },
        { _id : 1, host : "shard1-r2:27027" },
        { _id : 2, host : "shard1-r3:27026" },
      ]
    }
);
EOF

docker exec -it shard2-r1 mongosh --port 27025 <<EOF
rs.initiate(
    {
      _id : "r1",
      members: [
        { _id : 0, host : "shard2-r1:27025" },
        { _id : 1, host : "shard2-r2:27024" },
        { _id : 2, host : "shard2-r3:27023" },
      ]
    }
  );
EOF

docker exec -it mongos_router mongosh --port 27020 <<EOF

sh.addShard("r0/shard1-r1:27028");
sh.addShard("r1/shard2-r1:27025");

sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } );

use somedb

for(var i = 0; i < 1000; i++) db.helloDoc.insert({age:i, name:"ly"+i});

db.helloDoc.countDocuments();

EOF

docker exec -it redis_1 bash <<EOF
echo "yes" | redis-cli --cluster create   173.17.0.2:6379   173.17.0.3:6379   173.17.0.4:6379   173.17.0.5:6379   173.17.0.8:6379   173.17.0.9:6379   --cluster-replicas 1
EOF