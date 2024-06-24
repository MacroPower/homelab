#!/bin/bash

iptables -I INPUT 1 -p tcp -m tcp --dport 6443 -j ACCEPT -m comment \
    --comment "iX Custom Rule to allow connection requests to k8s cluster from all external sources"
