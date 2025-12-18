# Terraform Runner - Docker Image

Imagen Docker personalizada de Act Runner con todas las herramientas necesarias para CI/CD de Terraform.

## 🛠️ Herramientas Incluidas

- **Terraform 1.6.4** - Infraestructura como código
- **TFLint** - Linter de Terraform para best practices
- **Checkov** - Security scanner para archivos Terraform
- **Google Cloud SDK** - CLI de GCP
- **Docker** - Para ejecutar contenedores dentro del runner
- **Python 3** - Para scripts y herramientas
- **Act Runner 0.2.13** - Daemon para ejecutar Gitea Actions

## ⚡ Quick Start (Todo en Uno)

Si quieres construir y desplegar todo de una vez:

```bash
cd /path/to/Intraestrucutura

export GITEA_RUNNER_IP=10.30.90.102
export GITEA_RUNNER_TOKEN=tu-token-de-gitea

bash rebuild-and-deploy.sh
```

Este script ejecuta automáticamente:
1. `build.sh` - Limpia cache, elimina imagen anterior y construye de nuevo
2. `deploy.sh` - Elimina stack anterior y despliega con la nueva imagen

---

## 🚀 Construcción de la Imagen

### Opción Automática (Recomendado)

```bash
cd /path/to/Intraestrucutura
bash build.sh
```

El script `build.sh` automáticamente:
- ✅ Elimina la imagen anterior si existe
- ✅ Limpia el cache de Docker
- ✅ Construye la imagen completamente desde cero con `--no-cache`
- ✅ Intenta con `Dockerfile.terraform-complete` primero
- ✅ Si falla por problemas de GPG, automáticamente intenta con `Dockerfile.terraform-alternative`
- ✅ Verifica que todas las herramientas estén disponibles

### Dockerfiles Disponibles

**Dockerfile.terraform-complete** (Ubuntu 22.04):
- Usa Ubuntu 22.04 LTS
- Instala dependencias via apt-get
- Puede tener problemas de GPG signature en algunos entornos

**Dockerfile.terraform-alternative** (Ubuntu 24.04):
- Usa Ubuntu 24.04 LTS (más reciente)
- Instala Google Cloud SDK usando instalador directo (evita apt)
- Usa Docker CE CLI oficial
- Más robusto contra problemas de GPG

### Build Manual

Si prefieres construir manualmente:

```bash
# Usar Dockerfile principal
docker build --no-cache -f Dockerfile.terraform-complete -t terraform-runner:latest .

# O usar Dockerfile alternativo
docker build --no-cache -f Dockerfile.terraform-alternative -t terraform-runner:latest .

# O especificar cual usar con variable de entorno
DOCKERFILE=Dockerfile.terraform-alternative bash build.sh
```

## 📋 Verificar la Imagen

Después de construir, verifica que todas las herramientas estén disponibles:

```bash
docker run --rm terraform-runner:latest bash -c "check-tools.sh"
```

Deberías ver:
```
✅ Terraform: Terraform v1.6.4
✅ TFLint: TFLint version x.x.x
✅ Checkov: x.x.x
✅ Google Cloud SDK: Google Cloud SDK xxx.x.x
```

## 🐳 Desplegar con Docker Swarm

**Usando el script de deploy (Recomendado):**

```bash
cd /path/to/Intraestrucutura

# Configurar variables de entorno
export GITEA_RUNNER_IP=10.30.90.102
export GITEA_RUNNER_TOKEN=tu-token-de-gitea

# Desplegar
bash deploy.sh
```

El script `deploy.sh` automáticamente:
- ✅ Verifica que las variables de entorno estén configuradas
- ✅ Verifica que la imagen terraform-runner:latest exista
- ✅ Elimina el stack anterior si existe
- ✅ Despliega el nuevo stack
- ✅ Muestra el estado de los servicios y logs

**Despliegue manual (si prefieres):**

