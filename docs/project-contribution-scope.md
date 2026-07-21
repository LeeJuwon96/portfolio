# 팀 프로젝트 결과와 개인 기여 범위

이 문서는 `ktcloud4-acer` 조직의 공개 저장소와 Git 커밋 기록을 기준으로 팀 전체 결과와 이주원님의 직접 기여를 구분한 자료입니다.

## 작성 기준

- 확인 계정: [`LeeJuwon96`](https://github.com/LeeJuwon96)
- 확인 author email: `ljw3782@gmail.com`
- 확인 대상: `acer-mgmt`, `acer-argocd`, `acer-web`, `acer-aio`, `acer-docs`의 `main`
- merge commit은 직접 구현 건수에서 제외했습니다.

Git 커밋은 강한 구현 근거지만 모든 회의·테스트·운영 활동을 기록하지는 않습니다. 따라서 “커밋이 없다”를 “참여하지 않았다”로 해석하지 않고, 공개 Git으로 직접 입증할 수 있는 범위를 구분하는 목적으로 사용합니다.

## 커밋으로 확인되는 개인 기여

| 저장소 | 비병합 커밋 | 확인된 주요 영역 |
| --- | ---: | --- |
| [`acer-mgmt`](https://github.com/ktcloud4-acer/acer-mgmt) | 9 | mgmt DB 백업, MinIO→AWS S3 offsite, KST timestamp, restic schedule, Vault Agent secret, 백업 Runbook |
| [`acer-argocd`](https://github.com/ktcloud4-acer/acer-argocd) | 10 | Velero Schedule, etcd CronJob, bucket 분리, KST timestamp, ExternalSecret, credential parser test |
| [`acer-docs`](https://github.com/ktcloud4-acer/acer-docs) | 1 | Vault backup secret bootstrap Runbook |
| **합계** | **20** | 백업·복구 자동화, GitOps, Secret 연동, 문서화 |

## 영역별 구분

| 영역 | 팀 전체 결과 | 이주원님의 공개 Git 근거 | 포트폴리오 표현 |
| --- | --- | --- | --- |
| OpenStack | Kolla-Ansible 기반 AIO, Nova·Neutron·Glance·Keystone 환경 | `acer-aio`에서 `LeeJuwon96` 명의 직접 커밋은 확인되지 않음 | “팀이 구축한 OpenStack 환경에서 Kubernetes와 백업 파트를 연동·검증” |
| CI/CD | GitLab Runner, Harbor, SonarQube, Argo CD 기반 배포 흐름 | `acer-web`에서 직접 커밋은 확인되지 않음 | “팀 CI/CD 흐름을 이해하고 백업 manifest를 Argo CD GitOps로 연동” |
| 모니터링 | Prometheus, Grafana, Alertmanager, ELK 중앙 관측 환경 | 모니터링 구성 파일에 대한 직접 커밋은 확인되지 않음 | “팀 모니터링 환경과 백업 파트의 연동 지점을 이해하고 개선 지표를 도출” |
| Kubernetes 백업 | 팀별 namespace와 control-plane 백업 | Velero·etcd Schedule과 overlay 직접 구현 | “Velero Schedule과 etcd snapshot CronJob을 GitOps로 구성” |
| mgmt 백업 | DB·Storage·Config·host volume 백업 | mgmt DB backup script/timer 직접 구현 | “PostgreSQL·Storage·Config 백업 자동화 구성” |
| Offsite DR | MinIO 주요 bucket의 AWS S3 사본 | offsite script/service/timer 직접 구현 | “MinIO→AWS S3 offsite mirror 구현” |
| Secret 관리 | Vault·External Secrets 기반 credential 관리 | Vault Agent secret 전환과 Velero ExternalSecret 직접 구현 | “백업 credential을 Vault 기반으로 외부화” |
| 문서화 | 팀 운영·복구 문서 | 백업 아키텍처 자료와 Runbook 직접 작성 | “운영자가 따라 할 수 있는 복구 절차 문서화” |

## 대표 직접 기여 커밋

### mgmt 백업·Offsite

- [`fd0a517` Add scheduled mgmt backup job](https://github.com/ktcloud4-acer/acer-mgmt/commit/fd0a5176549379a1ec7957bc4a9b67a1cf630734)
- [`67f7843` Add MinIO offsite S3 mirror job](https://github.com/ktcloud4-acer/acer-mgmt/commit/67f7843e31aa0f2b1aedf7258135d2222651385c)
- [`8759b85` Mirror Velero before restic offsite backup](https://github.com/ktcloud4-acer/acer-mgmt/commit/8759b8584cac6a45279538035bbd304e0416c5d1)
- [`4f1833f` Use KST timestamps for mgmt DB backups](https://github.com/ktcloud4-acer/acer-mgmt/commit/4f1833f2537355a3442587d2286fbf5f0e8ff22d)
- [`6033f11` Fix restic schedule date math](https://github.com/ktcloud4-acer/acer-mgmt/commit/6033f115adc292a95738b8a04f3ce6b42942ce57)

### Kubernetes·GitOps 백업

- [`a82c102` Add Velero schedule for ljw web-service](https://github.com/ktcloud4-acer/acer-argocd/commit/a82c102c1f7531f5b1a994dc42e35df7a68d798e)
- [`fbfa425` Add Velero schedules for all web-service clusters](https://github.com/ktcloud4-acer/acer-argocd/commit/fbfa4256068b5ce68f5a9ba1c50f133e96f6fa7b)
- [`4c2aaf8` Add etcd snapshot backup schedule](https://github.com/ktcloud4-acer/acer-argocd/commit/4c2aaf8226a882a5ab1a03722e98617d32971e60)
- [`c84c242` Store etcd snapshots in etcd bucket](https://github.com/ktcloud4-acer/acer-argocd/commit/c84c24285dc99c6d67a7f3b97e00f1d672ec7746)
- [`f88a2db` Add tailscale namespace to Velero schedule](https://github.com/ktcloud4-acer/acer-argocd/commit/f88a2db84328262da68f645fe4a0a4eb3cffd4ea)

### Secret·안정성·문서화

- [`1c0ae57` Source backup secrets from Vault Agent](https://github.com/ktcloud4-acer/acer-mgmt/commit/1c0ae57e9d14438a4bbc3dbaefcab8da8a65bd7d)
- [`1ef6084` Manage Velero credentials with External Secrets](https://github.com/ktcloud4-acer/acer-argocd/commit/1ef6084034ef84a01eea948a303bd94333fc3440)
- [`9fbfcb9` Handle credential files without trailing newline](https://github.com/ktcloud4-acer/acer-argocd/commit/9fbfcb903a9b6b183622a7b66a78bcd76b7c20db)
- [`0360868` Add backup architecture runbooks](https://github.com/ktcloud4-acer/acer-mgmt/commit/036086808ffaafc05af39b12f09c490461207d55)
- [`5ba7b2e` Add Vault backup secret bootstrap runbook](https://github.com/ktcloud4-acer/acer-docs/commit/5ba7b2e914ede9a10e5fe5b258b4ce4582e9332f)

## 면접에서 사용할 설명

### 팀 전체 프로젝트

> 팀은 OpenStack 위에 Kubernetes 멀티 클러스터를 구성하고, GitLab CI·Harbor·Argo CD 배포, Prometheus·Grafana 모니터링, Vault 보안, MinIO·AWS S3 백업을 연결한 production-like 플랫폼을 구축했습니다.

### 나의 직접 기여

> 저는 백업·복구 파트를 담당했습니다. Velero Schedule과 etcd snapshot CronJob을 GitOps로 구성하고, mgmt 서버의 DB·Storage·Config 백업과 MinIO→AWS S3 offsite mirror를 script·systemd timer로 자동화했습니다. 또한 backup credential을 Vault Agent와 External Secrets로 외부화하고, 장애 유형별 Runbook을 작성했습니다. 이 범위는 공개 저장소의 20개 비병합 커밋으로 확인할 수 있습니다.

### 협업 영역

> OpenStack, CI/CD, 모니터링은 각 담당 팀원이 주도했습니다. 저는 해당 구성 전체를 제 구현이라고 말하지 않고, 백업 파트가 OpenStack 위 Kubernetes, Argo CD, Vault와 연결되는 지점을 이해하고 조율한 경험으로 설명합니다.

## 출처

- [ktcloud4-acer 조직](https://github.com/ktcloud4-acer)
- [acer-aio: OpenStack](https://github.com/ktcloud4-acer/acer-aio/tree/main/10-openstack-kolla)
- [acer-web: GitLab CI](https://github.com/ktcloud4-acer/acer-web/blob/main/.gitlab-ci.yml)
- [acer-mgmt: Prometheus](https://github.com/ktcloud4-acer/acer-mgmt/tree/main/compose/stacks/observability/prometheus)
- [acer-mgmt: Grafana](https://github.com/ktcloud4-acer/acer-mgmt/tree/main/compose/stacks/observability/grafana)
- [acer-argocd: Backup](https://github.com/ktcloud4-acer/acer-argocd/tree/main/backup)
