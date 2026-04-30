# Billing.GuruStatusToCashoutFeeGroup

> Configuration table mapping popular investor (Guru) tier levels to cashout fee groups; Rising Star and above are exempt from withdrawal fees, while lower tiers (No/Certified/Cadet) pay the default cashout fee.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | ID - IDENTITY PK CLUSTERED |
| **Partition** | N/A - PRIMARY filegroup |
| **Indexes** | 1 (PK on ID) |
| **System-Versioned** | YES - History.GuruStatusToCashoutFeeGroup |

---

## 1. Business Meaning

`Billing.GuruStatusToCashoutFeeGroup` defines the cashout fee treatment for customers based on their Popular Investor ("Guru") program tier. The table maps 7 GuruStatus levels to one of 3 cashout fee groups:

| GuruStatusID | GuruStatus Name | CashoutFeeGroupID | Fee Group |
|---|---|---|---|
| 0 | No (not a Popular Investor) | 1 | Default (pays standard cashout fees) |
| 1 | Certified | 1 | Default |
| 2 | Cadet | 1 | Default |
| 3 | Rising Star | 2 | **Exempt** (no cashout fees) |
| 4 | Champion | 2 | **Exempt** |
| 5 | Elite | 2 | **Exempt** |
| 6 | Elite Pro | 2 | **Exempt** |

**Key business rule**: Popular Investors at Rising Star tier and above are EXEMPT from cashout fees. This is an incentive for high-quality Popular Investors to remain on the platform.

`ProcessCashoutFeeGroupUpdate` implements the assignment logic: it takes the MAXIMUM of the CashoutFeeGroupID derived from the customer's PlayerLevel (via `Billing.PlayerLevelToCashoutFeeGroup`) and the GuruStatus-based group from this table. A customer benefits from whichever gives a higher (more favorable) fee group.

The table is system-versioned - changes to the mapping are tracked in History.GuruStatusToCashoutFeeGroup.

---

## 2. Business Logic

### 2.1 GuruStatus-to-FeeGroup Tier Threshold

**What**: Tier 3+ (Rising Star) triggers fee exemption. Tiers 0-2 pay default fees.

**Columns/Parameters Involved**: `GuruStatusID`, `CashoutFeeGroupID`

**Rules**:
```
GuruStatusID 0 (No PI) -> CashoutFeeGroupID=1 (Default) = pays standard fees
GuruStatusID 1 (Certified) -> CashoutFeeGroupID=1 (Default) = pays standard fees
GuruStatusID 2 (Cadet) -> CashoutFeeGroupID=1 (Default) = pays standard fees
GuruStatusID 3 (Rising Star) -> CashoutFeeGroupID=2 (Exempt) = NO cashout fees
GuruStatusID 4 (Champion) -> CashoutFeeGroupID=2 (Exempt) = NO cashout fees
GuruStatusID 5 (Elite) -> CashoutFeeGroupID=2 (Exempt) = NO cashout fees
GuruStatusID 6 (Elite Pro) -> CashoutFeeGroupID=2 (Exempt) = NO cashout fees

Note: GuruStatusID=7 (Removed) and 8 (Rejected) are NOT in this table.
  -> These statuses are not assigned a fee group here, treated as default by consumers.
```

### 2.2 MAX Logic with PlayerLevel (ProcessCashoutFeeGroupUpdate)

**What**: The effective CashoutFeeGroupID is the MAXIMUM of the GuruStatus-based and PlayerLevel-based fee groups. The customer always benefits from the most favorable (highest-numbered) group.

**Columns/Parameters Involved**: `GuruStatusID`, `CashoutFeeGroupID` (this table) + `PlayerLevelToCashoutFeeGroup`

**Rules**:
```
ProcessCashoutFeeGroupUpdate(@CID):
  1. Lookup PlayerLevel-based CashoutFeeGroupID from Billing.PlayerLevelToCashoutFeeGroup
  2. Lookup GuruStatus-based CashoutFeeGroupID from Billing.GuruStatusToCashoutFeeGroup (this table)
  3. EffectiveCashoutFeeGroupID = MAX(PlayerLevel-based, GuruStatus-based)
     -> CashoutFeeGroup values: 1=Default < 2=Exempt < 3=Discount
     -> A PopularInvestor at Elite tier (GuruStatus=5, FeeGroup=2/Exempt) AND
        a low PlayerLevel (FeeGroup=1/Default) -> takes max(1, 2) = 2 (Exempt)
  4. UPDATE BackOffice.Customer.CashoutFeeGroupID = MAX value (only if changed)
```

### 2.3 Country Exclusion

**What**: ProcessCashoutFeeGroupUpdate accepts a comma-separated list of excluded country codes. Customers in excluded countries skip the fee group update.

**Rules**:
```
@CountriesExcludedCashoutFeeGroupCalculation (e.g., 'US,GB,AU'):
  -> If customer's CountryID is in this list: no update, CashoutFeeGroupID unchanged
  -> If not in list: proceed with MAX(PlayerLevel, GuruStatus) calculation
```

---

## 3. Data Overview

| ID | GuruStatusID | GuruStatus | CashoutFeeGroupID | Fee Group |
|----|-------------|------------|------------------|-----------|
| 1 | 0 | No (not a PI) | 1 | Default - regular customer pays cashout fees |
| 2 | 1 | Certified | 1 | Default - entry-level PI still pays fees |
| 3 | 2 | Cadet | 1 | Default - learning PI still pays fees |
| 4 | 3 | Rising Star | 2 | Exempt - fee exemption begins at Rising Star |
| 5 | 4 | Champion | 2 | Exempt |
| 6 | 5 | Elite | 2 | Exempt |
| 7 | 6 | Elite Pro | 2 | Exempt - highest active tier, fully exempt |

