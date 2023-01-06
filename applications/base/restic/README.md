# Restic

This runs a [Restic][restic] HTTP server for any RClone backend. This is used by
external services, but you can also use it to back up k8s persistent volumes or
other data, e.g. from pgdump.

Unlike many other applications, this is not proxied externally (i.e. traffic
does not flow through Cloudflare), which allows for good speed and better
reliability (no timeouts etc). As a result of this, it needs its own cert, not
the normal one in the Traefik defaults.

## Restic Browser

You can use [Restic Browser][restic-browser] for a nice interface to restore
files. When prompted, select `REST Server` and use the normal Restic endpoint.

For the URL, since we also use basic auth middleware in addition to the normal
encryption, you can specify it in the URL, e.g.:

```text
https://user:pass@restic.example.com/repo
```

You may have to URL-encode the password.

## Relica

To use [Relica][relica], you will need to use the webdav endpoint. Also, the
cert must be valid since Relica does not pass the its environment to RClone
(thus you can't ignore self-signed certs).

Also, Windows users, in case you need to adjust the launch script, you can find
the launch command here:

```text
Win + R -> regedit -> HKCU\Software\Microsoft\Windows\CurrentVersion\Run
```

And then edit, e.g.:

```text
powershell -command "echo 'hello'; Start-Process powershell -ArgumentList \"\"\"C:\Users\macropower\AppData\Local\Relica\relica.exe\"\" -config \"\"C:\Users\macropower\AppData\Local\Relica\config.toml\"\" daemon\" -WindowStyle hidden"
```

I ended up not using Relica because you can't see the backup status, and also
the `Relica (Restic -> RClone) -> RClone HTTP server -> Backend` pipeline isn't
great. I am not sure why it doesn't support just using Restic to connect to an
HTTP server, but it does not.

[restic]: https://restic.net/
[relica]: https://relicabackup.com/
[restic-browser]: https://github.com/emuell/restic-browser
