# Rclone Copy

## S3 Upload Large Files

```sh
rclone copy -v \
    --size-only \
    --fast-list \
    --transfers 1 \
    --retries 10 \
    --retries-sleep 60s \
    --bwlimit 2M:off \
    /userdata/Backups s3-bucket:
```

## Download

```sh
rclone copy -v remote:/ /userdata/folder
```