```bash
export GITEA_RUNNER_IP=10.30.90.102
export GITEA_RUNNER_TOKEN=tu-token-de-gitea

# Eliminar stack anterior si existe
docker stack rm act-runner-stack
sleep 15

# Desplegar nuevo stack
docker stack deploy -c Docker-compuse.yml act-runner-stack

# Verificar
docker service ls | grep act-runner
docker service logs act-runner-stack_act_runner-terraform-1
```

## 🔧 Configuración del Pipeline

En tu workflow de Gitea (`.gitea/workflows/gitea-pipeline.yml`):

```yaml
jobs:
  validations:
    name: Validar Templates Terraform
    runs-on: ubuntu-latest  # Usa la imagen terraform-runner
    steps:
      - uses: actions/checkout@v4
      - uses: ./.cloud-arquitectura/validations
        with:
          templates_directory: './templates'
          skip_tool_installation: 'true'  # Importante!
```

**Importante:** Asegúrate de que `skip_tool_installation: 'true'` esté configurado en todos los jobs que usen las actions de Terraform.

## 🎯 Cómo Funciona

1. **Act Runner Daemon** ejecuta en el contenedor principal
2. Cuando un workflow se dispara, Act Runner **crea un contenedor nuevo** usando la imagen especificada en `RUNNER_LABELS`
3. Con la configuración actual, ese contenedor usa `terraform-runner:latest`, que tiene todas las herramientas
4. El workflow se ejecuta dentro de ese contenedor con acceso a Terraform, TFLint y Checkov

## 🔍 Troubleshooting

### Error: Terraform not found in PATH

**Causa:** El runner está usando una imagen diferente a `terraform-runner:latest`

**Solución:**
1. Verifica que la imagen se haya construido: `docker images | grep terraform-runner`
2. Verifica el RUNNER_LABELS en Docker-compuse.yml: debe contener `ubuntu-latest:docker://terraform-runner:latest`
3. Reinicia los runners: `docker stack rm act-runner-stack && docker stack deploy -c Docker-compuse.yml act-runner-stack`

### Error: GPG signature errors

**Causa:** El workflow está intentando instalar herramientas que ya están en la imagen

**Solución:** Asegúrate de que `skip_tool_installation: 'true'` esté en todos los usos de las actions

### Verificar qué imagen está usando el runner

```bash
# Ver logs del runner
docker service logs act-runner-stack_act_runner-terraform-1 -f

# Verificar contenedores en ejecución
docker ps -a | grep act_runner
```

## 📝 Actualizar la Imagen

Cuando hagas cambios al Dockerfile:

```bash
cd /path/to/Intraestrucutura

# 1. Reconstruir la imagen (limpia automáticamente)
bash build.sh

# 2. Redesplegar los runners
bash deploy.sh
```

Esto es equivalente a:
```bash
# Construir con limpieza
bash build.sh

# El script deploy.sh se encarga de:
# - Eliminar el stack anterior
# - Esperar a que se limpie completamente
# - Desplegar el nuevo stack
# - Verificar el estado
```

## 🧪 Testing Local

Prueba validaciones localmente:

```bash
docker run --rm -v $(pwd)/templates:/workspace terraform-runner:latest \
  bash -c "cd /workspace && validate-tf.sh ."
```

## 📚 Scripts Disponibles

Dentro del contenedor hay scripts útiles:

- `/usr/local/bin/check-tools.sh` - Verifica todas las herramientas instaladas
- `/usr/local/bin/validate-tf.sh <dir>` - Valida archivos Terraform en un directorio
- `/opt/act_runner/entrypoint.sh` - Script de inicio del runner

## 🔐 Seguridad

- Las credenciales de GCP se pasan como secretos en el workflow
- Los secretos no se almacenan en la imagen Docker
- El runner debe tener acceso al socket de Docker para ejecutar contenedores

## 📊 Recursos

- Memoria recomendada: 2GB por runner
- CPU recomendada: 2 cores por runner
- Almacenamiento: 10GB para caché y temporales
