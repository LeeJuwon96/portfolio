#!/usr/bin/env bash
set -euo pipefail

# 공개 문서용 예시입니다. 실제 운영값은 포함하지 않습니다.
# This script shows the backup flow without real secrets or internal paths.

STAMP="$(TZ=Asia/Seoul date +%Y%m%dT%H%M%SKST)"
BACKUP_ROOT="${BACKUP_ROOT:-./backups}"

mkdir -p "${BACKUP_ROOT}/postgres/${STAMP}"
mkdir -p "${BACKUP_ROOT}/storage/${STAMP}"
mkdir -p "${BACKUP_ROOT}/config/${STAMP}"

echo "[1/4] PostgreSQL logical dump"
echo "docker exec db pg_dump -Fc > ${BACKUP_ROOT}/postgres/${STAMP}/postgres.dump"
echo "docker exec db pg_dumpall --globals-only > ${BACKUP_ROOT}/postgres/${STAMP}/globals.sql"

echo "[2/4] Storage archive"
echo "tar -czf ${BACKUP_ROOT}/storage/${STAMP}/storage.tar.gz ./storage"

echo "[3/4] Config archive"
echo "tar -czf ${BACKUP_ROOT}/config/${STAMP}/config.tar.gz ./compose ./secrets.example"

echo "[4/4] Upload to object storage"
echo "mc cp --recursive ${BACKUP_ROOT}/postgres/${STAMP}/ object-storage/db-backup/postgres/daily/${STAMP}/"
