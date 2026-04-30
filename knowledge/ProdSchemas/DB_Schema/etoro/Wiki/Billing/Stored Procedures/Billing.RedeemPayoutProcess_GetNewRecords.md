# Billing.RedeemPayoutProcess_GetNewRecords

> Claims a batch of approved redeem payout records (status 4) and initiates the close-position phase by setting an exclusive processing lock.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns result set of claimed records for the close-position worker |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

After a back-office manager approves a batch of redemptions via `Billing.RedeemPayoutProcess_CreateRecords` (which sets RedeemStatusID=4), the automated payout service needs to pick them up and initiate the position-closing step. `Billing.RedeemPayoutProcess_GetNewRecords` is the "claim work" procedure for this close-position phase.

It atomically selects up to @MaxNumOfItems records that are ready for close-position processing (status=4, not already locked) and claims them with a correlation ID. The caller then uses the returned position and instrument data to call the trading engine to close the underlying position. NFT redeems receive higher priority (ORDER BY RedeemTypeID DESC). If the close-position step fails, `Billing.RedeemPayoutProcess_Abort` (with RedeemProcessType=1) releases the lock.

This is the first active processing step in the automated payout pipeline; `GetClosedPosiotnsRecords` handles the subsequent transfer-units step.

---

## 2. Business Logic

### 2.1 Atomic Claim-and-Lock for Close-Position Phase

**What**: Uses CTE + UPDATE to atomically claim records for position-closing.

**Columns/Parameters Involved**: `InClosePositionProcess`, `ClosePositionCorrelationID`, `InClosePositionProcessDate`, `RedeemStatusID`

**Rules**:
- Selects only records where `RedeemStatusID = 4` (InProcess) AND `InClosePositionProcess = 0` (not already being closed).
- Uses CTE for TOP N selection with NFT priority, then UPDATE atomically sets the lock.
- Outputs claimed RedeemIDs via OUTPUT clause into @Ids (dbo.IdList type).
- Returns full record set including customer verification level, funding, and CTF block status - all data needed by the position-closing service.

