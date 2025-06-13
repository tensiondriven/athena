if [ -f .env ]; then
    uv run --env-file .env pytest tests
else
    uv run pytest tests/test_aura_manager.py
fi
