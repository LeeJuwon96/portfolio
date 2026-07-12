# GitOps Backup: Velero Schedule and etcd CronJob

## 왜 GitOps로 관리했는가

백업 스케줄은 운영 정책입니다. 사람이 직접 클러스터에 명령어를 입력해서 만드는 것보다, Git에 선언적으로 관리하면 변경 이력과 리뷰가 남습니다.

프로젝트에서는 Kubernetes 백업 설정을 Git에 저장하고 Argo CD가 각 클러스터에 반영하는 구조로 관리했습니다.

## Velero Schedule

Velero는 Kubernetes 리소스 백업을 담당합니다.

백업 대상:

- application namespace
- network/operator namespace
- Secret, ConfigMap, Deployment, Service 등 Kubernetes API 리소스

예시:

```yaml
apiVersion: velero.io/v1
kind: Schedule
metadata:
  name: app-daily-1600-kst
  namespace: velero
spec:
  schedule: "CRON_TZ=Asia/Seoul 0 16 * * *"
  template:
    includedNamespaces:
      - web-service
      - tailscale
    snapshotVolumes: false
    ttl: 720h0m0s
```

Velero Schedule은 Kubernetes 기본 CronJob이 아니라 Velero가 CRD로 추가한 리소스입니다. 따라서 `spec.timeZone` 필드 대신 cron 표현식에 `CRON_TZ=Asia/Seoul`을 사용했습니다.

## etcd CronJob

etcd snapshot은 Kubernetes 기본 `CronJob`으로 실행했습니다.

백업 대상:

- Kubernetes control-plane 상태
- API object 저장소의 snapshot

예시:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: etcd-snapshot-daily-1540-kst
  namespace: velero
spec:
  schedule: "40 15 * * *"
  timeZone: Asia/Seoul
  concurrencyPolicy: Forbid
```

CronJob은 Kubernetes 기본 리소스라 `timeZone: Asia/Seoul`을 직접 사용할 수 있습니다.

## Velero와 etcd snapshot 차이

| 구분 | Velero | etcd snapshot |
| --- | --- | --- |
| 목적 | namespace 리소스 백업 | control-plane 상태 백업 |
| 리소스 형태 | Velero CRD | Kubernetes CronJob |
| 복구 방식 | Velero Restore | etcd restore 절차 |
| 주요 산출물 | Backup metadata | `snapshot.db` |
| 사용 상황 | namespace 삭제, Secret 복구 | control-plane 장애, 상태 검증 |

## 검증 포인트

- Velero `BackupStorageLocation`이 `Available` 상태인지 확인
- 최근 Backup이 생성되는지 확인
- etcd snapshot 파일과 `SHA256SUMS`가 생성되는지 확인
- `etcdutl snapshot status`로 snapshot을 읽을 수 있는지 확인
