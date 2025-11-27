#!/bin/bash

# Script para verificar e criar rede Docker compartilhada
# Uso: ./scripts/setup-network.sh [nome_da_rede]
# Esta rede é compartilhada entre Evolution API, Viki Assistant API, Frontend e MinIO

set -e

# Função para obter nome da rede
get_network_name() {
    # 1. Verificar se foi passado como argumento
    if [ ! -z "$1" ]; then
        echo "$1"
        return
    fi
    
    # 2. Tentar ler do arquivo .env
    if [ -f ".env" ]; then
        NETWORK_FROM_ENV=$(grep "^DOCKER_NETWORK_NAME=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'")
        if [ ! -z "$NETWORK_FROM_ENV" ]; then
            echo "$NETWORK_FROM_ENV"
            return
        fi
    fi
    
    # 3. Usar valor padrão
    echo "viki_assistant_network"
}

# Obter nome da rede
NETWORK_NAME=$(get_network_name "$1")

echo "🔍 Verificando rede Docker compartilhada: $NETWORK_NAME"

# Verificar se a rede existe
if docker network ls | grep -q "$NETWORK_NAME"; then
    echo "✅ Rede $NETWORK_NAME já existe"
    echo "📋 Detalhes da rede:"
    docker network inspect "$NETWORK_NAME" --format='{{.Name}}: {{.Driver}} - {{.IPAM.Config}}' 2>/dev/null || true
    
    echo ""
    echo "🐳 Containers conectados à rede:"
    docker network inspect "$NETWORK_NAME" --format='{{range .Containers}}{{.Name}} ({{.IPv4Address}}){{"\n"}}{{end}}' 2>/dev/null || echo "Nenhum container conectado"
else
    echo "🚀 Criando rede $NETWORK_NAME..."
    docker network create "$NETWORK_NAME"
    echo "✅ Rede $NETWORK_NAME criada com sucesso!"
fi

echo ""
echo "📊 Redes Docker disponíveis:"
docker network ls --format="table {{.ID}}\t{{.Name}}\t{{.Driver}}\t{{.Scope}}"

echo ""
echo "🎯 Esta rede é compartilhada entre:"
echo "   - Evolution API Stack"
echo "   - Viki Assistant API"
echo "   - Viki Assistant Frontend"
echo "   - MinIO Storage"
echo ""
echo "💡 Para conectar containers manualmente:"
echo "   docker network connect $NETWORK_NAME nome_do_container"

