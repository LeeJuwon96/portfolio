# mgmt Server Backup

## 개요

mgmt 서버에는 프로젝트 운영에 필요한 데이터와 도구가 모여 있었습니다. 그래서 Kubernetes 리소스 백업과 별도로 host/server 관점의 백업을 구성했습니다.

## 백업 대상

| 대상 | 방식 | 산출물 |
| --- | --- | --- |
| PostgreSQL | `pg_dump`, `pg_dumpall` | `postgres.dump`, `globals.sql` |
| Storage files | `tar` | `storage.tar.gz` |
| mgmt config | `tar` | `mgmt-config.tar.gz` |
| k3d/K3s datastore | SQLite backup API | `k3s-sqlite-datastore.tar.gz` |
| host volume | restic | encrypted snapshot |

## PostgreSQL dump

PostgreSQL은 volume 단위 복사보다 logical dump를 우선했습니다.

이유:

- 특정 테이블 또는 schema 단위 복구가 가능
- DB 버전/환경 차이에 비교적 유연
- 복구 테스트에서 결과 확인이 쉽다

## Storage와 설정 archive

파일형 데이터는 `tar.gz` archive로 묶었습니다.

설정 파일에는 민감정보가 포함될 수 있으므로 실제 저장소에는 원본 파일을 포함하지 않습니다. 포트폴리오 문서에서는 구조만 설명합니다.

## restic snapshot

Harbor, GitLab, Grafana 같은 도구의 host volume은 restic으로 snapshot을 남겼습니다.

restic을 사용한 이유:

- 암호화 지원
- 중복 제거
- snapshot 단위 복구
- S3-compatible backend 지원

## systemd timer

mgmt 서버 백업은 Kubernetes 내부 CronJob이 아니라 mgmt 서버의 systemd timer로 관리했습니다.

이유:

- 백업 대상이 Kubernetes 내부 리소스가 아니라 host filesystem과 Docker container
- `/home/mgmt-data` 같은 host 경로 접근이 필요
- DB container와 MinIO container를 같은 서버에서 직접 제어해야 함

## MinIO 업로드

백업 산출물은 로컬 보관 후 MinIO에 업로드했습니다.

```text
/home/mgmt-data/backups
└── supabase-postgres
└── supabase-storage
└── mgmt-config
└── k3d-mgmt-datastore
```

로컬에 남긴 이유는 restic이 2차 백업으로 host backup을 수행할 수 있도록 하기 위함입니다.
