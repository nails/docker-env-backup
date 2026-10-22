# Docker Environment: Backup

These Dockerfiles build a container which is responsible for running database and file system backups.

Base image: `php:8.5-cli-alpine3.24`. Backups are run by the [Shed CLI](https://github.com/shedcollective/shed-cli-tool), which uses `mysqldump` (from `mariadb-client`), `tar` and `s3cmd`.

`config/mariadb-client.cnf` turns off TLS certificate verification for the MariaDB client. Since MariaDB 11.4 the client verifies by default, and the MySQL 8 database container's self-signed certificate would fail that check.

## Tags

- `nails/docker-env-backup:latest` — published for `linux/amd64` and `linux/arm64`

## Building

The image is built with `docker buildx` for `linux/amd64` and `linux/arm64` and pushed to Docker Hub as one multi-arch tag, so it works on Apple Silicon Macs and x86 servers. Run it from either kind of machine (the non-native architecture is emulated, so it is slower):

```bash
bin/build.sh            # builds and pushes nails/docker-env-backup:latest
bin/build.sh <tag>      # any other tag
```

The script pushes as it builds and then checks both platforms are in the published manifest. Do **not** run `docker push nails/docker-env-backup`: it pushes the single-architecture image from your local store over the multi-arch tag.

To test changes on your own machine without pushing, build for your architecture only:

```bash
LOCAL=1 bin/build.sh
```
