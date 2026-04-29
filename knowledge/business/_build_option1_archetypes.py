"""Sub-Account Option 1 — destination-grain (archetype) classifier.

For each Synapse SP/View/Function in scope, parse the file, extract every
INSERT INTO <real-table> (<col_list>) SELECT ... block, and classify the
SP into one of six archetypes based on the destination column list, plus
detected validity-gate / population-filter / GROUP-BY signals.

Archetypes
----------
    A  Customer-keyed snapshot           one row per CID/GCID/AccountID per period;
                                         dominant flag/date columns; few money sums.
                                         Treatment: filter synthetics from population
                                         OR enrich destination with master_CID.

    B  Per-customer money aggregate      one row per CID per period; dominant money
                                         columns. Treatment: GROUP BY master_CID via
                                         JOIN Dim_MasterGCID.

    C  Dim-grain rollup with validity    no customer key in destination; sources
       gate (regulator-risk class)       filter on IsValidCustomer = 1 (or
                                         IsCreditReportValidCB = 1 / IsDepositor=1
                                         / VerificationLevelID / PlayerStatusID).
                                         Treatment: requires explicit
                                         IsValidCustomer-for-synthetics policy
                                         decision per SP — REGULATOR RISK.

    D  Money-flow at transaction grain   destination has CID + transaction-id col
                                         (TransactionID/PositionID/etc) + money cols.
                                         Treatment: enrich destination with
                                         master_CID column for downstream rollup.

    E  Population headcount              destination has count/users/wallets columns
                                         (no money cols dominant). Treatment:
                                         COUNT(DISTINCT master_GCID) instead of
                                         COUNT(DISTINCT GCID).

    F  Non-customer dim grain            no customer key + no validity gate; pure
       (no validity gate)                instrument/LP/HedgeServer dimensions.
                                         Treatment: policy decision — sub-account
                                         positions show separately or roll to master.

    X  No destination INSERT detected    view/function/lookup/legacy. Manual review.

Severity ordering for picking the dominant archetype when an SP has multiple
destinations: C > A > B > D > E > F > X.
Outputs:
    knowledge/business/subaccount-option1-triage.csv
    knowledge/business/subaccount-option1-archetype-summary.json
"""
from __future__ import annotations

import csv
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path
from typing import NamedTuple

sys.stdout.reconfigure(line_buffering=True)

REPO_ROOT = Path(r"C:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we")
KNOWLEDGE = Path(__file__).parent
SNAPSHOT_CSV = KNOWLEDGE / "_objectsstatus_snapshot.csv"
OUT_TRIAGE = KNOWLEDGE / "subaccount-option1-triage.csv"
OUT_SUMMARY = KNOWLEDGE / "subaccount-option1-archetype-summary.json"

SYNAPSE_SCHEMAS = {
    "BI_DB_dbo", "BI_DB_staging",
    "DWH_dbo", "DWH_staging", "DWH_pagetracking", "DWH_watchlists",
    "Dealing_dbo", "Dealing_staging",
    "eMoney_dbo", "eMoney_Tribe",
    "EXW_dbo", "EXW_Wallet",
    "DE_dbo", "general", "dbo",
    "DWH_tracking", "DWH_Migration",
}

OBJECT_TYPES_SCAN = ("Stored Procedures", "Functions", "Views")

# ---------------------------------------------------------------------------
# Column-name heuristics
# ---------------------------------------------------------------------------

# Whole-name customer-identity columns (lowercase, no brackets)
CUSTOMER_KEY_NAMES = {
    "cid", "gcid", "realcid", "accountid", "customerid",
    "walletid", "holderid", "userid", "user_id",
    "brokercid", "brokerid_cid", "providercid", "extaccountid",
    "ledger_account_id",
}

