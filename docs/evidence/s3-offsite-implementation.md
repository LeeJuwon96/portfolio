# MinIO → AWS S3 Offsite 백업 구현 증거

이 문서는 팀 프로젝트 공개 저장소에서 확인할 수 있는 MinIO → AWS S3 offsite 백업의 구현 근거와 이주원님의 직접 기여 범위를 정리한 자료입니다.

## 확인된 결론

- mgmt MinIO의 `db-backup`, `etcd`, `velero`, `restic` bucket을 AWS S3로 mirror하는 스크립트가 구현되어 있습니다.
- systemd oneshot service와 timer를 통해 매일 실행되도록 구성되어 있습니다.
- 초기 offsite 스크립트·service·timer는 이주원님이 직접 추가했습니다.
- 이후 팀원이 AWS S3 기본 암호화 사전검증과 Vault Raft snapshot 연동을 보강했습니다.
- S3 Lifecycle 정책은 실제 AWS 환경에 적용했지만, 정책 JSON이나 Terraform 같은 설정 코드는 공개 팀 저장소와 Git 이력에서 확인되지 않았습니다. 현재 공개 근거는 발표자료이며, AWS Console 화면 또는 CLI 출력의 비식별 사본을 추가하면 증거가 완성됩니다.

## 1. 직접 구현 근거

### 최초 offsite mirror 구현

