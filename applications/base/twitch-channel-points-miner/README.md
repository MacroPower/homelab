# Twitch Channel Points Miner

https://github.com/Tkd-Alex/Twitch-Channel-Points-Miner-v2

## Cookies

This container uses a pickled cookie to login to Twitch on your behalf.
Interactive login does not work for obvious reasons.

To use this, run the application on your local computer and login interactively.
This will save a cookie for you under `cookies/${USER}.pkl`.

You can encode this as Base64 and upload it to your secret vault, e.g.:

```bash
base64 -i cookies/${USER}.pkl | vault secrets set TWITCH_COOKIE
```

This cookie is added to the container as `Cookie.pkl`. Which means you must set
your username as `Cookie` in your `run.py` file, which will match that cookie.
