import logging
from datetime import datetime
from typing import Any
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from .analytics import summary
from .cache import trace_cache
from .data_loader import load_all, index_by_transaction, ensure_data
from .models import TraceQuery, TraceResult
from .reasoner import explain
from .trace_engine import trace_transaction, transaction_ids_for_date, transaction_ids_for_date_range

logging.basicConfig(level=logging.INFO, format="%(asctime)s | %(levelname)s | %(name)s | %(message)s")
logger=logging.getLogger("settlement-qa")
app=FastAPI(title="Settlement Q&A Agent", version="1.0.0")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"])

@app.on_event("startup")
def startup():
    ensure_data()

async def get_trace(tx):
    cached=trace_cache.get(tx)
    if cached: return cached
    tr=trace_transaction(tx)
    if not tr.timeline: raise HTTPException(404, f"Transaction {tx} was not found.")
    tr.explanation=await explain(tr)
    trace_cache.set(tx,tr)
    return tr

@app.get("/health")
def health():
    ensure_data()
    return {"status":"ok","service":"settlement-qa-agent","timestamp":datetime.utcnow().isoformat()+"Z"}

@app.get("/transactions")
def transactions(date_from:str|None=None,date_to:str|None=None,status:str|None=None,merchant_id:str|None=None,
                 page:int=Query(1,ge=1),page_size:int=Query(25,ge=1,le=100)):
    src=load_all(); idx={k:index_by_transaction(v) for k,v in src.items()}
    ids=transaction_ids_for_date_range(date_from,date_to) if (date_from or date_to) else sorted(set().union(*[set(x) for x in [idx[k] for k in idx]]))
    items=[]
    for tx in ids:
        g,b,l=idx["gateway"].get(tx),idx["bank"].get(tx),idx["ledger"].get(tx)
        tr=trace_transaction(tx)
        if merchant_id and (not g or g.get("merchant_id")!=merchant_id): continue
        if status and tr.overall_status!=status: continue
        items.append({"transaction_id":tx,"merchant_id":g.get("merchant_id") if g else None,
                      "amount":float(g["amount"]) if g and g.get("amount") else None,"currency":g.get("currency") if g else None,
                      "gateway_status":g.get("gateway_status") if g else None,"bank_status":b.get("bank_status") if b else None,
                      "ledger_status":l.get("ledger_status") if l else None,"overall_status":tr.overall_status,
                      "gateway_timestamp":g.get("gateway_timestamp") if g else None,"settlement_date":b.get("settlement_date") if b else None})
    total=len(items); start=(page-1)*page_size
    return {"items":items[start:start+page_size],"page":page,"page_size":page_size,"total":total,"pages":(total+page_size-1)//page_size}

@app.get("/trace/{transaction_id}",response_model=TraceResult)
async def trace(transaction_id:str):
    return await get_trace(transaction_id)

@app.post("/trace/query")
async def trace_query(q:TraceQuery):
    if q.transaction_id: return (await get_trace(q.transaction_id)).model_dump()
    if q.date:
        ids=transaction_ids_for_date(q.date)
        return {"date":q.date,"count":len(ids),"results":[(await get_trace(x)).model_dump() for x in ids]}
    raise HTTPException(400,"Provide transaction_id or date.")

@app.get("/analytics/summary")
def analytics_summary(): return summary()
