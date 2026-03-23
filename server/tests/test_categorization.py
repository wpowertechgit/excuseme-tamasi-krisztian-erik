from datetime import UTC, datetime

from app.categorization import infer_category, parse_or_infer_category
from app.models import AlibiStyle, ExcuseCategory
from app.repository import InMemoryRepository, _generation_from_snapshot, _wall_post_from_snapshot


def test_infer_category_from_keywords():
    assert (
        infer_category(
            truth='I missed the office meeting and my boss was furious.',
            excuse='A client presentation swallowed my whole morning.',
        )
        == ExcuseCategory.work
    )
    assert (
        infer_category(
            truth='I skipped football practice.',
            excuse='The stadium lights died before kickoff.',
        )
        == ExcuseCategory.sports
    )


def test_snapshot_parsers_infer_missing_category():
    generation = _generation_from_snapshot(
        'gen-1',
        {
            'truth': 'I was late because I was on the toilet.',
            'excuse': 'A bathroom emergency delayed me.',
            'style': 'serious',
            'language': 'en',
            'createdAt': datetime.now(UTC),
        },
    )
    wall_post = _wall_post_from_snapshot(
        'wall-1',
        {
            'truth': 'I missed practice.',
            'excuse': 'The gym flooded before training.',
            'style': 'goofy',
            'language': 'en',
            'createdAt': datetime.now(UTC),
        },
    )

    assert generation.category == ExcuseCategory.health
    assert wall_post.category == ExcuseCategory.sports


def test_parse_or_infer_preserves_valid_category():
    category = parse_or_infer_category(
        'romance',
        truth='I missed our date.',
        excuse='Cupid sabotaged the evening.',
    )

    assert category == ExcuseCategory.romance


def test_in_memory_backfill_updates_existing_records():
    repository = InMemoryRepository()
    user = repository.create_user(username='Karol', password_hash='hash')
    generation = repository.create_generation(
        user_id=user.id,
        username=user.username,
        truth='I missed practice.',
        excuse='The stadium gates jammed.',
        style=AlibiStyle.goofy,
        detected_language='en',
        category=ExcuseCategory.other,
    )
    repository.create_wall_post_from_generation(generation)

    result = repository.backfill_missing_categories()
    history = repository.list_history_for_user(user.id)
    wall_posts = repository.list_wall_posts()

    assert result == {'generations': 1, 'wall_posts': 1}
    assert history[0].category == ExcuseCategory.sports
    assert wall_posts[0].category == ExcuseCategory.sports
