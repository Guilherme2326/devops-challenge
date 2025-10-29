.PHONY: help install test run run-dev docker-build docker-run docker-stop docker-clean docker-compose-up docker-compose-down docker-compose-logs curl-test clean

help: ## Mostra esta mensagem de ajuda
	@echo "Comandos disponíveis:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}'

install: ## Instala as dependências do projeto
	pip install -r src/requirements.txt
	pip install pytest requests

test: ## Executa os testes
	pytest tests/ -v || echo "Pytest não instalado. Execute 'make install' primeiro."

run: ## Executa a aplicação com Gunicorn
	cd src && gunicorn --bind 0.0.0.0:8888 --workers 4 --threads 2 wsgi:app

run-dev: ## Executa a aplicação em modo desenvolvimento
	cd src && python application.py

docker-build: ## Constrói a imagem Docker
	docker build -t devops-challenge-api:latest .

docker-run: ## Executa o container Docker
	docker run -d \
		--name devops-challenge \
		-p 8888:8888 \
		--restart unless-stopped \
		devops-challenge-api:latest

docker-stop: ## Para e remove o container Docker
	docker stop devops-challenge || true
	docker rm devops-challenge || true

docker-clean: docker-stop ## Remove imagens e containers Docker
	docker rmi devops-challenge-api:latest || true

docker-compose-up: ## Inicia os serviços com Docker Compose
	docker compose up -d

docker-compose-down: ## Para os serviços do Docker Compose
	docker compose down

docker-compose-logs: ## Mostra os logs do Docker Compose
	docker compose logs -f

docker-compose-restart: ## Reinicia os serviços do Docker Compose
	docker compose restart

docker-compose-rebuild: ## Rebuild e restart dos serviços
	docker compose up -d --build

curl-test: ## Testa os endpoints da API
	@echo "Testando endpoint /"
	@curl -s http://localhost:8888/ | python -m json.tool || curl -s http://localhost:8888/
	@echo "\n\nTestando endpoint /healthcheck"
	@curl -s http://localhost:8888/healthcheck | python -m json.tool || curl -s http://localhost:8888/healthcheck

curl-test-nginx: ## Testa os endpoints via Nginx (porta 80)
	@echo "Testando endpoint / via Nginx"
	@curl -s http://localhost/ | python -m json.tool || curl -s http://localhost/
	@echo "\n\nTestando endpoint /healthcheck via Nginx"
	@curl -s http://localhost/healthcheck | python -m json.tool || curl -s http://localhost/healthcheck

clean: ## Limpa arquivos temporários
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
	find . -type f -name "*.pyo" -delete 2>/dev/null || true
	find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	rm -rf .pytest_cache 2>/dev/null || true
	rm -rf htmlcov 2>/dev/null || true
	rm -rf .coverage 2>/dev/null || true

logs: ## Mostra logs do container Docker
	docker logs -f devops-challenge

ps: ## Lista containers em execução
	docker ps

inspect: ## Inspeciona o container
	docker inspect devops-challenge

health: ## Verifica health do container
	docker inspect --format='{{.State.Health.Status}}' devops-challenge || echo "Container não encontrado ou sem health check"

stats: ## Mostra estatísticas dos containers
	docker stats

shell: ## Abre shell no container
	docker exec -it devops-challenge /bin/sh

full-reset: docker-clean clean ## Reset completo (para tudo e limpa)
	docker compose down -v
	docker system prune -f

# Comandos compostos para workflows comuns
dev: install run-dev ## Setup completo para desenvolvimento local

quick-start: docker-build docker-run curl-test ## Build, run e test rápido

compose-quick: ## Inicia tudo com Docker Compose e testa
	docker compose up -d
	@echo "\nServiços iniciados!"
	@echo "API: http://localhost:8888"
	@echo "Nginx: http://localhost"
	@sleep 5
	@make curl-test-nginx
