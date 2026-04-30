# Billing.LoadPaymentLogs

> Returns all rows from History.PaymentLog - a startup cache loader for the legacy payment audit log (cross-schema read from the History schema).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT * FROM History.PaymentLog |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.LoadPaymentLogs` is a startup cache loader that reads the complete contents of the `History.PaymentLog` audit table. The billing service may load this at startup to populate an in-memory history of payment log entries for fast access during session processing.

`History.PaymentLog` is a cross-schema audit table in the History schema that records payment event history. Loading the full log at startup would only be appropriate if the table is small; if it has grown significantly over time, this procedure would become impractical for startup loading and may instead be used for specific reporting or debugging purposes.

---

## 2. Business Logic

### 2.1 Full Payment Log Load

**What**: SELECT * with no filter - returns all rows and all columns from History.PaymentLog.

**Rules**:
- No parameters; no filtering; WITH (NOLOCK)
- Cross-schema read from the History schema
- RETURN 0 signals success
- No row count limit - returns entire table; callers must account for potential large result sets

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

### Output Columns

All columns from `History.PaymentLog` (cross-schema; exact columns from History schema DDL). Likely includes PaymentLogID, PaymentID, ActionDate, StatusID, and event detail fields.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | History.PaymentLog | READ | Cross-schema read of payment audit log; all rows returned |

### 5.2 Referenced By (other objects point to this)

Called from the billing application for payment log cache population or reporting queries.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.LoadPaymentLogs (procedure)
└── History.PaymentLog (cross-schema table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PaymentLog | Table | Cross-schema payment audit log; all rows returned without size limit |

### 6.2 Objects That Depend On This

No dependents found within the Billing schema stored procedures.

---

## 7. Technical Details

**Implementation notes**:
- `SET NOCOUNT ON` + `RETURN 0`; `WITH (NOLOCK)`
- Cross-schema (History) table access from Billing schema
- No row limit - may return large result sets if History.PaymentLog has grown significantly
- Part of the Load* family of startup cache loaders

---

## 8. Sample Queries

### 8.1 Check row count before loading
```sql
SELECT COUNT(*) FROM History.PaymentLog WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this procedure.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 6.8/10 (Elements: 6/10, Logic: 7/10, Relationships: 6/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.LoadPaymentLogs | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.LoadPaymentLogs.sql*
