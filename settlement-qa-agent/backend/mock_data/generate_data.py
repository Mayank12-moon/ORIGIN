import csv, random
from datetime import datetime, timedelta
from pathlib import Path

GATEWAY_FIELDS=["transaction_id","merchant_id","order_id","amount","currency","payment_method","gateway_status","gateway_timestamp","error_code","error_description"]
BANK_FIELDS=["transaction_id","utr_number","settlement_batch_id","bank_status","settlement_date","settled_amount","bank_remarks"]
LEDGER_FIELDS=["transaction_id","ledger_entry_id","entry_type","ledger_status","posted_date","reconciled_amount","reconciliation_flag"]

def generate(output_dir=None,count=500,seed=8):
    out=Path(output_dir or Path(__file__).parent/"data"); out.mkdir(parents=True,exist_ok=True)
    rng=random.Random(seed); base=datetime(2026,1,1,9)
    scenarios=["settled"]*240+["pending"]*70+["ledger_late"]*45+["amount_mismatch"]*40+["gateway_failed"]*35+["bank_rejected"]*25+["refund"]*25+["ambiguous"]*20
    rng.shuffle(scenarios)
    gs=[]; bs=[]; ls=[]
    for i in range(count):
        tx=f"TXN{100000+i:06d}"; merchant=f"MERCH{rng.randint(1001,1030)}"
        amount=round(rng.choice([149,299,499,799,999,1499,2499,4999,7999])+rng.random(),2)
        ts=base+timedelta(hours=rng.randint(0,24*180),minutes=rng.randint(0,59)); sc=scenarios[i]
        status={"settled":"captured","pending":"captured","ledger_late":"captured","amount_mismatch":"captured","gateway_failed":"failed","bank_rejected":"captured","refund":"refunded","ambiguous":"captured"}[sc]
        gs.append({"transaction_id":tx,"merchant_id":merchant,"order_id":f"order_{i+1:06d}","amount":f"{amount:.2f}","currency":"INR",
                   "payment_method":rng.choice(["card","upi","netbanking","wallet"]),"gateway_status":status,
                   "gateway_timestamp":ts.isoformat(timespec="seconds"),
                   "error_code":"" if status!="failed" else rng.choice(["GATEWAY_TIMEOUT","CARD_DECLINED","PG_502"]),
                   "error_description":"" if status!="failed" else "Issuer declined the payment"})
        if sc=="gateway_failed": continue
        if sc=="pending": bs_status="pending"; bdate=ts+timedelta(days=2,hours=rng.randint(1,8)); remark="Normal T+2 settlement window"
        elif sc=="bank_rejected": bs_status="rejected"; bdate=ts+timedelta(days=1); remark="Invalid beneficiary account"
        elif sc=="refund": bs_status="settled"; bdate=ts+timedelta(hours=rng.randint(18,36)); remark="Original settlement completed; refund initiated"
        else: bs_status="settled"; bdate=ts+timedelta(hours=rng.randint(6,30)); remark="Settlement completed"
        bs.append({"transaction_id":tx,"utr_number":f"UTR{rng.randint(10**11,10**12-1)}","settlement_batch_id":f"BATCH{rng.randint(10000,99999)}",
                   "bank_status":bs_status,"settlement_date":bdate.isoformat(timespec="seconds"),"settled_amount":f"{amount:.2f}","bank_remarks":remark})
        if sc=="ledger_late": lstatus="pending"; ldate=bdate+timedelta(hours=20); entry="credit"; recon=amount; flag="pending"
        elif sc=="amount_mismatch": lstatus="mismatched"; ldate=bdate+timedelta(hours=3); entry="credit"; recon=amount-rng.choice([10,25,50]); flag="mismatch"
        elif sc=="refund": lstatus="posted"; ldate=bdate+timedelta(hours=5); entry="reversal"; recon=-amount; flag="matched"
        elif sc=="bank_rejected": lstatus="pending"; ldate=bdate+timedelta(hours=8); entry="credit"; recon=amount; flag="pending"
        elif sc=="pending": lstatus="pending"; ldate=bdate+timedelta(hours=4); entry="credit"; recon=amount; flag="pending"
        else: lstatus="posted"; ldate=bdate+timedelta(hours=rng.randint(1,8)); entry="credit"; recon=amount; flag="matched"
        if sc=="ambiguous":
            missing=rng.choice(["gateway","bank","ledger"])
            if missing in {"gateway","bank","ledger"}: 
                if missing!="ledger": 
                    # ledger is still generated below unless it is the selected missing source
                    pass
                else:
                    continue
                # remove source row by skipping the appropriate append
        ls.append({"transaction_id":tx,"ledger_entry_id":f"LEDGER{rng.randint(100000,999999)}","entry_type":entry,"ledger_status":lstatus,
                   "posted_date":ldate.isoformat(timespec="seconds"),"reconciled_amount":f"{recon:.2f}","reconciliation_flag":flag})
        if sc=="ambiguous":
            missing=rng.choice(["gateway","bank"])
            if missing=="gateway": gs.pop()
            else: bs.pop()
    for rows,fields,name in [(gs,GATEWAY_FIELDS,"gateway_logs.csv"),(bs,BANK_FIELDS,"bank_settlements.csv"),(ls,LEDGER_FIELDS,"ledger_entries.csv")]:
        with (out/name).open("w",encoding="utf-8",newline="") as f:
            w=csv.DictWriter(f,fieldnames=fields); w.writeheader(); w.writerows(rows)
    return out

if __name__=="__main__": print(generate())
