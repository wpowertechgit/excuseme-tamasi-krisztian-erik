from __future__ import annotations

from dataclasses import dataclass
from datetime import UTC, datetime, timedelta

from .auth import hash_password
from .categorization import infer_category, parse_or_infer_category
from .config import Settings
from .models import AlibiStyle, ExcuseCategory

try:
    import firebase_admin
    from firebase_admin import firestore
except ImportError:  # pragma: no cover - exercised only without dependency installed
    firebase_admin = None
    firestore = None


SUPPORTED_REACTIONS = ('😂', '🔥', '💀', '🤡')


class RepositoryError(Exception):
    pass


class DuplicateUserError(RepositoryError):
    pass


@dataclass(slots=True)
class UserRecord:
    id: str
    username: str
    password_hash: str
    is_admin: bool
    created_at: datetime


@dataclass(slots=True)
class GenerationRecord:
    id: str
    user_id: str
    username: str
    truth: str
    excuse: str
    style: AlibiStyle
    detected_language: str
    category: ExcuseCategory
    published_to_wall: bool
    created_at: datetime


@dataclass(slots=True)
class WallPostRecord:
    id: str
    username: str
    truth: str
    excuse: str
    style: AlibiStyle
    detected_language: str
    category: ExcuseCategory
    generation_id: str
    reactions: dict[str, int]
    created_at: datetime

    @property
    def total_reactions(self) -> int:
        return sum(self.reactions.values())


def normalize_username(username: str) -> str:
    return username.strip().lower()


