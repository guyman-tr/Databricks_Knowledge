# Billing.GetCreditsHistoryByDate

> Returns the bonus and compensation credit history for a customer since a given date, joining BackOffice lookup tables to provide human-readable bonus type, campaign code, and compensation reason names, as part of the PaymentHistoryAPI.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @FromDate filter; optional @CreditID for single-record lookup |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetCreditsHistoryByDate` is the bonus-and-compensation retrieval component of the PaymentHistoryAPI. When a customer views their payment history (account statement, customer service portal), this procedure retrieves credit events of type "Compensation" (6) and "Bonus" (7) that occurred after a specified date. These are the two credit types that represent discretionary money credited to a customer outside of normal trading activity - bonuses awarded for promotions or campaigns, and compensations paid by operations for service issues.

The procedure was created in 2014 by idanfe and later updated by Geri Reshef in November 2016 (for max CreditID real DB changes in History.ActiveCredit). The `OPTION (RECOMPILE)` hint prevents parameter sniffing issues common when a single @CreditID is provided vs. no filter (the rowcount differs dramatically between the two cases).

Data flow: The PaymentHistoryAPI calls this procedure when building a customer's statement. The result enriches raw credit records with descriptive names from BackOffice tables: the bonus type name (e.g., "Welcome Bonus"), the campaign code (e.g., promotional campaign code for tracking), and the compensation reason name (e.g., "Market Disruption Compensation"). The caller aggregates this with deposit and cashout history from other procedures to build the complete payment timeline.

---

## 2. Business Logic

### 2.1 Bonus vs Compensation Filter

**What**: The procedure exclusively returns credit types 6 (Compensation) and 7 (Bonus) - filtering out all other transaction types from the credit history.

**Columns/Parameters Involved**: `CreditTypeID`, `@FromDate`

**Rules**:
- CreditTypeID = 6 (Compensation): Discretionary credits paid by operations as compensation for service issues, market disruptions, or errors. Joined to BackOffice.CompensationReason for the reason name.
- CreditTypeID = 7 (Bonus): Promotional credits awarded through marketing campaigns or programs. Joined to BackOffice.BonusType and BackOffice.Campaign for descriptive names.
- All other credit types (1=Deposit, 2=Cashout, 3=Open Position, etc.) are excluded - those are returned by other PaymentHistoryAPI procedures.
- `Occurred > @FromDate`: date filter uses strict greater-than (exclusive). Records on @FromDate itself are excluded.
- `OPTION (RECOMPILE)`: prevents cached plan issues when @CreditID switches between NULL (return all) and a specific value (return one record). The cardinality difference is large enough to cause suboptimal plans without recompile.

**Diagram**:
```
Credit types returned by this procedure:
  6 = Compensation  -> joined to BackOffice.CompensationReason
  7 = Bonus         -> joined to BackOffice.BonusType + BackOffice.Campaign

Credit types NOT returned (other PaymentHistoryAPI procedures):
  1=Deposit, 2=Cashout, 11=Chargeback, 12=Refund, etc.
