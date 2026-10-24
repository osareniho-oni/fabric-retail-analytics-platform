"""Offline fictional examples; not execution of the exported Spark, T-SQL, or DAX.
Run from any directory with Python 3.9+: python documentation/validation/run_examples.py
No network access or output files. All database work is in-memory SQLite.
"""
from pathlib import Path
from decimal import Decimal
from datetime import date
import csv
import json
import random
import sqlite3

DATA = Path(__file__).resolve().parents[2] / "data/sample-data"
FIXTURE = json.loads((DATA / "fixtures.json").read_text())


def sales_metrics():
    rows = FIXTURE["sales"]
    gross = sum(Decimal(str(r["LineAmount"])) for r in rows)
    discount = sum(Decimal(str(r["LineDiscountAmount"])) for r in rows)
    orders = len({r["TransactionNO"] for r in rows})
    units = sum(Decimal(str(r["Quantity"])) for r in rows)
    result = (gross, discount, gross-discount, orders, units, (gross-discount)/orders, units/orders, Decimal(len(rows))/orders)
    assert result == (50,2,48,2,4,24,2,Decimal("1.5"))
    return "gross=50, discount=2, net=48, orders=2, units=4, value/order=24, units/order=2, lines/order=1.5"


def daily_hr_rules():
    for filename, day, last, value in [("absent_data.csv","absent_date",False,"absent_hour"),("misconduct_trans.csv","misconduct_date",True,"decision_id")]:
        with (DATA / filename).open(newline="",encoding="utf-8") as file:
            source = list(csv.DictReader(file))
        assert len({r["source_record_ordinal"] for r in source}) == len(source)
        for seed in range(20):
            rows = source[:]
            random.Random(seed).shuffle(rows)
            retained = {}
            for row in sorted(rows,key=lambda r:int(r["source_record_ordinal"]),reverse=last):
                retained.setdefault((row["emp_id"],row[day]),row)
            assert int(next(iter(retained.values()))[value]) == 2
    return "ordinal-first absence=2 hours; ordinal-last misconduct decision=2 across shuffled examples"


def reference_rerun_contract():
    # An independent insert-if-absent example, not the exported Warehouse procedure.
    records = [(r["TransactionID"],r["LineAmount"]) for r in FIXTURE["sales"]]
    with sqlite3.connect(":memory:") as db:
        db.execute("create table fact(id integer primary key, amount numeric)")
        def load(rows):
            if len({r[0] for r in rows}) != len(rows):
                raise ValueError("duplicate source transaction ID")
            db.executemany("insert into fact select ?,? where not exists(select 1 from fact where id=?)",[(i,v,i) for i,v in rows])
        load(records)
        load(records)
        assert db.execute("select count(*),sum(amount) from fact").fetchone() == (3,50)
        try:
            load(records+[records[0]])
        except ValueError:
            return "repeat insert keeps 3 rows/50 amount; duplicate source IDs rejected in reference contract"
        raise AssertionError("duplicate source accepted")


def late_delivery_grain():
    rows = FIXTURE["purchases"]
    late = [r for r in rows if (date.fromisoformat(r["DeliveryDate"][:10])-date.fromisoformat(r["OrderDate"][:10])).days > 14]
    orders = len({r["TransactionNO"] for r in rows})
    assert len(late)/orders == 1
    assert len({r["TransactionNO"] for r in late})/orders == .5
    return "existing line/order arithmetic=1; distinct-order expectation=0.5 (known grain mismatch)"


def history_and_late_arrivals():
    event = date(2025,1,15)
    completed = date(2025,1,31)
    assert not event > completed
    versions = [(11,date(2025,1,1),date(2025,2,1)),(12,date(2025,2,1),None)]
    historical = next(k for k,start,end in versions if start <= event and (end is None or event < end))
    current = versions[-1][0]
    assert (historical,current) == (11,12)
    return "old-dated event outside next window; historical key=11 versus current key=12 (limitations reproduced)"


if __name__ == "__main__":
    for check in [sales_metrics,daily_hr_rules,reference_rerun_contract,late_delivery_grain,history_and_late_arrivals]:
        print("PASS",check.__name__+":",check())
    print("No Fabric/Spark/T-SQL/DAX execution or end-to-end validation is implied.")
