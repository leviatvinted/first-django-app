# first-django-app

## Domain & HTTPS Setup
- Configure DNS: point `levinathan.nl` A record to your EC2 Elastic IP. Optionally add `www` CNAME to the root.
- Update Ansible vars: set `allowed_hosts` with `levinathan.nl` first and define `letsencrypt_email` in [django-deploy-aws/ansible/group_vars/webservers.example.yml](django-deploy-aws/ansible/group_vars/webservers.example.yml). Provide secrets via Ansible Vault or `--extra-vars`.
- Re-deploy: run the Ansible playbook to issue a Let’s Encrypt certificate and enable HTTPS.

## Environment Configuration
- Required: `SECRET_KEY`, `DEBUG`, `ALLOWED_HOSTS`. See [.env.example](.env.example).
- HTTPS: set `CSRF_TRUSTED_ORIGINS` to include `https://levinathan.nl` (and `https://www.levinathan.nl` if used).
- Optional security flags: `SECURE_SSL_REDIRECT`, `SESSION_COOKIE_SECURE`, `CSRF_COOKIE_SECURE`. Enable (`True`) when HTTPS is active.

## Deployment Notes
- Do not commit secrets. Use Ansible Vault or pass via `--extra-vars`.
- Ensure `.env`, Terraform state/vars, and sensitive Ansible files are ignored (see [.gitignore](.gitignore)).
