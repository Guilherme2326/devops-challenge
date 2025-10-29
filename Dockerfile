# Multi-stage build para otimizar o tamanho da imagem
FROM python:3.9-slim as builder

# Define variáveis de ambiente
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Instala dependências do sistema necessárias para compilação
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc && \
    rm -rf /var/lib/apt/lists/*

# Cria diretório de trabalho
WORKDIR /app

# Copia apenas requirements primeiro para aproveitar cache do Docker
COPY src/requirements.txt .

# Instala dependências Python
RUN pip install --no-cache-dir --user -r requirements.txt


# Imagem final - menor possível
FROM python:3.9-slim

# Cria usuário não-root por segurança
RUN useradd -m -u 1000 appuser && \
    mkdir -p /app && \
    chown -R appuser:appuser /app

# Define variáveis de ambiente
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH=/home/appuser/.local/bin:$PATH

# Copia dependências da stage anterior
COPY --from=builder --chown=appuser:appuser /root/.local /home/appuser/.local

# Define diretório de trabalho
WORKDIR /app

# Copia código da aplicação
COPY --chown=appuser:appuser src/ .

# Muda para usuário não-root
USER appuser

# Expõe a porta da aplicação
EXPOSE 8888

# Healthcheck para monitoramento
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8888/healthcheck')" || exit 1

# Comando para iniciar a aplicação
CMD ["gunicorn", "--bind", "0.0.0.0:8888", "--workers", "4", "--threads", "2", "--timeout", "60", "--access-logfile", "-", "--error-logfile", "-", "wsgi:app"]