# Money / sum substrings
MONEY_SUBSTRINGS = (
    "amount", "balance", "commission", "_fee", "fee_", "fee$",
    "pnl", "p_l", "_volume", "volume_",
    "rollover", "dividend", "interest", "_nop", "revenue", "shortfall",
    "equity", "margin", "spread", "loss", "profit", "cashout",
    "bankpayin", "bankpayout", "card_pos", "card_atm", "settlement",
    "loan", "refund", "stake", "deposit_", "_deposit",
    "withdraw_", "_withdraw", "ticketfee", "exchangefee", "atmfee",
    "fxfee", "rate", "_usd", "totalreceive", "totalsend",
    "openingbalance", "closingbalance", "computedamount",
    "providervalue", "wallettrackervalue", "balanceadjustment",
    "chargebackadjustment", "fxgap", "delta", "principal",
    "totalcommission", "fullcommission", "varcommission",
    "credit_amount", "debit_amount", "interest_amount",
    "newdeposits", "newwithdraws",
)

# Whole-name population-flag columns (lowercase exact match)
POPULATION_FLAG_NAMES = {
    "isregistered", "isfunded", "isvalidcustomer", "isactive",
    "isdepositor", "istestcustomer", "isfted", "isdepositorglobal",
    "isexistinguser", "istest", "isnewuser",
    "ftd_date", "ftd_dateid", "ftddate",
    "registration_date", "registrationdate", "registereddate",
    "funded_date", "funded_dateid", "fundeddate", "firstfundeddate",
    "firstfundeddateid", "firstdepositdate", "firstdepositdateid",
    "firsttimefunded", "firsttimedeposit", "firsttimedepositdate",
    "firstactiondate", "firstactiondateid", "firstactiontype",
    "firsttradedate", "firsttradedateid", "firsttradeaction",
    "lastlogindate", "lastlogindateid", "loggedin",
    "activetraded", "balanceonlyaccount", "accountactive",
    "playerstatusid", "playerstatus", "verificationlevelid",
    "verificationlevel", "kycstatus", "iskyc",
    "fmidate", "fmodate", "fmi_date", "fmo_date",
    "isdepositorglobal", "fundedaccount",
    "iskycprovided", "iskycapproved", "iscompliancereviewed",
    "regulationid", "regulation",
}

# Count / headcount substrings
COUNT_SUBSTRINGS = (
    "count_", "_count", "newuser", "newwallet", "headcount",
    "_users", "_wallets", "uniqueuser", "distinctuser",
    "totalusers", "totalcustomers", "totalclients",
    "activeuser", "activetraders", "fundedusers",
    "uniquetraders", "newcustomers",
)

# Non-customer dimensional substrings
DIM_SUBSTRINGS = (
    "region", "country", "instrumentid", "instrumenttype",
    "instrumentname", "regulation", "mifid", "hedgeserver",
    "crypto", "currencyiso", "currencyid", "symbol", "exchange",
    "labelid", "marketingregion", "tradingplatform", "broker_",
    "platformid", "playerlevelid", "_real", "iscfd", "iscopy",
    "isfuture", "issettled", "leverage", "issecondary", "isbuy",
    "trantype", "lp_", "liquidityaccount", "actiontypeid",
)

# Transaction-grain identifiers (when present with money → archetype D)
TXN_GRAIN_SUBSTRINGS = (
    "transactionid", "positionid", "eventid", "orderid", "chargeid",
    "depositwithdrawid", "providertransactionid", "txid",
    "executiontime", "occurred", "blockchaintxid",
    "withdrawalid", "depositid", "settlementid",
    "credittransactionid", "instrumenttradeid", "tradeid",
    "actionid", "customeractionid",
)

# First-event / panel substrings — columns matching these are population
# markers (1st action, FMI/FMO date, Last login, FTD, etc.), not money sums.
# Take precedence over MONEY classification when both match.
FIRST_EVENT_SUBSTRINGS = (
    "1st", "2nd", "3rd", "4th", "5th",
    "first", "last_", "lastlog",
    "fmi_", "fmo_", "fmi$", "fmo$",
    "ftd", "registration", "fundeddate",
)


# ---------------------------------------------------------------------------
# SQL-text regexes
# ---------------------------------------------------------------------------

