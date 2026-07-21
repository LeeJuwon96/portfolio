# 백업 구현 상세

> 문서 목적: 백업 파트에서 실제로 구성한 도구, 자동화 방식, 저장 흐름을 구현 단위로 설명합니다.

## 1. Kubernetes 리소스 백업

Kubernetes namespace 리소스는 Velero Schedule로 백업했습니다.

주요 대상:

- application namespace
- operator namespace
- Deployment
- Service
- ConfigMap
- Secret

Velero를 사용한 이유는 GitOps만으로는 실제 클러스터에 생성된 Secret이나 운영 중 변경된 리소스 상태를 모두 보장하기 어렵기 때문입니다. Velero는 클러스터 API에 존재하는 리소스 상태를 백업하기 때문에 GitOps를 보완하는 역할을 합니다.

## 2. etcd snapshot

etcd snapshot은 Kubernetes control-plane 상태를 백업하기 위한 계층입니다.

| 구분 | Velero | etcd snapshot |
| --- | --- | --- |
| 복구 단위 | namespace / Kubernetes 리소스 | control-plane 상태 |
| 위험도 | 상대적으로 낮음 | 높음 |
| 사용 상황 | namespace 삭제, Secret 복구 | control-plane 장애 |
| 검증 방식 | Restore 리소스 생성 | checksum, status, restore rehearsal |

etcd restore는 클러스터 전체 상태에 영향을 줄 수 있으므로, 발표 환경에서는 실제 control-plane 복구 대신 snapshot 무결성과 restore rehearsal을 검증했습니다.

## 3. mgmt DB / Storage / Config 백업

mgmt 서버에서 관리되는 데이터는 Kubernetes 내부 리소스가 아니므로 Velero가 아니라 host/server 관점에서 백업했습니다.

백업 대상:

- PostgreSQL logical dump
- Storage file archive
- mgmt config archive
- k3d/K3s SQLite datastore

PostgreSQL은 volume 복사보다 `pg_dump` 기반 logical backup을 선택했습니다. 그 이유는 특정 테이블 또는 schema 단위 복구가 가능하고, 복구 테스트 결과를 SQL로 확인하기 쉽기 때문입니다.

## 4. restic host volume backup

Harbor, GitLab, Grafana 같은 mgmt 서비스는 host volume에 중요한 데이터를 저장합니다. 이 영역은 restic으로 snapshot을 남겼습니다.

restic을 사용한 이유:

- 암호화 지원
- 증분 백업
- 중복 제거
- snapshot 목록 조회
- stage directory로 선택 복구 가능

단순 `tar`나 `rsync`보다 장기적으로 백업 이력 관리와 선택 복구에 유리합니다.

## 5. MinIO 중앙 저장소

모든 백업 산출물은 mgmt MinIO에 저장했습니다.

| bucket | 목적 |
| --- | --- |
| `velero` | Kubernetes 리소스 백업 |
| `etcd` | control-plane snapshot |
| `db-backup` | PostgreSQL dump, storage, config |
| `restic` | host volume snapshot repository |

이렇게 분리하면 복구 상황에서 어떤 백업을 써야 하는지 빠르게 판단할 수 있습니다.

## 6. AWS S3 offsite mirror와 Lifecycle

MinIO만 있으면 mgmt 서버 장애 시 백업 저장소까지 함께 영향을 받을 수 있습니다. 그래서 mgmt MinIO의 주요 백업 bucket을 AWS S3로 mirror하고, S3에는 Lifecycle 정책을 적용했습니다.

```text
원본 데이터.
  -> mgmt MinIO
  -> AWS S3 offsite mirror
```

이 구조는 3-2-1 백업 원칙에 가까운 형태입니다. 다만 완성도 높은 3-2-1을 위해서는 정기 복구 리허설, 보관 정책, 알림 체계까지 함께 운영되어야 합니다.

## 7. 백업 스케줄

모든 백업 시간은 KST 기준으로 통일했습니다.

| 시간 | 작업 |
| --- | --- |
| 15:20 | AdGuard 백업 |
| 15:30 | DB / Storage / Config 백업 |
| 15:40 | etcd snapshot |
| 16:00 | Velero namespace 백업 |
| 16:20 | restic snapshot |
| 16:30 | MinIO to AWS S3 mirror |

실제 운영 환경이라면 서비스 사용량이 낮은 새벽 시간대가 더 적합할 수 있습니다. 프로젝트에서는 발표와 검증 편의를 위해 오후 시간대로 조정했습니다.

## 8. 실제 복구를 수행하지 않은 이유와 확인 범위

일부 복구는 실제 클러스터 상태에 큰 영향을 줄 수 있습니다.

특히 etcd restore는 namespace 하나만 되돌리는 작업이 아니라 control-plane 전체 상태를 되돌리는 작업입니다. 운영 중인 공유 팀 환경에서 이를 직접 수행하면 다른 팀원의 서비스에도 영향을 줄 수 있습니다.

공유 프로젝트 환경에서는 실제 restore를 수행하지 않고 다음 범위까지 확인하거나 절차로 정리했습니다.

| 항목 | 확인·문서화 범위 |
| --- | --- |
| Velero | backup 상태와 대상 확인, namespace restore 절차 문서화 |
| PostgreSQL | dump 산출물 확인, 선택 복구 명령과 확인 기준 문서화 |
| restic | snapshot 목록 확인, stage directory 복구 절차 문서화 |
| etcd | checksum과 snapshot status 확인, 격리 환경 restore 절차 문서화 |

정리:

운영 중인 공유 환경에서 전체 restore는 위험하기 때문에 백업 상태와 무결성 확인에 집중했습니다. 실제 장애 상황에서 따라 할 복구 순서와 확인 기준은 Runbook으로 분리해 정리했습니다.

## 9. 개선 가능 지점

- Prometheus Alertmanager 기반 백업 실패 알림
- 정기 복구 리허설 자동화
- RPO/RTO 수치화
- AWS S3 Lifecycle 전환 주기와 실제 보관 비용 모니터링 고도화
- 백업 성공/실패 대시보드 구성
