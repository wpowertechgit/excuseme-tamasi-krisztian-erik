from app.openrouter import _detect_language


def test_detect_language_defaults_obvious_english_to_en():
    assert _detect_language('Excuse me, I was late because the train stopped.') == 'en'


def test_detect_language_keeps_spanish_when_signal_is_clear():
    assert _detect_language('Llegue tarde porque una cabra secuestro el ascensor.') == 'es'
