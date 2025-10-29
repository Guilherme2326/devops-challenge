import pytest
import json
import sys
import os

# Adiciona o diretório src ao path para importar a aplicação
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

from application import app


@pytest.fixture
def client():
    """Cria um cliente de teste para a aplicação Flask"""
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client


def test_main_endpoint(client):
    """Testa o endpoint principal /"""
    response = client.get('/')
    
    assert response.status_code == 200
    assert response.content_type == 'application/json'
    
    data = json.loads(response.data)
    assert 'App Test' in data
    assert data['App Test'] == 'Alive'


def test_healthcheck_endpoint(client):
    """Testa o endpoint /healthcheck"""
    response = client.get('/healthcheck')
    
    assert response.status_code == 200
    assert response.content_type == 'application/json'
    
    data = json.loads(response.data)
    assert 'Status' in data
    assert data['Status'] == 'heart beating steady and strong'


def test_invalid_endpoint(client):
    """Testa um endpoint que não existe"""
    response = client.get('/invalid')
    assert response.status_code == 404


def test_main_endpoint_response_format(client):
    """Verifica o formato da resposta do endpoint principal"""
    response = client.get('/')
    data = json.loads(response.data)
    
    # Verifica se a resposta é um dicionário
    assert isinstance(data, dict)
    
    # Verifica se tem exatamente uma chave
    assert len(data) == 1


def test_healthcheck_endpoint_response_format(client):
    """Verifica o formato da resposta do endpoint healthcheck"""
    response = client.get('/healthcheck')
    data = json.loads(response.data)
    
    # Verifica se a resposta é um dicionário
    assert isinstance(data, dict)
    
    # Verifica se tem exatamente uma chave
    assert len(data) == 1

