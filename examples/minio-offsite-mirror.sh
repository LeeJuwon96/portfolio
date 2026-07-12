#!/usr/bin/env bash
set -euo pipefail

# Portfolio example only.
# Mirrors backup buckets from local MinIO to AWS S3.

SOURCE_ALIAS="${SOURCE_ALIAS:-local-minio}"
DEST_ALIAS="${DEST_ALIAS:-aws-s3}"
DEST_BUCKET="${DEST_BUCKET:-portfolio-backup-bucket}"

for bucket in db-backup etcd velero restic; do
  echo "mirror ${bucket}"
  echo "mc mirror ${SOURCE_ALIAS}/${bucket} ${DEST_ALIAS}/${DEST_BUCKET}/${bucket}"
done
