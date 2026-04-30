# Billing.Redeem_Add

> Creates a new redeem (stock redemption) request for a customer's position, validating that no active redeem already exists for the position before inserting.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @RedeemID OUTPUT - newly created redeem record ID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

A "redeem" in eToro represents the process by which a customer who holds real stock positions (not CFDs) requests to convert their position into cash. `Billing.Redeem_Add` is the entry point for creating this redemption request - it is the INSERT writer for the `Billing.Redeem` table.

The procedure exists to enforce the business rule that each position can only have one active redeem at a time. Without this check, the same position could be double-redeemed, resulting in duplicate payouts. The duplicate check excludes positions in the Terminated status (RedeemStatusID=20), so a terminated redeem allows a fresh one to be created.

Data flows from the trading platform when a customer requests to redeem their stock position. The procedure inserts with an initial status of 100 (the initial pending/requested state), records the current UTC time as both RequestDate and LastModificationDate, and returns the new RedeemID for downstream processing. The payout workflow then picks up this record via `Billing.RedeemPayoutProcess_CreateRecords`.

---

## 2. Business Logic

### 2.1 Duplicate Redeem Prevention

**What**: Ensures only one active redeem can exist per position.

**Columns/Parameters Involved**: `@PositionID`, `RedeemStatusID`

**Rules**:
- Before inserting, checks if `Billing.Redeem` has any row with this `PositionID` AND `RedeemStatusID <> 20` (Terminated).
- If found: raises error 60025 with message "Position number {X} already exists. cannot add a new redeem."
- If not found (or only terminated redeems exist): proceeds with INSERT.
- This allows resubmission after a terminated attempt but prevents concurrent duplicate processing.

**Diagram**:
```
IF EXISTS(SELECT 1 FROM Billing.Redeem WHERE PositionID = @PositionID AND RedeemStatusID <> 20)
    --> RAISERROR(60025) "Position already exists"
ELSE
    --> INSERT INTO Billing.Redeem WITH RedeemStatusID = 100
    --> @RedeemID = SCOPE_IDENTITY()
```

### 2.2 Redeem Type and NFT Priority

**What**: `@RedeemTypeID` differentiates standard stock redeems from NFT redeems, affecting processing priority.

**Columns/Parameters Involved**: `@RedeemTypeID`, `RedeemTypeID`

**Rules**:
- Default @RedeemTypeID = 0 (standard/regular stock redeem).
- Non-zero values indicate NFT or special redemption types.
- Added in June 2022 (PTL-76) to support NFT redemptions.
- `RedeemPayoutProcess_GetNewRecords` and `RedeemPayoutProcess_GetClosedPosiotnsRecords` both ORDER BY `r.RedeemTypeID DESC`, giving NFT redeems higher processing priority.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RedeemID | INT OUTPUT | NO | - | CODE-BACKED | OUTPUT: the newly created Billing.Redeem.RedeemID from SCOPE_IDENTITY(). The caller uses this to track the redeem record. |
| 2 | @CID | INT | NO | - | CODE-BACKED | Customer ID of the account holder requesting the redemption. Stored in Billing.Redeem.CID. |
| 3 | @PositionID | BIGINT | NO | - | CODE-BACKED | The trade position being redeemed. Must be unique among non-terminated redeems (error 60025 if duplicate). BIGINT since June 2021 (Shay O migration). |
| 4 | @Units | DECIMAL(16,8) | NO | - | CODE-BACKED | Number of stock units to redeem. Stored in Billing.Redeem.Units. High-precision decimal for fractional shares. |
| 5 | @Fee | DECIMAL(16,8) | NO | - | CODE-BACKED | Redemption fee charged to the customer, stored as Billing.Redeem.RedeemFee. |
| 6 | @Amount | MONEY | NO | - | CODE-BACKED | Requested redemption amount (estimated cash value), stored as Billing.Redeem.AmountOnRequest. The final settled amount (AmountOnClose) is populated later by RedeemStatusUpdate when status transitions to 6. |
| 7 | @FundingID | INT | NO | - | CODE-BACKED | The customer's funding record to which the redemption proceeds will be credited. FK to Billing.Funding. |
| 8 | @InstrumentID | INT | NO | - | CODE-BACKED | The financial instrument (stock) being redeemed. FK to instrument reference in Trade/Dictionary schema. |
| 9 | @CryptoID | INT | NO | - | CODE-BACKED | Crypto asset ID associated with this redemption. Used for NFT/crypto-backed redemptions. |
| 10 | @IPAddress | VARCHAR(16) | NO | - | CODE-BACKED | Customer's IP address at the time of the redemption request. Stored for audit and compliance purposes. |
| 11 | @RedeemTypeID | INT | YES | 0 | CODE-BACKED | Type of redemption: 0 = standard stock redeem (default). Non-zero values indicate NFT or special types (added PTL-76, June 2022). Higher values get priority in the payout queue (ORDER BY DESC). |
| 12 | @OperationID | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Optional idempotency/correlation identifier for the redemption operation. Added June 2022 (PTL-76). Allows the calling service to correlate database records with its own operation tracking. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all params) | Billing.Redeem | Direct write (INSERT) | Creates the initial redeem request row with status 100 |
| @PositionID | Billing.Redeem.PositionID | Unique check | Validates no active redeem exists for this position |
| @FundingID | Billing.Funding | Lookup | Target account for redemption proceeds |

