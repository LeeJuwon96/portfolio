# Security Notes

This repository is a sanitized portfolio artifact.

It intentionally excludes:

- real access keys
- real secret keys
- GitLab or GitHub tokens
- private kubeconfig files
- certificates and private keys
- real internal domains
- real private IP addresses
- production `.env` files

All YAML and shell files under `examples/` are rewritten examples for explanation only. They are not production manifests.

If adapting this repository for a real environment, secrets should be stored in a secure secret manager such as Vault, AWS Secrets Manager, Sealed Secrets, or External Secrets Operator.
