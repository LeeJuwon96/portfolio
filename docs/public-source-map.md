# Public Team Project Source Map

이 문서는 public으로 공개된 팀 프로젝트 저장소에서 백업 파트가 어디에 구현되어 있는지 정리한 자료입니다.

포트폴리오 저장소에는 운영 파일을 그대로 복사하지 않고, 구현 의도와 구조를 설명하는 방식으로 재작성했습니다.

## GitOps 백업 설정

| 팀 프로젝트 위치 | 역할 |
| --- | --- |
| `ktcloud4-acer/acer-argocd/backup/base/scalecart-daily-schedule.yaml` | Velero Schedule 기반 namespace 백업 |
| `ktcloud4-acer/acer-argocd/backup/base/etcd-snapshot-daily-cronjob.yaml` | Kubernetes CronJob 기반 etcd snapshot |
| `ktcloud4-acer/acer-argocd/backup/*/kustomization.yaml` | 팀/클러스터별 backup overlay |
| `ktcloud4-acer/acer-argocd/apps/velero.yaml` | Velero 설치/동기화 Application |
| `ktcloud4-acer/acer-argocd/apps/velero-schedule.yaml` | Velero schedule Application |

## mgmt 서버 백업 자동화

| 팀 프로젝트 위치 | 역할 |
| --- | --- |
| `ktcloud4-acer/acer-mgmt/compose/scripts/mgmt-db-backup.sh` | PostgreSQL dump, storage archive, config backup, k3d datastore backup |
| `ktcloud4-acer/acer-mgmt/compose/scripts/minio-offsite-s3-backup.sh` | MinIO bucket을 AWS S3로 mirror |
| `ktcloud4-acer/acer-mgmt/compose/scripts/adguard-backup.sh` | AdGuard 설정 백업 |
| `ktcloud4-acer/acer-mgmt/compose/scripts/backup-env.sh` | 백업 스크립트 공통 환경값 로딩 |
| `ktcloud4-acer/acer-mgmt/compose/systemd/acer-mgmt-db-backup.timer` | mgmt DB/Storage/Config 백업 schedule |
| `ktcloud4-acer/acer-mgmt/compose/systemd/minio-offsite-s3-backup.timer` | MinIO to AWS S3 mirror schedule |
| `ktcloud4-acer/acer-mgmt/compose/systemd/adguard-backup.timer` | AdGuard 백업 schedule |

## 백업 저장소 구성

| 팀 프로젝트 위치 | 역할 |
| --- | --- |
| `ktcloud4-acer/acer-mgmt/compose/stacks/backup/minio/compose.yaml` | 중앙 백업 저장소 MinIO |
| `ktcloud4-acer/acer-mgmt/compose/stacks/backup/restic/compose.yaml` | host volume snapshot용 restic |

## Secret / 인증 연동

| 팀 프로젝트 위치 | 역할 |
| --- | --- |
| `ktcloud4-acer/acer-argocd/security/eso/*/velero-externalsecret.yaml` | Velero S3 credential을 Kubernetes Secret으로 동기화 |
| `ktcloud4-acer/acer-argocd/security/eso/*/vault-auth.yaml` | Vault와 Kubernetes ServiceAccount 인증 연결 |
| `ktcloud4-acer/acer-mgmt/compose/tests/test-backup-vault-secret-config.sh` | 백업 secret 설정 검증 |
| `ktcloud4-acer/acer-mgmt/compose/tests/test-minio-offsite-vault-encryption.sh` | offsite backup secret/encryption 검증 |

## Runbook / 발표 자료

| 팀 프로젝트 위치 | 역할 |
| --- | --- |
| `ktcloud4-acer/acer-mgmt/docs/runbooks/backup-presentation.md` | 백업 발표용 설명 자료 |
| `ktcloud4-acer/acer-mgmt/docs/runbooks/backup-flow-architecture.html` | 백업 흐름 아키텍처 |
| `ktcloud4-acer/acer-mgmt/docs/runbooks/backup-beginner-guide.html` | 백업 입문자용 설명 자료 |
| `ktcloud4-acer/acer-mgmt/docs/runbooks/backup-architecture-overview.html` | 백업 구조 요약 |

## 포트폴리오에서 재구성한 이유

팀 프로젝트 원본에는 내부 도메인, 팀원 prefix, 운영 경로, secret 연동 방식 등 실제 환경 정보가 포함될 수 있습니다. 따라서 포트폴리오에는 원본 파일을 그대로 복사하지 않고 다음 기준으로 재작성했습니다.

- 실제 token, key, password 제외
- 내부 endpoint와 bucket 이름 일반화
- 팀원별 prefix 제거
- 운영 경로는 설명 가능한 수준으로만 표현
- 면접에서 설명하기 쉬운 구조 중심으로 재정리

## 면접 답변용 요약

“팀 프로젝트의 public repository에는 실제 구현 파일이 있고, 제 포트폴리오에는 해당 백업 파트를 민감정보 없이 재구성했습니다. Velero, etcd snapshot, PostgreSQL dump, restic, MinIO, AWS S3 mirror를 각각 어떤 장애 상황에 대응하기 위해 구성했는지 설명할 수 있도록 정리했습니다.”
