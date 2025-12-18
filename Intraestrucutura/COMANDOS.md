# Comandos para Gitea Terraform Runner

## 🔨 Construir la Imagen Docker

### Construcción estándar:
```bash
docker build --no-cache -f Dockerfile.gitea-terraform-runner -t gitea-terraform-runner:latest .
```

### Si tienes problemas de red/GPG, usa buildkit con retry:
```bash
DOCKER_BUILDKIT=1 docker build \
  --no-cache \
  --network=host \
  -f Dockerfile.gitea-terraform-runner \
  -t gitea-terraform-runner:latest .
```

### Con tag de versión:
```bash
docker build --no-cache -f Dockerfile.gitea-terraform-runner -t gitea-terraform-runner:latest -t gitea-terraform-runner:2.0 .
```

### Verificar la imagen construida:
```bash
docker images | grep gitea-terraform-runner
```

### Probar que las herramientas estén disponibles:
```bash
docker run --rm gitea-terraform-runner:latest check-tools.sh
```

### Verificar terraform específicamente:
```bash
docker run --rm gitea-terraform-runner:latest bash -c "which terraform && terraform --version"
```

---

## 🚀 Desplegar en Docker Swarm (Portainer)

### Método 1: Usando Docker CLI

#### 1. Configurar variables de entorno:
```bash
export GITEA_INSTANCE_URL=http://10.30.90.102:3000
export GITEA_RUNNER_TOKEN=tu-token-de-registro-aqui
export RUNNER_LABELS="ubuntu-latest:docker://gitea-terraform-runner:latest,terraform:docker://gitea-terraform-runner:latest"
```

#### 2. Desplegar el stack:
```bash
docker stack deploy -c docker-compose-swarm.yml gitea-runners
```

#### 3. Verificar servicios:
```bash
docker service ls | grep gitea-runners
```

#### 4. Ver logs de un runner:
```bash
docker service logs -f gitea-runners_gitea-terraform-runner-1
```

#### 5. Ver todos los logs:
```bash
docker service logs -f gitea-runners_gitea-terraform-runner-1
docker service logs -f gitea-runners_gitea-terraform-runner-2
docker service logs -f gitea-runners_gitea-terraform-runner-3
```

---

### Método 2: Usando Portainer UI

#### Paso 1: Subir la imagen (si es necesario)

Si construiste la imagen localmente, debes subirla al registry o asegurar que esté en todos los nodos:

```bash
# Guardar la imagen
docker save gitea-terraform-runner:latest -o gitea-terraform-runner.tar

# Copiar al servidor y cargarla
docker load -i gitea-terraform-runner.tar
```

#### Paso 2: Crear Stack en Portainer

1. Ve a **Portainer** → **Stacks** → **Add Stack**
2. Nombre del stack: `gitea-runners`
3. Pega el contenido de `docker-compose-swarm.yml`
4. En **Environment variables** agrega:
   ```
   GITEA_INSTANCE_URL=http://10.30.90.102:3000
   GITEA_RUNNER_TOKEN=tu-token-aqui
   RUNNER_LABELS=ubuntu-latest:docker://gitea-terraform-runner:latest,terraform:docker://gitea-terraform-runner:latest
   ```
5. Clic en **Deploy the stack**

---

## 🔄 Actualizar los Runners

### Eliminar stack anterior:
```bash
docker stack rm gitea-runners
```

### Esperar limpieza completa:
```bash
sleep 15
```

### Redesplegar:
```bash
docker stack deploy -c docker-compose-swarm.yml gitea-runners
```

---

## 🔧 Troubleshooting de Build

### Error: "At least one invalid signature was encountered"

Este error de GPG puede ser causado por problemas de tiempo del sistema o Docker. Soluciones:

**Paso 0: Verificar fecha/hora del sistema**
```bash
# En el host
date

# Si la fecha está incorrecta, corregirla:
sudo ntpdate -s time.nist.gov
# o
sudo timedatectl set-ntp true
```

**Paso 0b: Reiniciar Docker daemon**
```bash
sudo systemctl restart docker
# Esperar 10 segundos
sleep 10
```

