from __future__ import annotations

import json
from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from app.config import get_settings  # noqa: E402
from app.repository import FirestoreRepository  # noqa: E402


def main() -> None:
    repository = FirestoreRepository(get_settings())
    result = repository.backfill_missing_categories()
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()

