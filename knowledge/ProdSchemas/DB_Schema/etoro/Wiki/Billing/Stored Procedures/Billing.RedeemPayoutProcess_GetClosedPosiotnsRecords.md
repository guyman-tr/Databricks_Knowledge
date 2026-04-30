# Billing.RedeemPayoutProcess_GetClosedPosiotnsRecords

> Claims a batch of redeem payout records where the position has been closed (status 6) and initiates the transfer-units phase by setting an exclusive processing lock.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns result set of claimed records for the transfer-units worker |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

After a customer's position has been successfully closed (RedeemStatusID=6), the next step in the redemption payout workflow is to transfer the asset units to the appropriate destination. `Billing.RedeemPayoutProcess_GetClosedPosiotnsRecords` ("Posiotns" is a typo in the original name) is the "claim work" procedure for the transfer-units phase - it atomically selects up to @MaxNumOfItems records and locks them for exclusive processing.

The procedure uses an optimistic locking pattern: it finds unlocked records (InTransferUnitsProcess=0), atomically sets InTransferUnitsProcess=1 with a correlation ID, and returns the claimed batch. This prevents two concurrent workers from processing the same redeem record. If the transfer-units step fails, `Billing.RedeemPayoutProcess_Abort` (with RedeemProcessType=2) releases the lock for retry.

NFT redeems receive priority over standard stock redeems (ORDER BY RedeemTypeID DESC).

---

## 2. Business Logic

### 2.1 Atomic Claim-and-Lock Pattern

**What**: Uses a CTE + UPDATE to atomically claim records for exclusive processing.

**Columns/Parameters Involved**: `InTransferUnitsProcess`, `TransferUnitsCorrelationID`, `InTransferUnitsProcessDate`, `RedeemStatusID`

**Rules**:
- Selects only records with `RedeemStatusID = 6` (position closed) AND `InTransferUnitsProcess = 0` (not already being processed).
- Uses CTE to select top N with priority ordering, then UPDATE directly on the same CTE to atomically claim them.
- Outputs claimed RedeemIDs into @Ids table variable for the subsequent SELECT.
- NFT/special types (higher RedeemTypeID values) are prioritized: ORDER BY r.RedeemTypeID DESC.

