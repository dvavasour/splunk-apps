# splunk-apps
Where I keep my Splunk apps.

* [Handy Spells](#Handy_Spells)

* [Cheat Sheets](#Cheat_Sheets)
  * [Original Cheat Sheet](#Original_Cheat_Sheet)
  * [CFRT Cheat Sheet](#CFRT_Cheat_Sheet)

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


