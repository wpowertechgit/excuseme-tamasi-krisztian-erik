from __future__ import annotations

import re

from .models import ExcuseCategory


_CATEGORY_KEYWORDS: dict[ExcuseCategory, tuple[str, ...]] = {
    ExcuseCategory.work: (
        'work',
        'office',
        'meeting',
        'boss',
        'client',
        'deadline',
        'shift',
        'job',
        'coworker',
        'colleague',
        'email',
        'presentation',
        'commute',
    ),
    ExcuseCategory.personal: (
        'friend',
        'friends',
        'home',
        'house',
        'roommate',
        'neighbor',
        'errand',
        'laundry',
        'shopping',
        'appointment',
    ),
    ExcuseCategory.family: (
        'family',
        'mom',
        'mother',
        'dad',
        'father',
        'parent',
        'parents',
        'sister',
        'brother',
        'grandma',
        'grandpa',
        'child',
        'kid',
        'baby',
        'cousin',
    ),
    ExcuseCategory.romance: (
        'date',
        'girlfriend',
        'boyfriend',
        'wife',
        'husband',
        'partner',
        'romantic',
        'crush',
        'kiss',
        'anniversary',
        'valentine',
    ),
    ExcuseCategory.health: (
        'doctor',
        'dentist',
        'sick',
        'ill',
        'hospital',
        'clinic',
        'migraine',
        'headache',
        'fever',
        'medicine',
        'toilet',
        'bathroom',
        'stomach',
        'food poisoning',
        'injury',
    ),
    ExcuseCategory.sports: (
        'sport',
        'sports',
        'gym',
        'training',
        'practice',
        'match',
        'game',
        'stadium',
        'football',
        'soccer',
        'basketball',
        'tennis',
        'race',
        'workout',
    ),
    ExcuseCategory.travel: (
        'bus',
        'tram',
        'train',
        'flight',
        'airport',
        'traffic',
        'subway',
        'taxi',
        'uber',
        'car',
        'road',
        'elevator',
        'border',
        'travel',
        'commuting',
    ),
}


def infer_category(*, truth: str, excuse: str) -> ExcuseCategory:
    haystack = _normalize_for_matching(f'{truth} {excuse}')
    scores = {category: 0 for category in ExcuseCategory}

    for category, keywords in _CATEGORY_KEYWORDS.items():
        for keyword in keywords:
            pattern = rf'(^|\s){re.escape(keyword)}($|\s)'
            if re.search(pattern, haystack):
                scores[category] += 1

    best_category = max(scores, key=scores.get)
    if scores[best_category] > 0:
        return best_category
    return ExcuseCategory.personal if truth.strip() or excuse.strip() else ExcuseCategory.other


def parse_or_infer_category(
    raw_category: object,
    *,
    truth: str,
    excuse: str,
) -> ExcuseCategory:
    try:
        return ExcuseCategory(str(raw_category))
    except ValueError:
        return infer_category(truth=truth, excuse=excuse)


def _normalize_for_matching(text: str) -> str:
    lowered = text.lower()
    cleaned = re.sub(r'[^a-z0-9\s]+', ' ', lowered)
    return re.sub(r'\s+', ' ', cleaned).strip()