VAL_FILTER_RX = re.compile(
    r"\b(?:IsValidCustomer|IsCreditReportValid(?:CB)?)\b\s*=\s*1",
    re.I,
)
POP_FILTER_RX = re.compile(
    r"\b(?:IsDepositor|IsFunded|IsRegistered|IsActive|IsTestCustomer|IsFTDed|FundedAccount)\b\s*[=<>!]+\s*[01]",
    re.I,
)
VERIFICATION_FILTER_RX = re.compile(
    r"\b(?:VerificationLevelID|PlayerStatusID)\b\s*(?:=|<>|!=|NOT\s+IN|IN)\b",
    re.I,
)
SNAPSHOT_JOIN_RX = re.compile(r"\bFact_SnapshotCustomer\b", re.I)
DIMCUST_JOIN_RX = re.compile(r"\bDim_Customer\b", re.I)

GROUP_BY_RX = re.compile(
    r"\bGROUP\s+BY\b\s+([^\n;]{1,400})",
    re.I,
)

# INSERT INTO <dest> [(<cols>)] (SELECT|EXEC|VALUES)
INSERT_RX = re.compile(
    r"\bINSERT\s+INTO\s+"
    r"(?P<dest>(?:\[?[A-Za-z_][A-Za-z0-9_]*\]?\.\s*)?\[?[A-Za-z_][A-Za-z0-9_#]*\]?(?:\s*\.\s*\[?[A-Za-z_][A-Za-z0-9_]*\]?)?)"
    r"\s*(?:WITH\s*\([^)]*\))?\s*"
    r"(?:\(\s*(?P<cols>[^()]*(?:\([^)]*\)[^()]*)*)\)\s*)?"
    r"(?P<tail>SELECT|EXEC|EXECUTE|VALUES|WITH)",
    re.I | re.S,
)


# ---------------------------------------------------------------------------
# Utilities
# ---------------------------------------------------------------------------

def strip_comments(text: str) -> str:
    """Replace SQL comments with spaces, preserving line numbers."""
    out = list(text)
    n = len(text)
    i = 0
    while i < n:
        if i + 1 < n and text[i] == "/" and text[i + 1] == "*":
            j = text.find("*/", i + 2)
            j = (j + 2) if j >= 0 else n
            for k in range(i, j):
                if out[k] != "\n":
                    out[k] = " "
            i = j
            continue
        if i + 1 < n and text[i] == "-" and text[i + 1] == "-":
            j = text.find("\n", i)
            j = j if j >= 0 else n
            for k in range(i, j):
                out[k] = " "
            i = j
            continue
        i += 1
    return "".join(out)


def parse_col_list(raw: str) -> list[str]:
    """Parse a parenthesized INSERT col list into normalized column names."""
    cols: list[str] = []
    depth = 0
    cur: list[str] = []
    for ch in raw:
        if ch == "(":
            depth += 1; cur.append(ch); continue
        if ch == ")":
            depth -= 1; cur.append(ch); continue
        if ch == "," and depth == 0:
            cols.append("".join(cur).strip())
            cur = []
            continue
        cur.append(ch)
    if cur:
        cols.append("".join(cur).strip())
    out: list[str] = []
    for c in cols:
        c = c.strip().rstrip(",")
        if not c:
            continue
        c = c.replace("[", "").replace("]", "")
        # Take the trailing identifier after dots / spaces
        parts = re.split(r"[\s\.]+", c)
        parts = [p for p in parts if p]
        if not parts:
            continue
        out.append(parts[-1].strip())
    return [c for c in out if c]


def normalize_col(col: str) -> str:
    return re.sub(r"[^a-z0-9_]", "", col.lower())


def col_classes(cols: list[str]) -> dict:
    """Bucket each destination column. Order of precedence: customer-key >
    pop-flag > txn > count > money > dim > other."""
    customer_keys: list[str] = []
    money_cols: list[str] = []
    count_cols: list[str] = []
    dim_cols: list[str] = []
    txn_cols: list[str] = []
    pop_flag_cols: list[str] = []
    other: list[str] = []
    for c in cols:
        cl = c.lower()
        clean = normalize_col(c)
        if clean in CUSTOMER_KEY_NAMES:
            customer_keys.append(c); continue
        if clean in POPULATION_FLAG_NAMES:
            pop_flag_cols.append(c); continue
        # First-event / panel patterns trump money — "1stActionAmount" is a
        # first-event marker, not a money aggregate.
        if any(s in cl for s in FIRST_EVENT_SUBSTRINGS):
            pop_flag_cols.append(c); continue
        if any(s in cl for s in TXN_GRAIN_SUBSTRINGS):
            txn_cols.append(c); continue
        if any(s in cl for s in COUNT_SUBSTRINGS):
            count_cols.append(c); continue
        if any(s in cl for s in MONEY_SUBSTRINGS):
            money_cols.append(c); continue
        if any(s in cl for s in DIM_SUBSTRINGS):
            dim_cols.append(c); continue
        other.append(c)
    return {
        "customer_keys": customer_keys,
        "money_cols": money_cols,
        "count_cols": count_cols,
        "dim_cols": dim_cols,
        "txn_cols": txn_cols,
        "pop_flag_cols": pop_flag_cols,
        "other": other,
    }


