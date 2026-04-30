# Customer.SetBalanceChangeMirrorAmount

> Updates a customer's Credit balance by a mirror-related amount, snaps the mirror's cash and equity state for audit, and logs the credit event - used for mirror fund adjustments (dividends, distributions, allocations) where only Credit changes without affecting RealizedEquity.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INT, @MirrorID INT, @CreditTypeID TINYINT; no output (RETURN 0 on success, THROW on error) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When a copy-trading mirror generates a cash event - for example, a dividend distribution or a fund allocation to a mirror investor - `SetBalanceChangeMirrorAmount` is the balance entry point. Unlike position-open/close events that update multiple balance fields, this procedure adjusts only the `Credit` field in `CustomerMoney`. `RealizedEquity` and `TotalCash` are not modified here.

The procedure reads the mirror's current `Amount` (cash) and `RealizedEquity` from `Trade.Mirror` to capture a snapshot of the mirror state at the time of the credit event. These mirror values are recorded in the credit history row but do not feed back into CustomerMoney. This allows the audit trail to show how much cash was in the mirror at the exact moment a dividend or distribution was paid.

Key design notes:
- `@AmountInCents` follows the application convention: amounts arrive in cents (MONEY type), divided by 100 for dollar storage.
- `@CreditTypeID` is flexible (TINYINT passed by caller), enabling this single procedure to serve multiple mirror event subtypes without hardcoding a type.
- `@MirrorDividendID` links the event to a specific mirror dividend payment record (defaults to 0 = no dividend link).
- `@Identity = null` is passed to `SetBalanceInsertCredit_Native` - the CreditID is not returned to the caller.
- `BSLRealFunds` is captured (from OUTPUT) and forwarded to the credit record, but NOT updated by this procedure (FB 43262, 17/01/2016).

---

## 2. Business Logic

### 2.1 Cent-to-Dollar Conversion

**What**: @AmountInCents arrives as MONEY in cents; converted to dollars before use.

**Rules**:
- `@AmountInDollars = @AmountInCents / 100`
- All CustomerMoney updates and credit log entries use @AmountInDollars.

### 2.2 Credit-Only Balance Update

**What**: Only the `Credit` field in CustomerMoney is changed. RealizedEquity and TotalCash are not touched.

**Columns/Parameters Involved**: `Credit` in Customer.CustomerMoney

**Rules**:
- `Credit += @AmountInDollars`
- Uses OUTPUT clause to capture NewCredit, OldCredit, TotalCash, RealizedEquity, BonusCredit, BSLRealFunds.
- RealizedEquity and TotalCash are captured from the OUTPUT (for the credit record) but are NOT modified.

```
CustomerMoney after:
  Credit         += AmountInDollars
  TotalCash      - UNCHANGED (captured, not modified)
  RealizedEquity - UNCHANGED (captured, not modified)
  BSLRealFunds   - UNCHANGED (captured, not modified)
```

### 2.3 Mirror State Snapshot

**What**: After updating CustomerMoney, the procedure reads the current mirror state to capture MirrorCash and MirrorEquity for the credit record.

**Columns/Parameters Involved**: `Trade.Mirror.Amount`, `Trade.Mirror.RealizedEquity`, `@MirrorDividendID`

**Rules**:
- `SELECT @MirrorCash = Amount, @MirrorEquity = RealizedEquity FROM Trade.Mirror WHERE MirrorID = @MirrorID`
- `@MirrorDividendID = ISNULL(@MirrorDividendID, 0)` - NULL guard defaults to 0.
- `@BSLRealFunds = ISNULL(@BSLRealFunds, 0)` - NULL guard.
- These values are forwarded to SetBalanceInsertCredit_Native for the audit record.

### 2.4 TotalCashChange = 0

**What**: The credit record logs TotalCashChange = 0, reflecting that total cash is not modified by this event.

