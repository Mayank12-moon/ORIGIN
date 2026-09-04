# Backend

```bash
cd backend
python -m venv .venv
# macOS/Linux: source .venv/bin/activate
# Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env
uvicorn app.main:app --reload
```

API: `http://127.0.0.1:8000`

The app auto-generates data if CSVs are missing. You can manually regenerate with `python mock_data/generate_data.py`.

Endpoints:
- `GET /health`
- `GET /transactions?date_from=&date_to=&status=&merchant_id=&page=&page_size=`
- `GET /trace/{transaction_id}`
- `POST /trace/query` with `{"transaction_id":"TXN100000"}` or `{"date":"2026-03-12"}`
- `GET /analytics/summary`

`LLM_PROVIDER=none` is the zero-key default. Optional `groq` and `gemini` modes use `LLM_API_KEY` and fall back to deterministic reasoning if the provider fails.
