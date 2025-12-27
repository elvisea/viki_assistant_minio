#!/bin/bash

# ===========================================
# Script para Configurar CORS no MinIO
# ===========================================
# Este script configura CORS no bucket do MinIO usando o MinIO Client (mc)
# Permite que o navegador carregue imagens diretamente do MinIO via presigned URLs
#
# Uso:
#   ./scripts/configure-cors.sh
#
# Ou via docker-compose (execução automática)
#

set -e  # Para a execução em caso de erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variáveis de ambiente (com valores padrão)
MINIO_ENDPOINT="${MINIO_ENDPOINT:-http://minio:9000}"
MINIO_ACCESS_KEY="${MINIO_ROOT_USER:-minioadmin}"
MINIO_SECRET_KEY="${MINIO_ROOT_PASSWORD:-minioadmin123}"
MINIO_BUCKET="${MINIO_BUCKET_NAME:-viki-assistant}"
NETWORK_NAME="${DOCKER_NETWORK_NAME:-viki_assistant_network}"

# Caminhos
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="$PROJECT_DIR/config/cors-config.xml"

echo "🔧 Configurando CORS no MinIO..."
echo "=================================================="
echo ""

# Verificar se o arquivo de configuração existe
if [ ! -f "$CONFIG_FILE" ]; then
  echo -e "${RED}❌ Arquivo de configuração CORS não encontrado: $CONFIG_FILE${NC}"
  exit 1
fi

echo "📋 Configurações:"
echo "   Endpoint: $MINIO_ENDPOINT"
echo "   Bucket: $MINIO_BUCKET"
echo "   Network: $NETWORK_NAME"
echo ""

# Verificar se a rede Docker existe
if ! docker network inspect "$NETWORK_NAME" > /dev/null 2>&1; then
  echo -e "${YELLOW}⚠️  Rede Docker '$NETWORK_NAME' não encontrada${NC}"
  echo "   Criando rede..."
  docker network create "$NETWORK_NAME" || {
    echo -e "${RED}❌ Erro ao criar rede Docker${NC}"
    exit 1
  }
  echo -e "${GREEN}✅ Rede criada com sucesso${NC}"
fi

# Verificar se o MinIO está rodando
if ! docker ps --format '{{.Names}}' | grep -q "^minio$"; then
  echo -e "${YELLOW}⚠️  Container MinIO não está rodando${NC}"
  echo "   Iniciando MinIO..."
  cd "$PROJECT_DIR"
  docker compose up -d minio || {
    echo -e "${RED}❌ Erro ao iniciar MinIO${NC}"
    exit 1
  }
  
  # Aguardar MinIO estar pronto
  echo "   Aguardando MinIO estar pronto..."
  for i in {1..30}; do
    if docker exec minio curl -f http://localhost:9000/minio/health/live > /dev/null 2>&1; then
      echo -e "${GREEN}✅ MinIO está pronto${NC}"
      break
    fi
    if [ $i -eq 30 ]; then
      echo -e "${RED}❌ MinIO não ficou pronto a tempo${NC}"
      exit 1
    fi
    sleep 2
  done
fi

echo ""
echo "🔗 Configurando alias do MinIO Client..."
echo ""

# Executar configuração CORS usando MinIO Client via Docker
docker run --rm \
  --network "$NETWORK_NAME" \
  -v "$CONFIG_FILE:/tmp/cors-config.xml:ro" \
  minio/mc:latest \
  sh -c "
    # Configurar alias
    mc alias set myminio $MINIO_ENDPOINT $MINIO_ACCESS_KEY $MINIO_SECRET_KEY || {
      echo '❌ Erro ao configurar alias do MinIO'
      exit 1
    }
    
    # Verificar se o bucket existe
    if ! mc ls myminio/$MINIO_BUCKET > /dev/null 2>&1; then
      echo '⚠️  Bucket $MINIO_BUCKET não existe, criando...'
      mc mb myminio/$MINIO_BUCKET || {
        echo '❌ Erro ao criar bucket'
        exit 1
      }
      echo '✅ Bucket criado com sucesso'
    fi
    
    # Aplicar configuração CORS
    echo '📝 Aplicando configuração CORS...'
    mc cors set download /tmp/cors-config.xml myminio/$MINIO_BUCKET || {
      echo '❌ Erro ao configurar CORS'
      exit 1
    }
    
    # Verificar configuração aplicada
    echo ''
    echo '✅ CORS configurado com sucesso!'
    echo ''
    echo '📋 Configuração aplicada:'
    mc cors get myminio/$MINIO_BUCKET
  "

if [ $? -eq 0 ]; then
  echo ""
  echo -e "${GREEN}✅ CORS configurado com sucesso no bucket '$MINIO_BUCKET'!${NC}"
  echo ""
  echo "💡 As imagens agora devem carregar corretamente no navegador."
  echo ""
else
  echo ""
  echo -e "${RED}❌ Erro ao configurar CORS${NC}"
  echo ""
  echo "💡 Você pode tentar configurar manualmente via:"
  echo "   1. Console do MinIO: https://minio.vikiassistant.com.br/minio/"
  echo "   2. Ou executar este script novamente"
  exit 1
fi