### 5.2 Referenced By (other objects point to this)

No SQL procedure callers found in the Billing schema. Called by the trading platform when a customer initiates a stock redemption. The created record is subsequently processed by:
- `Billing.RedeemPayoutProcess_CreateRecords` - picks up status=3 redeems for BO approval
- `Billing.RedeemStatusUpdate` - transitions the redeem status through its lifecycle

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.Redeem_Add (procedure)
└── Billing.Redeem (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Redeem | Table | Duplicate check (SELECT) and new record INSERT |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application (trading platform) | External caller | Calls this to create new redemption requests |
| Billing.RedeemPayoutProcess_CreateRecords | Procedure | Processes Billing.Redeem rows created by this procedure |
| Billing.RedeemStatusUpdate | Procedure | Updates the status of rows created by this procedure |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Duplicate check | Business rule | IF EXISTS (PositionID with RedeemStatusID <> 20): raises error 60025. Prevents double-redeeming an active position. |
| Initial status | Hardcoded value | RedeemStatusID = 100 on INSERT (initial/pending state). |

---

## 8. Sample Queries

### 8.1 Create a new stock redemption request

```sql
DECLARE @NewRedeemID INT
EXEC Billing.Redeem_Add
    @RedeemID = @NewRedeemID OUTPUT,
    @CID = 123456,
    @PositionID = 9876543210,
    @Units = 10.00000000,
    @Fee = 2.50000000,
    @Amount = 500.00,
    @FundingID = 789,
    @InstrumentID = 101,
    @CryptoID = 0,
    @IPAddress = '192.168.1.1',
    @RedeemTypeID = 0
SELECT @NewRedeemID AS CreatedRedeemID
```

### 8.2 Check for existing active redeems before calling (preview what procedure validates)

```sql
SELECT RedeemID, RedeemStatusID, RequestDate
FROM Billing.Redeem WITH (NOLOCK)
WHERE PositionID = 9876543210
AND RedeemStatusID <> 20  -- Terminated
```

### 8.3 View new redeems awaiting back-office processing

```sql
SELECT r.RedeemID, r.CID, r.PositionID, r.Units, r.AmountOnRequest, r.RedeemTypeID, r.RequestDate
FROM Billing.Redeem r WITH (NOLOCK)
WHERE r.RedeemStatusID = 100  -- Initial pending state
ORDER BY r.RedeemTypeID DESC, r.RequestDate ASC  -- NFT types prioritized
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.9/10 (Elements: 10/10, Logic: 7/10, Relationships: 6/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 related analyzed (RedeemStatusUpdate, RedeemPayoutProcess_CreateRecords) | App Code: skipped | Corrections: 0 applied*
*Object: Billing.Redeem_Add | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.Redeem_Add.sql*
