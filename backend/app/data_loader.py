import csv
import logging
from pathlib import Path
from .config import settings

logger = logging.getLogger(__name__)

FILES = {
    "gateway": "gateway_logs.csv",
    "bank": "bank_settlements.csv",
    "ledger": "ledger_entries.csv",
}

def ensure_data():
    data_dir = settings()["data_dir"]
    data_dir.mkdir(parents=True, exist_ok=True)
    if any(not (data_dir/name).exists() for name in FILES.values()):
        from mock_data.generate_data import generate
        logger.info("Generating mock settlement data")
        generate(data_dir, 500)

def load_source(source):
    ensure_data()
    with (settings()["data_dir"]/FILES[source]).open(encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))

def load_all():
    return {k: load_source(k) for k in FILES}

def index_by_transaction(rows):
    return {r["transaction_id"]: r for r in rows if r.get("transaction_id")}
