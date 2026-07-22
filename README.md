# Kubernetes 백업·복구 프로젝트 정리

Kubernetes 기반 팀 프로젝트에서 백업/복구 파트를 담당하며 정리한 기술 문서입니다.

이 저장소는 실제 운영 저장소의 원본 파일을 복사한 것이 아니라, 프로젝트에서 설계하고 검증한 백업 구조를 **민감정보 없이 재구성한 포트폴리오**입니다.

## 문서 안내

- `README.md`: 프로젝트 요약
- [`docs/backup-architecture.md`](docs/backup-architecture.md): 백업 구조
- [`docs/gitops-velero-etcd.md`](docs/gitops-velero-etcd.md): Kubernetes 백업 자동화
- [`docs/backup-details.md`](docs/backup-details.md): 실제 구현 내용
- [`docs/restore-runbook.md`](docs/restore-runbook.md): 복구 절차 설계
- [`docs/evidence/s3-offsite-implementation.md`](docs/evidence/s3-offsite-implementation.md): S3 offsite 구현 증거
- [`docs/project-contribution-scope.md`](docs/project-contribution-scope.md): 팀 결과와 개인 기여

## 한눈에 보는 구조

백업 대상의 특성에 따라 Kubernetes 리소스, 클러스터 상태, DB, 서비스 볼륨으로 구분하고 각 대상에 맞는 도구를 적용했습니다.

## 프로젝트에서 해결한 문제

서비스는 Kubernetes 클러스터 위에서 동작하고, 데이터베이스와 운영 도구는 mgmt 서버에서 관리되는 구조였습니다. 그래서 단일 도구로 모든 것을 백업하기보다 복구 대상의 성격에 따라 백업 방식을 분리했습니다.

| 복구 대상 | 사용 도구 | 백업 결과 |
| --- | --- | --- |
| Kubernetes namespace 리소스 | Velero | Deployment, Service, ConfigMap, Secret |
| 클러스터 control-plane 상태 | etcd snapshot | `snapshot.db`, `SHA256SUMS` |
| PostgreSQL 데이터 | `pg_dump`, `pg_dumpall` | `postgres.dump`, `globals.sql` |
| Storage 파일과 설정 | `tar`, shell script | 압축 archive |
| mgmt 서버 볼륨 | restic | 암호화 snapshot repository |
| 중앙 백업 저장소 | MinIO | bucket/prefix 기반 보관 |
| Offsite 백업·장기 보관 | AWS S3 | MinIO 백업본 복제, 생명주기 정책 적용 |

## 백업 구성

각 데이터의 성격에 맞는 백업·검증 절차를 정리했습니다. mgmt MinIO의 주요 백업 bucket은 AWS S3로 복제하고, S3에는 생명주기 정책을 적용해 장기 보관 비용을 관리했습니다.

## 내가 담당한 역할

- 백업 대상을 Kubernetes 리소스, DB, 파일, control-plane 상태로 분류
- Velero Schedule과 Kubernetes CronJob 기반 백업 자동화 구조 정리
- mgmt 서버의 PostgreSQL dump, 설정 archive, k3d/K3s datastore 백업 흐름 정리
- MinIO bucket 구조를 백업 목적별로 분리
- MinIO 주요 백업 bucket의 AWS S3 offsite 복제 및 생명주기 정책 적용
- 장애 상황별 복구 절차와 검증 기준 문서화

## 구현 핵심

### 1. GitOps 기반 Kubernetes 백업

Velero Schedule은 Kubernetes 리소스 백업을 담당하고, etcd snapshot은 CronJob으로 실행했습니다.

- Velero Schedule: namespace 리소스 백업
- CronJob: control-plane 노드에서 etcd snapshot 생성
- Argo CD: Git에 저장된 백업 설정을 각 클러스터에 반영

관련 문서: [GitOps 백업 구조](docs/gitops-velero-etcd.md)

### 2. mgmt 서버 백업

