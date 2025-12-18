#!/bin/bash
# Script completo: construir imagen y desplegar runners

set -e

echo "========================================"
echo "🔄 Rebuild & Deploy Terraform Runners"
echo "========================================"
echo ""
echo "Este script ejecutará:"
echo "1. 🔨 Construir nueva imagen (con limpieza)"
echo "2. 🚀 Desplegar runners en Docker Swarm"
echo ""

# Paso 1: Construir
echo "========================================="
echo "Paso 1: Construyendo imagen..."
echo "========================================="
bash build.sh

if [ $? -ne 0 ]; then
    echo "❌ Error en la construcción de la imagen"
    exit 1
fi

echo ""
echo "========================================="
echo "Paso 2: Desplegando runners..."
echo "========================================="
bash deploy.sh

if [ $? -ne 0 ]; then
    echo "❌ Error en el despliegue de runners"
    exit 1
fi

echo ""
echo "========================================="
echo "✅ Proceso completo finalizado"
echo "========================================="
echo ""
echo "🎉 La imagen ha sido reconstruida y los runners están desplegados"
echo ""