```

### 2.2 Optional Single-Record Lookup

**What**: The @CreditID parameter (optional, defaults to NULL) allows fetching a single specific credit record.

**Columns/Parameters Involved**: `@CreditID`, `CreditID`

**Rules**:
- `@CreditID = NULL` (default): returns all qualifying bonus/compensation credits since @FromDate for the customer.
- `@CreditID = {value}`: returns only the specific credit record. Combined with the CreditTypeID IN (6,7) and date filters - the record must still be a Bonus or Compensation type and within the date range.
- `ISNULL(@CreditID, 0) = 0 OR CreditID = @CreditID`: evaluates to TRUE when @CreditID is NULL (via ISNULL default), or when the row matches the specific ID.

### 2.3 BackOffice Enrichment JOINs

**What**: Three LEFT JOINs add human-readable labels to the raw credit data.

**Columns/Parameters Involved**: `BonusTypeID`, `CampaignID`, `CompensationReasonID`

**Rules**:
- `BackOffice.BonusType` (LEFT JOIN on BonusTypeID): provides `BonusTypeName` for Bonus credits (CreditTypeID=7). NULL if the credit has no BonusTypeID.
- `BackOffice.Campaign` (LEFT JOIN on CampaignID): provides `BonusCampaignCode` (the campaign tracking code) for credits linked to a marketing campaign. NULL if no campaign.
- `BackOffice.CompensationReason` (LEFT JOIN on CompensationReasonID): provides `CompensationReasonName` for Compensation credits (CreditTypeID=6). NULL if no reason code.
- For Compensation records (type 6): CompensationReasonName is populated, BonusTypeName/BonusCampaignCode are typically NULL.
- For Bonus records (type 7): BonusTypeName and/or BonusCampaignCode are populated, CompensationReasonName is typically NULL.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID whose credit history to retrieve. Filters History.Credit.CID. |
| 2 | @FromDate | DATETIME | NO | - | CODE-BACKED | Earliest date for credit records (exclusive - Occurred > @FromDate). The PaymentHistoryAPI caller typically passes the customer's last statement date or a fixed lookback window. |
| 3 | @CreditID | BIGINT | YES | NULL | CODE-BACKED | Optional filter to retrieve a single specific credit record. When NULL (default), all qualifying credits since @FromDate are returned. When provided, filters to exactly one credit entry (while still enforcing type and date filters). |

**Returns** (SELECT output columns):

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | CreditID | BIGINT | NO | CODE-BACKED | Unique identifier of the credit transaction in History.Credit. Primary key of the source table. Used by the caller to reference a specific credit event. |
| 2 | CreditTypeID | INT | NO | CODE-BACKED | Type of credit transaction. Always 6 or 7 in this result set. 6=Compensation (discretionary credit for service issues), 7=Bonus (promotional/campaign credit). Full lookup: Dictionary.CreditType. |
| 3 | Occurred | DATETIME | NO | CODE-BACKED | UTC timestamp when the credit was applied to the customer's account. Always after @FromDate. |
| 4 | Payment | DECIMAL | YES | CODE-BACKED | Monetary amount of the credit in USD. Positive values represent credits to the customer's balance. Amount for a bonus award or compensation payment. |
| 5 | CompensationReasonName | NVARCHAR | YES | CODE-BACKED | Human-readable name of the compensation reason from BackOffice.CompensationReason. Populated for CreditTypeID=6 (Compensation) records. NULL for Bonus records or when no reason code was recorded. Examples: "Market Disruption", "System Error Compensation". |
| 6 | BonusCampaignCode | VARCHAR | YES | CODE-BACKED | Campaign tracking code from BackOffice.Campaign for the marketing campaign that generated this bonus. Populated for CreditTypeID=7 (Bonus) records linked to a campaign. NULL for Compensation records or uncampaigned bonuses. |
| 7 | BonusTypeName | NVARCHAR | YES | CODE-BACKED | Human-readable name of the bonus type from BackOffice.BonusType. Populated for CreditTypeID=7 (Bonus) records. NULL for Compensation records or when no bonus type was recorded. Examples: "Welcome Bonus", "Loyalty Bonus". |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, Occurred, CreditTypeID | History.Credit | Direct read (SELECT) | Source of bonus and compensation credit history filtered to types 6 and 7 |
| BonusTypeID | BackOffice.BonusType | LEFT JOIN lookup | Resolves bonus type ID to display name for PaymentHistoryAPI output |
| CampaignID | BackOffice.Campaign | LEFT JOIN lookup | Resolves campaign ID to code for tracking which promotion generated a bonus |
| CompensationReasonID | BackOffice.CompensationReason | LEFT JOIN lookup | Resolves compensation reason ID to display name for PaymentHistoryAPI output |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins | EXECUTE grant | Permission | BI admin user with execute access - used for analytics and monitoring |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetCreditsHistoryByDate (procedure)
├── History.Credit (table - archive DB)
├── BackOffice.BonusType (table)
├── BackOffice.Campaign (table)
└── BackOffice.CompensationReason (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Credit | Table (archive DB) | Primary read - SELECT with NOLOCK, filtered to CID + date range + CreditTypeID IN (6,7) |
| BackOffice.BonusType | Table | LEFT JOIN on BonusTypeID to provide BonusTypeName display value |
| BackOffice.Campaign | Table | LEFT JOIN on CampaignID to provide BonusCampaignCode display value |
| BackOffice.CompensationReason | Table | LEFT JOIN on CompensationReasonID to provide CompensationReasonName display value |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PaymentHistoryAPI | External service | Called as part of payment history rendering - retrieves bonus/compensation segment of customer transaction history |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Feature | Details |
|---------|---------|
| OPTION (RECOMPILE) | Forces plan recompilation per execution. Prevents parameter sniffing: when @CreditID=NULL returns many rows (full customer history) vs. @CreditID={value} returns 0-1 rows, the optimal index strategy differs dramatically. |
| TRY/CATCH | Wraps entire SELECT in error handling that prints server/DB/procedure context and error details. Errors are printed to the output but not re-raised. |

---

## 8. Sample Queries

### 8.1 Get all bonus and compensation history for a customer since a date

```sql
-- Returns all bonus (type 7) and compensation (type 6) credits since Jan 1, 2024
EXEC [Billing].[GetCreditsHistoryByDate]
    @CID = 1234567,
    @FromDate = '2024-01-01',
    @CreditID = NULL
```

### 8.2 Look up a specific credit record

```sql
-- Retrieve details for a single compensation or bonus credit
EXEC [Billing].[GetCreditsHistoryByDate]
    @CID = 1234567,
    @FromDate = '2020-01-01',  -- wide date range to ensure it's included
    @CreditID = 9876543
```

### 8.3 Understand CreditType values for this procedure

```sql
-- Full credit type reference - this procedure returns types 6 and 7 only
SELECT CreditTypeID, Name
FROM [Dictionary].[CreditType] WITH (NOLOCK)
WHERE CreditTypeID IN (6, 7)
-- Expected: 6=Compensation, 7=Bonus
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.4/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 run; 9B skipped - no repos; 11 complete)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Billing.GetCreditsHistoryByDate | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetCreditsHistoryByDate.sql*
