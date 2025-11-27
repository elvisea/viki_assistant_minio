# MinIO Setup

## Repositório

Este serviço MinIO é mantido no repositório:

- `https://github.com/elvisea/viki_assistant_minio`

Ele é pensado para ser um serviço de infraestrutura **separado** dos demais projetos
(como a API `viki_assistant_api`), podendo ser reutilizado por múltiplos serviços.

## Configuração

1. **Copie o arquivo de exemplo**:
   ```bash
   cp .env.example .env
   ```

2. **Edite o arquivo `.env`** conforme necessário:
   ```env
   # Credenciais (obrigatórias)
   MINIO_ROOT_USER=minioadmin
   MINIO_ROOT_PASSWORD=minioadmin123
   
   # Configuração opcional
   # Dev / ambiente local
   MINIO_BROWSER_REDIRECT_URL=http://localhost:9001
   # Produção (console MinIO atrás de proxy no subdomínio)
   # MINIO_BROWSER_REDIRECT_URL=https://minio.vikiassistant.com.br
   MINIO_PORT=9000
   MINIO_CONSOLE_PORT=9001
   MINIO_BUCKET=minio-bucket
   UID=1000
   GID=1000
   ```

## Rede Docker Compartilhada

Este projeto utiliza a rede Docker compartilhada `viki_assistant_network` para comunicação
com outros serviços do ecossistema Viki Assistant (API, Frontend, Evolution API).

### Configuração da Rede

**IMPORTANTE**: Antes de iniciar os containers, você precisa criar a rede Docker compartilhada:

```bash
# Criar a rede (execute apenas uma vez)
./scripts/setup-network.sh

# Ou manualmente:
docker network create viki_assistant_network
```

O script `scripts/setup-network.sh` verifica se a rede existe e a cria se necessário.
Você pode executá-lo de qualquer projeto do ecossistema.

### Projetos Conectados à Rede

- **MinIO Storage** (este projeto)
- **Viki Assistant API**
- **Viki Assistant Frontend**
- **Evolution API**

### Comunicação Entre Serviços

Dentro da rede Docker, os serviços podem acessar o MinIO usando o nome do container:

- **MinIO API**: `http://minio:9000` (dentro da rede)
- **MinIO Console**: `http://minio:9001` (dentro da rede)

Para acesso externo (do host), continue usando `localhost` com as portas mapeadas.

## Para executar

```bash
# 1. Criar rede Docker compartilhada (se ainda não existir)
./scripts/setup-network.sh

# 2. Iniciar o MinIO
docker-compose up -d
```

**📁 Criação automática da pasta `data`:** O docker-compose criará automaticamente a pasta `./data` com as permissões corretas (755, owner 1000:1000) usando um container de inicialização.

## Acessos

- **API MinIO**: http://localhost:9000 (ou porta definida em MINIO_PORT)
- **Console Web**: http://localhost:9001 (ou porta definida em MINIO_CONSOLE_PORT)

## Credenciais

- **Usuário**: Definido em `MINIO_ROOT_USER` (padrão: minioadmin)
- **Senha**: Definida em `MINIO_ROOT_PASSWORD` (padrão: minioadmin123)

## Estrutura de dados

Os dados serão salvos na pasta `./data` do diretório atual.

## 🔧 Solução de Problemas

### Erro: "file access denied" ou container reiniciando

Se o MinIO não conseguir iniciar devido a problemas de permissão, você pode corrigir manualmente:

**Parar o serviço:**
```bash
docker-compose down
```

**Criar pasta data com permissões corretas:**
```bash
mkdir -p data
sudo chown -R 1000:1000 data
chmod -R 755 data
```

**Reiniciar o serviço:**
```bash
docker-compose up -d
```

### Verificar se está funcionando

```bash
# Status dos containers
docker ps | grep minio

# Logs do MinIO
docker logs minio

# Testar API
curl http://localhost:9000/minio/health/live
```

## Variáveis de Ambiente Disponíveis

| Variável | Descrição | Valor Padrão |
|----------|-----------|--------------|
| `MINIO_ROOT_USER` | Usuário administrador | `minioadmin` |
| `MINIO_ROOT_PASSWORD` | Senha do administrador | `minioadmin123` |
| `MINIO_BROWSER_REDIRECT_URL` | URL de redirecionamento | `http://localhost:9001` (dev) / `https://minio.vikiassistant.com.br` (prod) |
| `MINIO_PORT` | Porta da API | `9000` |
| `MINIO_CONSOLE_PORT` | Porta do console web | `9001` |
| `MINIO_BUCKET` | Bucket padrão (opcional) | `minio-bucket` |
| `UID` | ID do usuário Linux/Mac | `1000` |
| `GID` | ID do grupo Linux/Mac | `1000` |

