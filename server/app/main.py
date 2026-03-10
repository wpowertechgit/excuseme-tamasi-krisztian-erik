from contextlib import asynccontextmanager

from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware

from .config import Settings, get_settings
from .models import ErrorResponse, GenerateExcuseRequest, GenerateExcuseResponse
from .openrouter import OpenRouterClient, OpenRouterError


@asynccontextmanager
async def lifespan(_: FastAPI):
    yield


app = FastAPI(
    title='Excuse Me API',
    version='1.0.0',
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=['*'],
    allow_credentials=False,
    allow_methods=['*'],
    allow_headers=['*'],
)


def get_openrouter_client(
    settings: Settings = Depends(get_settings),
) -> OpenRouterClient:
    return OpenRouterClient(settings)


@app.get('/health')
async def healthcheck() -> dict[str, str]:
    return {'status': 'ok'}


@app.post(
    '/api/excuses/generate',
    response_model=GenerateExcuseResponse,
    responses={
        status.HTTP_400_BAD_REQUEST: {'model': ErrorResponse},
        status.HTTP_502_BAD_GATEWAY: {'model': ErrorResponse},
        status.HTTP_504_GATEWAY_TIMEOUT: {'model': ErrorResponse},
    },
)
async def generate_excuse(
    payload: GenerateExcuseRequest,
    client: OpenRouterClient = Depends(get_openrouter_client),
) -> GenerateExcuseResponse:
    try:
        return await client.generate_excuse(
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
