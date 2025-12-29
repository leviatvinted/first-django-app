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

## GitHub Actions

### CI (tests)
- Workflow: [./.github/workflows/ci.yml](.github/workflows/ci.yml)
- Runs on pushes/PRs to `main`/`master`.
- Installs `requirements.txt` and runs `python blog_app/manage.py test`.

### Deploy (Ansible)
- Workflow: [./.github/workflows/deploy.yml](.github/workflows/deploy.yml)
- Triggers: push to `main` and manual `workflow_dispatch`.
- Uses existing playbook at [django-deploy-aws/ansible/deploy.yml](django-deploy-aws/ansible/deploy.yml).

Required repository secrets:
- `SSH_PRIVATE_KEY`: Private key contents for the `ubuntu` user on the EC2 host (paste the PEM text; do not base64).
- `SSH_USER` (optional, default `ubuntu`): SSH username.
- `TARGET_HOST` (optional): IP or hostname to override inventory; if omitted, workflow uses [django-deploy-aws/ansible/hosts.ini](django-deploy-aws/ansible/hosts.ini).
- `ANSIBLE_VAULT_PASSWORD` (only if you start using Vault): Provide via `ANSIBLE_VAULT_PASSWORD` and add `--vault-password-file` or `ANSIBLE_VAULT_PASSWORD_FILE` to the workflow as needed.

Notes:
- The workflow writes the `SSH_PRIVATE_KEY` to `~/.ssh/gh_actions.pem` and uses it via `--private-key`.
- To override the host at dispatch time, provide the `target_host` input.
- Ensure the target security group allows SSH (22), HTTP (80) and HTTPS (443) from the runner IPs.
