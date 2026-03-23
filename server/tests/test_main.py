from __future__ import annotations

from httpx import ASGITransport, AsyncClient
import pytest

from app.config import get_settings
from app.main import app, get_openrouter_client, get_repository
from app.models import AlibiStyle, ExcuseCategory, GeneratedExcuseDraft
from app.openrouter import OpenRouterError
from app.repository import InMemoryRepository


class StubOpenRouterClient:
    def __init__(self, result=None, error=None):
        self._result = result
        self._error = error

    async def generate_excuse(self, *, truth: str, style: AlibiStyle):
        if self._error:
            raise self._error
        return self._result or GeneratedExcuseDraft(
            excuse=f'Generated for {truth}',
            detectedLanguage='en',
            style=style,
            category=ExcuseCategory.work,
        )


@pytest.fixture
def repository():
    return InMemoryRepository()


@pytest.fixture(autouse=True)
def override_dependencies(repository):
    app.dependency_overrides[get_repository] = lambda: repository
    app.dependency_overrides[get_openrouter_client] = lambda: StubOpenRouterClient()
    yield
    app.dependency_overrides.clear()
    if hasattr(app.state, 'test_repository'):
        delattr(app.state, 'test_repository')


async def _signup_and_get_token(client: AsyncClient, username='karol'):
    response = await client.post(
        '/api/auth/signup',
        json={'username': username, 'password': 'secret123'},
    )
    assert response.status_code == 200
    return response.json()['token']


@pytest.mark.asyncio
async def test_signup_returns_token():
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url='http://testserver',
    ) as client:
        response = await client.post(
            '/api/auth/signup',
            json={'username': 'Karol', 'password': 'secret123'},
        )

    assert response.status_code == 200
    assert response.json()['username'] == 'Karol'
    assert response.json()['isAdmin'] is False
    assert response.json()['token']


@pytest.mark.asyncio
async def test_signup_rejects_duplicate_user():
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url='http://testserver',
    ) as client:
        await client.post(
            '/api/auth/signup',
            json={'username': 'Karol', 'password': 'secret123'},
        )
        response = await client.post(
            '/api/auth/signup',
            json={'username': 'Karol', 'password': 'secret123'},
        )

    assert response.status_code == 409
    assert response.json()['detail'] == 'Username already exists.'


@pytest.mark.asyncio
async def test_login_rejects_invalid_password():
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url='http://testserver',
    ) as client:
        await client.post(
            '/api/auth/signup',
            json={'username': 'Karol', 'password': 'secret123'},
        )
        response = await client.post(
            '/api/auth/login',
            json={'username': 'Karol', 'password': 'wrongpass'},
        )

    assert response.status_code == 401
    assert response.json()['detail'] == 'Invalid username or password.'


@pytest.mark.asyncio
async def test_seeded_admin_can_login():
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url='http://testserver',
    ) as client:
        response = await client.post(
            '/api/auth/login',
            json={'username': 'admin', 'password': 'adminpass'},
        )

    assert response.status_code == 200
    assert response.json()['username'] == 'admin'
    assert response.json()['isAdmin'] is True


@pytest.mark.asyncio
async def test_generate_excuse_requires_authentication():
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url='http://testserver',
    ) as client:
        response = await client.post(
            '/api/excuses/generate',
            json={'truth': 'I overslept.', 'style': 'goofy'},
        )

    assert response.status_code == 401


@pytest.mark.asyncio
async def test_generate_excuse_persists_generation(repository):
    app.dependency_overrides[get_openrouter_client] = lambda: StubOpenRouterClient(
        result=GeneratedExcuseDraft(
            excuse='A unionized pigeon blocked the tram.',
            detectedLanguage='en',
            style=AlibiStyle.goofy,
            category=ExcuseCategory.travel,
        ),
    )
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url='http://testserver',
    ) as client:
        token = await _signup_and_get_token(client)
        response = await client.post(
            '/api/excuses/generate',
            json={'truth': 'I missed the tram.', 'style': 'goofy'},
            headers={'Authorization': f'Bearer {token}'},
        )

    assert response.status_code == 200
    payload = response.json()
    assert payload['category'] == 'travel'
    assert payload['generationId']
    history = repository.list_history_for_user('karol')
    assert len(history) == 1
    assert history[0].truth == 'I missed the tram.'


@pytest.mark.asyncio
async def test_generate_excuse_handles_upstream_timeout():
    app.dependency_overrides[get_openrouter_client] = lambda: StubOpenRouterClient(
        error=OpenRouterError('OpenRouter timed out.'),
    )
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url='http://testserver',
    ) as client:
        token = await _signup_and_get_token(client)
        response = await client.post(
            '/api/excuses/generate',
            json={'truth': 'Toilet emergency.', 'style': 'serious'},
            headers={'Authorization': f'Bearer {token}'},
        )

    assert response.status_code == 504
    assert response.json()['detail'] == 'The alibi engine timed out.'


