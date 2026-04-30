# Billing.ProcessCashoutFeeGroupUpdate

> Recomputes and applies the correct CashoutFeeGroupID to a customer's BackOffice.Customer record based on their current player level and guru status, excluding country-exempt customers - called by the withdrawal service to keep fee tiers synchronized.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID - the global customer ID to process |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.ProcessCashoutFeeGroupUpdate` is the fee-tier assignment engine for withdrawal fee calculation. When a customer's withdrawal is being processed, the withdrawal service (`WithdrawalServiceUser`) calls this procedure to ensure the customer is assigned to the correct cashout fee group - which determines what fee percentage or structure applies to their withdrawals.

The logic uses two dimensions to assign a fee group:
1. **Player Level** (`PlayerLevelID`): tiered based on trading activity or deposit history.
2. **Guru Status** (`GuruStatusID`): whether the customer is a Popular Investor / Guru.

When both dimensions have mappings, the procedure takes the MAX (highest/most favorable) fee group. Country-exempt customers (those in a configured exclusion list) are skipped entirely - no update occurs.

The procedure also returns whether the fee group actually changed (`@IsCashoutFeeGroupChanged`), enabling callers to react to the change (e.g., trigger downstream notifications or recalculations).

---

## 2. Business Logic

### 2.1 CID Resolution from GCID

**What**: Resolves the internal CID from the global customer identifier.

**Parameters Involved**: `@GCID`, `@CID`

**Rules**:
- SELECT @CID = CID FROM ... WHERE GCID = @GCID.
- @GCID is the global/external customer identifier; CID is the internal integer key used throughout the Billing schema.

### 2.2 Country Exclusion Check

**What**: Skips fee group update for customers in excluded countries.

**Parameters Involved**: `@CID`, country exclusion list

**Rules**:
- Reads a configured list of excluded country codes (via STRING_SPLIT or a lookup table).
- Looks up the customer's country.
- If the customer's country is in the exclusion list, the procedure exits without updating @IsCashoutFeeGroupChanged remains 0 (no change).
- This exempts certain regulated markets or promotional markets from standard cashout fee tiers.

### 2.3 Fee Group Computation

**What**: Computes the applicable CashoutFeeGroupID from player level and guru status mappings.

**Columns Involved**: Various lookup tables: `PlayerLevelToCashoutFeeGroup`, `GuruStatusToCashoutFeeGroup`

**Rules**:
- Looks up current PlayerLevelID for @CID.
- Looks up current GuruStatusID for @CID.
- Queries PlayerLevelToCashoutFeeGroup to get the fee group for the player level.
- Queries GuruStatusToCashoutFeeGroup to get the fee group for the guru status.
- Applies MAX(CashoutFeeGroupID) across the UNION of both results. This ensures the customer always receives the highest (most beneficial) fee tier when both dimensions have mappings.
- If neither dimension has a mapping, @NewCashoutFeeGroupID may be NULL.

### 2.4 Conditional Update

**What**: Updates the customer record only if the fee group has changed.

**Columns Involved**: `BackOffice.Customer.CashoutFeeGroupID`

**Rules**:
- Compares @NewCashoutFeeGroupID with the current BackOffice.Customer.CashoutFeeGroupID.
- Only executes UPDATE IF they differ (prevents unnecessary write operations).
- Sets @IsCashoutFeeGroupChanged = 1 when an update occurs; remains 0 if no change.
- UPDATE BackOffice.Customer SET CashoutFeeGroupID=@NewCashoutFeeGroupID WHERE CID=@CID.

