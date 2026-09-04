import json
import logging
import httpx
from .config import settings
from .models import TraceResult

logger=logging.getLogger(__name__)

def deterministic(trace: TraceResult):
    t={x.stage.lower():x for x in trace.timeline}
    g,b,l=t.get("gateway"),t.get("bank"),t.get("ledger")
    p=[]
    if not g: p.append("The gateway record is missing, so the transaction origin cannot be verified.")
    elif g.status=="captured": p.append("The gateway captured the payment successfully.")
    elif g.status=="failed": p.append("The gateway reports a failed payment.")
    elif g.status=="authorized": p.append("The gateway authorized the payment, but authorization alone does not prove settlement.")
    elif g.status=="refunded": p.append("The gateway reports a refund flow; downstream reversal records must be considered.")
    else: p.append(f"The gateway status is {g.status}.")
    if b:
        p.append({"settled":"The bank shows the transaction as settled.","pending":"The bank has not completed settlement yet; this is consistent with a delay.","on_hold":"The bank has placed the settlement on hold.","rejected":f"The bank rejected the settlement ({b.raw_fields.get('bank_remarks') or 'no reason supplied'})."} .get(b.status, f"The bank status is {b.status}."))
    else: p.append("There is no bank settlement row, so a bank outcome cannot be confirmed.")
    if l:
        p.append({"posted":"The internal ledger entry is posted.","pending":"The internal ledger entry is still pending.","mismatched":"The internal ledger marks the entry as mismatched."}.get(l.status, f"The ledger status is {l.status}."))
    else: p.append("There is no ledger row, so reconciliation cannot be fully confirmed.")
    p.append({
        "settled":"Overall, the evidence supports a completed settlement.",
        "delayed":"Overall, the evidence points to a delay rather than completed end-to-end settlement.",
        "failed":"Overall, the transaction should be treated as failed downstream.",
        "mismatched":"Overall, the sources disagree, so reconciliation is required.",
        "unknown":"Overall, the evidence is incomplete, so a definitive conclusion would be unsafe.",
    }[trace.overall_status])
    p.append(f"Confidence is {trace.confidence:.0%}; {len(trace.exceptions)} exception(s) are listed separately.")
    return " ".join(p)

async def llm(trace):
    s=settings()
    if s["llm_provider"] not in {"groq","gemini"} or not s["llm_api_key"]: return None
    prompt=("Explain this settlement trace for a support agent. Use only supplied evidence; never invent facts. "
            "Explicitly state uncertainty. Keep the answer concise.\n\n"+json.dumps(trace.model_dump(), indent=2))
    try:
        async with httpx.AsyncClient(timeout=20) as c:
            if s["llm_provider"]=="groq":
                model=s["llm_model"] or "llama-3.3-70b-versatile"
                r=await c.post("https://api.groq.com/openai/v1/chat/completions",
                    headers={"Authorization":f"Bearer {s['llm_api_key']}"},
                    json={"model":model,"messages":[{"role":"system","content":"Be evidence-bound."},{"role":"user","content":prompt}],"temperature":.1})
                r.raise_for_status(); return r.json()["choices"][0]["message"]["content"].strip()
            model=s["llm_model"] or "gemini-2.0-flash"
            r=await c.post(f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={s['llm_api_key']}",
                           json={"contents":[{"parts":[{"text":prompt}]}]})
            r.raise_for_status(); return r.json()["candidates"][0]["content"]["parts"][0]["text"].strip()
    except Exception as e:
        logger.warning("LLM failed; using deterministic reasoner: %s", e)
        return None

async def explain(trace):
    return await llm(trace) or deterministic(trace)
