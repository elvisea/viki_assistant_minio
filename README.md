# Viki Assistant MinIO

Serviço MinIO para armazenamento de objetos do Viki Assistant.

## Configuração

### Variáveis de Ambiente

Crie um arquivo `.env` baseado no `.env.example`:

```bash
cp .env.example .env
```

**IMPORTANTE sobre `MINIO_BROWSER_REDIRECT_URL`:**

Quando o MinIO está atrás de um proxy reverso (nginx) com HTTPS:

- ❌ **NÃO use**: `MINIO_BROWSER_REDIRECT_URL=https://minio.vikiassistant.com.br`
- ❌ **NÃO use**: `MINIO_BROWSER_REDIRECT_URL=http://minio.vikiassistant.com.br`
- ✅ **Use apenas o domínio**: `MINIO_BROWSER_REDIRECT_URL=minio.vikiassistant.com.br`
- ✅ **Ou remova/comente a variável**: O MinIO funcionará corretamente sem ela quando estiver atrás de proxy reverso

O MinIO não aceita protocolo (`https://` ou `http://`) na variável `MINIO_BROWSER_REDIRECT_URL` quando está atrás de um proxy reverso, pois o nginx já gerencia o HTTPS.

## Uso

### Iniciar os serviços

```bash
docker compose up -d
```

### Verificar logs

```bash
docker logs minio
```

### Parar os serviços

```bash
docker compose down
```

## Rede

Este serviço requer que a rede `viki_assistant_network` já exista. Se não existir, crie com:

```bash
docker network create viki_assistant_network
```

## Portas

- **9000**: API do MinIO
- **9001**: Console do MinIO

## Acesso

O MinIO está configurado para ser acessado através do nginx em:
- `https://minio.vikiassistant.com.br` (API)
- `https://minio.vikiassistant.com.br/minio/` (Console)

## Configuração de CORS

O CORS (Cross-Origin Resource Sharing) é configurado automaticamente quando o MinIO inicia, permitindo que o frontend carregue imagens diretamente via presigned URLs.

### Configuração Automática

O container `minio-cors-setup` é executado automaticamente após o MinIO estar pronto e configura o CORS no bucket `viki-assistant`. A configuração está definida em `config/cors-config.xml` e inclui as seguintes origens permitidas:

- `https://vikiassistant.com.br` (produção)
- `http://localhost:3001` (desenvolvimento)
- `http://localhost:3000` (desenvolvimento)
- `http://127.0.0.1:3001` (desenvolvimento)
- `http://127.0.0.1:3000` (desenvolvimento)

### Execução Manual

Se precisar reconfigurar o CORS manualmente, execute:

```bash
./scripts/configure-cors.sh
```

O script:
- Verifica se a rede Docker existe (cria se necessário)
- Verifica se o MinIO está rodando (inicia se necessário)
- Configura o alias do MinIO Client
- Cria o bucket se não existir
- Aplica a configuração CORS do arquivo `config/cors-config.xml`

### Variáveis de Ambiente

O script e o container de configuração CORS usam as seguintes variáveis de ambiente (com valores padrão):

- `MINIO_ENDPOINT`: Endpoint do MinIO (padrão: `http://minio:9000`)
- `MINIO_ROOT_USER`: Usuário root do MinIO (padrão: `minioadmin`)
- `MINIO_ROOT_PASSWORD`: Senha root do MinIO (padrão: `minioadmin123`)
- `MINIO_BUCKET_NAME`: Nome do bucket (padrão: `viki-assistant`)
- `DOCKER_NETWORK_NAME`: Nome da rede Docker (padrão: `viki_assistant_network`)

### Personalizar Origens Permitidas

Para adicionar ou remover origens permitidas, edite o arquivo `config/cors-config.xml`:

```xml
<AllowedOrigin>https://sua-origem.com</AllowedOrigin>
```

Depois, reexecute o script ou reinicie o container `minio-cors-setup`:

```bash
docker compose restart minio-cors-setup
```

### Verificar Configuração CORS

Para verificar a configuração CORS atual, você pode usar o MinIO Client:

```bash
docker run --rm --network viki_assistant_network minio/mc:latest \
  sh -c "
    mc alias set myminio http://minio:9000 minioadmin minioadmin123
    mc cors get myminio/viki-assistant
  "
```

Ou acesse o console do MinIO em `https://minio.vikiassistant.com.br/minio/` e vá em **Settings > CORS**.
