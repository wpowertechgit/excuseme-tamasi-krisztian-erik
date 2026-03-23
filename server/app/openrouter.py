from __future__ import annotations

import json
import re

import httpx

from .config import Settings
from .models import AlibiStyle, ExcuseCategory, GeneratedExcuseDraft

SYSTEM_PROMPT = (
    "Your goal is to transform the user's pathetic truth into a legendary excuse.\n"
    "RULES:\n"
    "Style - GOOFY: Be surreal, unexpected, and borderline genius. Aim for an 'XD' reaction.\n"
    "Style - SERIOUS: Be professional and make it seem like an unavoidable force majeure.\n"
    "CRITICAL: Always respond in the EXACT same language as the user's input. Validate the context beforehand\n"
    "FORMAT: Max 2 short sentences for the excuse text.\n"
    "OUTPUT: Reply with a single JSON object only. No markdown fences. "
    'Use exactly these keys: "excuse" and "category".\n'
    "CATEGORY: Choose one of: work, personal, family, romance, health, sports, travel, other.\n"
    "TONE: Act like a person who is way too good at lying."
)


class OpenRouterError(Exception):
    pass


LANGUAGE_HINTS = {
    'hu': {
        'patterns': [r'[áéíóöőúüűÁÉÍÓÖŐÚÜŰ]'],
        'tokens': {'hogy', 'mert', 'volt', 'vagy', 'egy', 'az', 'és', 'nem'},
    },
    'es': {
        'patterns': [r'[ñáéíóúÑÁÉÍÓÚ]'],
        'tokens': {'el', 'la', 'de', 'que', 'porque', 'una', 'un', 'me'},
    },
    'pl': {
        'patterns': [r'[ąćęłńóśźżĄĆĘŁŃÓŚŹŻ]'],
        'tokens': {'sie', 'się', 'nie', 'tak', 'ale', 'że', 'bo', 'jest'},
    },
    'en': {
        'patterns': [],
        'tokens': {'the', 'and', 'because', 'was', 'were', 'late', 'my', 'I'},
    },
}


def _detect_language(text: str) -> str:
    lowered = text.lower()
    words = re.findall(r"[a-zA-Záéíóöőúüűñąćęłńóśźż']+", lowered)
    scores: dict[str, int] = {}

    for language, hints in LANGUAGE_HINTS.items():
        score = 0
        for pattern in hints['patterns']:
            if re.search(pattern, text):
                score += 3
        score += sum(1 for word in words if word in hints['tokens'])
        scores[language] = score

    best_language = max(scores, key=scores.get)
    if scores[best_language] > 0:
        return best_language
    if re.search(r'[a-zA-Z]', text):
        return 'en'
    return 'unknown'


def _extract_json_object(content: str) -> dict[str, object]:
    stripped = content.strip()
    match = re.search(r'\{.*\}', stripped, re.DOTALL)
    candidate = match.group(0) if match else stripped
    try:
        data = json.loads(candidate)
    except json.JSONDecodeError as exc:
        raise OpenRouterError('Model returned invalid JSON.') from exc
    if not isinstance(data, dict):
        raise OpenRouterError('Model returned an invalid payload.')
    return data


def _parse_generated_excuse(
    content: str,
    *,
    style: AlibiStyle,
    expected_language: str,
) -> GeneratedExcuseDraft:
    data = _extract_json_object(content)
    excuse = str(data.get('excuse', '')).strip()
    category_value = str(data.get('category', '')).strip().lower()
    if not excuse:
        raise OpenRouterError('Model returned an empty excuse.')
    try:
        category = ExcuseCategory(category_value)
    except ValueError as exc:
        raise OpenRouterError('Model returned an invalid category.') from exc

    actual_language = _detect_language(excuse)
    if (
        expected_language != 'unknown'
        and actual_language not in {expected_language, 'unknown'}
    ):
        raise OpenRouterError('Model returned an excuse in the wrong language.')

    return GeneratedExcuseDraft(
        excuse=excuse,
        detectedLanguage=expected_language,
        style=style,
        category=category,
    )


def _build_messages(
    *,
    truth: str,
    style: AlibiStyle,
    expected_language: str,
    retry: bool,
) -> list[dict[str, str]]:
    user_content = (
        f'Style: {style.value}\n'
        f'User truth: {truth}\n'
        f'Required output language: {expected_language}'
    )
    if retry:
        user_content += (
            '\nYour previous answer was invalid. '
            'Return valid JSON only, with the correct language and allowed category.'
        )

    return [
        {'role': 'system', 'content': SYSTEM_PROMPT},
        {'role': 'user', 'content': user_content},
    ]


class OpenRouterClient:
    def __init__(
        self,
        settings: Settings,
        http_client: httpx.AsyncClient | None = None,
    ) -> None:
        self._settings = settings
        self._http_client = http_client

    async def generate_excuse(
        self,
        *,
        truth: str,
        style: AlibiStyle,
    ) -> GeneratedExcuseDraft:
        if not self._settings.openrouter_api_key:
            raise OpenRouterError('OpenRouter API key is not configured.')

        expected_language = _detect_language(truth)

        if self._http_client is not None:
            return await self._generate_with_client(
                self._http_client,
                truth=truth,
                style=style,
                expected_language=expected_language,
            )

        async with httpx.AsyncClient(
            timeout=self._settings.openrouter_timeout_seconds,
        ) as client:
            return await self._generate_with_client(
                client,
                truth=truth,
                style=style,
                expected_language=expected_language,
            )

    async def _generate_with_client(
        self,
        client: httpx.AsyncClient,
        *,
        truth: str,
        style: AlibiStyle,
        expected_language: str,
    ) -> GeneratedExcuseDraft:
        for attempt in range(2):
            payload = {
                'model': self._settings.openrouter_model,
                'messages': _build_messages(
                    truth=truth,
                    style=style,
                    expected_language=expected_language,
                    retry=attempt > 0,
                ),
            }
            content = await self._send_request(client, payload)
            try:
                return _parse_generated_excuse(
                    content,
                    style=style,
                    expected_language=expected_language,
                )
            except OpenRouterError:
                if attempt == 1:
                    raise

        raise OpenRouterError('Model returned an invalid excuse payload.')

    async def _send_request(
        self,
        client: httpx.AsyncClient,
        payload: dict[str, object],
    ) -> str:
        try:
            response = await client.post(
                'https://openrouter.ai/api/v1/chat/completions',
                headers={
                    'Authorization': f'Bearer {self._settings.openrouter_api_key}',
                    'Content-Type': 'application/json',
                },
                json=payload,
            )
            response.raise_for_status()
        except httpx.TimeoutException as exc:
            raise OpenRouterError('OpenRouter timed out.') from exc
        except httpx.HTTPError as exc:
            raise OpenRouterError('OpenRouter request failed.') from exc

        data = response.json()
        content = (
            data.get('choices', [{}])[0]
            .get('message', {})
            .get('content', '')
            .strip()
        )
        if not content:
            raise OpenRouterError('Model returned an empty excuse.')

        return content

