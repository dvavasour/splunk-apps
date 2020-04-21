# ELK

* [ELK](#ELK)
  * [Elasticsearch](#Elasticsearch)
  * [Logstash](#Logstash)



## Elasticsearch
### Installation on EC2 Instance

```
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
```

Then (removing the spaces at the starts of the lines)

```
cat > /etc/yum.repos.d/elasticsearch.repo <<EOF
[elasticsearch]
name=Elasticsearch repository for Apache Licensed 7.x packages
baseurl=https://artifacts.elastic.co/packages/oss-7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF
```

Install Java

```
yum install -y java-1.8.0-openjdk
update-alternatives --config java
```

And check Java with: `java -version`

Install Elasticsearch
```
yum install elasticsearch-oss
```

Fix some parameters in `/etc/elasticsearch/elasticsearch.yml`:

* `cluster.name` (*Arbitrary String*)
* `node.name` (*Arbitrary String*)
* `network.host` (*Local IP Address*)
* `discover.seed_hosts` (*Local IP Address*)
* `cluster.initial_master_nodes` (*Local IP Address*)

Fix a kernel parameter: `sysctl -w vm.max_map_count=262144` and the number of file handles with `ulimit -n 65535` (or edit `/etc/security/limits.conf`)

And start Elasticsearch

```
sudo systemctl start elasticsearch.service
```

Test if it's alive by navigating to port 9200 on this server and see if it spews out some JSON describing the instance.

## Logstash
### Installation on EC2 Instance

Install Java

```
yum install -y java-1.8.0-openjdk
update-alternatives --config java
```

And check Java with: `java -version`

Set up repo as for Elasticsearch

```
yum install logstash-oss
```

To test the connection

```
cd /usr/share/logstash
bin/logstash -e 'input { stdin { } } output { elasticsearch { hosts => ["10.0.3.166"] } }'
```

Then enter a message.

Use Postman to check the events are being indexed, with `GET` method to:

[https://<e.g. 10.0.0.1>:9200/logstash-*/_search](https://10.0.0.1:9200/logstash-*/_search)

* `logstash-*` matches any index created for logstash events
* `_search` returns all events

## Kibana
### Installation on EC2 Instance


Set up repo as for Elasticsearch

```
yum install kibana-oss
```

Set variables in `/etc/kibana/kibana.yml

* `server.host="<this machine's IP address>"`
* `server.name="<The name the users will see>"`
* `elasticsearch.hosts=["<elasticsearc-host>:9200"]`


Start the service and look to <IP-address>:5601

Start by Management -> Index Patterns and set up `logstash-*` and `@timestamp` for the index pattern, then use discover to see test events.

