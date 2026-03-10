import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app, get_openrouter_client
from app.models import AlibiStyle, GenerateExcuseResponse
from app.openrouter import OpenRouterError


class StubClient:
    def __init__(self, result=None, error=None):
        self._result = result
        self._error = error

    async def generate_excuse(self, *, truth: str, style: AlibiStyle):
        if self._error:
            raise self._error
        return self._result or GenerateExcuseResponse(
            excuse=f'Generated for {truth}',
            detectedLanguage='en',
            style=style,
        )


@pytest.mark.asyncio
async def test_generate_excuse_success():
    app.dependency_overrides[get_openrouter_client] = lambda: StubClient()
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url='http://testserver',
    ) as client:
        response = await client.post(
            '/api/excuses/generate',
            json={'truth': 'I overslept.', 'style': 'goofy'},
        )

    assert response.status_code == 200
    assert response.json()['style'] == 'goofy'
    app.dependency_overrides.clear()


@pytest.mark.asyncio
async def test_generate_excuse_rejects_empty_truth():
    app.dependency_overrides[get_openrouter_client] = lambda: StubClient()
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url='http://testserver',
    ) as client:
        response = await client.post(
            '/api/excuses/generate',
            json={'truth': '   ', 'style': 'goofy'},
        )

    assert response.status_code == 422
    app.dependency_overrides.clear()


@pytest.mark.asyncio
async def test_generate_excuse_handles_timeout():
    app.dependency_overrides[get_openrouter_client] = lambda: StubClient(
        error=OpenRouterError('OpenRouter timed out.'),
    )
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url='http://testserver',
    ) as client:
        response = await client.post(
            '/api/excuses/generate',
            json={'truth': 'Toilet emergency.', 'style': 'serious'},
        )

    assert response.status_code == 504
    assert response.json()['detail'] == 'The alibi engine timed out.'
    app.dependency_overrides.clear()


@pytest.mark.asyncio
async def test_generate_excuse_handles_upstream_failure():
    app.dependency_overrides[get_openrouter_client] = lambda: StubClient(
        error=OpenRouterError('OpenRouter request failed.'),
    )
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url='http://testserver',
    ) as client:
        response = await client.post(
            '/api/excuses/generate',
            json={'truth': 'Missed the bus.', 'style': 'serious'},
        )

    assert response.status_code == 502
    assert response.json()['detail'] == 'The alibi engine failed upstream.'
    app.dependency_overrides.clear()
