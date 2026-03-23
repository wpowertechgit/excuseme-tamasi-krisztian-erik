from __future__ import annotations

from collections import Counter
from contextlib import asynccontextmanager
from datetime import UTC

from fastapi import Depends, FastAPI, HTTPException, Query, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from .auth import AuthError, create_access_token, decode_access_token, hash_password, verify_password
from .config import Settings, get_settings
from .models import (
    AuthRequest,
    AuthResponse,
    CountBucket,
    DailyActivityPoint,
    DeleteWallPostResponse,
    ErrorResponse,
    ExcuseCategory,
    GenerateExcuseRequest,
    GenerateExcuseResponse,
    HistoryEntryResponse,
    IncrementReactionRequest,
    PublishGenerationResponse,
    PublicWallPostResponse,
    StatsOverviewResponse,
    UserIdentity,
)
from .openrouter import OpenRouterClient, OpenRouterError
from .repository import (
    DuplicateUserError,
    FirestoreRepository,
    GenerationRecord,
    InMemoryRepository,
    RepositoryError,
    WallPostRecord,
)


@asynccontextmanager
async def lifespan(_: FastAPI):
    yield


app = FastAPI(
    title='Excuse Me API',
    version='2.0.0',
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=['*'],
    allow_credentials=False,
    allow_methods=['*'],
    allow_headers=['*'],
)

bearer_scheme = HTTPBearer(auto_error=False)


def get_openrouter_client(
    settings: Settings = Depends(get_settings),
) -> OpenRouterClient:
    return OpenRouterClient(settings)


def get_repository(
    settings: Settings = Depends(get_settings),
):
    if settings.app_env == 'test' or settings.persistence_backend == 'memory':
        if not hasattr(app.state, 'test_repository'):
            app.state.test_repository = InMemoryRepository(
                admin_username=settings.admin_username,
                admin_password=settings.admin_password,
            )
        return app.state.test_repository
    try:
        return FirestoreRepository(settings)
    except RepositoryError as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(exc),
        ) from exc


def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    settings: Settings = Depends(get_settings),
    repository=Depends(get_repository),
) -> UserIdentity:
    if credentials is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail='Authentication required.',
        )
    try:
        payload = decode_access_token(credentials.credentials, settings)
    except AuthError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail='Invalid authentication token.',
        ) from exc

    user_id = str(payload.get('sub', ''))
    user = repository.get_user_by_id(user_id)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail='User account no longer exists.',
        )
    return UserIdentity(
        userId=user.id,
        username=user.username,
        isAdmin=user.is_admin,
    )


def require_admin(current_user: UserIdentity = Depends(get_current_user)) -> UserIdentity:
    if not current_user.isAdmin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail='Admin access required.',
        )
    return current_user


@app.get('/health')
async def healthcheck() -> dict[str, str]:
    return {'status': 'ok'}


@app.post(
    '/api/auth/signup',
    response_model=AuthResponse,
    responses={
        status.HTTP_409_CONFLICT: {'model': ErrorResponse},
    },
)
async def signup(
    payload: AuthRequest,
    settings: Settings = Depends(get_settings),
    repository=Depends(get_repository),
) -> AuthResponse:
    try:
        user = repository.create_user(
            username=payload.username,
            password_hash=hash_password(payload.password),
        )
    except DuplicateUserError as exc:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail='Username already exists.',
        ) from exc

    token = create_access_token(
        user_id=user.id,
        username=user.username,
        settings=settings,
    )
    return AuthResponse(
        token=token,
        username=user.username,
        isAdmin=user.is_admin,
    )


@app.post(
    '/api/auth/login',
    response_model=AuthResponse,
    responses={
        status.HTTP_401_UNAUTHORIZED: {'model': ErrorResponse},
    },
)
async def login(
    payload: AuthRequest,
    settings: Settings = Depends(get_settings),
    repository=Depends(get_repository),
) -> AuthResponse:
    user = repository.get_user_by_username(payload.username)
    if user is None or not verify_password(payload.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail='Invalid username or password.',
        )

    token = create_access_token(
        user_id=user.id,
        username=user.username,
        settings=settings,
    )
    return AuthResponse(
        token=token,
        username=user.username,
        isAdmin=user.is_admin,
    )


