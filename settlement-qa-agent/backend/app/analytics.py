from collections import Counter, defaultdict
from datetime import datetime
from statistics import mean
from .data_loader import load_all
from .trace_engine import trace_transaction

def summary():
    sources=load_all()
    ids=sorted({r["transaction_id"] for rows in sources.values() for r in rows})
    statuses=Counter(); fields=Counter(); delays=[]; daily=defaultdict(list)
    for tx in ids:
        tr=trace_transaction(tx); statuses[tr.overall_status]+=1
        for e in tr.exceptions: fields[e.field]+=1
        times=[]
        for s in tr.timeline:
            if s.timestamp:
                try: times.append(datetime.fromisoformat(s.timestamp.replace("Z","+00:00")))
                except ValueError: pass
        if len(times)>=2:
            d=(max(times)-min(times)).total_seconds()/3600
            delays.append(d); daily[min(times).date().isoformat()].append(d)
    return {
        "status_counts":dict(statuses),
        "average_settlement_delay_hours":round(mean(delays),2) if delays else 0,
        "exception_frequency":dict(fields),
        "delay_trend":[{"date":d,"average_delay_hours":round(mean(v),2)} for d,v in sorted(daily.items())],
    }