**Diagram**:
```
@GCID
  |
  Resolve @CID
  |
  Check country exclusion list
    Excluded? -> EXIT (no update, @IsCashoutFeeGroupChanged=0)
  |
  SELECT PlayerLevelID for @CID
  SELECT GuruStatusID for @CID
  |
  SELECT MAX(CashoutFeeGroupID) FROM (
    SELECT CashoutFeeGroupID FROM PlayerLevelToCashoutFeeGroup WHERE PlayerLevelID=@PlayerLevelID
    UNION ALL
    SELECT CashoutFeeGroupID FROM GuruStatusToCashoutFeeGroup WHERE GuruStatusID=@GuruStatusID
  ) AS combined
  -> @NewCashoutFeeGroupID
  |
  Current = New?
    YES -> EXIT (@IsCashoutFeeGroupChanged=0)
    NO  ->
      UPDATE BackOffice.Customer SET CashoutFeeGroupID=@NewCashoutFeeGroupID
      @IsCashoutFeeGroupChanged=1
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int | NO | - | CODE-BACKED | Global customer identifier. Resolved to internal @CID before processing. The external-facing customer ID used by the withdrawal service. |
| 2 | @IsCashoutFeeGroupChanged | bit | YES | OUTPUT | CODE-BACKED | OUTPUT: 1 if the customer's CashoutFeeGroupID was updated, 0 if no change occurred (already correct, country-excluded, or no mapping found). Allows the caller to react to fee tier changes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.Customer | Read + Write | Reads current CashoutFeeGroupID; updates it if the computed value differs. |
| @CID | PlayerLevelToCashoutFeeGroup | Read (SELECT) | Gets the fee group for the customer's player level tier. |
| @CID | GuruStatusToCashoutFeeGroup | Read (SELECT) | Gets the fee group for the customer's guru/popular investor status. |
| Country exclusion | Country exclusion config | Read | Skips processing for exempt countries. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| WithdrawalServiceUser (db role) | - | EXEC | Called during withdrawal processing to ensure correct cashout fee group is applied before fee calculation. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.ProcessCashoutFeeGroupUpdate (procedure)
├── BackOffice.Customer (table) - READ current fee group, UPDATE if changed
├── PlayerLevelToCashoutFeeGroup (table) - READ fee group by player level
├── GuruStatusToCashoutFeeGroup (table) - READ fee group by guru status
└── Country exclusion config (table/config) - READ excluded countries
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | SELECT current CashoutFeeGroupID; UPDATE to new value if changed. |
| PlayerLevelToCashoutFeeGroup | Table | SELECT CashoutFeeGroupID for the customer's PlayerLevelID. |
| GuruStatusToCashoutFeeGroup | Table | SELECT CashoutFeeGroupID for the customer's GuruStatusID. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| WithdrawalServiceUser application role | Application | Invoked during withdrawal processing to synchronize cashout fee tier. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

The BackOffice.Customer UPDATE uses the CID primary key for a single-row seek. The fee group lookups use PlayerLevelID and GuruStatusID - these are small reference tables. The country exclusion check uses STRING_SPLIT or an in-memory comparison on small lists.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Update cashout fee group for a customer

```sql
DECLARE @Changed BIT;
EXEC Billing.ProcessCashoutFeeGroupUpdate
    @GCID = 12345,
    @IsCashoutFeeGroupChanged = @Changed OUTPUT;
SELECT @Changed AS WasUpdated;
-- 1 = fee group changed, 0 = no change needed
```

### 8.2 Check current cashout fee group for a customer

```sql
SELECT CID, CashoutFeeGroupID
FROM BackOffice.Customer WITH (NOLOCK)
WHERE CID = (SELECT CID FROM ... WHERE GCID = 12345);
```

### 8.3 Preview available fee group mappings

```sql
-- Player level fee groups
SELECT PlayerLevelID, CashoutFeeGroupID
FROM Billing.PlayerLevelToCashoutFeeGroup WITH (NOLOCK)
ORDER BY PlayerLevelID;

-- Guru status fee groups
SELECT GuruStatusID, CashoutFeeGroupID
FROM Billing.GuruStatusToCashoutFeeGroup WITH (NOLOCK)
ORDER BY GuruStatusID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.9/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.ProcessCashoutFeeGroupUpdate | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.ProcessCashoutFeeGroupUpdate.sql*