@app.post(
    '/api/excuses/generate',
    response_model=GenerateExcuseResponse,
    responses={
        status.HTTP_400_BAD_REQUEST: {'model': ErrorResponse},
        status.HTTP_401_UNAUTHORIZED: {'model': ErrorResponse},
        status.HTTP_502_BAD_GATEWAY: {'model': ErrorResponse},
        status.HTTP_504_GATEWAY_TIMEOUT: {'model': ErrorResponse},
    },
)
async def generate_excuse(
    payload: GenerateExcuseRequest,
    client: OpenRouterClient = Depends(get_openrouter_client),
    current_user: UserIdentity = Depends(get_current_user),
    repository=Depends(get_repository),
) -> GenerateExcuseResponse:
    try:
        draft = await client.generate_excuse(
            truth=payload.truth,
            style=payload.style,
        )
    except OpenRouterError as exc:
        message = str(exc)
        if 'timed out' in message.lower():
            raise HTTPException(
                status_code=status.HTTP_504_GATEWAY_TIMEOUT,
                detail='The alibi engine timed out.',
            ) from exc
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail='The alibi engine failed upstream.',
        ) from exc

    generation = repository.create_generation(
        user_id=current_user.userId,
        username=current_user.username,
        truth=payload.truth,
        excuse=draft.excuse,
        style=draft.style,
        detected_language=draft.detectedLanguage,
        category=draft.category,
    )
    return GenerateExcuseResponse(
        generationId=generation.id,
        excuse=draft.excuse,
        detectedLanguage=draft.detectedLanguage,
        style=draft.style,
        category=draft.category,
    )


@app.post(
    '/api/wall/publish/{generation_id}',
    response_model=PublishGenerationResponse,
    responses={
        status.HTTP_401_UNAUTHORIZED: {'model': ErrorResponse},
        status.HTTP_403_FORBIDDEN: {'model': ErrorResponse},
        status.HTTP_404_NOT_FOUND: {'model': ErrorResponse},
    },
)
async def publish_generation(
    generation_id: str,
    current_user: UserIdentity = Depends(get_current_user),
    repository=Depends(get_repository),
) -> PublishGenerationResponse:
    generation = repository.get_generation(generation_id)
    if generation is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail='Generation not found.',
        )
    if generation.user_id != current_user.userId:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail='You can only publish your own excuses.',
        )

    updated_generation = generation
    if not generation.published_to_wall:
        updated_generation = repository.mark_generation_published(generation_id) or generation
        wall_post = repository.create_wall_post_from_generation(updated_generation)
        return PublishGenerationResponse(
            wallPostId=wall_post.id,
            generationId=generation_id,
            published=True,
        )

    return PublishGenerationResponse(
        wallPostId='already-published',
        generationId=generation_id,
        published=True,
    )


@app.get(
    '/api/wall',
    response_model=list[PublicWallPostResponse],
)
async def get_wall_feed(
    repository=Depends(get_repository),
) -> list[PublicWallPostResponse]:
    posts = repository.list_wall_posts()
    return [_wall_post_response(post) for post in posts]


@app.post(
    '/api/wall/react/{post_id}',
    response_model=PublicWallPostResponse,
    responses={
        status.HTTP_400_BAD_REQUEST: {'model': ErrorResponse},
        status.HTTP_404_NOT_FOUND: {'model': ErrorResponse},
    },
)
async def react_to_wall_post(
    post_id: str,
    payload: IncrementReactionRequest,
    repository=Depends(get_repository),
) -> PublicWallPostResponse:
    try:
        post = repository.increment_wall_reaction(post_id, payload.emoji)
    except RepositoryError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        ) from exc
    if post is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail='Wall post not found.',
        )
    return _wall_post_response(post)


