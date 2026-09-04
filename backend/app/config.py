from functools import lru_cache
from pathlib import Path
import os
from dotenv import load_dotenv

load_dotenv()

@lru_cache
def settings():
    backend_dir = Path(__file__).resolve().parents[1]
    data_dir = Path(os.getenv("DATA_DIR", "mock_data/data"))
    if not data_dir.is_absolute():
        data_dir = backend_dir / data_dir
    return {
        "data_dir": data_dir,
        "llm_provider": os.getenv("LLM_PROVIDER", "none").lower(),
        "llm_api_key": os.getenv("LLM_API_KEY", ""),
        "llm_model": os.getenv("LLM_MODEL", ""),
        "stale_threshold_days": int(os.getenv("STALE_THRESHOLD_DAYS", "2")),
        "cache_ttl_seconds": int(os.getenv("CACHE_TTL_SECONDS", "120")),
    }
