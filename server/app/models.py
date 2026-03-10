from enum import Enum

from pydantic import BaseModel, Field, field_validator


class AlibiStyle(str, Enum):
    goofy = 'goofy'
    serious = 'serious'


class GenerateExcuseRequest(BaseModel):
    truth: str = Field(min_length=1, max_length=240)
    style: AlibiStyle

    @field_validator('truth')
    @classmethod
    def validate_truth(cls, value: str) -> str:
        cleaned = value.strip()
        if not cleaned:
            raise ValueError('Truth cannot be empty.')
        return cleaned


class GenerateExcuseResponse(BaseModel):
    excuse: str
    detectedLanguage: str
    style: AlibiStyle


class ErrorResponse(BaseModel):
    detail: str
