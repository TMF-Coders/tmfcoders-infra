# Coren POC — Landing Zone (governance)

Esta capa vive en el repo **central de infraestructura** y define SOLO la
frontera de gobierno del compartimento Coren POC:

- **Project** Scaleway dedicado → billing aislado
- **IAM application + API key** `coren-poc-deploy` con permisos scoped al
  project → la usa el repo de la aplicación para desplegar su stack

Lo que corre *dentro* del compartimento (VM, IP, clave Mistral, cloud-init)
NO está aquí: vive en `coren-customer-platform/infra/` y consume el
`project_id` de esta capa vía `terraform_remote_state`.

> Separación de responsabilidades:
> **Plataforma/Ops** posee la caja (este repo). **El equipo de la app**
> posee lo que corre dentro (repo de Coren).

## Deploy

```bash
export SCW_ACCESS_KEY=... SCW_SECRET_KEY=...
export AWS_ACCESS_KEY_ID=$SCW_ACCESS_KEY AWS_SECRET_ACCESS_KEY=$SCW_SECRET_KEY
export SCW_DEFAULT_REGION=fr-par SCW_DEFAULT_ZONE=fr-par-1

cd 1-org/coren-poc
terraform init && terraform apply
```

Tras el apply, pasa al repo de la app las credenciales scoped:

```bash
terraform output -raw deploy_api_key_id       # → SCW_ACCESS_KEY (CI Coren)
terraform output -raw deploy_api_key_secret   # → SCW_SECRET_KEY (CI Coren, secreto)
terraform output -raw project_id              # → el app repo lo lee vía remote_state
```

## Teardown

```bash
# Primero destruye la app (en coren-customer-platform/infra), luego:
cd 1-org/coren-poc && terraform destroy
```
