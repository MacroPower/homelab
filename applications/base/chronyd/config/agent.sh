#!/bin/sh

# LOG_LEVEL environment variable is not present, so populate with chrony default (0)
# chrony log levels: 0 (informational), 1 (warning), 2 (non-fatal error) and 3 (fatal error)
if [ -z "${LOG_LEVEL}" ]; then
  LOG_LEVEL=0
else
  # confirm log level is between 0-3, since these are the only log levels supported
  if [ "${LOG_LEVEL}" -gt 3 ]; then
    # level outside of supported range, let's set to default (0)
    LOG_LEVEL=0
  fi
fi

# confirm correct permissions on chrony run directory
if [ -d /run/chrony ]; then
  chown -R chrony:chrony /run/chrony
  chmod o-rx /run/chrony
  # remove previous pid file if it exist
  rm -f /var/run/chrony/chronyd.pid
fi

# confirm correct permissions on chrony variable state directory
if [ -d /var/lib/chrony ]; then
  chown -R chrony:chrony /var/lib/chrony
fi

exec /usr/sbin/chronyd -d -f /etc/chrony/chrony.conf -L ${LOG_LEVEL}
