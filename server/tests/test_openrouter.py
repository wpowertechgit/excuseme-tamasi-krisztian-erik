import httpx
import pytest

from app.config import Settings
from app.models import AlibiStyle
from app.openrouter import OpenRouterClient, OpenRouterError


def build_settings() -> Settings:
    return Settings.model_construct(
        app_env='test',
        openrouter_api_key='test-key',
        openrouter_model='test-model',
        openrouter_timeout_seconds=5,
    )


class FakeHttpClient:
    def __init__(self, responses=None, error=None):
        self._responses = list(responses or [])
        self._error = error
        self.calls = 0

    async def post(self, *args, **kwargs):
        if self._error:
            raise self._error
        response = self._responses[self.calls]
        self.calls += 1
        return response


@pytest.mark.asyncio
async def test_openrouter_parses_response():
    response = httpx.Response(
        200,
        json={
            'choices': [
                {'message': {'content': 'A diplomatic plumbing event slowed me down.'}}
            ]
        },
    )
    client = OpenRouterClient(
        build_settings(),
        http_client=FakeHttpClient(responses=[response]),
    )

    result = await client.generate_excuse(
        truth='Késtem, mert a mosdó fogva volt.',
        style=AlibiStyle.serious,
    )

    assert result.excuse == 'A diplomatic plumbing event slowed me down.'
    assert result.detectedLanguage == 'hu'


@pytest.mark.asyncio
async def test_openrouter_rejects_empty_content():
    response = httpx.Response(
        200,
        json={'choices': [{'message': {'content': '   '}}]},
    )
    client = OpenRouterClient(
        build_settings(),
        http_client=FakeHttpClient(responses=[response]),
    )

    with pytest.raises(OpenRouterError):
        await client.generate_excuse(
            truth='I overslept.',
            style=AlibiStyle.goofy,
        )


@pytest.mark.asyncio
async def test_openrouter_retries_wrong_language():
    wrong_language = httpx.Response(
        200,
        json={'choices': [{'message': {'content': 'Una cabra secuestro el ascensor.'}}]},
    )
    corrected = httpx.Response(
        200,
        json={'choices': [{'message': {'content': 'A goat hijacked the elevator.'}}]},
    )
    fake_client = FakeHttpClient(responses=[wrong_language, corrected])
    client = OpenRouterClient(
        build_settings(),
        http_client=fake_client,
    )

    result = await client.generate_excuse(
        truth='I was late because the elevator got stuck.',
        style=AlibiStyle.goofy,
    )

    assert result.excuse == 'A goat hijacked the elevator.'
    assert fake_client.calls == 2