class InMemoryRepository:
    def __init__(
        self,
        *,
        admin_username: str = 'admin',
        admin_password: str = 'adminpass',
    ) -> None:
        self._users: dict[str, UserRecord] = {}
        self._generations: dict[str, GenerationRecord] = {}
        self._wall_posts: dict[str, WallPostRecord] = {}
        self._counter = 0
        self._ensure_admin_account(
            username=admin_username,
            password=admin_password,
        )

    def _next_id(self, prefix: str) -> str:
        self._counter += 1
        return f'{prefix}-{self._counter}'

    def create_user(
        self,
        *,
        username: str,
        password_hash: str,
        is_admin: bool = False,
    ) -> UserRecord:
        user_id = normalize_username(username)
        if user_id in self._users:
            raise DuplicateUserError('Username already exists.')
        record = UserRecord(
            id=user_id,
            username=username,
            password_hash=password_hash,
            is_admin=is_admin,
            created_at=datetime.now(UTC),
        )
        self._users[user_id] = record
        return record

    def _ensure_admin_account(self, *, username: str, password: str) -> None:
        if self.get_user_by_username(username) is not None:
            return
        self.create_user(
            username=username,
            password_hash=hash_password(password),
            is_admin=True,
        )

    def get_user_by_username(self, username: str) -> UserRecord | None:
        return self._users.get(normalize_username(username))

    def get_user_by_id(self, user_id: str) -> UserRecord | None:
        return self._users.get(user_id)

    def create_generation(
        self,
        *,
        user_id: str,
        username: str,
        truth: str,
        excuse: str,
        style: AlibiStyle,
        detected_language: str,
        category: ExcuseCategory,
    ) -> GenerationRecord:
        generation_id = self._next_id('gen')
        record = GenerationRecord(
            id=generation_id,
            user_id=user_id,
            username=username,
            truth=truth,
            excuse=excuse,
            style=style,
            detected_language=detected_language,
            category=category,
            published_to_wall=False,
            created_at=datetime.now(UTC),
        )
        self._generations[generation_id] = record
        return record

    def get_generation(self, generation_id: str) -> GenerationRecord | None:
        return self._generations.get(generation_id)

    def mark_generation_published(self, generation_id: str) -> GenerationRecord | None:
        record = self._generations.get(generation_id)
        if record is None:
            return None
        updated = GenerationRecord(
            id=record.id,
            user_id=record.user_id,
            username=record.username,
            truth=record.truth,
            excuse=record.excuse,
            style=record.style,
            detected_language=record.detected_language,
            category=record.category,
            published_to_wall=True,
            created_at=record.created_at,
        )
        self._generations[generation_id] = updated
        return updated

    def create_wall_post_from_generation(
        self,
        generation: GenerationRecord,
    ) -> WallPostRecord:
        post_id = self._next_id('wall')
        record = WallPostRecord(
            id=post_id,
            username=generation.username,
            truth=generation.truth,
            excuse=generation.excuse,
            style=generation.style,
            detected_language=generation.detected_language,
            category=generation.category,
            generation_id=generation.id,
            reactions={emoji: 0 for emoji in SUPPORTED_REACTIONS},
            created_at=datetime.now(UTC),
        )
        self._wall_posts[post_id] = record
        return record

    def list_history_for_user(self, user_id: str) -> list[GenerationRecord]:
        return sorted(
            (
                record
                for record in self._generations.values()
                if record.user_id == user_id
            ),
            key=lambda record: record.created_at,
            reverse=True,
        )

    def list_wall_posts(self, *, category: ExcuseCategory | None = None) -> list[WallPostRecord]:
        records = self._wall_posts.values()
        if category is not None:
            records = (record for record in records if record.category == category)
        return sorted(records, key=lambda record: record.created_at, reverse=True)

    def list_leaderboard(self, *, days: int | None = None) -> list[WallPostRecord]:
        records = self.list_wall_posts()
        if days is not None:
            cutoff = datetime.now(UTC) - timedelta(days=days)
            records = [record for record in records if record.created_at >= cutoff]
        return sorted(
            records,
            key=lambda record: (record.total_reactions, record.created_at),
            reverse=True,
        )

    def increment_wall_reaction(
        self,
        post_id: str,
        emoji: str,
    ) -> WallPostRecord | None:
        if emoji not in SUPPORTED_REACTIONS:
            raise RepositoryError('Unsupported reaction.')
        record = self._wall_posts.get(post_id)
        if record is None:
            return None
        updated_reactions = dict(record.reactions)
        updated_reactions[emoji] = updated_reactions.get(emoji, 0) + 1
        updated = WallPostRecord(
            id=record.id,
            username=record.username,
            truth=record.truth,
            excuse=record.excuse,
            style=record.style,
            detected_language=record.detected_language,
            category=record.category,
            generation_id=record.generation_id,
            reactions=updated_reactions,
            created_at=record.created_at,
        )
        self._wall_posts[post_id] = updated
        return updated

    def delete_wall_post(self, post_id: str) -> WallPostRecord | None:
        record = self._wall_posts.pop(post_id, None)
        if record is None:
            return None
        if record.generation_id:
            generation = self._generations.get(record.generation_id)
            if generation is not None:
                self._generations[record.generation_id] = GenerationRecord(
                    id=generation.id,
                    user_id=generation.user_id,
                    username=generation.username,
                    truth=generation.truth,
                    excuse=generation.excuse,
                    style=generation.style,
                    detected_language=generation.detected_language,
                    category=generation.category,
                    published_to_wall=False,
                    created_at=generation.created_at,
                )
        return record

    def backfill_missing_categories(self) -> dict[str, int]:
        updated_generations = 0
        updated_wall_posts = 0

        for generation_id, generation in list(self._generations.items()):
            inferred = infer_category(truth=generation.truth, excuse=generation.excuse)
            if generation.category == inferred:
                continue
            self._generations[generation_id] = GenerationRecord(
                id=generation.id,
                user_id=generation.user_id,
                username=generation.username,
                truth=generation.truth,
                excuse=generation.excuse,
                style=generation.style,
                detected_language=generation.detected_language,
                category=inferred,
                published_to_wall=generation.published_to_wall,
                created_at=generation.created_at,
            )
            updated_generations += 1

        for post_id, post in list(self._wall_posts.items()):
            inferred = infer_category(truth=post.truth, excuse=post.excuse)
            if post.category == inferred:
                continue
            self._wall_posts[post_id] = WallPostRecord(
                id=post.id,
                username=post.username,
                truth=post.truth,
                excuse=post.excuse,
                style=post.style,
                detected_language=post.detected_language,
                category=inferred,
                generation_id=post.generation_id,
                reactions=post.reactions,
                created_at=post.created_at,
            )
            updated_wall_posts += 1

        return {
            'generations': updated_generations,
            'wall_posts': updated_wall_posts,
        }


