# Monitoring.GetCreateWalletCount

> Counts successful and failed wallet creation requests within a date range, excluding known benign error codes (WL.0104 and WL.0102) from the failure count.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns Success and Failed counts for wallet creation |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.GetCreateWalletCount tracks the health of the wallet creation pipeline by counting how many wallets were successfully created versus how many failed within a given date range. This is a core operational health metric - a spike in failures or a drop in successes indicates potential system issues.

Without this procedure, the operations team would have no quick way to assess whether wallet creation is functioning normally. Wallet creation is often the first step in a customer's crypto journey, so failures here directly impact customer onboarding.

The procedure uses OUTER APPLY to find the most recent status per request, then conditionally counts successes (StatusId=1) and failures (StatusId=2). Notably, two specific error codes are excluded from failures: WL.0104 (unknown) and WL.0102 (user permission/crypto type restriction) - these are expected business-rule rejections, not system failures.

---

## 2. Business Logic

### 2.1 Success/Failure Classification

**What**: Categorizes wallet creation outcomes while filtering known benign rejections.

**Columns/Parameters Involved**: `RequestStatusId`, `DetailsJson`, `RequestTypeId`

**Rules**:
- RequestTypeId = 0 identifies wallet creation requests
- RequestStatusId = 1 -> Success (wallet created)
- RequestStatusId = 2 -> Potential failure, BUT:
  - If DetailsJson starts with '{"Code":"WL.0104"' -> excluded (not counted as failure)
  - If DetailsJson starts with '{"Code":"WL.0102"' -> excluded (user cannot create wallet for this crypto type / no permission)
- Only the MOST RECENT status per request is considered (TOP 1 ORDER BY Id DESC)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BeginDate | DATE | NO | - | CODE-BACKED | Start of the reporting period (inclusive). |
| 2 | @EndDate | DATE | NO | - | CODE-BACKED | End of the reporting period (inclusive). |

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Success | INT | NO | - | CODE-BACKED | Count of wallet creation requests where the most recent status is Done (1). |
| 2 | Failed | INT | NO | - | CODE-BACKED | Count of wallet creation requests where the most recent status is Error (2), excluding WL.0104 and WL.0102 error codes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | Wallet.Requests | FROM (read) | Source of wallet creation requests (RequestTypeId = 0) |
| Query body | Wallet.RequestStatuses | OUTER APPLY | Gets the most recent status per request |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external monitoring tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetCreateWalletCount (procedure)
  ├── Wallet.Requests (table)
  └── Wallet.RequestStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Requests | Table | FROM - wallet creation requests |
| Wallet.RequestStatuses | Table | OUTER APPLY - most recent status lookup |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check today's wallet creation health
```sql
EXEC Monitoring.GetCreateWalletCount @BeginDate = '2026-04-15', @EndDate = '2026-04-15';
```

### 8.2 Check last 7 days
```sql
DECLARE @Today DATE = CAST(GETUTCDATE() AS DATE);
EXEC Monitoring.GetCreateWalletCount @BeginDate = DATEADD(DAY, -7, @Today), @EndDate = @Today;
```

### 8.3 Investigate recent wallet creation failures
```sql
SELECT TOP 20 r.Id, r.Gcid, r.CryptoId, r.Timestamp, rs.DetailsJson
FROM Wallet.Requests r WITH (NOLOCK)
OUTER APPLY (
    SELECT TOP 1 rs2.RequestStatusId, rs2.DetailsJson
    FROM Wallet.RequestStatuses rs2 WITH (NOLOCK)
    WHERE rs2.RequestId = r.Id ORDER BY rs2.Id DESC
) rs
WHERE r.RequestTypeId = 0 AND rs.RequestStatusId = 2
  AND r.Timestamp >= DATEADD(DAY, -1, GETUTCDATE())
ORDER BY r.Timestamp DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetCreateWalletCount | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.GetCreateWalletCount.sql*