def detect_group_by_customer_key(text: str) -> tuple[bool, str]:
    """Return (has_group_by_cust_key, evidence_snippet).

    Walks all GROUP BY clauses; flags ones that group by a customer-identity
    column. Returns the first such evidence."""
    for m in GROUP_BY_RX.finditer(text):
        clause = m.group(1)
        clean_tokens = re.findall(r"[A-Za-z_][A-Za-z0-9_]*", clause)
        for tok in clean_tokens:
            if tok.lower() in CUSTOMER_KEY_NAMES:
                line_no = text.count("\n", 0, m.start()) + 1
                snippet = re.sub(r"\s+", " ", clause)[:160]
                return True, f"L{line_no}: GROUP BY {snippet}"
    return False, ""


def detect_validity_gate(text: str) -> tuple[bool, str, bool, str]:
    """Detect (has_val_filter, evidence, has_pop_filter, evidence)."""
    val_evidence = ""
    pop_evidence = ""

    def _snippet(m_obj) -> str:
        line_no = text.count("\n", 0, m_obj.start()) + 1
        s_start = max(text.rfind("\n", 0, m_obj.start()) + 1, m_obj.start() - 40)
        nl = text.find("\n", m_obj.end())
        s_end = min(nl if nl > 0 else len(text), m_obj.end() + 80)
        snip = re.sub(r"\s+", " ", text[s_start:s_end]).strip()[:160]
        return f"L{line_no}: {snip}"

    m = VAL_FILTER_RX.search(text)
    if m:
        val_evidence = _snippet(m)

    m2 = POP_FILTER_RX.search(text)
    if m2:
        pop_evidence = _snippet(m2)

    if not pop_evidence:
        m3 = VERIFICATION_FILTER_RX.search(text)
        if m3:
            pop_evidence = _snippet(m3)

    return bool(val_evidence), val_evidence, bool(pop_evidence), pop_evidence


# ---------------------------------------------------------------------------
# Destination & archetype detection
# ---------------------------------------------------------------------------

class Destination(NamedTuple):
    table: str
    cols: list[str]
    line_no: int
    archetype: str
    confidence: str
    why: str


def is_real_destination(table: str) -> bool:
    """Skip temp tables, table variables, tempdb refs."""
    t = table.replace("[", "").replace("]", "").strip()
    if not t:
        return False
    last = t.split(".")[-1].strip()
    if last.startswith("#") or last.startswith("@"):
        return False
    if t.lower().startswith("tempdb."):
        return False
    return True


