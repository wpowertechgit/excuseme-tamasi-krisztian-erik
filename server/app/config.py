from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_env: str = Field(default='development', alias='APP_ENV')
    persistence_backend: str = Field(
        default='firestore',
        alias='PERSISTENCE_BACKEND',
    )
    openrouter_api_key: str = Field(default='', alias='OPENROUTER_API_KEY')
    openrouter_model: str = Field(
        default='google/gemini-2.0-flash-001',
        alias='OPENROUTER_MODEL',
    )
    openrouter_timeout_seconds: float = Field(
        default=20,
        alias='OPENROUTER_TIMEOUT_SECONDS',
    )
    auth_jwt_secret: str = Field(
        default='dev-only-change-me',
        alias='AUTH_JWT_SECRET',
    )
    auth_jwt_exp_minutes: int = Field(
        default=60 * 24 * 7,
        alias='AUTH_JWT_EXP_MINUTES',
    )
    firebase_project_id: str | None = Field(
        default=None,
        alias='FIREBASE_PROJECT_ID',
    )
    admin_username: str = Field(
        default='admin',
        alias='ADMIN_USERNAME',
    )
    admin_password: str = Field(
        default='adminpass',
        alias='ADMIN_PASSWORD',
    )

    model_config = SettingsConfigDict(
        env_file='.env',
        env_file_encoding='utf-8',
        populate_by_name=True,
    )


@lru_cache
def get_settings() -> Settings:
    return Settings()
