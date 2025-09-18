# TCPM

## Cookie Generation

```sh
docker run --name tcpm -v $(pwd)/apps/twitch/channel-points-miner/base/config/run.py:/usr/src/app/run.py:ro -p 5000:5000 rdavidoff/twitch-channel-points-miner-v2
```