GuruStatusID 7 (Removed) and 8 (Rejected) not mapped - treated as default externally.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY(1,1) | NO | auto | VERIFIED | Surrogate PK. Auto-incremented row identifier. Not the natural business key - lookups are by GuruStatusID. |
| 2 | GuruStatusID | int | YES | NULL | VERIFIED | Popular Investor tier level. FK to Dictionary.GuruStatus(GuruStatusID) via unnamed FK. DEFAULT NULL (unusual - should always be set). 7 values mapped: 0=No, 1=Certified, 2=Cadet, 3=Rising Star, 4=Champion, 5=Elite, 6=Elite Pro. |
| 3 | CashoutFeeGroupID | int | YES | NULL | VERIFIED | Cashout fee treatment for this Guru tier. FK to Dictionary.CashoutFeeGroup(CashoutFeeGroupID). DEFAULT NULL (unusual - should always be set). 1=Default (fees apply), 2=Exempt (no fees), 3=Discount (reduced fees - not used for any GuruStatus). |
| 4 | Trace | computed | NO | - | VERIFIED | Non-persisted JSON audit string (HostName, AppName, SUserName, SPID, DBName, ObjectName). Same pattern across temporal tables. |
| 5 | ValidFrom | datetime2(7) | NO | - | VERIFIED | System-time start. GENERATED ALWAYS AS ROW START. |
| 6 | ValidTo | datetime2(7) | NO | - | VERIFIED | System-time end. GENERATED ALWAYS AS ROW END. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GuruStatusID | Dictionary.GuruStatus | FK (explicit) | Popular Investor tier level |
| CashoutFeeGroupID | Dictionary.CashoutFeeGroup | FK (explicit) | Cashout fee treatment (Default/Exempt/Discount) |
| (history) | History.GuruStatusToCashoutFeeGroup | System-Versioning | Temporal history of mapping changes |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.ProcessCashoutFeeGroupUpdate | GuruStatusID, CashoutFeeGroupID | READER | Looks up fee group by GuruStatusID and takes MAX with PlayerLevel-based group |
| Billing.PlayerLevelToCashoutFeeGroup | CashoutFeeGroupID | RELATED | Sibling table - PlayerLevel-based fee groups; MAX of both tables applied per customer |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GuruStatusToCashoutFeeGroup (table)
|- Dictionary.GuruStatus (table)       [FK: GuruStatusID]
|- Dictionary.CashoutFeeGroup (table)  [FK: CashoutFeeGroupID]
|- History.GuruStatusToCashoutFeeGroup [temporal history]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.GuruStatus | Table | FK target - Popular Investor tier levels |
| Dictionary.CashoutFeeGroup | Table | FK target - fee group definitions (Default/Exempt/Discount) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.ProcessCashoutFeeGroupUpdate | Stored Procedure | READER - UNION with PlayerLevelToCashoutFeeGroup, takes MAX |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (unnamed) | CLUSTERED PK | ID ASC | - | - | Active (FILLFACTOR 95) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK (clustered) | PRIMARY KEY | ID - unique row |
| FK (unnamed) | FOREIGN KEY | CashoutFeeGroupID must exist in Dictionary.CashoutFeeGroup |
| FK (unnamed) | FOREIGN KEY | GuruStatusID must exist in Dictionary.GuruStatus |
| FK_GuruStatusToCashoutFeeGroup_GuruStatusID_TPL | DEFAULT | GuruStatusID defaults to NULL |
| FK_GuruStatusToCashoutFeeGroup_CashoutFeeGroupID_TPL | DEFAULT | CashoutFeeGroupID defaults to NULL |

### 7.3 Temporal History

| Property | Value |
|----------|-------|
| System-Versioning | ON |
| History Table | History.GuruStatusToCashoutFeeGroup |
| ValidFrom/ValidTo | datetime2(7) GENERATED ALWAYS AS ROW START/END |

---

## 8. Sample Queries

### 8.1 Get cashout fee group for a customer based on GuruStatus
```sql
SELECT  GS.Name         AS GuruStatusName,
        CFG.Name        AS CashoutFeeGroup,
        GSCFG.GuruStatusID,
        GSCFG.CashoutFeeGroupID
FROM    Billing.GuruStatusToCashoutFeeGroup GSCFG WITH (NOLOCK)
INNER JOIN Dictionary.GuruStatus GS WITH (NOLOCK)
        ON GSCFG.GuruStatusID = GS.GuruStatusID
INNER JOIN Dictionary.CashoutFeeGroup CFG WITH (NOLOCK)
        ON GSCFG.CashoutFeeGroupID = CFG.CashoutFeeGroupID
ORDER BY GSCFG.GuruStatusID;
```

### 8.2 Find all customers with GuruStatus-based fee exemption
```sql
SELECT  BC.CID,
        GS.Name     AS GuruStatus,
        CFG.Name    AS CashoutFeeGroup
FROM    BackOffice.Customer BC WITH (NOLOCK)
INNER JOIN Dictionary.GuruStatus GS WITH (NOLOCK)
        ON BC.GuruStatusID = GS.GuruStatusID
INNER JOIN Billing.GuruStatusToCashoutFeeGroup GSCFG WITH (NOLOCK)
        ON GSCFG.GuruStatusID = BC.GuruStatusID
INNER JOIN Dictionary.CashoutFeeGroup CFG WITH (NOLOCK)
        ON GSCFG.CashoutFeeGroupID = CFG.CashoutFeeGroupID
WHERE   GSCFG.CashoutFeeGroupID = 2  -- Exempt
ORDER BY GS.Name, BC.CID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this specific table.

---

*Generated: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GuruStatusToCashoutFeeGroup | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.GuruStatusToCashoutFeeGroup.sql*
