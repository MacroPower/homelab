# Rclone Copy

## S3 Upload Large Files

```bash
rclone copy -v \           ## -v = Prints Status
    --size-only \          ## Reduces S3 cost.
    --fast-list \          ## Reduces S3 cost.
    --transfers 1 \        ## Large files should be transferred one at a time.
    --retries 10 \         ##
    --retries-sleep 60s \  ##
    --bwlimit 2M:off \     ## Limits the upload speed to 2MB/s
    /userdata/Backups s3-bucket:
```

## Download

```sh
rclone copy -v remote:/ /userdata/folder
```
