# Trade.ReportWrongDataInHistoryCredit

> Detects customers whose most recent History.Credit record disagrees with Customer.CustomerMoney on RealizedEquity or Credit values, using a dual-snapshot approach with a 5-minute delay to filter out false positives from in-memory table lag.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - runs as a scheduled monitoring job |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure monitors the consistency between the live credit ledger (`History.Credit`) and the cached financial summary (`Customer.CustomerMoney`). For each customer who has a credit record in the last 24 hours, it compares the most recent credit record's RealizedEquity and Credit values against the CustomerMoney table. Any mismatch is a potential sign of a failed financial update or transaction sequencing issue.

The key design feature is the **dual-snapshot anti-false-positive pattern**: the check runs twice with a 5-minute WAITFOR delay between snapshots. Only customers whose discrepancy is present in BOTH snapshots (via INTERSECT) are reported. This was introduced by Elad in January 2021 to address false positives caused by in-memory table lag on the History schema.

When real discrepancies are found, an HTML email is sent to tradingbackend, DBA, and the team lead (naseemra). The procedure is a production alert meant to be triggered by a SQL Agent job.

---

## 2. Business Logic

### 2.1 Dual-Snapshot False-Positive Filtering

**What**: Two-pass verification using a 5-minute WAITFOR delay to distinguish transient from persistent discrepancies.

**Columns/Parameters Involved**: `#a`, `#b` (temp tables), `History.ActiveCreditView.CreditID`, `RANK()`

**Rules**:
- Snapshot #a: taken at job start, snapshot #b: taken 5 minutes later
- INTERSECT of CID+Remark from both snapshots = only persistent issues
- Transient issues (transaction in flight, replication lag) clear between snapshots and are filtered out
- Developer comment: "Because of the change of in memory, we have false positive, we execute the same proc twice with 30sec delay" - delay was originally 30s, now 5 minutes (WAITFOR '00:05:00')

**Diagram**:
```
T=0: Take snapshot #a (customers with discrepancies)
       |
T+5min: Take snapshot #b (same check)
       |
       INTERSECT: only CIDs in BOTH snapshots -> alert
       |-> Transient: appears in #a but not #b -> ignored (no alert)
       |-> Persistent: appears in both -> send email alert
```

### 2.2 Credit Record Selection Logic

**What**: Uses RANK() to select the single most recent credit record per customer within the last 24 hours.

**Columns/Parameters Involved**: `History.ActiveCreditView.CreditID`, `RANK() OVER (PARTITION BY AC.CID ORDER BY AC.CreditID DESC)`

**Rules**:
- Only credit records with Occurred > DATEADD(dd,-1,getdate()) are considered
- RANK()=1 = most recent credit record per CID
- Compares AC.RealizedEquity vs CM.RealizedEquity AND AC.Credit vs CM.Credit
- TotalCash comparison is commented out (similar to CustomerMoney versions)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (no parameters) | - | - | - | CODE-BACKED | No input parameters. Scheduled monitoring job. WAITFOR '00:05:00' means each execution takes ~5+ minutes to complete. |

**Output columns (in @Tbl / email):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | CID | BIGINT | NO | - | CODE-BACKED | Customer with persistent financial data discrepancy between History.Credit (most recent record) and Customer.CustomerMoney. |
| 3 | ColumnsNames | VARCHAR(40) | NO | - | CODE-BACKED | Space-delimited list of which columns disagree: 'RealizedEquity ' and/or 'Credit '. TotalCash is defined but commented out. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Main JOIN | Customer.CustomerMoney | Lookup | Source of RealizedEquity, TotalCash, Credit for comparison |
| Main JOIN | History.ActiveCreditView | Lookup | Provides most recent credit snapshot per CID (last 24h) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ReportWrongDataInHistoryCredit (procedure)
|- Customer.CustomerMoney (table)
|- History.ActiveCreditView (view - in-memory credit records)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerMoney | Table | Provides live Credit, RealizedEquity, TotalCash values |
| History.ActiveCreditView | View | Provides the most recent credit ledger entries (last 24 hours) for comparison |

### 6.2 Objects That Depend On This

No dependents found - standalone monitoring procedure.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Time window | Logic | Occurred > DATEADD(dd, -1, getdate()) - only credit records from last 24 hours are checked |
| Dual-snapshot | Logic | INTERSECT between two snapshots 5 minutes apart - requires persistent discrepancy to alert |

---

## 8. Sample Queries

### 8.1 Execute the History.Credit consistency check (note: takes 5+ minutes)

```sql
EXEC Trade.ReportWrongDataInHistoryCredit
```

### 8.2 Check current discrepancies without the dual-snapshot delay

```sql
SELECT DISTINCT CM.CID,
    AC.RealizedEquity AS AC_RealizedEquity,
    CM.RealizedEquity AS CM_RealizedEquity,
    AC.Credit AS AC_Credit,
    CM.Credit AS CM_Credit,
    CONCAT(
        CASE WHEN AC.RealizedEquity <> CM.RealizedEquity THEN 'RealizedEquity ' ELSE '' END,
        CASE WHEN AC.Credit <> CM.Credit THEN 'Credit ' ELSE '' END
    ) AS Remark
FROM Customer.CustomerMoney CM WITH (NOLOCK)
JOIN History.ActiveCreditView AC WITH (NOLOCK) ON CM.CID = AC.CID
    AND AC.Occurred > DATEADD(dd, -1, GETDATE())
WHERE RANK() OVER (PARTITION BY AC.CID ORDER BY AC.CreditID DESC) = 1
    AND (AC.RealizedEquity <> CM.RealizedEquity OR AC.Credit <> CM.Credit)
```

### 8.3 Check most recent credit record per CID from last 24 hours

```sql
SELECT AC.CID, AC.CreditID, AC.RealizedEquity, AC.Credit, AC.Occurred,
    RANK() OVER (PARTITION BY AC.CID ORDER BY AC.CreditID DESC) AS CreditRank
FROM History.ActiveCreditView AC WITH (NOLOCK)
WHERE AC.Occurred > DATEADD(dd, -1, GETDATE())
ORDER BY AC.CID, CreditRank
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ReportWrongDataInHistoryCredit | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ReportWrongDataInHistoryCredit.sql*
