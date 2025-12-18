#!/bin/bash
# Script para construir la imagen Docker de Terraform Runner

set -e

IMAGE_NAME="terraform-runner"
IMAGE_TAG="latest"
DOCKERFILE="Dockerfile.terraform-complete"

echo "========================================="
echo "🔨 Construyendo imagen Docker"
echo "========================================="
echo "Imagen: $IMAGE_NAME:$IMAGE_TAG"
echo "Dockerfile: $DOCKERFILE"
echo ""

# Eliminar imagen anterior si existe
echo "🗑️  Limpiando imagen anterior..."
if docker images "$IMAGE_NAME:$IMAGE_TAG" | grep -q "$IMAGE_NAME"; then
    echo "Eliminando imagen anterior: $IMAGE_NAME:$IMAGE_TAG"
    docker rmi -f "$IMAGE_NAME:$IMAGE_TAG" 2>/dev/null || true
    echo "✅ Imagen anterior eliminada"
else
    echo "ℹ️  No hay imagen anterior para eliminar"
fi
echo ""

# Limpiar cache de Docker
echo "🧹 Limpiando cache de Docker..."
docker builder prune -f
echo "✅ Cache limpiado"
echo ""

# Construir la imagen
echo "🔨 Construyendo nueva imagen..."
docker build -f "$DOCKERFILE" -t "$IMAGE_NAME:$IMAGE_TAG" .

echo ""
echo "========================================="
echo "✅ Imagen construida exitosamente"
echo "========================================="
echo ""

# Verificar la imagen
echo "📦 Información de la imagen:"
docker images "$IMAGE_NAME:$IMAGE_TAG"

echo ""
echo "🧪 Probando herramientas en la imagen..."
docker run --rm "$IMAGE_NAME:$IMAGE_TAG" bash -c "
    echo 'Terraform:' && terraform --version | head -1
    echo 'TFLint:' && tflint --version | head -1
    echo 'Checkov:' && checkov --version | head -1
    echo 'Google Cloud SDK:' && gcloud --version | head -1
"

echo ""
echo "========================================="
echo "🚀 La imagen está lista para usar"
echo "========================================="
echo ""
echo "Para desplegar los runners, ejecuta:"
echo "  docker stack deploy -c Docker-compuse.yml act-runner-stack"
echo ""