**Diagram**:
```
CTE: TOP @MaxNumOfItems WHERE RedeemStatusID=6 AND InTransferUnitsProcess=0
                              ORDER BY RedeemTypeID DESC (NFT priority)
     |
     v
UPDATE RedeemPayoutProcess SET
  InTransferUnitsProcess = 1
  InTransferUnitsProcessDate = GETUTCDATE()
  TransferUnitsCorrelationID = @CorrelationID
OUTPUT RedeemID INTO @Ids
     |
     v
SELECT full record set for @Ids (with customer, funding, CTF data)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MaxNumOfItems | INT | NO | - | CODE-BACKED | Maximum number of records to claim in this batch. Controls the TOP N in the CTE selection. |
| 2 | @CorrelationID | VARCHAR(36) | NO | - | CODE-BACKED | Unique identifier for this processing session. Written to TransferUnitsCorrelationID on claimed records. Used by Billing.RedeemPayoutProcess_Abort to release locks for this specific session on failure. |

**Output Columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | ProcessID | INT | NO | - | CODE-BACKED | Billing.RedeemPayoutProcess.RedeemPayoutProcessID of the claimed record. |
| 4 | RedeemID | INT | NO | - | CODE-BACKED | Billing.Redeem.RedeemID. |
| 5 | PositionID | BIGINT | NO | - | CODE-BACKED | Trading position that was closed and is now in transfer-units phase. |
| 6 | RedeemTypeID | INT | NO | - | CODE-BACKED | Redeem type (0=standard, non-zero=NFT or special). Used for prioritization. |
| 7 | InstrumentID | INT | NO | - | CODE-BACKED | Financial instrument being redeemed. |
| 8 | CryptoID | INT | NO | - | CODE-BACKED | Crypto asset ID for crypto/NFT redemptions. |
| 9 | CID | INT | NO | - | CODE-BACKED | Customer ID. |
| 10 | GCID | INT | YES | - | CODE-BACKED | Global customer ID from Customer.Customer. |
| 11 | PlayerStatusID | INT | YES | - | CODE-BACKED | Customer player status from Customer.Customer. |
| 12 | PlayerLevelID | INT | YES | - | CODE-BACKED | Customer player level from Customer.Customer. |
| 13 | VerificationLevelID | INT | YES | - | CODE-BACKED | Customer verification level from BackOffice.Customer. |
| 14 | FundingID | INT | NO | - | CODE-BACKED | Target funding record for redemption proceeds. |
| 15 | FundingTypeID | INT | NO | - | CODE-BACKED | Funding method type from Billing.Funding. |
| 16 | IsBlocked | BIT | NO | - | CODE-BACKED | Whether the CustomerToFunding relationship is blocked. From Billing.CustomerToFunding. |
| 17 | Units | DECIMAL(16,8) | NO | - | CODE-BACKED | Units to transfer. |
| 18 | AmountOnClose | MONEY | YES | - | CODE-BACKED | Settlement amount calculated at position close. |
| 19 | WithdrawToFundingID | INT | YES | - | CODE-BACKED | Linked withdrawal-to-funding record if applicable. |
| 20 | RedeemFee | DECIMAL(16,8) | YES | - | CODE-BACKED | Fee charged for this redemption. |
| 21 | ManagerID | INT | YES | - | CODE-BACKED | Back-office manager who approved this redeem. |
| 22 | Remark | VARCHAR | YES | - | CODE-BACKED | Free-text remark on the redeem. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CorrelationID | Billing.RedeemPayoutProcess | UPDATE (lock claim) | Sets InTransferUnitsProcess=1 and TransferUnitsCorrelationID |
| Output data | Billing.Redeem | READ | Redeem details for claimed records |
| Output data | BackOffice.Customer | READ | Verification level |
| Output data | Customer.Customer | READ | GCID, PlayerStatusID, PlayerLevelID |
| Output data | Billing.Funding | READ | FundingTypeID |
| Output data | Billing.CustomerToFunding | READ | IsBlocked flag |

### 5.2 Referenced By (other objects point to this)

No SQL callers found. Called by the automated payout processing service to claim transfer-units work.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.RedeemPayoutProcess_GetClosedPosiotnsRecords (procedure)
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
| Billing.RedeemPayoutProcess | Table | UPDATE to set InTransferUnitsProcess lock; SELECT for return data |
| Billing.Redeem | Table | JOIN for redeem details and status filter |
| BackOffice.Customer | Table | JOIN for VerificationLevelID |
| Customer.Customer | Table | JOIN for GCID, PlayerStatusID, PlayerLevelID |
| Billing.Funding | Table | JOIN for FundingTypeID |
| Billing.CustomerToFunding | Table | JOIN for IsBlocked |
| dbo.IdList | User Defined Type | Internal @Ids table variable for OUTPUT clause |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.RedeemPayoutProcess_Abort (RedeemProcessType=2) | Procedure | Releases the InTransferUnitsProcess lock on failure |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| OPTION (RECOMPILE) | Query hint | On the return SELECT to prevent parameter sniffing. |
| NFT priority | Ordering | ORDER BY RedeemTypeID DESC ensures NFT/special redeems are processed before standard ones. |
| Atomic claim | CTE + UPDATE | The CTE-based UPDATE atomically selects and locks in a single statement. |

---

## 8. Sample Queries

### 8.1 Claim a batch of closed-position records for transfer-units processing

```sql
EXEC Billing.RedeemPayoutProcess_GetClosedPosiotnsRecords
    @MaxNumOfItems = 50,
    @CorrelationID = 'c3d4e5f6-3456-7890-cdef-012345678901'
```

### 8.2 Check records currently locked in transfer-units processing

```sql
SELECT rpp.RedeemPayoutProcessID, rpp.RedeemID, rpp.InTransferUnitsProcess,
       rpp.TransferUnitsCorrelationID, rpp.InTransferUnitsProcessDate
FROM Billing.RedeemPayoutProcess rpp WITH (NOLOCK)
JOIN Billing.Redeem r WITH (NOLOCK) ON rpp.RedeemID = r.RedeemID
WHERE rpp.InTransferUnitsProcess = 1
AND r.RedeemStatusID = 6
```

### 8.3 Count pending transfer-units work by redeem type

```sql
SELECT r.RedeemTypeID, COUNT(*) AS PendingCount
FROM Billing.RedeemPayoutProcess rpp WITH (NOLOCK)
JOIN Billing.Redeem r WITH (NOLOCK) ON rpp.RedeemID = r.RedeemID
WHERE r.RedeemStatusID = 6
AND rpp.InTransferUnitsProcess = 0
GROUP BY r.RedeemTypeID
ORDER BY r.RedeemTypeID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.6/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 22 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 related analyzed (RedeemPayoutProcess_Abort) | App Code: skipped | Corrections: 0 applied*
*Object: Billing.RedeemPayoutProcess_GetClosedPosiotnsRecords | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.RedeemPayoutProcess_GetClosedPosiotnsRecords.sql*