def classify_destination(cols: list[str], full_text: str) -> tuple[str, str, str]:
    """Return (archetype, confidence, key_insight)."""
    cc = col_classes(cols)
    has_cust = bool(cc["customer_keys"])
    n_money = len(cc["money_cols"])
    n_count = len(cc["count_cols"])
    n_pop = len(cc["pop_flag_cols"])
    n_txn = len(cc["txn_cols"])
    n_dim = len(cc["dim_cols"])

    has_val_gate, _, has_pop_gate, _ = detect_validity_gate(full_text)
    has_gb_cust, _ = detect_group_by_customer_key(full_text)

    if not has_cust:
        # No customer key in destination
        if n_count > 0 and n_money == 0:
            return "E", "high", "headcount destination — no customer key, count columns present"
        if n_count > max(n_money, 1) and n_count >= 2:
            return "E", "medium", "looks like headcount (count cols dominate)"
        if has_val_gate or has_pop_gate:
            return "C", "high", "dim-grain rollup gated on IsValidCustomer/population — REGULATOR-RISK class"
        return "F", "high", "non-customer dim grain, no validity gate — policy decision"

    # has_cust — customer key in destination
    if n_txn > 0 and n_money > 0:
        return "D", "high", f"transaction-grain money flow per customer ({n_txn} txn-id cols, {n_money} money cols)"
    if n_count > n_money + n_pop and n_count >= 1:
        return "E", "medium", "customer-keyed but contains count columns"
    # A vs B: dominant money cols → B; dominant flags / few money → A
    if n_money >= 3 and n_money > n_pop:
        return "B", "high" if has_gb_cust else "medium", f"per-customer money aggregate ({n_money} money cols)"
    if n_pop >= 3 or (n_pop >= 1 and n_money <= 1):
        return "A", "high", f"customer-keyed snapshot/panel ({n_pop} flag/date cols)"
    if n_money >= 1:
        return "B", "medium", f"customer-keyed with {n_money} money col(s) — borderline A/B"
    return "A", "medium", "customer-keyed destination, grain unclear"


def find_destinations(stripped_text: str, raw_text: str) -> list[Destination]:
    """Find every INSERT INTO <real-table> ... and classify each."""
    destinations: list[Destination] = []
    for m in INSERT_RX.finditer(stripped_text):
        dest = m.group("dest").replace("\n", " ").strip()
        dest = re.sub(r"\s+", "", dest)
        cols_raw = m.group("cols") or ""
        if not is_real_destination(dest):
            continue
        line_no = stripped_text.count("\n", 0, m.start()) + 1
        cols = parse_col_list(cols_raw) if cols_raw else []
        if not cols:
            # No explicit col list — destination grain is hard to determine
            destinations.append(Destination(dest, [], line_no, "X", "low",
                                            "INSERT without explicit col list — cannot determine destination grain"))
            continue
        archetype, conf, why = classify_destination(cols, stripped_text)
        destinations.append(Destination(dest, cols, line_no, archetype, conf, why))
    return destinations


SEVERITY = {"C": 0, "A": 1, "B": 2, "D": 3, "E": 4, "F": 5, "X": 6}


def pick_dominant(destinations: list[Destination]) -> Destination | None:
    if not destinations:
        return None
    return min(destinations, key=lambda d: (SEVERITY.get(d.archetype, 9), d.line_no))


# ---------------------------------------------------------------------------
# Recommendation table
# ---------------------------------------------------------------------------

ARCHETYPE_ACTION = {
    "A": "filter-synthetics-from-population OR enrich-dest-with-master_CID",
    "B": "aggregate-to-master via JOIN Dim_MasterGCID + GROUP BY master_CID",
    "C": "decide-IsValidCustomer-policy-for-synthetics (REGULATOR RISK)",
    "D": "enrich-dest-with-master_CID column for downstream rollup",
    "E": "swap COUNT(DISTINCT CID/GCID) -> COUNT(DISTINCT master_GCID)",
    "F": "policy decision — sub-account positions show separately or roll to master",
    "X": "manual review — no INSERT destination detected",
}

ARCHETYPE_LABEL = {
    "A": "Customer-keyed snapshot",
    "B": "Per-customer money aggregate",
    "C": "Dim-grain rollup with validity gate (REGULATOR-RISK)",
    "D": "Money-flow at transaction grain",
    "E": "Population headcount",
    "F": "Non-customer dim grain (no validity gate)",
    "X": "No destination INSERT detected",
}


# ---------------------------------------------------------------------------
# Snapshot / file walk
# ---------------------------------------------------------------------------

def load_snapshot() -> dict[str, dict]:
    if not SNAPSHOT_CSV.exists():
        sys.exit(f"missing {SNAPSHOT_CSV} — run _build_objectsstatus_snapshot.py first")
    out: dict[str, dict] = {}
    with SNAPSHOT_CSV.open(encoding="utf-8") as f:
        for r in csv.DictReader(f):
            out[r["ProcedureName"].lower()] = {
                "ProcessName": r["ProcessName"],
                "Priority": int(r["Priority"]),
                "IsActive": int(r["IsActive"]),
            }
    return out


