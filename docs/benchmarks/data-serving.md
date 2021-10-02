# Data Serving

[![Pulls on DockerHub][dhpulls]][dhrepo] [![Stars on DockerHub][dhstars]][dhrepo]

The data serving benchmark relies on the Yahoo! Cloud Serving Benchmark (YCSB). YCSB is a framework to benchmark data store systems. This framework comes with appropriate interfaces to populate and stress many popular data serving systems. Here we provide the instructions and pointers to download and install YCSB and use it with the Cassandra data store.

## Generating Datasets

The YCSB client has a data generator. After starting Cassandra, YCSB can start loading the data. First, you need to create a keyspace named *usertable* and a column family for YCSB. This is a must for YCSB to load data and run.



### Server Container

**Note**: The following commands will run the Cassandra within host's network. To make sure that slaves and master can communicate with each other, the master container's hostname, which should be host's hostname, must be able to be resolved to the same IP address by the master container and all slave containers. 

Start the server container that will run cassandra server and installs a default keyspace usertable:

```bash
$ docker run --name cassandra-server --privileged --net host cloudsuite/data-serving:server
```
### Multiple Server Containers

~~Please note the server containers cannot be hosted on the same node when the host network configuration is used because they will all try to use the same port.~~
You can run on the same node with a custom docker network. Use `--net host` only if you're running this across different machines/vms. 

Create the network:
```bash
$ docker network create cass-net
```

For a cluster setup with multiple servers, we need to instantiate a seed server :

```bash
$ docker run --name cassandra-server-seed --privileged --net cass-net cloudsuite/data-serving:server

OR

docker run --name cassandra-server-seed --privileged --net cass-net public.ecr.aws/cilantro/data-serving:server

OR if you want to run a seed server which self initializes, use this. Remember to set recordcount equal to your client's.
docker run --name cassandra-server-seed --privileged --net cass-net -e RECORDCOUNT=1000 public.ecr.aws/cilantro/data-serving:server-cilantro
```

You can optionally specify the listen address with `-e CASSANDRA_LISTEN_ADDRESS=<hostname or IP>`

Then we prepare the server as previously.

The other server containers are instantiated as follows:

```bash
$ docker run --name cassandra-server(id) --privileged --net cass-net -e CASSANDRA_SEEDS=cassandra-server-seed cloudsuite/data-serving:server

Example:
$ 
docker run --rm --name cassandra-server1 --privileged --net cass-net -e CASSANDRA_SEEDS=cassandra-server-seed public.ecr.aws/cilantro/data-serving:server
docker run --name cassandra-server2 --privileged --net cass-net -e CASSANDRA_SEEDS=cassandra-server-seed cloudsuite/data-serving:server
docker run --name cassandra-server3 --privileged --net cass-net -e CASSANDRA_SEEDS=cassandra-server-seed cloudsuite/data-serving:server

OR if you're using public.ecr.aws/cilantro/data-serving:server-cilantro, simply create more of them as indepdent DBs
```

You can find more details at the websites: http://wiki.apache.org/cassandra/GettingStarted and https://hub.docker.com/_/cassandra/.

Make sure all non-seed servers are established (adding them concurrently may lead to a [problem](https://docs.datastax.com/en/cassandra/2.1/cassandra/operations/ops_add_node_to_cluster_t.html)).

### Client Container
After successfully creating the aforementioned schema, you are ready to benchmark with YCSB.
Start the client container specifying server name(s), or IP address(es), separated with commas, as the last command argument:

```bash
docker run --name cassandra-client --net cass-net -e OPERATIONCOUNT=1000 -e RECORDCOUNT=5000 -e THREADCOUNT=16 cloudsuite/data-serving:client "cassandra-server-seed,cassandra-server1" /tmp

OR

docker run --name cassandra-client --net cass-net -e OPERATIONCOUNT=1000 -e RECORDCOUNT=5000 -e THREADCOUNT=16 public.ecr.aws/cilantro/data-serving:client "cassandra-server-seed,cassandra-server1" /tmp

If you do not want to initialize the database (e.g. you're using the public.ecr.aws/cilantro/data-serving:server-cilantro image), set NOINITDB=1
docker run --name cassandra-client --rm --net cass-net -e NOINITDB=1 -e OPERATIONCOUNT=1000 -e RECORDCOUNT=1000 -e THREADCOUNT=16 public.ecr.aws/cilantro/data-serving:client "cassandra-server-seed,cassandra-server-seed2" /tmp
```

More detailed instructions on generating the dataset can be found in Step 5 at [this](http://github.com/brianfrankcooper/YCSB/wiki/Running-a-Workload) link. Although Step 5 in the link describes the data loading procedure, other steps (e.g., 1, 2, 3, 4) are very useful to understand the YCSB settings.

A rule of thumb on the dataset size
-----------------------------------
To emulate a realistic setup, you can generate more data than your main memory size if you have a low-latency, high-bandwidth I/O subsystem. For example, for a machine with 24GB memory, you can generate 30 million records corresponding to a 30GB dataset size.

_Note_: The dataset resides in Cassandra’s data folder(s).The actual data takes up more space than the total size of the records because data files have metadata structures (e.g., index). Make sure you have enough disk space.

Tuning the server performance
-----------------------------
1. In general, the server settings are under the $CASSANDRA_PATH/conf folder. The main file is cassandra.yaml. The file has comments about all parameters. This parameters can also be found here: http://wiki.apache.org/cassandra/StorageConfiguration
2. You can modify the *target* and *threadcount* variables to tune the benchmark and utilize the server. The throughput depends on the number of hard drives on the server. If there are enough disks, the cores can be utilized after running the benchmark for 10 minutes. Make sure that half of the main memory is free for the operating system file buffers and caching.
3. Additionally, the following links are useful pointers for performance tuning:

	a. http://spyced.blogspot.com/2010/01/linux-performance-basics.html

	b. http://wiki.apache.org/cassandra/MemtableThresholds

Running the benchmark
---------------------
The benchmark is run automatically with the client container. One can modify the record count in the database and/or the number of operations performed by the benchmark specifying the corresponding variables when running the client container:
```
$ docker run -e RECORDCOUNT=<#> -e OPERATIONCOUNT=<#> --name cassandra-client --net host cloudsuite/data-serving:client "cassandra-server-seed,cassandra-server1"
```

[dhrepo]: https://hub.docker.com/r/cloudsuite/data-serving/ "DockerHub Page"
[dhpulls]: https://img.shields.io/docker/pulls/cloudsuite/data-serving.svg "Go to DockerHub Page"
[dhstars]: https://img.shields.io/docker/stars/cloudsuite/data-serving.svg "Go to DockerHub Page"

Thoughts on N Servers,one each for easier scaling
---------------------

The problem with the above implementation is that it creates one database and scales it across nodes.
This is not good because cassandra scales vertically really [slow](https://docs.datastax.com/en/cassandra-oss/2.1/cassandra/operations/ops_add_node_to_cluster_t.html) and requires waiting between adding nodes.
Instead, we can have multiple DBs running, one per resource. This would scale faster.
However, this would require:

1. run ycsb load on server instantiation to ensure each server has the db.
2. The kubernetes service should automatically detect new services