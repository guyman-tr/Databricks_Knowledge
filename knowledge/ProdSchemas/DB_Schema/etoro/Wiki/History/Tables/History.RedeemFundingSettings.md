# History.RedeemFundingSettings

> System-versioned temporal history table for Billing.RedeemFundingSettings, archiving past configurations of which funding/payment types (per player tier) are eligible for wallet redemption and how long deposits must age before qualifying.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Composite temporal key (ValidTo, ValidFrom) |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on ValidTo ASC, ValidFrom ASC) |

---

## 1. Business Meaning

This table is the **active system-versioned temporal history table** for `Billing.RedeemFundingSettings` (the source table explicitly declares `HISTORY_TABLE = [History].[RedeemFundingSettings]`). SQL Server automatically archives superseded rows here when any row in `Billing.RedeemFundingSettings` is updated or deleted.

The source table controls a critical part of the **Redeem feature eligibility check**: given a customer's player tier (PlayerLevelID) and their deposit's payment method (FundingTypeID), what are the rules for whether that deposit's funds are redeemable? The key business rules encoded per row are:
- **IsActive**: Is this funding type eligible for redemption at all?
- **CancellationTimeInDays**: How many days must pass from the customer's First Time Deposit (FTD) date before this deposit type can be redeemed? This prevents immediate withdrawal of freshly deposited funds.
- **SlidingDaysToIgnore**: A sliding window adjustment to the eligibility calculation.

`Billing.GetRedeemValidationData` joins `Billing.RedeemFundingSettings` (via `BF.FundingTypeID = RS.FundingTypeID`) and checks `GETUTCDATE() >= DATEADD(dd, RS.CancellationTimeInDays, @FTDDate)` to determine if enough time has passed. This history table enables audit queries: "what were the redemption eligibility rules for a given funding type on a specific past date?"

With 38 rows and active changes as recently as March 2026, the configuration evolves regularly.

---

## 2. Business Logic

### 2.1 Deposit Age-Gating for Redemption

**What**: Deposits can only be redeemed after a minimum number of days from the customer's First Time Deposit (FTD) date, configurable per funding type and player level.

**Columns/Parameters Involved**: `CancellationTimeInDays`, `FundingTypeID`, `PlayerLevelID`, `IsActive`

**Rules**:
- Only deposits where `IsActive=1` for the (FundingTypeID, PlayerLevelID) combination are eligible for redemption
- The deposit is only redeemable if: `GETUTCDATE() >= DATEADD(day, CancellationTimeInDays, FTDDate)`
- Example: CancellationTimeInDays=60 means a credit card deposit can only be redeemed 60 days after the FTD date
- ACH deposits (FundingTypeID=29) have a separate sub-calculation but the same CancellationTimeInDays logic applies
- `Billing.GetRedeemNFTValidationData` also uses this table for NFT-specific redemption validation

**Diagram**:
```
Customer requests Redeem
  |
  +--> For each deposit in Billing.Deposit
  |       JOIN Billing.Funding ON FundingID
  |       JOIN Billing.RedeemFundingSettings ON FundingTypeID
  |
  +--> Check: RS.IsActive = 1
  +--> Check: RS.PlayerLevelID = Customer.PlayerLevelID
  +--> Check: GETUTCDATE() >= DATEADD(day, RS.CancellationTimeInDays, FTDDate)
  |
  +--> PASS -> Deposit amount counts toward redeemable balance
  +--> FAIL -> Deposit excluded from redeemable calculation
```

### 2.2 Temporal Validity

**What**: Each history row represents a past state of a funding setting, valid during a specific time window.

**Columns/Parameters Involved**: `ValidFrom`, `ValidTo`

**Rules**:
- `ValidFrom`: instant this row became the current state in `Billing.RedeemFundingSettings`
- `ValidTo`: instant this row was superseded by an update or delete
- Current (live) rows remain in `Billing.RedeemFundingSettings`; historical rows are here
- Most recent batch of changes: ValidFrom=2026-03-09, ValidTo=2026-03-10 (configuration tuning)

