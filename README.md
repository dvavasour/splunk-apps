# splunk-apps
Where I keep my Splunk apps.

* [Handy Spells](#Handy_Spells)
* [Cheat Sheets](#Cheat_Sheets)
  * [Original Cheat Sheet](#Original_Cheat_Sheet)
  * [CFRT Cheat Sheet](#CFRT_Cheat_Sheet)
* [NHSD Technical Lessons](#NHSD_Technical_Lessons)
  * [Field Calculation Order](#Field_Calculation_Order)
  * [Datamodel Lookups](#Datamodel_Lookups)
  * [Custom Geo Lookup](#Custom_Geo_Lookup)
  * [Chloropleth Field Ordering](#Chloropleth_Field_Ordering)
  * [Map Tiles](#Map_Tiles)
* [ELK](#ELK)
  * [Elasticsearch](#Elasticsearch)
  * [Logstash](#Logstash)


# Handy Spells
### Reload configs (props.conf, transforms.conf etc)
`http://splunk-dev.dv-aws.uk/en-GB/debug/refresh`

### Example using CURL to fire event to HEC
`curl -k https://splunk-dev.dv-aws.uk:8088/services/collector -H 'Authorization: Splunk dd8a1447-0952-4782-8834-55345d93d2ae' -d '{"event": "ifttt from curl"}'`


# Cheat Sheets
## Original Cheat Sheet
![Alt Text for Original Cheet Sheet](https://github.com/dvavasour/splunk-apps/blob/master/jpeg/Splunk_Spellbook.jpeg)

## CFRT Cheat Sheet
![Alt Text for CFRT Cheet Sheet](https://github.com/dvavasour/splunk-apps/blob/master/jpeg/CFRT_Notes_V2.jpeg)

# NHSD Technical Lessons
## Field Calculation Order
[https://docs.splunk.com/Documentation/Splunk/8.0.1/Knowledge/Searchtimeoperationssequence](https://docs.splunk.com/Documentation/Splunk/8.0.1/Knowledge/Searchtimeoperationssequence)

## Datamodel Lookups
When you add a "lookup" to a datamodel, you specify the lookup-file field names and the returned aliases. This doesn't work: the aliases are applied late, and the datamodel works on the lookup-file field names. The implications are:

* You cannot use the same lookup table twice for (for example) source postcode from ODS and also target postcode from ODS. The conflicting lookup-file field names will break it
* When you reference the results using `tstats`, it seems you have to do so by lookup-file field name, not the alias
* When you pivot, the alias is presented. However, when you open the pivot in search it uses the lookup-file field name and renames it in the search

## Custom Geo Lookup
[https://www.splunk.com/en_us/blog/tips-and-tricks/use-custom-polygons-in-your-choropleth-maps.html](https://www.splunk.com/en_us/blog/tips-and-tricks/use-custom-polygons-in-your-choropleth-maps.html)
[https://docs.splunk.com/Documentation/Splunk/8.0.1/Knowledge/Configuregeospatiallookups](https://docs.splunk.com/Documentation/Splunk/8.0.1/Knowledge/Configuregeospatiallookups)

The XPath bit works, but there's one more thing: the name of the lookup needs to match the Folder/Schema in the KML file

## Chloropleth Field Ordering
It seems that you need the key value for a chloropleth to be in column 1 (0?) of the results - best to fix this before feeding into the `geom` command

## Map Tiles
If you use an external mapping base (i.e. Openstreetmap), the tiles don't go through Splunk, it directs the browser to download them. This means that the browser must have access to the source of tiles.

# ELK
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

Fix some parameters in `/etc/elasticsearch/elasticsearch.yml`:

* `cluster.name`
* `node.name`
* `network.host`
* `discover.seed_hosts`

Fix a kernal parameter: `sysctl -w vm.max_map_count=262144` and the number of file handles with `ulimit -n 65535` (or edit `/etc/security/limits.conf`)

And start Elasticsearch

```
yum install elasticsearch-oss
sudo systemctl start elasticsearch.service
```

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

[https://<IP Address>:9200/logstash-*/_search](https://<IP Address>:9200/logstash-*/_search)

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