def parse_object_id(path: Path) -> tuple[str, str, str] | None:
    try:
        rel = path.relative_to(REPO_ROOT)
    except ValueError:
        return None
    parts = rel.parts
    if len(parts) < 3:
        return None
    schema = parts[0]
    if schema not in SYNAPSE_SCHEMAS:
        return None
    type_dir = parts[1]
    if type_dir not in OBJECT_TYPES_SCAN:
        return None
    fname = path.stem
    if fname.lower().startswith(schema.lower() + "."):
        object_name = fname[len(schema) + 1:]
    else:
        object_name = fname
    type_map = {
        "Stored Procedures": "SP",
        "Functions":         "Func",
        "Views":             "View",
    }
    return schema, object_name, type_map[type_dir]


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> int:
    snapshot = load_snapshot()
    print(f"loaded {len(snapshot)} priority/process entries", flush=True)

    rows: list[dict] = []
    by_archetype: Counter = Counter()
    by_arch_pri: Counter = Counter()
    by_arch_conf: defaultdict[str, Counter] = defaultdict(Counter)
    by_action: Counter = Counter()
    n_total = 0
    n_no_dest = 0
    examples_per_arch: defaultdict[str, list[str]] = defaultdict(list)

    for schema_dir in sorted(REPO_ROOT.iterdir()):
        if not schema_dir.is_dir() or schema_dir.name not in SYNAPSE_SCHEMAS:
            continue
        for type_name in OBJECT_TYPES_SCAN:
            type_dir = schema_dir / type_name
            if not type_dir.exists():
                continue
            for sql_file in type_dir.glob("*.sql"):
                n_total += 1
                ident = parse_object_id(sql_file)
                if not ident:
                    continue
                schema, obj_name, obj_type = ident

                try:
                    raw = sql_file.read_text(encoding="utf-8", errors="replace")
                except OSError:
                    continue

                stripped = strip_comments(raw)
                destinations = find_destinations(stripped, raw)

                key = f"{schema}.{obj_name}".lower()
                meta = snapshot.get(key, {})
                priority = meta.get("Priority", -1)
                process = meta.get("ProcessName", "")
                is_active = meta.get("IsActive", -1)

                has_val, val_ev, has_pop, pop_ev = detect_validity_gate(stripped)
                has_gb_cust, gb_ev = detect_group_by_customer_key(stripped)
                touches_snapshot = bool(SNAPSHOT_JOIN_RX.search(stripped))
                touches_dimcust = bool(DIMCUST_JOIN_RX.search(stripped))

                if not destinations:
                    n_no_dest += 1
                    archetype = "X"
                    confidence = "low"
                    why = "no INSERT INTO real-table detected (view/function/lookup)"
                    dom_dest = None
                    dest_tables = ""
                    cust_keys = ""
                    money_cols = ""
                    count_cols = ""
                    dim_cols = ""
                    txn_cols = ""
                    pop_cols = ""
                    n_dest = 0
                else:
                    dom_dest = pick_dominant(destinations)
                    archetype = dom_dest.archetype
                    confidence = dom_dest.confidence
                    why = dom_dest.why
                    dest_tables = "; ".join(d.table for d in destinations)
                    n_dest = len(destinations)

                    # Aggregate col-classes across all destinations
                    all_cols: list[str] = []
                    for d in destinations:
                        all_cols.extend(d.cols)
                    cc = col_classes(all_cols)
                    cust_keys = ", ".join(sorted(set(cc["customer_keys"])))
                    money_cols = ", ".join(sorted(set(cc["money_cols"]))[:8])
                    count_cols = ", ".join(sorted(set(cc["count_cols"]))[:8])
                    dim_cols = ", ".join(sorted(set(cc["dim_cols"]))[:8])
                    txn_cols = ", ".join(sorted(set(cc["txn_cols"]))[:8])
                    pop_cols = ", ".join(sorted(set(cc["pop_flag_cols"]))[:8])

                rows.append({
                    "schema":              schema,
                    "object_name":         obj_name,
                    "object_type":         obj_type,
                    "priority":            priority,
                    "process_name":        process,
                    "is_active":           is_active,
                    "archetype":           archetype,
                    "archetype_label":     ARCHETYPE_LABEL[archetype],
                    "confidence":          confidence,
                    "n_destinations":      n_dest,
                    "destination_tables":  dest_tables,
                    "dest_customer_keys":  cust_keys,
                    "dest_money_cols":     money_cols,
                    "dest_count_cols":     count_cols,
                    "dest_dim_cols":       dim_cols,
                    "dest_txn_cols":       txn_cols,
                    "dest_pop_flag_cols":  pop_cols,
                    "has_validity_filter": int(has_val),
                    "validity_evidence":   val_ev,
                    "has_population_filter": int(has_pop),
                    "population_evidence": pop_ev,
                    "has_group_by_customer_key": int(has_gb_cust),
                    "group_by_evidence":   gb_ev,
                    "touches_fact_snapshot_customer": int(touches_snapshot),
                    "touches_dim_customer": int(touches_dimcust),
                    "recommended_action":  ARCHETYPE_ACTION[archetype],
                    "key_insight":         why,
                    "file_path":           str(sql_file),
                })

                by_archetype[archetype] += 1
                pri_bucket = priority if priority >= 0 else "unscheduled"
                by_arch_pri[(archetype, pri_bucket)] += 1
                by_arch_conf[archetype][confidence] += 1
                by_action[ARCHETYPE_ACTION[archetype]] += 1

                if priority >= 60 and len(examples_per_arch[archetype]) < 6:
                    examples_per_arch[archetype].append(
                        f"{schema}.{obj_name} (pri={priority})"
                    )

    # Sort: severity, then priority desc, then schema/name
    rows.sort(key=lambda r: (
        SEVERITY.get(r["archetype"], 9),
        -(r["priority"] if isinstance(r["priority"], int) else -1),
        r["schema"], r["object_name"],
    ))

    if rows:
        with OUT_TRIAGE.open("w", newline="", encoding="utf-8") as f:
            w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
            w.writeheader()
            for r in rows:
                w.writerow(r)

    summary = {
        "scope": {
            "repo": str(REPO_ROOT),
            "files_scanned": n_total,
            "files_classified": len(rows),
            "files_no_destination": n_no_dest,
        },
        "archetype_legend": {a: ARCHETYPE_LABEL[a] for a in "ABCDEFX"},
        "recommended_action_by_archetype": ARCHETYPE_ACTION,
        "by_archetype": [
            {
                "archetype": a,
                "label": ARCHETYPE_LABEL[a],
                "count": by_archetype.get(a, 0),
                "confidence_breakdown": dict(by_arch_conf.get(a, {})),
            }
            for a in "ABCDEFX"
        ],
        "by_archetype_priority": {
            f"{a}|{p}": n
            for (a, p), n in sorted(by_arch_pri.items(), key=lambda x: (x[0][0], str(x[0][1])))
        },
        "by_recommended_action": dict(by_action),
        "high_priority_examples": {a: examples_per_arch[a] for a in "ABCDEFX" if examples_per_arch[a]},
    }
    OUT_SUMMARY.write_text(json.dumps(summary, indent=2), encoding="utf-8")

    print(f"\nscan complete:", flush=True)
    print(f"  files scanned:        {n_total}", flush=True)
    print(f"  files classified:     {len(rows)}", flush=True)
    print(f"  files no destination: {n_no_dest}", flush=True)

    print("\nby archetype:", flush=True)
    for a in "ABCDEFX":
        n = by_archetype.get(a, 0)
        if n:
            confs = dict(by_arch_conf.get(a, {}))
            print(f"  {a}  {ARCHETYPE_LABEL[a]:<55s} n={n:>5}  confidence={confs}", flush=True)

    print("\nby archetype × priority:", flush=True)
    for (a, p), n in sorted(by_arch_pri.items(), key=lambda x: (SEVERITY[x[0][0]], -(x[0][1] if isinstance(x[0][1], int) else 9999))):
        print(f"  {a}  pri {str(p):>11}  -> {n}", flush=True)

    print(f"\nwrote {OUT_TRIAGE}", flush=True)
    print(f"wrote {OUT_SUMMARY}", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
