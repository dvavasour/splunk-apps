#!/bin/bash
for i in cron meaillog messages secure spooler
do
    setfacl -m g:splunk:rx /var/log/$i
done
