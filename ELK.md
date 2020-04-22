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

Install Java *(check if this is necessary, or if a current Elastic version bundles its own JVM)*

```
yum install -y java-1.8.0-openjdk
update-alternatives --config java
```

And check Java with: `java -version`

Install Elasticsearch
```
yum install elasticsearch-oss
```

Set the JVM heap size in `/etc/elasticsearch/jvm.options` with both figures at about 1/3 total memory (less if bunking up with logstash) and definitely less than 32GB

Fix some parameters in `/etc/elasticsearch/elasticsearch.yml`:

* `cluster.name` (*Arbitrary String*)
* `node.name` (*Arbitrary String*)
* `network.host` (*Local IP Address*)
* `discover.seed_hosts` (*Local IP Address*)
* `cluster.initial_master_nodes` (*Local IP Address*)

Setting system parameters (should supersede the below)

```
mkdir /etc/systemd/system/elasticsearch.service.d
cat > /etc/systemd/system/elasticsearch.service.d/elasticsearch.conf <<EOF
[Service]
LimitNOFILE=131072
LimitNOPROC=8192
LimitMEMLOCK=infinity
LimitFSIZE=infinity
LimitAS=infinity
EOF
```



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

## Filebeat

```
yum install filebeat
```

Then edit `/etc/filebeat/filebeat.yml`:

*input section*
```
...
enabled: true
paths:
  - /var/log/messages
document_type: syslog
```

*general section*
```
...
tags: ["tagname1", "tagname2"]

fields:
  dunstan_field: dunstan_value
```

*outputs section*

* turn off elasticsearch output
* turn on logstash output, setting host and port

Now go back to the logstash server and `/etc/logstash/conf.d` and create a file `beats.conf`
```

input {
    beats {
        port => "5043"
    }

}

filter {
    if [type] == "syslog" {
        grok {
            match => { "message" => "%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSL\
OGHOST:syslog_hostname} %{DATA:syslog_program}(?:\[%{POSINT:syslog_pid}\])?: %{\
GREEDYDATA:syslog_message}" }
        }
        date {
            match => [ "syslog_timestamp", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss"\
 ]
        }
    }
}

output {
    elasticsearch {
        hosts => ["10.0.3.132"]
        index => "%{[@metadata][beat]}-%{+YYYY.MM.dd}"
        document_type => "%{[@metadata][type]}"
    }

}
```

And restart logstash

Then start filebeat on the filebeat server.


Add on a netflow listener, at the end of the input section in filebeat.yml

```
- type: netflow
  host: "0.0.0.0:2055"
  protocols: [ v5, v9, ipfix ]
```
