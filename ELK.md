# ELK

* [ELK](#ELK)
  * [Elasticsearch](#Elasticsearch)
  * [Environment](#Environment)
  * [Logstash](#Logstash)
  * [Kibana](#Kibana)
  * [Filebeat](#Filebeat)


## Environment

Have worked mostly on t2.small or t3a.small spot instances. Four instances, three with 10GB of storage and an Elasticsearch instance with bigger. Nice open security groups and for my current purposes the UserData is:
```
#!/bin/bash -xe

yum update -y
yum install -y emacs
yum install -y sysstat
yum install -y telnet
yum install -y git
yum install -y java-1.8.0-openjdk

rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

cat > /etc/yum.repos.d/elasticsearch.repo <<EOF
[elasticsearch]
name=Elasticsearch repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF

useradd dunstan
cd ~ec2-user; tar cf - .ssh | (cd ~dunstan; tar xf - ; chown -R dunstan:dunstan .)

usermod -p '$1$9fd9W5tD$MNx07vBuS3vVXewBoIbi40' dunstan
usermod -G wheel dunstan
```
You may want your own variations, especially if your name isn't `dunstan` and your preferred output of `md5pass` isn't the password in my head.

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

Alternatively we'll blat a parameter file over that one that's there:

```
cat > /etc/elasticsearch.elasticsearch.yml <<EOF
cluster.name: lab

node.name: lab1

path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch

bootstrap.memory_lock: true

network.host: 0.0.0.0
http.port: 9200

discovery.type: 'single-node'

indices.query.bool.max_clause_count: 8192
search.max_buckets: 250000

action.destructive_requires_name: 'true'

reindex.remote.whitelist: '*:*'

xpack.monitoring.enabled: 'true'
xpack.monitoring.collection.enabled: 'true'
xpack.monitoring.collection.interval: 30s

xpack.security.enabled: 'true'
xpack.security.audit.enabled: 'false'

node.ml: 'false'
xpack.ml.enabled: 'false'

xpack.watcher.enabled: 'false'

xpack.ilm.enabled: 'true'

xpack.sql.enabled: 'true'
EOF
```

Now, having set `xpack.security.enabled` to true means we're going to have to set up users. This is done using
`/usr/share/elasticsearch/bin/elasticsearch-setup-passwords interactive`. Alternatively turn it off.

Setting system parameters (should supersede the below)

```
mkdir /etc/systemd/system/elasticsearch.service.d
cat > /etc/systemd/system/elasticsearch.service.d/elasticsearch.conf <<EOF
[Service]
LimitNOFILE=131072
LimitNPROC=8192
LimitMEMLOCK=infinity
LimitFSIZE=infinity
LimitAS=infinity
EOF
```

And also

```
cat > /etc/sysctl.d/70-elasticsearch.conf <<EOF
vm.max_map_count=262144
EOF
```

Reread these parameters with `systemctl daemon-reload`


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

Alternatively we'll blat a parameter file over that one that's there:
```
cat > /etc/kibana/kibana.yml
server.name: 'lab1'
server.host: '0.0.0.0'
server.port: 5601

server.maxPayloadBytes: 8388608

elasticsearch.hosts: ['http://127.0.0.1:9200']
elasticsearch.username: 'kibana'
elasticsearch.password: 'changeme'
elasticsearch.requestTimeout: 132000
elasticsearch.shardTimeout: 120000

kibana.index: '.kibana'

#kibana.defaultAppId: 'dashboard/<dashboard_id>'

#logging.quiet: true
#logging.timezone: 'UTC'

vega.enableExternalUrls: true

console.enabled: true

xpack.security.enabled: true
xpack.security.audit.enabled: false

xpack.monitoring.enabled: true
xpack.monitoring.kibana.collection.enabled: true
xpack.monitoring.kibana.collection.interval: 30000

xpack.monitoring.ui.enabled: true
xpack.monitoring.min_interval_seconds: 30
#xpack.monitoring.ui.container.elasticsearch.enabled: 'false'

#xpack.apm.enabled: true
#xpack.apm.ui.enabled: true

xpack.grokdebugger.enabled: true
xpack.searchprofiler.enabled: true

xpack.graph.enabled: false

xpack.infra.enabled: true
#xpack.infra.sources.default.logAlias: 'filebeat-*'
#xpack.infra.sources.default.metricAlias: 'metricbeat-*'
#xpack.infra.sources.default.fields.timestamp: '@timestamp'
#xpack.infra.sources.default.fields.message: ['message','@message']
#xpack.infra.sources.default.fields.tiebreaker: '_doc'
#xpack.infra.sources.default.fields.host: 'beat.hostname'
#xpack.infra.sources.default.fields.container: 'docker.container.name'
#xpack.infra.sources.default.fields.pod: 'kubernetes.pod.name'

xpack.ml.enabled: false

xpack.reporting.enabled: false
#xpack.reporting.encryptionKey: ''

#xpack.spaces.enabled: true
#xpack.spaces.maxSpaces: 1000
```

Again, consider whether you want to have `xpack.security.enabled` set. The entries for `xpack.apm` and `xpack.spaces` are turned off because of bugs in Kibana - it it works with them on, turn them on.

Worth starting by hand first so you'll see java packages being bundled/built.

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
