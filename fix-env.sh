#!/bin/bash

# Script para corrigir o arquivo .env do MinIO
# Remove o protocolo https:// da variável MINIO_BROWSER_REDIRECT_URL

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Corrigindo arquivo .env do MinIO ===${NC}"
echo ""

# Procurar arquivo .env
ENV_PATHS=(
    "$HOME/viki-assistant-minio/.env"
    "$HOME/projects/viki_assistant/viki_assistant_minio/.env"
    "./.env"
    "$(pwd)/.env"
)

ENV_FILE=""

for path in "${ENV_PATHS[@]}"; do
    if [ -f "$path" ]; then
        ENV_FILE="$path"
        echo -e "${GREEN}✓ Arquivo .env encontrado: $ENV_FILE${NC}"
        break
    fi
done

if [ -z "$ENV_FILE" ]; then
    echo -e "${YELLOW}Arquivo .env não encontrado nos locais comuns.${NC}"
    echo -e "${YELLOW}Por favor, informe o caminho completo do arquivo .env:${NC}"
    read -p "Caminho: " ENV_FILE
    
    if [ ! -f "$ENV_FILE" ]; then
        echo -e "${RED}✗ Arquivo não encontrado: $ENV_FILE${NC}"
        exit 1
    fi
fi

echo ""

# Criar backup
BACKUP_FILE="${ENV_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
cp "$ENV_FILE" "$BACKUP_FILE"
echo -e "${GREEN}✓ Backup criado: $BACKUP_FILE${NC}"
echo ""

# Verificar e corrigir MINIO_BROWSER_REDIRECT_URL
if grep -q "^MINIO_BROWSER_REDIRECT_URL=" "$ENV_FILE"; then
    CURRENT_VALUE=$(grep "^MINIO_BROWSER_REDIRECT_URL=" "$ENV_FILE" | cut -d '=' -f2)
    echo -e "${YELLOW}Valor atual: MINIO_BROWSER_REDIRECT_URL=$CURRENT_VALUE${NC}"
    
    if [[ "$CURRENT_VALUE" == https://* ]]; then
        echo -e "${RED}✗ Problema encontrado: URL contém 'https://'${NC}"
        NEW_VALUE="${CURRENT_VALUE#https://}"
        sed -i "s|^MINIO_BROWSER_REDIRECT_URL=.*|MINIO_BROWSER_REDIRECT_URL=$NEW_VALUE|" "$ENV_FILE"
        echo -e "${GREEN}✓ Corrigido para: MINIO_BROWSER_REDIRECT_URL=$NEW_VALUE${NC}"
    elif [[ "$CURRENT_VALUE" == http://* ]]; then
        echo -e "${YELLOW}⚠ URL contém 'http://', removendo...${NC}"
        NEW_VALUE="${CURRENT_VALUE#http://}"
        sed -i "s|^MINIO_BROWSER_REDIRECT_URL=.*|MINIO_BROWSER_REDIRECT_URL=$NEW_VALUE|" "$ENV_FILE"
        echo -e "${GREEN}✓ Corrigido para: MINIO_BROWSER_REDIRECT_URL=$NEW_VALUE${NC}"
    else
        echo -e "${GREEN}✓ Valor já está correto (sem protocolo)${NC}"
    fi
elif grep -q "^#.*MINIO_BROWSER_REDIRECT_URL=" "$ENV_FILE"; then
    echo -e "${GREEN}✓ Variável já está comentada${NC}"
else
    echo -e "${YELLOW}⚠ Variável MINIO_BROWSER_REDIRECT_URL não encontrada${NC}"
    echo -e "${GREEN}✓ Isso é correto - o MinIO funcionará sem ela quando estiver atrás de proxy reverso${NC}"
fi

echo ""
echo -e "${BLUE}=== Próximos passos ===${NC}"
echo ""
echo -e "${YELLOW}1. Reinicie o container MinIO:${NC}"
echo -e "   ${GREEN}docker restart minio${NC}"
echo ""
echo -e "${YELLOW}2. Verifique se o container iniciou corretamente:${NC}"
echo -e "   ${GREEN}docker logs minio --tail 20${NC}"
echo ""
echo -e "${YELLOW}3. Aguarde alguns segundos e teste:${NC}"
echo -e "   ${GREEN}curl http://127.0.0.1:9000/minio/health/live${NC}"
echo ""