@pytest.mark.asyncio
async def test_publish_generation_creates_wall_post(repository):
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url='http://testserver',
    ) as client:
        token = await _signup_and_get_token(client)
        generation = await client.post(
            '/api/excuses/generate',
            json={'truth': 'I overslept.', 'style': 'goofy'},
            headers={'Authorization': f'Bearer {token}'},
        )
        generation_id = generation.json()['generationId']
        publish = await client.post(
            f'/api/wall/publish/{generation_id}',
            headers={'Authorization': f'Bearer {token}'},
        )

    assert publish.status_code == 200
    assert publish.json()['published'] is True
    assert len(repository.list_wall_posts()) == 1
    assert repository.list_history_for_user('karol')[0].published_to_wall is True


@pytest.mark.asyncio
async def test_history_and_stats_return_user_data():
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url='http://testserver',
    ) as client:
        token = await _signup_and_get_token(client)
        generate = await client.post(
            '/api/excuses/generate',
            json={'truth': 'I overslept.', 'style': 'goofy'},
            headers={'Authorization': f'Bearer {token}'},
        )
        generation_id = generate.json()['generationId']
        await client.post(
            f'/api/wall/publish/{generation_id}',
            headers={'Authorization': f'Bearer {token}'},
        )
        history = await client.get(
            '/api/history',
            headers={'Authorization': f'Bearer {token}'},
        )
        stats = await client.get(
            '/api/stats/overview',
            headers={'Authorization': f'Bearer {token}'},
        )

    assert history.status_code == 200
    assert history.json()[0]['publishedToWall'] is True
    assert stats.status_code == 200
    assert stats.json()['totalGenerations'] == 1
    assert stats.json()['publishedCount'] == 1


@pytest.mark.asyncio
async def test_categories_and_leaderboard_return_public_posts(repository):
    user = repository.create_user(username='Karol', password_hash='hash')
    generation = repository.create_generation(
        user_id=user.id,
        username=user.username,
        truth='Missed practice.',
        excuse='The stadium flooded.',
        style=AlibiStyle.serious,
        detected_language='en',
        category=ExcuseCategory.sports,
    )
    repository.mark_generation_published(generation.id)
    wall_post = repository.create_wall_post_from_generation(generation)
    wall_post.reactions['🔥'] = 3
    wall_post.reactions['😂'] = 2

    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url='http://testserver',
    ) as client:
        category_response = await client.get('/api/categories/sports')
        leaderboard_response = await client.get('/api/leaderboard?window=all')

    assert category_response.status_code == 200
    assert category_response.json()[0]['category'] == 'sports'
    assert leaderboard_response.status_code == 200
    assert leaderboard_response.json()[0]['totalReactions'] == 5


@pytest.mark.asyncio
async def test_wall_feed_and_reactions_return_backend_posts(repository):
    user = repository.create_user(username='Karol', password_hash='hash')
    generation = repository.create_generation(
        user_id=user.id,
        username=user.username,
        truth='I overslept.',
        excuse='A raccoon sabotaged the tram schedule.',
        style=AlibiStyle.goofy,
        detected_language='en',
        category=ExcuseCategory.travel,
    )
    wall_post = repository.create_wall_post_from_generation(generation)

    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url='http://testserver',
    ) as client:
        feed = await client.get('/api/wall')
        react = await client.post(
            f'/api/wall/react/{wall_post.id}',
            json={'emoji': '🔥'},
        )

    assert feed.status_code == 200
    assert feed.json()[0]['excuse'] == 'A raccoon sabotaged the tram schedule.'
    assert react.status_code == 200
    assert react.json()['reactions']['🔥'] == 1


@pytest.mark.asyncio
async def test_admin_can_delete_wall_post(repository):
    user = repository.create_user(username='Karol', password_hash='hash')
    generation = repository.create_generation(
        user_id=user.id,
        username=user.username,
        truth='I overslept.',
        excuse='A raccoon sabotaged the tram schedule.',
        style=AlibiStyle.goofy,
        detected_language='en',
        category=ExcuseCategory.travel,
    )
    wall_post = repository.create_wall_post_from_generation(generation)

    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url='http://testserver',
    ) as client:
        admin_login = await client.post(
            '/api/auth/login',
            json={'username': 'admin', 'password': 'adminpass'},
        )
        token = admin_login.json()['token']
        response = await client.delete(
            f'/api/admin/wall/{wall_post.id}',
            headers={'Authorization': f'Bearer {token}'},
        )

    assert response.status_code == 200
    assert response.json()['deleted'] is True
    assert repository.list_wall_posts() == []


@pytest.mark.asyncio
async def test_non_admin_cannot_delete_wall_post(repository):
    user = repository.create_user(username='Karol', password_hash='hash')
    generation = repository.create_generation(
        user_id=user.id,
        username=user.username,
        truth='I overslept.',
        excuse='A raccoon sabotaged the tram schedule.',
        style=AlibiStyle.goofy,
        detected_language='en',
        category=ExcuseCategory.travel,
    )
    wall_post = repository.create_wall_post_from_generation(generation)

    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url='http://testserver',
    ) as client:
        token = await _signup_and_get_token(client, username='regular_user')
        response = await client.delete(
            f'/api/admin/wall/{wall_post.id}',
            headers={'Authorization': f'Bearer {token}'},
        )

    assert response.status_code == 403
    assert len(repository.list_wall_posts()) == 1
