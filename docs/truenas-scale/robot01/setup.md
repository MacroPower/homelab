# Setup

Not IAC because the TF providers don't work really well. Maybe one day.

Create a shared macvlan network for docker containers:

```
docker network create -d macvlan \
  --subnet=10.42.2.0/24 \
  -o parent=vlan4000 \
  shared_macvlan
```

For some reason you can't set `fe80::1` as a default route. So, add a post-init command:

```
ip -6 route replace default via fe80::1 dev eno1
```
