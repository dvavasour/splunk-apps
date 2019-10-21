#!/bin/bash
for i in cron maillog messages secure spooler
do
    setfacl -m g:splunk:rx /var/log/$i
done