mgmt 서버에서는 컨테이너로 실행되는 DB와 host volume을 백업했습니다.

- PostgreSQL logical dump
- Storage 파일 archive
- 운영 설정 archive
- k3d/K3s SQLite datastore backup
- restic snapshot

### 3. 중앙 저장소, offsite 복제와 보관 비용 관리

백업 산출물은 MinIO에 목적별 bucket/prefix로 구분해 저장했습니다. mgmt MinIO의 주요 백업 bucket을 AWS S3로 복제해 offsite 사본을 확보했고, S3에는 생명주기 정책을 적용하여 오래된 객체의 보관 비용을 줄이도록 구성했습니다.

- `velero`: Kubernetes 리소스 백업
- `etcd`: control-plane snapshot
- `db-backup`: DB dump, storage, config
- `restic`: host volume snapshot repository

관련 문서: [백업 아키텍처](docs/backup-architecture.md)

## 복구 절차 설계

백업은 파일 생성보다 실제 복구 가능성이 중요하다고 판단해 장애 유형별 복구 절차를 분리했습니다. 공유 프로젝트 환경에 영향을 줄 수 있어 전체 복구를 수행한 결과가 아니라, 백업 상태와 무결성을 확인하고 실제 복구 시 사용할 순서와 기준을 정리한 내용입니다.

| 장애 상황 | 설계한 복구 방식 |
| --- | --- |
| namespace 삭제 | Velero Restore |
| 회원 데이터 삭제 | PostgreSQL dump restore |
| mgmt volume 손상 | restic restore |
| control-plane 장애 | etcd snapshot 상태·checksum 확인 후 격리 환경에서 restore |

관련 문서: [복구 Runbook](docs/restore-runbook.md)

## 예시 파일

실제 운영 파일이 아니라, 민감정보를 제거해 공개 문서용으로 재작성한 예시입니다.

- [Velero Schedule 예시](examples/velero-schedule.yaml)
- [etcd CronJob 예시](examples/etcd-snapshot-cronjob.yaml)
- [mgmt DB 백업 흐름 예시](examples/mgmt-db-backup-flow.sh)

## 공개 구현 증거와 기여 범위

공개된 [팀 프로젝트 GitHub](https://github.com/ktcloud4-acer)의 원본 코드와 Git 커밋을 기준으로 구현 증거와 개인 기여 범위를 정리했습니다.

- [MinIO → AWS S3 offsite 구현 증거](docs/evidence/s3-offsite-implementation.md)
- [팀 프로젝트 결과와 개인 기여 범위](docs/project-contribution-scope.md)

S3 Lifecycle 정책은 실제 AWS 환경에 적용했지만 공개 저장소에는 설정 코드가 남아 있지 않아, 발표자료를 보조 근거로 표시하고 추가 공개 증거가 필요한 항목으로 구분했습니다.

## 보안 처리

이 저장소에는 다음 정보를 포함하지 않습니다.

- 실제 Access Key, Secret Key, Token
- 내부 도메인과 사설 IP
- 실제 팀원 prefix
- 실제 운영 bucket 이름
- `.env`, kubeconfig, certificate, private key

## 배운 점

백업에서 중요한 것은 단순히 백업 파일을 만드는 것이 아니라, 장애 상황에서 어떤 백업을 선택해 어떤 순서로 복구할 수 있는지 설명 가능한 구조를 만드는 것이라고 느꼈습니다.

Kubernetes 리소스, DB 데이터, 파일 볼륨, control-plane 상태는 복구 방식이 다르기 때문에 백업 도구도 분리되어야 했고, 이 과정을 통해 백업을 운영 안정성과 장애 대응 전략의 일부로 바라보게 되었습니다.

또한 MinIO 백업본을 AWS S3로 외부 복제하고 생명주기 정책을 적용하면서, 백업은 복구 가능성뿐 아니라 장애 도메인 분리, 보관 기간과 비용까지 함께 고려해야 한다는 점을 배웠습니다.
