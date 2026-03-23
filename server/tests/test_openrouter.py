import httpx
import pytest

from app.config import Settings
from app.models import AlibiStyle, ExcuseCategory
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
async def test_openrouter_parses_structured_response():
    response = httpx.Response(
        200,
        request=httpx.Request('POST', 'http://testserver'),
        json={
            'choices': [
                {
                    'message': {
                        'content': (
                            '{"excuse":"Egy diplomatikus vizvezetek-incidens tartott fel.",'
                            '"category":"health"}'
                        ),
                    },
                }
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

    assert result.excuse == 'Egy diplomatikus vizvezetek-incidens tartott fel.'
    assert result.detectedLanguage == 'hu'
    assert result.category == ExcuseCategory.health


@pytest.mark.asyncio
async def test_openrouter_rejects_invalid_json():
    response = httpx.Response(
        200,
        request=httpx.Request('POST', 'http://testserver'),
        json={'choices': [{'message': {'content': 'not-json'}}]},
    )
    client = OpenRouterClient(
        build_settings(),
        http_client=FakeHttpClient(responses=[response, response]),
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
        request=httpx.Request('POST', 'http://testserver'),
        json={
            'choices': [
                {
                    'message': {
                        'content': (
                            '{"excuse":"Una cabra secuestro el ascensor.",'
                            '"category":"travel"}'
                        ),
                    },
                }
            ]
        },
    )
    corrected = httpx.Response(
        200,
        request=httpx.Request('POST', 'http://testserver'),
        json={
            'choices': [
                {
                    'message': {
                        'content': (
                            '{"excuse":"A goat hijacked the elevator.",'
                            '"category":"travel"}'
                        ),
                    },
                }
            ]
        },
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
    assert result.category == ExcuseCategory.travel
    assert fake_client.calls == 2