## Segurança

⚠️ **Para produção**, altere as credenciais padrão por valores mais seguros!

## Como funciona

1. **Container `minio-init`**: Executa primeiro e cria a pasta `./data` com permissões corretas
2. **Container `minio`**: Inicia após o init container e usa a pasta já configurada
3. **Dependência**: O MinIO só inicia depois que a pasta está pronta 

## CI/CD e Deploy (GitHub Actions → Hostinger)

Este repositório possui um workflow de deploy automático em:

- `.github/workflows/deploy.yml`

### Visão geral

- **Ambiente de destino**: servidor na Hostinger (mesmo utilizado pela API e Evolution API).
- **Estratégia**:
  - Faz checkout do repositório.
  - Cria chave SSH e configura o host `deploy_host`.
  - Garante que o diretório remoto (`REMOTE_TARGET`) exista.
  - Garante que a Docker network compartilhada (`DOCKER_NETWORK_NAME`, ex.: `viki_assistant_network`) exista.
  - Gera um arquivo `.env` no workflow usando **GitHub Secrets**.
  - Envia `docker-compose.yml` + `.env` via `scp` para o servidor.
  - Executa `docker compose down` + `docker compose up -d` no servidor remoto.

### GatILHOS DO WORKFLOW

- Executa para:
  - `push` na branch `main` (deploy automático).
  - `pull_request` para `main` (apenas validação do workflow, sem SSH).
- É acionado apenas quando houver alterações em:
  - `docker-compose.yml`
  - `.github/workflows/deploy.yml`

### Secrets necessários no repositório

No GitHub (Settings → Secrets and variables → Actions), configure pelo menos:

- **Infraestrutura / SSH / destino** (reutilizando o padrão dos outros projetos):
  - `SSH_PRIVATE_KEY`
  - `REMOTE_HOST`
  - `REMOTE_USER`
  - `REMOTE_PORT`
  - `REMOTE_TARGET` (diretório remoto onde o stack MinIO ficará na Hostinger)
  - (Opcional) `DOCKER_NETWORK_NAME` — se omitido, o workflow usa `viki_assistant_network`. **Não é necessário adicionar esta secret se você usar o nome padrão `viki_assistant_network`**.

- **Configuração do MinIO** (usadas para gerar o `.env` remoto):
  - `MINIO_ROOT_USER`
  - `MINIO_ROOT_PASSWORD`
  - `MINIO_PORT` (ex.: `9000`)
  - `MINIO_CONSOLE_PORT` (ex.: `9001`)
  - `MINIO_BROWSER_REDIRECT_URL` (ex.: `http://localhost:9001` em dev / `https://minio.vikiassistant.com.br` em produção)
  - `MINIO_BUCKET` (nome do bucket padrão que você deseja utilizar)

Com esses secrets configurados, qualquer alteração relevante em `docker-compose.yml`
ou no próprio workflow fará com que o MinIO seja redeployado automaticamente
no servidor da Hostinger.

## Configuração de Nginx (proxy para o console do MinIO)

Para expor o console web do MinIO em produção usando o domínio
`https://minio.vikiassistant.com.br`, configure um host no Nginx similar a:

```nginx
server {
    server_name minio.vikiassistant.com.br;

    # WebSocket do MinIO (Object Browser)
    location /ws/ {
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_pass http://127.0.0.1:9001;
        proxy_read_timeout 600s;
    }

    # Demais rotas (login, browser, etc.)
    location / {
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_pass http://127.0.0.1:9001;
        proxy_read_timeout 600s;
    }

    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/minio.vikiassistant.com.br/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/minio.vikiassistant.com.br/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
}

server {
    if ($host = minio.vikiassistant.com.br) {
        return 301 https://$host$request_uri;
    }
    listen 80;
    server_name minio.vikiassistant.com.br;
    return 404;
}
```

Após alterar o arquivo de configuração:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

Com isso, o console em `https://minio.vikiassistant.com.br/` e o bucket
(`https://minio.vikiassistant.com.br/browser/viki-assistant`) passam a carregar
corretamente, incluindo o uso de WebSockets.