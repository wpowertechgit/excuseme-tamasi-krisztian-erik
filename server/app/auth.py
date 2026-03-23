from __future__ import annotations

import base64
import hashlib
import hmac
import json
import secrets
from datetime import UTC, datetime, timedelta

from .config import Settings


class AuthError(Exception):
    pass


def _b64url_encode(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b'=').decode('ascii')


def _b64url_decode(data: str) -> bytes:
    padding = '=' * ((4 - len(data) % 4) % 4)
    return base64.urlsafe_b64decode(data + padding)


def hash_password(password: str) -> str:
    salt = secrets.token_hex(16)
    iterations = 120_000
    derived_key = hashlib.pbkdf2_hmac(
        'sha256',
        password.encode('utf-8'),
        salt.encode('utf-8'),
        iterations,
    )
    return (
        f'pbkdf2_sha256${iterations}${salt}$'
        f'{base64.b64encode(derived_key).decode("ascii")}'
    )


def verify_password(password: str, password_hash: str) -> bool:
    try:
        algorithm, iterations, salt, encoded_hash = password_hash.split('$', 3)
    except ValueError:
        return False

    if algorithm != 'pbkdf2_sha256':
        return False

    derived_key = hashlib.pbkdf2_hmac(
        'sha256',
        password.encode('utf-8'),
        salt.encode('utf-8'),
        int(iterations),
    )
    return hmac.compare_digest(
        base64.b64encode(derived_key).decode('ascii'),
        encoded_hash,
    )


def create_access_token(*, user_id: str, username: str, settings: Settings) -> str:
    now = datetime.now(UTC)
    payload = {
        'sub': user_id,
        'username': username,
        'iat': int(now.timestamp()),
        'exp': int(
            (now + timedelta(minutes=settings.auth_jwt_exp_minutes)).timestamp(),
        ),
    }
    header = {'alg': 'HS256', 'typ': 'JWT'}
    encoded_header = _b64url_encode(
        json.dumps(header, separators=(',', ':')).encode('utf-8'),
    )
    encoded_payload = _b64url_encode(
        json.dumps(payload, separators=(',', ':')).encode('utf-8'),
    )
    signature = hmac.new(
        settings.auth_jwt_secret.encode('utf-8'),
        f'{encoded_header}.{encoded_payload}'.encode('ascii'),
        hashlib.sha256,
    ).digest()
    return f'{encoded_header}.{encoded_payload}.{_b64url_encode(signature)}'


def decode_access_token(token: str, settings: Settings) -> dict[str, object]:
    try:
        encoded_header, encoded_payload, encoded_signature = token.split('.')
    except ValueError as exc:
        raise AuthError('Invalid token format.') from exc

    expected_signature = hmac.new(
        settings.auth_jwt_secret.encode('utf-8'),
        f'{encoded_header}.{encoded_payload}'.encode('ascii'),
        hashlib.sha256,
    ).digest()
    if not hmac.compare_digest(
        _b64url_encode(expected_signature),
        encoded_signature,
    ):
        raise AuthError('Invalid token signature.')

    payload = json.loads(_b64url_decode(encoded_payload))
    exp = int(payload.get('exp', 0))
    if exp < int(datetime.now(UTC).timestamp()):
        raise AuthError('Token expired.')
    return payload

