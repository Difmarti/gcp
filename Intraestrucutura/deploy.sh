#!/bin/bash
# Script para desplegar los runners de Terraform en Docker Swarm

set -e

STACK_NAME="act-runner-stack"
COMPOSE_FILE="Docker-compuse.yml"

echo "========================================="
echo "🚀 Desplegando Terraform Runners"
echo "========================================="
echo ""

# Verificar variables de entorno
echo "🔐 Verificando variables de entorno..."
if [ -z "$GITEA_RUNNER_IP" ]; then
    echo "⚠️  GITEA_RUNNER_IP no está configurado"
    read -p "Ingresa la IP del servidor Gitea (ej: 10.30.90.102): " GITEA_RUNNER_IP
    export GITEA_RUNNER_IP
fi

if [ -z "$GITEA_RUNNER_TOKEN" ]; then
    echo "⚠️  GITEA_RUNNER_TOKEN no está configurado"
    read -p "Ingresa el token de registro del runner: " GITEA_RUNNER_TOKEN
    export GITEA_RUNNER_TOKEN
fi

echo "✅ Variables configuradas:"
echo "   GITEA_RUNNER_IP: $GITEA_RUNNER_IP"
echo "   GITEA_RUNNER_TOKEN: [OCULTO]"
echo ""

# Verificar si la imagen existe
echo "📦 Verificando imagen terraform-runner:latest..."
if ! docker images | grep -q "terraform-runner.*latest"; then
    echo "❌ ERROR: La imagen terraform-runner:latest no existe"
    echo "   Por favor, ejecuta primero: bash build.sh"
    exit 1
fi
echo "✅ Imagen encontrada"
echo ""

# Eliminar stack anterior si existe
echo "🗑️  Limpiando deployment anterior..."
if docker stack ls | grep -q "$STACK_NAME"; then
    echo "Eliminando stack existente: $STACK_NAME"
    docker stack rm "$STACK_NAME"

    echo "Esperando a que se eliminen los servicios..."
    sleep 15

    # Verificar que se eliminó completamente
    while docker stack ps "$STACK_NAME" 2>/dev/null | grep -q .; do
        echo "Esperando eliminación completa..."
        sleep 5
    done

    echo "✅ Stack anterior eliminado"
else
    echo "ℹ️  No hay stack anterior para eliminar"
fi
echo ""

# Desplegar el nuevo stack
echo "🚀 Desplegando stack..."
docker stack deploy -c "$COMPOSE_FILE" "$STACK_NAME"

if [ $? -ne 0 ]; then
    echo "❌ Error al desplegar el stack"
    exit 1
fi

echo "✅ Stack desplegado"
echo ""

# Verificar el despliegue
echo "📊 Verificando servicios..."
echo "Esperando a que los servicios se inicien..."
sleep 10

docker service ls | grep "$STACK_NAME"

echo ""
echo "Estado de las réplicas:"
docker service ls | grep "$STACK_NAME" | awk '{print $2, $3, $4}'

echo ""

# Mostrar logs de un runner
echo "📝 Mostrando logs del primer runner (últimas 20 líneas)..."
echo "----------------------------------------"

FIRST_SERVICE=$(docker service ls | grep "$STACK_NAME" | head -1 | awk '{print $2}')

if [ ! -z "$FIRST_SERVICE" ]; then
    docker service logs --tail 20 "$FIRST_SERVICE"
else
    echo "⚠️  No se pudo obtener el nombre del servicio"
fi

echo ""
echo "========================================="
echo "✅ Deployment completado exitosamente"
echo "========================================="
echo ""
echo "📋 Próximos pasos:"
echo "1. Espera 30 segundos a que los runners se registren en Gitea"
echo "2. Ve a Gitea → Settings → Actions → Runners"
echo "3. Verifica que aparezcan 3 runners con labels 'ubuntu-latest' y 'terraform'"
echo "4. Ejecuta tu pipeline gitea-pipeline.yml"
echo ""
echo "🔍 Comandos útiles:"
echo "- Ver servicios: docker service ls | grep $STACK_NAME"
echo "- Ver logs: docker service logs -f ${STACK_NAME}_act_runner-terraform-1"
echo "- Ver contenedores: docker ps | grep $STACK_NAME"
echo "- Eliminar stack: docker stack rm $STACK_NAME"
echo ""