---

## 3. Data Overview

| ID | PlayerLevelID | FundingTypeID | CancellationTimeInDays | IsActive | SlidingDaysToIgnore | ValidFrom | ValidTo | Meaning |
|---|---|---|---|---|---|---|---|---|
| 3 | 1 (Bronze) | 3 | 60 | true | 0 | 2026-03-09 | 2026-03-10 | Bronze-tier customers using FundingType 3 had a 60-day cancellation window briefly on Mar 9-10, 2026 before the setting was updated the next day |
| 15 | 5 (Silver) | 3 | 60 | true | 0 | 2026-03-09 | 2026-03-10 | Silver-tier, same FundingType 3, same 60-day window - part of a batch configuration update on Mar 9 that was quickly revised |
| 27 | 3 (Gold) | 3 | 60 | true | 0 | 2026-03-09 | 2026-03-10 | Gold-tier FundingType 3: same pattern. TimeStamp=2019-05-27 shows the original creation date; ValidFrom=2026 shows it was updated in 2026 |
| 39 | 2 (Platinum) | 3 | 60 | true | 0 | 2026-03-09 | 2026-03-10 | Platinum-tier FundingType 3: the 2026-03-09 batch update affected all player levels simultaneously (BillingService_stg via SQLCMD) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Surrogate identifier of the original `Billing.RedeemFundingSettings` row (not an identity in the history table). Copied from the source table's IDENTITY column. Same ID can appear multiple times - one row per historical state. |
| 2 | PlayerLevelID | int | NO | - | VERIFIED | Customer loyalty tier for which this setting applies. FK to Dictionary.PlayerLevel (via source table FK). Values: 1=Bronze, 2=Platinum, 3=Gold, 4=Internal, 5=Silver, 6=Platinum Plus, 7=Diamond. `Billing.GetRedeemValidationData` filters by `RS.PlayerLevelID = (SELECT PlayerLevelID FROM Customer.Customer WHERE CID = @CID)`. |
| 3 | FundingTypeID | int | NO | - | VERIFIED | The payment method of the deposit. Joined to `Billing.Funding.FundingTypeID` in the redemption validation logic. Known values from History.FundingType: 1=CreditCard, 2=WireTransfer, 3=unknown (3rd type), 29=ACH (special-cased in GetRedeemValidationData). FK to History.FundingType and Dictionary.FundingType. |
| 4 | CancellationTimeInDays | int | NO | - | VERIFIED | Minimum number of days that must elapse from the customer's First Time Deposit (FTD) date before this funding type's deposits are eligible for redemption. Validated in `Billing.GetRedeemValidationData` as: `GETUTCDATE() >= DATEADD(day, CancellationTimeInDays, @FTDDate)`. Value of 60 means deposits using this funding type cannot be redeemed until 60 days after the FTD. |
| 5 | IsActive | bit | NO | - | VERIFIED | Whether this (FundingType, PlayerLevel) combination is currently eligible for redemption. 1=eligible, 0=blocked. `Billing.GetRedeemValidationData` filters `RS.IsActive=1`. When IsActive=0, deposits from this funding type do not count toward the customer's redeemable balance regardless of age. |
| 6 | TimeStamp | datetime | YES | - | CODE-BACKED | Application-managed original creation or modification timestamp for this setting row. Set by the application at INSERT time. In historical data this shows the original 2019 creation dates, even for rows whose ValidFrom is 2026, because the data content (and hence TimeStamp) didn't change - only the temporal metadata did. |
| 7 | SlidingDaysToIgnore | int | NO | 0 | NAME-INFERRED | A sliding window adjustment to the deposit eligibility calculation. Default=0 meaning no days are excluded. Non-zero values may exclude a recent window of days from the eligibility count. The precise calculation is not confirmed from available code evidence. All 38 history rows have SlidingDaysToIgnore=0. |
| 8 | Trace | nvarchar(733) | NO | - | CODE-BACKED | Computed JSON audit trail (copied value from source table's computed column). Contains: HostName, AppName (e.g., "SQLCMD" = manual admin change), SUserName (e.g., "BillingService_stg"), SPID, DBName, ObjectName. Identifies who/what made the change to the source row that caused this history entry to be created. |
| 9 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | UTC instant when this row became the current state in `Billing.RedeemFundingSettings`. Automatically managed by SQL Server's temporal system versioning (GENERATED ALWAYS AS ROW START in source). |
| 10 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | UTC instant when this row was superseded. Automatically set by SQL Server when the source row was updated or deleted. Leading key of the clustered index for efficient temporal range scans. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ID | Billing.RedeemFundingSettings | Temporal History | Each row is a past state of the source table row identified by this ID. |
| PlayerLevelID | Dictionary.PlayerLevel | Implicit (FK on source) | Customer tier: 1=Bronze, 2=Platinum, 3=Gold, 4=Internal, 5=Silver, 6=Platinum Plus, 7=Diamond. |
| FundingTypeID | History.FundingType / Dictionary.FundingType | Implicit | Payment method: 1=CreditCard, 2=WireTransfer, 29=ACH (from procedure code). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.RedeemFundingSettings | HISTORY_TABLE | Temporal History | Active source table - SQL Server automatically moves expired rows here. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.RedeemFundingSettings (table)
  (temporal history - no code-level dependencies; populated automatically by SQL Server from Billing.RedeemFundingSettings)
```

---

### 6.1 Objects This Depends On

No dependencies. Populated automatically by SQL Server temporal system versioning.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.RedeemFundingSettings | Table | Active source table - all expired rows archived here automatically |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_RedeemFundingSettings | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | Active |

Note: DATA_COMPRESSION = PAGE on both table and clustered index.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION = PAGE | Storage | Page compression for archival data. |

---

## 8. Sample Queries

### 8.1 View all historical redemption eligibility rule changes
```sql
SELECT
    h.ID,
    h.PlayerLevelID,
    dp.Name AS PlayerLevel,
    h.FundingTypeID,
    h.CancellationTimeInDays,
    h.IsActive,
    h.SlidingDaysToIgnore,
    h.ValidFrom,
    h.ValidTo,
    JSON_VALUE(h.Trace, '$.SUserName') AS ChangedBy
FROM [History].[RedeemFundingSettings] h WITH (NOLOCK)
JOIN [Dictionary].[PlayerLevel] dp WITH (NOLOCK) ON dp.PlayerLevelID = h.PlayerLevelID
ORDER BY h.ValidTo DESC, h.FundingTypeID, h.PlayerLevelID
```

### 8.2 What were the redemption rules for a specific funding type on a past date
```sql
-- Uses temporal query on source table (reads History automatically)
SELECT PlayerLevelID, FundingTypeID, CancellationTimeInDays, IsActive, SlidingDaysToIgnore
FROM [Billing].[RedeemFundingSettings]
FOR SYSTEM_TIME AS OF '2025-01-01T00:00:00'
WHERE FundingTypeID = @FundingTypeID
ORDER BY PlayerLevelID
```

### 8.3 Track configuration change history for a specific (FundingType, PlayerLevel) combination
```sql
SELECT
    ID,
    CancellationTimeInDays,
    IsActive,
    SlidingDaysToIgnore,
    ValidFrom AS EffectiveFrom,
    ValidTo AS EffectiveTo,
    JSON_VALUE(Trace, '$.AppName') AS ChangedByApp,
    JSON_VALUE(Trace, '$.SUserName') AS ChangedBy
FROM [History].[RedeemFundingSettings] WITH (NOLOCK)
WHERE FundingTypeID = @FundingTypeID
  AND PlayerLevelID = @PlayerLevelID
ORDER BY ValidFrom ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.1/10 (Elements: 9.0/10, Logic: 10/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.RedeemFundingSettings | Type: Table | Source: etoro/etoro/History/Tables/History.RedeemFundingSettings.sql*
