# Billing.WithdrawService_GetInstantCashoutStatus

> Returns the effective cashout status of a withdrawal by combining the parent Withdraw status with any WithdrawToFunding payment leg status, prioritising the payment leg status when it exists.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @withdrawID - withdrawal to check |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.WithdrawService_GetInstantCashoutStatus` is a lightweight status-check procedure used by the instant cashout flow in the withdrawal service. It returns the most granular available status for a withdrawal: if a payment leg (`WithdrawToFunding`) exists, its `CashoutStatusID` reflects the actual payment execution state and takes priority; if no payment leg exists yet, the parent `Billing.Withdraw.CashoutStatusID` is used as the fallback.

This distinction matters because `Billing.Withdraw` and `Billing.WithdrawToFunding` can have different statuses at the same point in time. For example, the parent Withdraw may be `CashoutStatusID=2` (InProcess) while the payment leg is already at `CashoutStatusID=6` (Payment Sent) - the WTF status is more current. The `ISNULL(WTF.CashoutStatusID, W.CashoutStatusID)` pattern returns the WTF status when present, falling back to the Withdraw status when no leg exists.

The `ResponseID` return value provides the payment provider's reference ID for the transaction, enabling the instant cashout service to track provider acknowledgements.

---

## 2. Business Logic

### 2.1 Effective Status: WTF Status Takes Priority Over Withdraw Status

**What**: The "effective" status is the payment leg status (WTF) when a payment leg exists, otherwise the parent withdrawal status.

**Columns/Parameters Involved**: `Billing.WithdrawToFunding.CashoutStatusID`, `Billing.Withdraw.CashoutStatusID`

**Rules**:
- `ISNULL(WTF.CashoutStatusID, W.CashoutStatusID)`: if a WTF row exists, return its CashoutStatusID. If no WTF row exists (NULL from LEFT JOIN), return W.CashoutStatusID.
- A withdrawal can have multiple WTF rows (multiple payment legs). In that case, this query returns one row per WTF leg. The caller is expected to handle the multi-row case.
- WTF statuses are more granular and current than the parent Withdraw status.

**Diagram**:
```
Billing.Withdraw (W)
  LEFT JOIN Billing.WithdrawToFunding (WTF) ON W.WithdrawID = WTF.WithdrawID

No WTF rows:   CashoutStatusID = W.CashoutStatusID (fallback)
1+ WTF rows:   CashoutStatusID = WTF.CashoutStatusID (actual payment leg status)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @withdrawID | INTEGER | NO | - | CODE-BACKED | The withdrawal to check. FK to `Billing.Withdraw.WithdrawID`. |

**Result Set Columns**:

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | CashoutStatusID | INT | Effective status: `WTF.CashoutStatusID` if a payment leg exists, else `W.CashoutStatusID`. Values: 1=Pending, 2=InProcess, 3=Processed, 4=Cancelled, 5=Partially Processed, 6=Payment Sent, 7=Rejected, etc. |
| 2 | ResponseID | INT | Payment provider response reference ID from `Billing.WithdrawToFunding.ResponseID`. NULL if no payment leg exists. Used to correlate with provider acknowledgement records. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @withdrawID | Billing.Withdraw | FK (read) | Reads parent withdrawal status. |
| @withdrawID | Billing.WithdrawToFunding | LEFT JOIN (read) | Reads payment leg status and ResponseID. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| WithdrawService (application) | - | Caller | Instant cashout flow polls this to check payment execution status. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawService_GetInstantCashoutStatus (procedure)
├── Billing.Withdraw (table)
└── Billing.WithdrawToFunding (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | SELECT CashoutStatusID (fallback status) WHERE WithdrawID=@withdrawID |
| Billing.WithdrawToFunding | Table | LEFT JOIN: payment leg status (WTF.CashoutStatusID) and ResponseID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No DB-layer dependents found | - | Called from withdrawal service application layer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. Returns 0 rows if the @withdrawID does not exist. Returns 1 row per WTF leg (may be >1 if multiple payment legs).

---

## 8. Sample Queries

### 8.1 Check status of a withdrawal

```sql
EXEC Billing.WithdrawService_GetInstantCashoutStatus @withdrawID = 987654;
```

### 8.2 Inline equivalent showing both statuses

```sql
SELECT
    W.WithdrawID,
    W.CashoutStatusID AS WithdrawStatus,
    WTF.CashoutStatusID AS WTFStatus,
    ISNULL(WTF.CashoutStatusID, W.CashoutStatusID) AS EffectiveStatus,
    WTF.ResponseID
FROM Billing.Withdraw W WITH (NOLOCK)
LEFT JOIN Billing.WithdrawToFunding WTF WITH (NOLOCK) ON W.WithdrawID = WTF.WithdrawID
WHERE W.WithdrawID = 987654;
```

### 8.3 Find withdrawals with mismatched parent/leg statuses

```sql
SELECT
    W.WithdrawID,
    W.CashoutStatusID AS ParentStatus,
    WTF.CashoutStatusID AS LegStatus
FROM Billing.Withdraw W WITH (NOLOCK)
JOIN Billing.WithdrawToFunding WTF WITH (NOLOCK) ON W.WithdrawID = WTF.WithdrawID
WHERE W.CashoutStatusID <> WTF.CashoutStatusID
  AND W.RequestDate > DATEADD(DAY, -7, GETDATE())
ORDER BY W.RequestDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawService_GetInstantCashoutStatus | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawService_GetInstantCashoutStatus.sql*