[커밋 `67f7843` - Add MinIO offsite S3 mirror job](https://github.com/ktcloud4-acer/acer-mgmt/commit/67f7843e31aa0f2b1aedf7258135d2222651385c)

이 커밋에서 이주원님이 다음 세 파일을 추가했습니다.

- `compose/scripts/minio-offsite-s3-backup.sh`
- `compose/systemd/minio-offsite-s3-backup.service`
- `compose/systemd/minio-offsite-s3-backup.timer`

### 현재 mirror 로직

[현재 offsite 백업 스크립트 21~66행](https://github.com/ktcloud4-acer/acer-mgmt/blob/main/compose/scripts/minio-offsite-s3-backup.sh#L21-L66)

현재 스크립트에서 확인되는 동작은 다음과 같습니다.

1. MinIO와 AWS S3 alias를 구성합니다.
2. AWS S3 bucket의 SSE-S3 또는 SSE-KMS 기본 암호화를 먼저 확인합니다.
3. `db-backup`, `etcd`, `velero`를 AWS S3의 같은 prefix로 mirror합니다.
4. `restic` mirror는 최대 3회 재시도합니다.
5. 모든 작업이 끝나면 완료 로그를 남깁니다.

### Velero 순서 보완

[커밋 `8759b85` - Mirror Velero before restic offsite backup](https://github.com/ktcloud4-acer/acer-mgmt/commit/8759b8584cac6a45279538035bbd304e0416c5d1)

Velero backup을 restic보다 먼저 복제하도록 순서를 보완한 커밋도 이주원님이 작성했습니다.

## 2. 자동 실행 근거

| 근거 | 확인 내용 |
| --- | --- |
| [systemd service](https://github.com/ktcloud4-acer/acer-mgmt/blob/main/compose/systemd/minio-offsite-s3-backup.service#L1-L8) | 스크립트를 oneshot 작업으로 실행 |
| [systemd timer](https://github.com/ktcloud4-acer/acer-mgmt/blob/main/compose/systemd/minio-offsite-s3-backup.timer#L1-L10) | 매일 16:30 실행, 서버가 꺼져 있던 경우 `Persistent=true`로 보완 |
| [mgmt 백업 자동화 최초 커밋](https://github.com/ktcloud4-acer/acer-mgmt/commit/fd0a5176549379a1ec7957bc4a9b67a1cf630734) | PostgreSQL·Storage·Config 백업 script/service/timer 추가 |

프로젝트에서는 발표와 검증 편의를 위해 오후 시간대를 사용했습니다. 실제 운영 환경에서는 트래픽과 RPO를 기준으로 시간대를 다시 정해야 합니다.

## 3. Secret 관리 근거

[커밋 `1c0ae57` - Source backup secrets from Vault Agent](https://github.com/ktcloud4-acer/acer-mgmt/commit/1c0ae57e9d14438a4bbc3dbaefcab8da8a65bd7d)

이주원님은 offsite 백업이 `.env`의 고정 값 대신 Vault Agent가 렌더링한 다음 secret 파일을 읽도록 변경했습니다.

- `backup-minio.env`
- `offsite-s3.env`

[현재 스크립트 7~19행](https://github.com/ktcloud4-acer/acer-mgmt/blob/main/compose/scripts/minio-offsite-s3-backup.sh#L7-L19)에서 Vault secret 경로와 필요한 값을 확인할 수 있습니다.

## 4. 팀 후속 검증과 개인 기여 구분

[현재 암호화 사전검증 테스트](https://github.com/ktcloud4-acer/acer-mgmt/blob/main/compose/tests/test-minio-offsite-vault-encryption.sh#L70-L118)는 다음을 확인합니다.

- 기본 암호화를 확인하지 못하면 mirror를 실행하지 않는지
- SSE-S3와 SSE-KMS가 활성화된 경우 네 bucket을 모두 mirror하는지
- credential이 표준 출력과 오류 출력에 노출되지 않는지

현재 `main`의 이 테스트를 로컬에서 실행한 결과는 다음과 같습니다.

```text
MINIO_OFFSITE_VAULT_ENCRYPTION=PASS
```

다만 이 테스트와 현재의 암호화 fail-closed 로직은 팀원의 후속 커밋에서 추가됐습니다. 따라서 면접에서는 다음처럼 구분합니다.

- **내 직접 기여**: offsite script/service/timer 최초 구현, 네 bucket mirror 흐름, 실행 순서 보완, Vault Agent secret 연동
- **팀 후속 개선**: AWS 기본 암호화 사전검증 테스트와 Vault Raft snapshot offsite 경로 확장

## 5. Lifecycle 적용 증거 상태

실제 프로젝트에서는 AWS S3 Lifecycle을 다음과 같이 적용했습니다.

- 30일 이후 Standard-IA 전환
- 90일 이후 Glacier 전환

현재 공개 가능한 보조 근거는 [프로젝트 발표자료](../../acer-ppt_발표자료.pdf) 16페이지입니다. 다만 공개 팀 저장소 전체와 Git 이력에서는 Lifecycle policy JSON, AWS CLI 적용 명령 또는 IaC 파일을 찾지 못했습니다.

포트폴리오의 증거 수준을 높이려면 아래 중 하나를 비식별 처리해 추가합니다.

1. AWS Console의 Management → Lifecycle rules 화면
2. 다음 명령의 결과에서 계정·bucket 정보를 제거한 JSON

```bash
aws s3api get-bucket-lifecycle-configuration \
  --bucket "$AWS_S3_BUCKET" \
  --query 'Rules[].{ID:ID,Status:Status,Transitions:Transitions}'
```

3. AWS S3 객체 목록에서 `db-backup`, `etcd`, `velero`, `restic` prefix와 수정 시각만 보이도록 가린 화면

Access Key, Secret Key, account ID, 실제 bucket 이름은 공개하지 않습니다.

## 6. 면접용 답변

> mgmt MinIO의 백업 저장소가 같은 서버 장애의 영향을 받는 문제를 줄이기 위해 `db-backup`, `etcd`, `velero`, `restic` bucket을 AWS S3로 mirror하는 스크립트와 systemd service·timer를 구현했습니다. 이후 Vault Agent가 렌더링한 credential을 사용하도록 개선했고, AWS S3에는 30일 후 Standard-IA, 90일 후 Glacier로 전환하는 Lifecycle 정책을 적용했습니다. 제가 직접 구현한 범위와 팀원이 후속 보강한 암호화 검증은 커밋 기준으로 구분해 설명할 수 있습니다.

## 출처

- [팀 프로젝트 조직](https://github.com/ktcloud4-acer)
- [acer-mgmt](https://github.com/ktcloud4-acer/acer-mgmt)
- [최초 offsite 구현 커밋](https://github.com/ktcloud4-acer/acer-mgmt/commit/67f7843e31aa0f2b1aedf7258135d2222651385c)
- [현재 offsite 스크립트](https://github.com/ktcloud4-acer/acer-mgmt/blob/main/compose/scripts/minio-offsite-s3-backup.sh)