class FirestoreRepository:
    def __init__(self, settings: Settings) -> None:
        if firebase_admin is None or firestore is None:
            raise RepositoryError(
                'firebase-admin is required for Firestore-backed persistence.',
            )
        self._settings = settings
        if not firebase_admin._apps:
            options = {}
            if settings.firebase_project_id:
                options['projectId'] = settings.firebase_project_id
            firebase_admin.initialize_app(options=options or None)
        self._db = firestore.client()
        self._ensure_admin_account(
            username=settings.admin_username,
            password=settings.admin_password,
        )

    @property
    def _users(self):
        return self._db.collection('users')

    @property
    def _generations(self):
        return self._db.collection('excuse_generations')

    @property
    def _wall_posts(self):
        return self._db.collection('wall_posts')

    def create_user(
        self,
        *,
        username: str,
        password_hash: str,
        is_admin: bool = False,
    ) -> UserRecord:
        user_id = normalize_username(username)
        reference = self._users.document(user_id)
        snapshot = reference.get()
        if snapshot.exists:
            raise DuplicateUserError('Username already exists.')
        created_at = datetime.now(UTC)
        reference.set(
            {
                'username': username,
                'passwordHash': password_hash,
                'isAdmin': is_admin,
                'createdAt': created_at,
            },
        )
        return UserRecord(
            id=user_id,
            username=username,
            password_hash=password_hash,
            is_admin=is_admin,
            created_at=created_at,
        )

    def _ensure_admin_account(self, *, username: str, password: str) -> None:
        if self.get_user_by_username(username) is not None:
            return
        self.create_user(
            username=username,
            password_hash=hash_password(password),
            is_admin=True,
        )

    def get_user_by_username(self, username: str) -> UserRecord | None:
        return self.get_user_by_id(normalize_username(username))

    def get_user_by_id(self, user_id: str) -> UserRecord | None:
        snapshot = self._users.document(user_id).get()
        if not snapshot.exists:
            return None
        data = snapshot.to_dict() or {}
        created_at = data.get('createdAt') or datetime.now(UTC)
        return UserRecord(
            id=snapshot.id,
            username=data.get('username', snapshot.id),
            password_hash=data.get('passwordHash', ''),
            is_admin=bool(data.get('isAdmin', False)),
            created_at=_ensure_datetime(created_at),
        )

    def create_generation(
        self,
        *,
        user_id: str,
        username: str,
        truth: str,
        excuse: str,
        style: AlibiStyle,
        detected_language: str,
        category: ExcuseCategory,
    ) -> GenerationRecord:
        reference = self._generations.document()
        created_at = datetime.now(UTC)
        reference.set(
            {
                'userId': user_id,
                'username': username,
                'truth': truth,
                'excuse': excuse,
                'style': style.value,
                'language': detected_language,
                'category': category.value,
                'publishedToWall': False,
                'createdAt': created_at,
            },
        )
        return GenerationRecord(
            id=reference.id,
            user_id=user_id,
            username=username,
            truth=truth,
            excuse=excuse,
            style=style,
            detected_language=detected_language,
            category=category,
            published_to_wall=False,
            created_at=created_at,
        )

    def get_generation(self, generation_id: str) -> GenerationRecord | None:
        snapshot = self._generations.document(generation_id).get()
        if not snapshot.exists:
            return None
        return _generation_from_snapshot(snapshot.id, snapshot.to_dict() or {})

    def mark_generation_published(self, generation_id: str) -> GenerationRecord | None:
        reference = self._generations.document(generation_id)
        snapshot = reference.get()
        if not snapshot.exists:
            return None
        reference.update({'publishedToWall': True})
        data = snapshot.to_dict() or {}
        data['publishedToWall'] = True
        return _generation_from_snapshot(snapshot.id, data)

    def create_wall_post_from_generation(
        self,
        generation: GenerationRecord,
    ) -> WallPostRecord:
        reference = self._wall_posts.document()
        created_at = datetime.now(UTC)
        reference.set(
            {
                'username': generation.username,
                'truth': generation.truth,
                'excuse': generation.excuse,
                'style': generation.style.value,
                'language': generation.detected_language,
                'category': generation.category.value,
                'generationId': generation.id,
                'reactions': {emoji: 0 for emoji in SUPPORTED_REACTIONS},
                'lolCount': 0,
                'createdAt': created_at,
            },
        )
        return WallPostRecord(
            id=reference.id,
            username=generation.username,
            truth=generation.truth,
            excuse=generation.excuse,
            style=generation.style,
            detected_language=generation.detected_language,
            category=generation.category,
            generation_id=generation.id,
            reactions={emoji: 0 for emoji in SUPPORTED_REACTIONS},
            created_at=created_at,
        )

    def list_history_for_user(self, user_id: str) -> list[GenerationRecord]:
        snapshots = self._generations.where('userId', '==', user_id).stream()
        records = [
            _generation_from_snapshot(snapshot.id, snapshot.to_dict() or {})
            for snapshot in snapshots
        ]
        return sorted(records, key=lambda record: record.created_at, reverse=True)

    def list_wall_posts(self, *, category: ExcuseCategory | None = None) -> list[WallPostRecord]:
        snapshots = self._wall_posts.stream()
        records = [
            _wall_post_from_snapshot(snapshot.id, snapshot.to_dict() or {})
            for snapshot in snapshots
        ]
        if category is not None:
            records = [record for record in records if record.category == category]
        return sorted(records, key=lambda record: record.created_at, reverse=True)

    def list_leaderboard(self, *, days: int | None = None) -> list[WallPostRecord]:
        records = self.list_wall_posts()
        if days is not None:
            cutoff = datetime.now(UTC) - timedelta(days=days)
            records = [record for record in records if record.created_at >= cutoff]
        return sorted(
            records,
            key=lambda record: (record.total_reactions, record.created_at),
            reverse=True,
        )

    def increment_wall_reaction(
        self,
        post_id: str,
        emoji: str,
    ) -> WallPostRecord | None:
        if emoji not in SUPPORTED_REACTIONS:
            raise RepositoryError('Unsupported reaction.')
        reference = self._wall_posts.document(post_id)
        snapshot = reference.get()
        if not snapshot.exists:
            return None
        reference.update({f'reactions.{emoji}': firestore.Increment(1)})
        data = snapshot.to_dict() or {}
        raw_reactions = data.get('reactions')
        if isinstance(raw_reactions, dict):
            updated_reactions = dict(raw_reactions)
        else:
            updated_reactions = {reaction: 0 for reaction in SUPPORTED_REACTIONS}
            updated_reactions['😂'] = int(data.get('lolCount', 0))
        updated_reactions[emoji] = int(updated_reactions.get(emoji, 0)) + 1
        data['reactions'] = updated_reactions
        return _wall_post_from_snapshot(snapshot.id, data)

    def delete_wall_post(self, post_id: str) -> WallPostRecord | None:
        reference = self._wall_posts.document(post_id)
        snapshot = reference.get()
        if not snapshot.exists:
            return None
        record = _wall_post_from_snapshot(snapshot.id, snapshot.to_dict() or {})
        reference.delete()
        if record.generation_id:
            generation_reference = self._generations.document(record.generation_id)
            generation_snapshot = generation_reference.get()
            if generation_snapshot.exists:
                generation_reference.update({'publishedToWall': False})
        return record

    def backfill_missing_categories(self) -> dict[str, int]:
        updated_generations = 0
        updated_wall_posts = 0

        for snapshot in self._generations.stream():
            data = snapshot.to_dict() or {}
            inferred = infer_category(
                truth=str(data.get('truth', '')),
                excuse=str(data.get('excuse', '')),
            )
            try:
                current = ExcuseCategory(str(data.get('category')))
            except ValueError:
                current = None
            if current == inferred:
                continue
            snapshot.reference.update({'category': inferred.value})
            updated_generations += 1

        for snapshot in self._wall_posts.stream():
            data = snapshot.to_dict() or {}
            inferred = infer_category(
                truth=str(data.get('truth', '')),
                excuse=str(data.get('excuse', '')),
            )
            try:
                current = ExcuseCategory(str(data.get('category')))
            except ValueError:
                current = None
            if current == inferred:
                continue
            snapshot.reference.update({'category': inferred.value})
            updated_wall_posts += 1

        return {
            'generations': updated_generations,
            'wall_posts': updated_wall_posts,
        }


