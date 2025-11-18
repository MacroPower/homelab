# Setup

Create a shared macvlan network for docker containers:

```
docker network create -d macvlan \
  --subnet=10.10.0.0/16 \
  --subnet=fc42:0:0:a::/64 \
  -o parent=bond0 \
  shared_macvlan
```