**Rules**:
- `@TotalCashChange = 0` - passed explicitly to SetBalanceInsertCredit_Native.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID of the account receiving the mirror amount change. |
| 2 | @CreditTypeID | TINYINT | NO | - | CODE-BACKED | Credit event type. Flexible - caller supplies the specific mirror event type. Common values include mirror-related CreditTypeIDs from Dictionary.CreditType (e.g., 18=Account balance to mirror, 19=Mirror balance to account). |
| 3 | @AmountInCents | MONEY | NO | - | CODE-BACKED | Amount to apply in CENTS (application convention). Divided by 100 internally to get dollars. Can be positive (credit to account) or negative (debit). |
| 4 | @Description | VARCHAR(255) | YES | NULL | CODE-BACKED | Human-readable description of the mirror amount change, stored in the credit history record. |
| 5 | @MirrorID | INT | NO | - | CODE-BACKED | The copy-trading mirror ID whose cash/equity state is read and linked to this credit event. Used to look up MirrorCash and MirrorEquity from Trade.Mirror. |
| 6 | @MirrorDividendID | INT | YES | 0 | CODE-BACKED | Optional mirror dividend payment reference. Links this credit event to a specific dividend distribution record. Defaults to 0 (no dividend linkage). ISNULL-guarded to 0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.CustomerMoney | MODIFIER | UPDATE Credit += AmountInDollars |
| @MirrorID | Trade.Mirror | READ | SELECT Amount, RealizedEquity for mirror state snapshot |
| @CID | Customer.SetBalanceInsertCredit_Native | Caller (EXEC) | Logs the mirror amount credit event |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.SetBalance | EXEC | Caller | Central balance router delegates mirror-amount credit types here |
| Mirror dividend/distribution pipelines | External | Callers | Called for each mirror cash event (dividends, distributions, fund allocation) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SetBalanceChangeMirrorAmount (procedure)
+-- Customer.CustomerMoney (table) [UPDATE Credit]
+-- Trade.Mirror (table) [READ Amount, RealizedEquity]
+-- Customer.SetBalanceInsertCredit_Native (procedure) [INSERT credit record]
      +-- History.ActiveCreditRecentMemoryBucket (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerMoney | Table | UPDATE - adds AmountInDollars to Credit |
| Trade.Mirror | Table | SELECT - reads Amount and RealizedEquity for mirror snapshot |
| Customer.SetBalanceInsertCredit_Native | Procedure | EXEC - inserts credit history record |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.SetBalance | Procedure | Calls this for mirror amount adjustment events |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| ISNULL(@MirrorDividendID, 0) | Guard | Ensures 0 is stored in credit record if no dividend ID supplied |
| ISNULL(@BSLRealFunds, 0) | Guard | Prevents NULL BSLRealFunds reaching the credit INSERT |
| Credit-only update | Design | Only Credit is modified; TotalCash and RealizedEquity are unchanged - mirror fund events are credit adjustments, not realized equity events |
| TotalCashChange = 0 | Audit convention | Mirror amount changes record zero total-cash impact in the credit log |
| @Identity = null | Design | CreditID not returned to caller; used for fire-and-forget mirror events |

---

## 8. Sample Queries

### 8.1 Find all mirror amount changes for a customer

```sql
SELECT
    acb.CreditID,
    acb.CreditTypeID,
    ct.Name AS CreditTypeName,
    acb.Payment AS AmountChanged,
    acb.MirrorID,
    acb.MirrorCash,
    acb.MirrorEquity,
    acb.MirrorDividendID,
    acb.Description,
    acb.Occurred
FROM History.ActiveCreditBucket_VW acb WITH (NOLOCK)
JOIN Dictionary.CreditType ct WITH (NOLOCK) ON ct.CreditTypeID = acb.CreditTypeID
WHERE acb.CID = 12345
    AND acb.MirrorID IS NOT NULL AND acb.MirrorID > 0
ORDER BY acb.Occurred DESC
```

### 8.2 Find all mirror dividend payments for a specific mirror

```sql
SELECT
    acb.CID,
    acb.Payment AS DividendAmountUSD,
    acb.MirrorDividendID,
    acb.Credit AS CreditAfterDividend,
    acb.Occurred
FROM History.ActiveCreditBucket_VW acb WITH (NOLOCK)
WHERE acb.MirrorID = 55555
    AND acb.MirrorDividendID IS NOT NULL AND acb.MirrorDividendID > 0
ORDER BY acb.Occurred DESC
```

### 8.3 Check mirror cash state at time of dividend credit

```sql
DECLARE @MirrorID INT = 55555;

SELECT
    m.MirrorID,
    m.Amount AS CurrentMirrorCash,
    m.RealizedEquity AS CurrentMirrorEquity,
    acb.MirrorCash AS MirrorCashAtCreditTime,
    acb.MirrorEquity AS MirrorEquityAtCreditTime,
    acb.Payment AS DividendAmount,
    acb.Occurred
FROM Trade.Mirror m WITH (NOLOCK)
LEFT JOIN History.ActiveCreditBucket_VW acb WITH (NOLOCK)
    ON acb.MirrorID = m.MirrorID
    AND acb.MirrorDividendID IS NOT NULL
WHERE m.MirrorID = @MirrorID
ORDER BY acb.Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 8.5/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.SetBalanceChangeMirrorAmount | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.SetBalanceChangeMirrorAmount.sql*
