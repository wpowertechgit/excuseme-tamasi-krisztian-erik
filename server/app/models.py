from __future__ import annotations

from datetime import datetime
from enum import Enum

from pydantic import BaseModel, Field, field_validator


class AlibiStyle(str, Enum):
    goofy = 'goofy'
    serious = 'serious'


class ExcuseCategory(str, Enum):
    work = 'work'
    personal = 'personal'
    family = 'family'
    romance = 'romance'
    health = 'health'
    sports = 'sports'
    travel = 'travel'
    other = 'other'


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


class GeneratedExcuseDraft(BaseModel):
    excuse: str = Field(min_length=1)
    detectedLanguage: str
    style: AlibiStyle
    category: ExcuseCategory

    @field_validator('excuse')
    @classmethod
    def validate_excuse(cls, value: str) -> str:
        cleaned = value.strip()
        if not cleaned:
            raise ValueError('Excuse cannot be empty.')
        return cleaned


class GenerateExcuseResponse(GeneratedExcuseDraft):
    generationId: str


class PublishGenerationResponse(BaseModel):
    wallPostId: str
    generationId: str
    published: bool


class DeleteWallPostResponse(BaseModel):
    wallPostId: str
    deleted: bool


class IncrementReactionRequest(BaseModel):
    emoji: str = Field(min_length=1, max_length=4)


class ErrorResponse(BaseModel):
    detail: str


class AuthRequest(BaseModel):
    username: str = Field(min_length=3, max_length=24)
    password: str = Field(min_length=6, max_length=128)

    @field_validator('username')
    @classmethod
    def validate_username(cls, value: str) -> str:
        cleaned = value.strip()
        if not cleaned:
            raise ValueError('Username cannot be empty.')
        if not cleaned.replace('_', '').replace('-', '').isalnum():
            raise ValueError(
                'Username may contain only letters, numbers, underscores, and hyphens.',
            )
        return cleaned


class AuthResponse(BaseModel):
    token: str
    username: str
    isAdmin: bool


class UserIdentity(BaseModel):
    userId: str
    username: str
    isAdmin: bool


class HistoryEntryResponse(BaseModel):
    id: str
    truth: str
    excuse: str
    style: AlibiStyle
    detectedLanguage: str
    category: ExcuseCategory
    publishedToWall: bool
    createdAt: datetime


class CountBucket(BaseModel):
    label: str
    value: int


class DailyActivityPoint(BaseModel):
    date: str
    count: int


class StatsOverviewResponse(BaseModel):
    totalGenerations: int
    publishedCount: int
    categoryBreakdown: list[CountBucket]
    styleBreakdown: list[CountBucket]
    languageBreakdown: list[CountBucket]
    dailyActivity: list[DailyActivityPoint]


class PublicWallPostResponse(BaseModel):
    id: str
    username: str
    truth: str
    excuse: str
    style: AlibiStyle
    detectedLanguage: str
    category: ExcuseCategory
    reactions: dict[str, int]
    totalReactions: int
    createdAt: datetime
    generationId: str
