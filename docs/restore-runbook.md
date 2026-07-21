# 복구 절차 설계

> 문서 목적: 실제 복구 완료 결과가 아니라, 장애 상황에서 사용할 복구 순서와 확인 기준을 정리합니다.

공유 프로젝트 환경에 영향을 줄 수 있어 end-to-end restore는 수행하지 않았습니다. 이 문서의 명령은 민감정보를 제거한 절차 예시이며, 실제 적용 전에는 격리된 환경에서 검증해야 합니다.

## 1. Namespace 삭제 복구

장애 상황:

- application namespace 삭제
- operator namespace 삭제
- Secret, ConfigMap, Service 리소스 손실

복구 방식:

1. Velero backup 목록 확인
2. 최신 backup 선택
3. `Restore` 리소스 생성
4. namespace, Deployment, Pod, Secret 상태 확인

핵심 검증:

```bash
kubectl -n velero get backup
kubectl -n velero get restore
kubectl -n web-service get deploy,pod,svc,secret
```

## 2. PostgreSQL 데이터 복구

장애 상황:

- 회원 데이터 삭제
- 일부 테이블 데이터 손상

복구 방식:

1. MinIO에서 최신 PostgreSQL dump 다운로드
2. `SHA256SUMS`로 무결성 확인
3. 필요한 table 또는 schema만 선택 복구
4. 데이터 count와 샘플 row 확인

핵심 검증:

```bash
sha256sum -c SHA256SUMS
pg_restore --data-only --schema=public --table=app_users
```

## 3. restic volume 복구

장애 상황:

- Harbor, GitLab, Grafana 등 host volume 손상

복구 방식:

1. 서비스 정지
2. restic snapshot 목록 확인
3. stage directory에 restore
4. 복원 결과 검증 후 원래 경로로 교체
5. 서비스 재기동

핵심 검증:

```bash
restic snapshots
restic restore <snapshot-id> --target <restore-stage>
```

## 4. etcd snapshot 검증

장애 상황:

- control-plane 상태 이상
- API object 저장소 복구 가능성 확인 필요

검증 방식:

1. MinIO에서 최신 snapshot 다운로드
2. checksum 확인
3. `etcdutl snapshot status` 실행
4. 격리된 환경에서 임시 디렉터리 restore 수행

핵심 검증:

```bash
sha256sum -c SHA256SUMS
etcdutl snapshot status snapshot.db
etcdutl snapshot restore snapshot.db --data-dir ./restore-test
```

## 주의사항

etcd snapshot은 namespace 하나를 복구하기 위한 도구가 아닙니다. etcd는 클러스터 control-plane 상태를 저장하므로, 잘못 복구하면 클러스터 전체 상태에 영향을 줄 수 있습니다.

따라서 프로젝트에서는 실제 restore를 수행하지 않고 snapshot 상태와 checksum을 확인했으며, restore 순서와 주의사항을 문서로 정리했습니다.