@app.delete(
    '/api/admin/wall/{post_id}',
    response_model=DeleteWallPostResponse,
    responses={
        status.HTTP_401_UNAUTHORIZED: {'model': ErrorResponse},
        status.HTTP_403_FORBIDDEN: {'model': ErrorResponse},
        status.HTTP_404_NOT_FOUND: {'model': ErrorResponse},
    },
)
async def delete_wall_post(
    post_id: str,
    _: UserIdentity = Depends(require_admin),
    repository=Depends(get_repository),
) -> DeleteWallPostResponse:
    post = repository.delete_wall_post(post_id)
    if post is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail='Wall post not found.',
        )
    return DeleteWallPostResponse(
        wallPostId=post.id,
        deleted=True,
    )


@app.get(
    '/api/history',
    response_model=list[HistoryEntryResponse],
    responses={
        status.HTTP_401_UNAUTHORIZED: {'model': ErrorResponse},
    },
)
async def get_history(
    current_user: UserIdentity = Depends(get_current_user),
    repository=Depends(get_repository),
) -> list[HistoryEntryResponse]:
    history = repository.list_history_for_user(current_user.userId)
    return [_history_response(entry) for entry in history]


@app.get(
    '/api/stats/overview',
    response_model=StatsOverviewResponse,
    responses={
        status.HTTP_401_UNAUTHORIZED: {'model': ErrorResponse},
    },
)
async def get_stats_overview(
    current_user: UserIdentity = Depends(get_current_user),
    repository=Depends(get_repository),
) -> StatsOverviewResponse:
    history = repository.list_history_for_user(current_user.userId)
    return _build_stats_overview(history)


@app.get(
    '/api/categories/{category}',
    response_model=list[PublicWallPostResponse],
)
async def get_category_feed(
    category: ExcuseCategory,
    repository=Depends(get_repository),
) -> list[PublicWallPostResponse]:
    posts = repository.list_wall_posts(category=category)
    return [_wall_post_response(post) for post in posts]


@app.get(
    '/api/leaderboard',
    response_model=list[PublicWallPostResponse],
)
async def get_leaderboard(
    window: str = Query(default='all', pattern='^(all|week)$'),
    repository=Depends(get_repository),
) -> list[PublicWallPostResponse]:
    days = 7 if window == 'week' else None
    posts = repository.list_leaderboard(days=days)
    return [_wall_post_response(post) for post in posts]


def _history_response(record: GenerationRecord) -> HistoryEntryResponse:
    return HistoryEntryResponse(
        id=record.id,
        truth=record.truth,
        excuse=record.excuse,
        style=record.style,
        detectedLanguage=record.detected_language,
        category=record.category,
        publishedToWall=record.published_to_wall,
        createdAt=record.created_at.astimezone(UTC),
    )


def _wall_post_response(record: WallPostRecord) -> PublicWallPostResponse:
    return PublicWallPostResponse(
        id=record.id,
        username=record.username,
        truth=record.truth,
        excuse=record.excuse,
        style=record.style,
        detectedLanguage=record.detected_language,
        category=record.category,
        reactions=record.reactions,
        totalReactions=record.total_reactions,
        createdAt=record.created_at.astimezone(UTC),
        generationId=record.generation_id,
    )


def _build_stats_overview(history: list[GenerationRecord]) -> StatsOverviewResponse:
    category_counter = Counter(entry.category.value for entry in history)
    style_counter = Counter(entry.style.value for entry in history)
    language_counter = Counter(entry.detected_language for entry in history)
    day_counter = Counter(entry.created_at.astimezone(UTC).date().isoformat() for entry in history)

    return StatsOverviewResponse(
        totalGenerations=len(history),
        publishedCount=sum(1 for entry in history if entry.published_to_wall),
        categoryBreakdown=_counter_to_buckets(category_counter),
        styleBreakdown=_counter_to_buckets(style_counter),
        languageBreakdown=_counter_to_buckets(language_counter),
        dailyActivity=[
            DailyActivityPoint(date=date, count=count)
            for date, count in sorted(day_counter.items())
        ],
    )


def _counter_to_buckets(counter: Counter[str]) -> list[CountBucket]:
    return [
        CountBucket(label=label, value=value)
        for label, value in sorted(
            counter.items(),
            key=lambda item: (-item[1], item[0]),
        )
    ]
