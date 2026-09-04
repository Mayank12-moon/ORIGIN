from datetime import datetime, date
from .data_loader import load_all, index_by_transaction
from .models import TraceResult, TimelineStage, ExceptionItem

def _dt(v):
    if not v: return None
    try: return datetime.fromisoformat(v.replace("Z","+00:00"))
    except ValueError:
        try: return datetime.fromisoformat(v[:10])
        except ValueError: return None

def _num(v):
    try: return float(v) if v not in (None,"") else None
    except (ValueError, TypeError): return None

def trace_transaction(transaction_id):
    src = load_all()
    idx = {k:index_by_transaction(v) for k,v in src.items()}
    g,b,l = idx["gateway"].get(transaction_id), idx["bank"].get(transaction_id), idx["ledger"].get(transaction_id)
    exc, timeline = [], []

    if not g: exc.append(ExceptionItem(field="gateway_logs", severity="critical", message="No gateway row exists for this transaction."))
    if not b: exc.append(ExceptionItem(field="bank_settlements", severity="warning", message="No bank settlement row exists; the bank outcome cannot be confirmed."))
    if not l: exc.append(ExceptionItem(field="ledger_entries", severity="warning", message="No ledger row exists; reconciliation cannot be fully confirmed."))

    if g: timeline.append(TimelineStage(stage="Gateway", status=g.get("gateway_status","unknown"), timestamp=g.get("gateway_timestamp"), source="gateway_logs.csv", raw_fields=g))
    if b: timeline.append(TimelineStage(stage="Bank", status=b.get("bank_status","unknown"), timestamp=b.get("settlement_date"), source="bank_settlements.csv", raw_fields=b))
    if l: timeline.append(TimelineStage(stage="Ledger", status=l.get("ledger_status","unknown"), timestamp=l.get("posted_date"), source="ledger_entries.csv", raw_fields=l))

    ga, ba, la = _num(g.get("amount")) if g else None, _num(b.get("settled_amount")) if b else None, _num(l.get("reconciled_amount")) if l else None
    if ga is not None and la is not None and abs(ga-la) > .01:
        exc.append(ExceptionItem(field="amount", severity="critical", message=f"Gateway amount {ga:.2f} conflicts with ledger reconciled amount {la:.2f}."))
    if ga is not None and ba is not None and abs(ga-ba) > .01:
        exc.append(ExceptionItem(field="settled_amount", severity="critical", message=f"Bank settled amount {ba:.2f} differs from gateway amount {ga:.2f}."))
    if l and l.get("reconciliation_flag") == "mismatch":
        exc.append(ExceptionItem(field="reconciliation_flag", severity="critical", message="The ledger explicitly marks this transaction as a reconciliation mismatch."))
    if g and g.get("gateway_status") == "failed" and (b or l):
        exc.append(ExceptionItem(field="cross_source_status", severity="warning", message="Gateway says failed, but a downstream row exists; investigate the downstream record."))

    times = [x for x in [_dt(g.get("gateway_timestamp")) if g else None, _dt(b.get("settlement_date")) if b else None, _dt(l.get("posted_date")) if l else None] if x]
    if len(times) >= 2:
        span = (max(times)-min(times)).total_seconds()/3600
        if span > 72:
            exc.append(ExceptionItem(field="timestamps", severity="warning", message=f"Source timestamps span {span:.1f} hours; this is outside the normal mock settlement window."))

    gs, bs, ls = g.get("gateway_status") if g else None, b.get("bank_status") if b else None, l.get("ledger_status") if l else None
    if not g or (not b and not l):
        overall = "unknown"
    elif gs == "failed":
        overall = "failed"
    elif any(e.severity=="critical" and e.field in {"amount","settled_amount","reconciliation_flag"} for e in exc):
        overall = "mismatched"
    elif bs == "rejected":
        overall = "failed"
    elif gs == "captured" and bs == "settled" and ls == "posted":
        overall = "settled"
    elif gs in {"captured","authorized","refunded"} and (bs in {"pending","on_hold"} or ls in {"pending","mismatched"} or not b or not l):
        overall = "delayed" if (b or l) else "unknown"
    elif gs == "refunded" and bs == "settled":
        overall = "settled"
    else:
        overall = "unknown"

    confidence = 1.0 - min(.30, .15*sum(x is None for x in (g,b,l))) - min(.25, .10*len(exc))
    if overall == "unknown": confidence = min(confidence, .45)
    if overall == "mismatched": confidence = min(confidence, .75)
    confidence = max(.05, round(confidence,2))
    return TraceResult(
        transaction_id=transaction_id, overall_status=overall, confidence=confidence,
        timeline=timeline, explanation="", exceptions=exc,
        generated_at=datetime.utcnow().isoformat(timespec="seconds")+"Z"
    )

def transaction_ids_for_date(target_date):
    date.fromisoformat(target_date)
    ids=set()
    for rows in load_all().values():
        for r in rows:
            for f in ("gateway_timestamp","settlement_date","posted_date"):
                if r.get(f) and r[f][:10] == target_date:
                    ids.add(r["transaction_id"]); break
    return sorted(ids)

def transaction_ids_for_date_range(date_from=None, date_to=None):
    start = date.fromisoformat(date_from) if date_from else None
    end = date.fromisoformat(date_to) if date_to else None
    ids=set()
    for rows in load_all().values():
        for r in rows:
            for f in ("gateway_timestamp","settlement_date","posted_date"):
                if not r.get(f): continue
                try: d=date.fromisoformat(r[f][:10])
                except ValueError: continue
                if (start is None or d>=start) and (end is None or d<=end):
                    ids.add(r["transaction_id"]); break
    return sorted(ids)
