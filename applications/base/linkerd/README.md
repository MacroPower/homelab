# linkerd

## CNI

I've encountered quite a few issues with the CNI plugin.

For some reason, it appears that sometimes it just does not work on some hosts.
I'm not sure why, but the affected hosts cannot mesh pods (network validation
will fail). I just reschedule the CNI pod a few times and that seems to fix it.

It will also randomly revert itself. I'm not sure if this is due to MicroOS.

Notably, you can't see if this is working via just restarting a container. The
entier pod has to be rescheduled. This includes linkerd's own pods.
