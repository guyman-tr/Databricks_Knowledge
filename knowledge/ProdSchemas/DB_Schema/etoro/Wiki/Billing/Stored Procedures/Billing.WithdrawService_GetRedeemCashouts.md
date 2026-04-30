# Billing.WithdrawService_GetRedeemCashouts

> Returns the cashout amount and position closure date for a specific crypto redemption request, used by the withdrawal service to retrieve the fiat value resulting from a redeemed crypto position.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @RedeemID - the redemption request to look up |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.WithdrawService_GetRedeemCashouts` retrieves the cashout details for a crypto redemption - specifically, the fiat amount the customer received (`AmountOnClose`) and when the underlying position was closed (`EndDateTime`). This information is used by the withdrawal service when processing a withdrawal that is linked to a crypto redemption event.

The procedure exists because a "redeem cashout" is different from a standard withdrawal: the customer first redeems a crypto position (selling their crypto for fiat via the `Billing.Redeem` pipeline), and then that resulting fiat amount may be withdrawn. The withdrawal service needs to know the exact amount and closure time of the redemption to validate and process the subsequent withdrawal.

`Billing.Redeem` stores the redemption request and the resulting fiat amount (`AmountOnClose`), while `History.Position` stores the closed trading position including the `EndDateTime` when the crypto was sold. This procedure joins the two to provide a complete picture of the redemption event.

---

## 2. Business Logic

### 2.1 Optional CID Filter with Mandatory RedeemID

**What**: The procedure requires @RedeemID but has an optional @CID validation that can serve as an ownership check.

**Columns/Parameters Involved**: `@RedeemID`, `@CID`, `Billing.Redeem.CID`

**Rules**:
- `@RedeemID` is required and must match a row in `Billing.Redeem`.
- `@CID` is optional (default NULL). When provided, it adds `r.CID = @CID` to the WHERE clause, acting as an ownership validation (ensuring the redemption belongs to the requesting customer). When NULL, the CID check is skipped.
- Returns 0 rows if no matching Redeem record exists (or if @CID is provided but doesn't match).

### 2.2 AmountOnClose as the Cashout Amount

**What**: The cashout amount is the fiat proceeds from closing the crypto position.

**Columns/Parameters Involved**: `Billing.Redeem.AmountOnClose`

**Rules**:
- `AmountOnClose` is the fiat value (in USD) of the crypto position when it was closed during the redemption process.
- `ISNULL(r.AmountOnClose, 0)` returns 0 if the position has not yet been closed (AmountOnClose is set after the position closes, not at request time).
- For the withdrawal service, a 0 here likely means the redemption is not yet complete and the withdrawal cannot proceed.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | YES | NULL | CODE-BACKED | Optional customer ownership check. When provided, the redemption must belong to this CID. When NULL, ownership is not verified and any RedeemID is returned. |
| 2 | @RedeemID | INT | NO | - | CODE-BACKED | The crypto redemption request to retrieve. FK to `Billing.Redeem.RedeemID`. Required - the primary lookup key. |

**Result Set Columns**:

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | RedeemID | INT | The redemption request ID (same as @RedeemID - confirmed for caller). |
| 2 | Amount | MONEY | The fiat amount received when the crypto position was sold (`Billing.Redeem.AmountOnClose`). Returns 0 if AmountOnClose is NULL (position not yet closed). |
| 3 | ClosedOn | DATETIME | The timestamp when the underlying trading position was closed (`History.Position.EndDateTime`). Represents when the crypto was actually sold. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @RedeemID | Billing.Redeem | FK (read) | Reads RedeemID, AmountOnClose, CID, PositionID. |
| PositionID | History.Position | JOIN | Reads EndDateTime - when the crypto position was closed. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| WithdrawService (application) | - | Caller | Called to retrieve the fiat proceeds and closure date for a crypto redemption before processing the associated withdrawal. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawService_GetRedeemCashouts (procedure)
├── Billing.Redeem (table) - redemption request and fiat amount
└── History.Position (table) - position closure date
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Redeem | Table | SELECT RedeemID, AmountOnClose, PositionID WHERE CID matches (optionally) AND RedeemID=@RedeemID |
| History.Position | Table | JOIN on PositionID to get EndDateTime (closure timestamp) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No DB-layer dependents found | - | Called from withdrawal service application layer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. Uses implicit JOIN (old-style comma syntax) between Billing.Redeem and History.Position.

---

## 8. Sample Queries

### 8.1 Get cashout details for a specific redemption

```sql
EXEC Billing.WithdrawService_GetRedeemCashouts @CID = 12345, @RedeemID = 67890;
```

### 8.2 Get cashout details without CID validation

```sql
EXEC Billing.WithdrawService_GetRedeemCashouts @CID = NULL, @RedeemID = 67890;
```

### 8.3 Retrieve all completed redemption cashouts for a customer

```sql
SELECT
    r.RedeemID,
    ISNULL(r.AmountOnClose, 0) AS Amount,
    hp.EndDateTime AS ClosedOn,
    r.RedeemStatusID
FROM Billing.Redeem r WITH (NOLOCK)
JOIN History.Position hp WITH (NOLOCK) ON hp.PositionID = r.PositionID
WHERE r.CID = 12345
  AND r.AmountOnClose IS NOT NULL
ORDER BY hp.EndDateTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 8.0/10, Relationships: 8.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawService_GetRedeemCashouts | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawService_GetRedeemCashouts.sql*
