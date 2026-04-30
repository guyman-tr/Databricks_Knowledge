# Trade.Gain_UpdateNewBonuses

> Retrieves new Popular Investor and Affiliate compensation credits older than 24 hours for bonus withdrawal processing.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns resultset of compensation credit records |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure fetches new compensation credit records from the History.Credit archive that qualify as Popular Investor ("Guru") or Affiliate payment bonuses. These are credits that were granted to users as part of the Popular Investor program (CompensationReasonID=41) or the Affiliate payment program (CompensationReasonID=51), classified under the Compensation credit type (CreditTypeID=6).

The procedure exists to support the bonus withdrawal clawback workflow. When a user who received Popular Investor or Affiliate bonuses requests a withdrawal, the system needs to identify which bonuses were granted and potentially deduct or reclaim those bonus amounts. Without this procedure, the withdrawal system would have no way to discover new bonus credits that need tracking.

Data flows from History.Credit (the credit/debit archive) through this procedure to the calling service (likely a withdrawal or bonus management service, accessible to the SuperRank_Shadow role). The procedure only returns credits that are at least 24 hours old (a cooling-off period) and newer than a given watermark (@MinID), enabling incremental polling for new bonus records.

---

## 2. Business Logic

### 2.1 Incremental Polling with Watermark

**What**: The procedure uses a high-watermark pattern to fetch only NEW bonus credits since the last poll.

**Columns/Parameters Involved**: `@MinID`, `CreditID`

**Rules**:
- @MinID acts as a cursor/watermark - only credits with CreditID > @MinID are returned
- The caller tracks the highest CreditID seen and passes it on the next call
- This avoids re-processing already-handled bonus credits

### 2.2 24-Hour Cooling Period

**What**: Only compensation credits older than 24 hours are eligible for processing.

**Columns/Parameters Involved**: `Occurred`

**Rules**:
- Filter: `DATEADD(HOUR, 24, Occurred) < GETUTCDATE()` ensures credits must be at least 24 hours old
- This prevents premature processing of recently granted bonuses
- Likely allows time for reversals or corrections before the bonus is considered final

### 2.3 CID-Based Filtering

**What**: The procedure supports both single-customer and batch modes.

**Columns/Parameters Involved**: `@CID`, `CID`

**Rules**:
- When @CID != -1, returns bonuses for a specific customer only
- When @CID = -1, returns all qualifying bonuses across all customers (batch mode)
- The -1 sentinel value is a convention for "all customers"

**Diagram**:
```
Caller passes @CID and @MinID
         |
    @CID = -1?
    /        \
  YES         NO
   |           |
 All CIDs    Specific CID
   |           |
 Filter:     Filter:
 CreditID>@MinID    CreditID>@MinID
 24hr cooldown      24hr cooldown
 CreditTypeID=6     CreditTypeID=6
 Reason IN(41,51)   Reason IN(41,51)
                    CID=@CID
   \          /
    Return resultset
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID to filter by. Pass -1 to retrieve bonuses for ALL customers (batch mode). Any other value filters to that specific customer's compensation credits. |
| 2 | @MinID | BIGINT | NO | - | CODE-BACKED | High-watermark CreditID. Only credits with CreditID > @MinID are returned. The caller persists the max CreditID from each result batch and passes it on the next invocation for incremental polling. |
| 3 | BaseCreditID | BIGINT | NO | - | CODE-BACKED | The CreditID from History.Credit, aliased as BaseCreditID. Serves as the unique identifier for the bonus credit record and the basis for tracking in the withdrawal clawback workflow. |
| 4 | CID | INT | NO | - | CODE-BACKED | The customer ID who received the compensation bonus. Identifies the Popular Investor or Affiliate partner. |
| 5 | Occurred | DATETIME | NO | - | CODE-BACKED | Timestamp when the compensation credit was granted. Must be at least 24 hours old (cooling-off period) to appear in results. |
| 6 | Amount | MONEY | NO | - | CODE-BACKED | The TotalCashChange from History.Credit, aliased as Amount. Represents the monetary value of the Popular Investor or Affiliate bonus payment. |
| 7 | WithdrawChecked | - | YES | NULL | CODE-BACKED | Always returned as NULL. Placeholder column for downstream processing - likely populated by the calling service to indicate whether this bonus has been checked against withdrawal requests. |
| 8 | WithdrawProcessed | - | YES | NULL | CODE-BACKED | Always returned as NULL. Placeholder column for downstream processing - likely populated by the calling service to indicate whether the withdrawal clawback has been processed for this bonus. |
| 9 | WithdrawID | - | YES | NULL | CODE-BACKED | Always returned as NULL. Placeholder column for downstream processing - likely populated by the calling service to link this bonus to a specific withdrawal operation. |
| 10 | CreditIDs | VARCHAR(MAX) | YES | NULL | CODE-BACKED | Always returned as NULL (cast to VARCHAR(MAX)). Placeholder column for downstream processing - likely populated to track multiple related credit IDs when bonuses are consolidated or split during withdrawal processing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM clause | History.Credit | Direct Read | Reads compensation credit records from the credit history archive |
| CreditTypeID filter | Dictionary.CreditType | Lookup | Filters to CreditTypeID=6 (Compensation) |
| CompensationReasonID filter | BackOffice.CompensationReason | Lookup | Filters to IDs 41 (Guru cash with CO) and 51 (Affiliate payment with CO) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SuperRank_Shadow (role) | GRANT EXECUTE | Permission | The SuperRank_Shadow database role has execute permission, indicating this is called by a background/service process |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.Gain_UpdateNewBonuses (procedure)
└── History.Credit (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Credit | Table | SELECT FROM - reads compensation credit records with NOLOCK |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.Gain_GetCustomersWithMultiplePayoutDays | Stored Procedure | Related Gain/Popular Investor procedure (uses same CompensationReasonID=41 filter) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all new bonuses since a watermark (batch mode)

```sql
EXEC Trade.Gain_UpdateNewBonuses
    @CID = -1,
    @MinID = 0;
```

### 8.2 Get new bonuses for a specific customer

```sql
EXEC Trade.Gain_UpdateNewBonuses
    @CID = 12345678,
    @MinID = 500000000;
```

### 8.3 Verify compensation reason values used by this procedure

```sql
SELECT  cr.CompensationReasonID,
        cr.Name
FROM    BackOffice.CompensationReason cr WITH (NOLOCK)
WHERE   cr.CompensationReasonID IN (41, 51);
-- 41 = Guru cash with CO (Popular Investor)
-- 51 = Affiliate payment with CO
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.Gain_UpdateNewBonuses | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.Gain_UpdateNewBonuses.sql*
