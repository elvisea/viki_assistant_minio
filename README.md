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