def _ensure_datetime(value: object) -> datetime:
    if isinstance(value, datetime):
        return value if value.tzinfo else value.replace(tzinfo=UTC)
    return datetime.now(UTC)


def _generation_from_snapshot(snapshot_id: str, data: dict[str, object]) -> GenerationRecord:
    truth = str(data.get('truth', ''))
    excuse = str(data.get('excuse', ''))
    return GenerationRecord(
        id=snapshot_id,
        user_id=str(data.get('userId', '')),
        username=str(data.get('username', 'anonymous')),
        truth=truth,
        excuse=excuse,
        style=AlibiStyle(str(data.get('style', AlibiStyle.goofy.value))),
        detected_language=str(data.get('language', 'unknown')),
        category=parse_or_infer_category(
            data.get('category'),
            truth=truth,
            excuse=excuse,
        ),
        published_to_wall=bool(data.get('publishedToWall', False)),
        created_at=_ensure_datetime(data.get('createdAt')),
    )


def _wall_post_from_snapshot(snapshot_id: str, data: dict[str, object]) -> WallPostRecord:
    truth = str(data.get('truth', ''))
    excuse = str(data.get('excuse', ''))
    raw_reactions = data.get('reactions')
    reactions = {emoji: 0 for emoji in SUPPORTED_REACTIONS}
    if isinstance(raw_reactions, dict):
        for emoji in SUPPORTED_REACTIONS:
            reactions[emoji] = int(raw_reactions.get(emoji, 0))
    else:
        reactions['😂'] = int(data.get('lolCount', 0))
    return WallPostRecord(
        id=snapshot_id,
        username=str(data.get('username', 'anonymous')),
        truth=truth,
        excuse=excuse,
        style=AlibiStyle(str(data.get('style', AlibiStyle.goofy.value))),
        detected_language=str(data.get('language', 'unknown')),
        category=parse_or_infer_category(
            data.get('category'),
            truth=truth,
            excuse=excuse,
        ),
        generation_id=str(data.get('generationId', '')),
        reactions=reactions,
        created_at=_ensure_datetime(data.get('createdAt')),
    )