**Paso 1: Limpiar TODO el cache de Docker**
```bash
docker system prune -a --volumes --force
docker builder prune -a --force
```

**Opción 1: Limpiar cache de Docker**
```bash
docker system prune -a
docker builder prune -a --force
```

**Opción 2: Usar BuildKit con network host**
```bash
DOCKER_BUILDKIT=1 docker build \
  --no-cache \
  --network=host \
  -f Dockerfile.gitea-terraform-runner \
  -t gitea-terraform-runner:latest .
```

**Opción 3: Reintentar el build (a veces es temporal)**
```bash
# Simplemente vuelve a intentar
docker build --no-cache -f Dockerfile.gitea-terraform-runner -t gitea-terraform-runner:latest .
```

**Opción 4: Si estás detrás de un proxy/firewall**
```bash
docker build \
  --no-cache \
  --build-arg http_proxy=http://tu-proxy:puerto \
  --build-arg https_proxy=http://tu-proxy:puerto \
  -f Dockerfile.gitea-terraform-runner \
  -t gitea-terraform-runner:latest .
```

---

## 🧪 Comandos de Verificación

### Ver estado de los servicios:
```bash
docker service ls
```

### Ver réplicas por servicio:
```bash
docker service ps gitea-runners_gitea-terraform-runner-1
docker service ps gitea-runners_gitea-terraform-runner-2
docker service ps gitea-runners_gitea-terraform-runner-3
```

### Inspeccionar un servicio:
```bash
docker service inspect gitea-runners_gitea-terraform-runner-1
```

### Ver variables de entorno de un servicio:
```bash
docker service inspect gitea-runners_gitea-terraform-runner-1 --format='{{json .Spec.TaskTemplate.ContainerSpec.Env}}' | jq
```

### Ver labels configurados en los logs:
```bash
docker service logs gitea-runners_gitea-terraform-runner-1 2>&1 | grep -i "labels"
```

### Ejecutar comando dentro de un contenedor del runner:
```bash
# Obtener el ID del contenedor
CONTAINER_ID=$(docker ps | grep gitea-terraform-runner-1 | awk '{print $1}')

# Ejecutar comando
docker exec -it $CONTAINER_ID terraform --version
docker exec -it $CONTAINER_ID check-tools.sh
```

---

## 🗑️ Limpiar Todo

### Eliminar stack:
```bash
docker stack rm gitea-runners
```

### Eliminar volúmenes (CUIDADO - borra datos de registro):
```bash
docker volume rm gitea-runners_gitea_runner_data_1
docker volume rm gitea-runners_gitea_runner_data_2
docker volume rm gitea-runners_gitea_runner_data_3
```

### Eliminar imagen:
```bash
docker rmi gitea-terraform-runner:latest
```

---

## 📝 Variables de Entorno Importantes

| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `GITEA_INSTANCE_URL` | URL del servidor Gitea | `http://10.30.90.102:3000` |
| `GITEA_RUNNER_TOKEN` | Token de registro del runner | (obtener de Gitea) |
| `RUNNER_NAME` | Nombre del runner | `gitea-terraform-runner-1` |
| `RUNNER_LABELS` | Labels para el runner | `ubuntu-latest:docker://gitea-terraform-runner:latest,terraform:docker://gitea-terraform-runner:latest` |

---

## 🎯 Verificar que Funciona en Pipeline

Después de desplegar, ejecuta tu pipeline `gitea-pipeline.yml` y deberías ver:

```
⏭️  Skipping tool installation (using pre-installed tools)
✅ Terraform found: Terraform v1.6.4
✅ TFLint found: TFLint version x.x.x
✅ Checkov found: x.x.x

Tools summary:
- Terraform: Terraform v1.6.4
- TFLint: TFLint version x.x.x
- Checkov: x.x.x
```

Y en los logs del runner deberías ver:
```
level=info msg="runner: gitea-terraform-runner-1, with version: v0.2.13, with labels: [ubuntu-latest terraform], declare successfully"
```
