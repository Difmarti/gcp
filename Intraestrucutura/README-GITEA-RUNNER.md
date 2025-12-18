# Gitea Terraform Runner - Deployment Guide

## 📦 Archivos Importantes

- `Dockerfile.gitea-terraform-runner` - Dockerfile optimizado con herramientas en PATH estándar
- `docker-compose-swarm.yml` - Compose para Docker Swarm (usar en Portainer)
- `.env.example` - Ejemplo de variables de entorno
- `COMANDOS.md` - Todos los comandos necesarios

## 🎯 Diferencia Clave con Versión Anterior

### ✅ SOLUCIÓN AL PROBLEMA DE PATH

**Problema anterior:**
- Terraform instalado en `/opt/terraform/terraform`
- PATH no incluía `/opt/terraform`
- Workflows no encontraban terraform

**Solución actual:**
- Terraform instalado directamente en `/usr/local/bin/terraform`
- TFLint instalado directamente en `/usr/local/bin/tflint`
- Ambos están en el PATH estándar de Linux
- ✅ **Workflows encuentran las herramientas automáticamente**

## 🚀 Quick Start

### 1. Construir la Imagen

```bash
cd /ruta/a/Intraestrucutura

docker build --no-cache \
  -f Dockerfile.gitea-terraform-runner \
  -t gitea-terraform-runner:latest .
```

### 2. Verificar la Imagen

```bash
docker run --rm gitea-terraform-runner:latest bash -c "
  echo 'Terraform:' && which terraform && terraform --version
  echo 'TFLint:' && which tflint && tflint --version
  echo 'Checkov:' && which checkov && checkov --version
"
```

Deberías ver:
```
Terraform: /usr/local/bin/terraform
Terraform v1.6.4
TFLint: /usr/local/bin/tflint
...
```

### 3. Configurar Variables de Entorno

```bash
export GITEA_INSTANCE_URL=http://10.30.90.102:3000
export GITEA_RUNNER_TOKEN=tu-token-aqui
export RUNNER_LABELS="ubuntu-latest:docker://gitea-terraform-runner:latest,terraform:docker://gitea-terraform-runner:latest"
```

### 4. Desplegar en Docker Swarm

```bash
docker stack deploy -c docker-compose-swarm.yml gitea-runners
```

### 5. Verificar Deployment

```bash
# Ver servicios
docker service ls | grep gitea-runners

# Ver logs
docker service logs -f gitea-runners_gitea-terraform-runner-1
```

Deberías ver en los logs:
```
level=info msg="runner: gitea-terraform-runner-1, with version: v0.2.13,
with labels: [ubuntu-latest terraform], declare successfully"
```

## 📋 Uso en Portainer

### Opción 1: Via Portainer UI

1. **Stacks** → **Add Stack**
2. Nombre: `gitea-runners`
3. Pega el contenido de `docker-compose-swarm.yml`
4. **Environment variables**:
   ```
   GITEA_INSTANCE_URL=http://10.30.90.102:3000
   GITEA_RUNNER_TOKEN=tu-token
   RUNNER_LABELS=ubuntu-latest:docker://gitea-terraform-runner:latest,terraform:docker://gitea-terraform-runner:latest
   ```
5. **Deploy the stack**

### Opción 2: Via Git Repository en Portainer

1. **Stacks** → **Add Stack**
2. **Repository**: URL de tu repo
3. **Compose path**: `Intraestrucutura/docker-compose-swarm.yml`
4. Agregar las variables de entorno
5. **Deploy**

## 🔧 Configuración de Pipeline

Tu `gitea-pipeline.yml` debe tener:

```yaml
jobs:
  validations:
    runs-on: ubuntu-latest  # Usará gitea-terraform-runner:latest
    steps:
      - uses: actions/checkout@v4
      - uses: ./.cloud-arquitectura/validations
        with:
          templates_directory: './templates'
          skip_tool_installation: 'true'  # IMPORTANTE
```

## ✅ Verificación de Éxito

### En los logs del runner:
```
✅ Terraform: /usr/local/bin/terraform - Terraform v1.6.4
✅ TFLint: /usr/local/bin/tflint - TFLint version x.x.x
✅ Checkov: /usr/local/bin/checkov - x.x.x

runner: gitea-terraform-runner-1, with labels: [ubuntu-latest terraform]
```

### En los logs del pipeline:
```
⏭️  Skipping tool installation (using pre-installed tools)
✅ Terraform found: Terraform v1.6.4
✅ TFLint found: TFLint version x.x.x
✅ Checkov found: x.x.x
```

## 🎯 Arquitectura

```
┌─────────────────────────────────────────┐
│  Docker Swarm / Portainer               │
├─────────────────────────────────────────┤
│                                         │
│  Stack: gitea-runners                   │
│  ┌─────────────────────────────────┐   │
│  │ gitea-terraform-runner-1        │   │
│  │ Image: gitea-terraform-runner   │   │
│  │ Labels: ubuntu-latest,terraform │   │
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │ gitea-terraform-runner-2        │   │
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │ gitea-terraform-runner-3        │   │
│  └─────────────────────────────────┘   │
│                                         │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│  Gitea Workflow Execution               │
├─────────────────────────────────────────┤
│  runs-on: ubuntu-latest                 │
│     ↓                                   │
│  Runner spawns:                         │
│  docker://gitea-terraform-runner:latest │
│     ↓                                   │
│  Container with:                        │
│  - /usr/local/bin/terraform ✅          │
│  - /usr/local/bin/tflint ✅             │
│  - /usr/local/bin/checkov ✅            │
└─────────────────────────────────────────┘
```

## 🔍 Troubleshooting

### Labels no aparecen correctos

**Síntoma:**
```
with labels: [ubuntu-latest ubuntu-22.04]
```

**Solución:**
Verificar que `RUNNER_LABELS` esté correctamente configurado:
```bash
docker service inspect gitea-runners_gitea-terraform-runner-1 \
  --format='{{json .Spec.TaskTemplate.ContainerSpec.Env}}' | jq
```

### Terraform not found

**Síntoma:**
```
ERROR: Terraform not found in PATH
```

**Solución:**
1. Verificar dentro del contenedor:
```bash
docker exec -it $(docker ps | grep gitea-terraform-runner-1 | awk '{print $1}') which terraform
```

2. Si no aparece `/usr/local/bin/terraform`, la imagen no se construyó correctamente. Reconstruir:
```bash
docker build --no-cache -f Dockerfile.gitea-terraform-runner -t gitea-terraform-runner:latest .
```

## 📞 Support

Para más detalles, consulta:
- `COMANDOS.md` - Lista completa de comandos
- `.env.example` - Variables de entorno de ejemplo



 cd /docker/gitea/runner/terraform

  # 1. Verificar hora
  date

  # 2. Reiniciar Docker
  sudo systemctl restart docker && sleep 10

  # 3. Limpiar cache
  docker system prune -a --force
  docker builder prune -a --force

  # 4. Construir
  docker build --no-cache \
    -f Dockerfile.gitea-terraform-runner \
    -t gitea-terraform-runner:latest .

  # 5. Verificar
  docker run --rm gitea-terraform-runner:latest bash -c "terraform --version && tflint --version && checkov --version"
