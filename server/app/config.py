from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_env: str = Field(default='development', alias='APP_ENV')
    openrouter_api_key: str = Field(alias='OPENROUTER_API_KEY')
    openrouter_model: str = Field(
        default='google/gemini-2.0-flash-001',
        alias='OPENROUTER_MODEL',
    )
    openrouter_timeout_seconds: float = Field(
        default=20,
        alias='OPENROUTER_TIMEOUT_SECONDS',
    )

    model_config = SettingsConfigDict(
        env_file='.env',
        env_file_encoding='utf-8',
        populate_by_name=True,
    )


@lru_cache
def get_settings() -> Settings:
    return Settings()