**Diagram**:
```
CTE: TOP @MaxNumOfItems WHERE RedeemStatusID=4 AND InClosePositionProcess=0
                              ORDER BY RedeemTypeID DESC (NFT priority)
     |
     v
UPDATE RedeemPayoutProcess SET
  InClosePositionProcess = 1
  InClosePositionProcessDate = GETUTCDATE()
  ClosePositionCorrelationID = @CorrelationID
OUTPUT RedeemID INTO @Ids
     |
     v
SELECT full record set for @Ids
  (includes OperationID, RedeemTypeID for NFT/special processing differentiation)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MaxNumOfItems | INT | NO | - | CODE-BACKED | Maximum records to claim. Controls TOP N in CTE selection. |
| 2 | @CorrelationID | VARCHAR(36) | NO | - | CODE-BACKED | Unique ID for this processing session. Written to ClosePositionCorrelationID on claimed records. Used by RedeemPayoutProcess_Abort (RedeemProcessType=1) to release locks on failure. |

**Output Columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | ProcessID | INT | NO | - | CODE-BACKED | Billing.RedeemPayoutProcess.RedeemPayoutProcessID. |
| 4 | RedeemID | INT | NO | - | CODE-BACKED | Billing.Redeem.RedeemID. |
| 5 | RedeemTypeID | INT | NO | - | CODE-BACKED | 0=standard, non-zero=NFT or special. Passed to position-closing service to differentiate close behavior. |
| 6 | OperationID | UNIQUEIDENTIFIER | YES | - | CODE-BACKED | Idempotency key for the redemption operation (PTL-76). Passed to position-closing service. |
| 7 | PositionID | BIGINT | NO | - | CODE-BACKED | Trading position to be closed. Primary input to the position-closing engine. |
| 8 | InstrumentID | INT | NO | - | CODE-BACKED | Financial instrument. Used by closing service to determine settlement/closing rules. |
| 9 | CryptoID | INT | NO | - | CODE-BACKED | Crypto asset ID for crypto/NFT positions. |
| 10 | CID | INT | NO | - | CODE-BACKED | Customer ID. |
| 11 | GCID | INT | YES | - | CODE-BACKED | Global customer ID from Customer.Customer. |
| 12 | PlayerStatusID | INT | YES | - | CODE-BACKED | Customer player status. |
| 13 | PlayerLevelID | INT | YES | - | CODE-BACKED | Customer player level. |
| 14 | VerificationLevelID | INT | YES | - | CODE-BACKED | KYC verification level from BackOffice.Customer. |
| 15 | FundingID | INT | NO | - | CODE-BACKED | Target funding for redemption proceeds. |
| 16 | FundingTypeID | INT | NO | - | CODE-BACKED | Funding method type. |
| 17 | IsBlocked | BIT | NO | - | CODE-BACKED | Whether CustomerToFunding is blocked. From Billing.CustomerToFunding. |
| 18 | Units | DECIMAL(16,8) | NO | - | CODE-BACKED | Units to redeem. |
| 19 | AmountOnClose | MONEY | YES | - | CODE-BACKED | Settlement amount at close (populated after status transitions to 6). |
| 20 | WithdrawToFundingID | INT | YES | - | CODE-BACKED | Linked withdrawal-to-funding if any. |
| 21 | RedeemFee | DECIMAL(16,8) | YES | - | CODE-BACKED | Fee for this redemption. |
| 22 | ManagerID | INT | YES | - | CODE-BACKED | Approving BO manager. |
| 23 | Remark | VARCHAR | YES | - | CODE-BACKED | Free-text remark. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Lock claim | Billing.RedeemPayoutProcess | UPDATE | Sets InClosePositionProcess=1 on claimed records |
| Return data | Billing.Redeem | READ | Redeem details |
| Return data | BackOffice.Customer | READ | Verification level |
| Return data | Customer.Customer | READ | GCID, player info |
| Return data | Billing.Funding | READ | FundingTypeID |
| Return data | Billing.CustomerToFunding | READ | IsBlocked flag |

### 5.2 Referenced By (other objects point to this)

No SQL callers found. Called by the automated payout service to claim close-position work.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.RedeemPayoutProcess_GetNewRecords (procedure)
├── Billing.RedeemPayoutProcess (table)
├── Billing.Redeem (table)
├── BackOffice.Customer (table)
├── Customer.Customer (table)
├── Billing.Funding (table)
└── Billing.CustomerToFunding (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.RedeemPayoutProcess | Table | UPDATE lock claim + SELECT return data |
| Billing.Redeem | Table | JOIN for status filter and redeem details |
| BackOffice.Customer | Table | JOIN for VerificationLevelID |
| Customer.Customer | Table | JOIN for GCID, PlayerStatusID, PlayerLevelID |
| Billing.Funding | Table | JOIN for FundingTypeID |
| Billing.CustomerToFunding | Table | JOIN for IsBlocked |
| dbo.IdList | User Defined Type | @Ids internal table variable |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.RedeemPayoutProcess_Abort (RedeemProcessType=1) | Procedure | Releases InClosePositionProcess lock on failure |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NFT priority | ORDER BY | RedeemTypeID DESC ensures NFT/special redeems are processed before standard stock. |
| Atomic claim | CTE + UPDATE | Single-statement CTE UPDATE atomically selects and locks. |

---

## 8. Sample Queries

### 8.1 Claim a batch of new records for close-position processing

```sql
EXEC Billing.RedeemPayoutProcess_GetNewRecords
    @MaxNumOfItems = 50,
    @CorrelationID = 'd4e5f6a7-4567-8901-defa-123456789012'
```

### 8.2 Check pending close-position work

```sql
SELECT r.RedeemTypeID, COUNT(*) AS PendingCount
FROM Billing.RedeemPayoutProcess rpp WITH (NOLOCK)
JOIN Billing.Redeem r WITH (NOLOCK) ON rpp.RedeemID = r.RedeemID
WHERE r.RedeemStatusID = 4
AND rpp.InClosePositionProcess = 0
GROUP BY r.RedeemTypeID
ORDER BY r.RedeemTypeID DESC
```

### 8.3 Check currently locked records in close-position phase

```sql
SELECT rpp.RedeemPayoutProcessID, r.PositionID, r.CID,
       rpp.ClosePositionCorrelationID, rpp.InClosePositionProcessDate
FROM Billing.RedeemPayoutProcess rpp WITH (NOLOCK)
JOIN Billing.Redeem r WITH (NOLOCK) ON rpp.RedeemID = r.RedeemID
WHERE rpp.InClosePositionProcess = 1
AND r.RedeemStatusID = 4
ORDER BY rpp.InClosePositionProcessDate
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.6/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 23 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 related analyzed (RedeemPayoutProcess_Abort) | App Code: skipped | Corrections: 0 applied*
*Object: Billing.RedeemPayoutProcess_GetNewRecords | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.RedeemPayoutProcess_GetNewRecords.sql*
