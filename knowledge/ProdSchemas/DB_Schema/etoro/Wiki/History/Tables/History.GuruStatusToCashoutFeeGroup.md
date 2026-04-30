# History.GuruStatusToCashoutFeeGroup

> SQL Server system-versioned temporal history table for Billing.GuruStatusToCashoutFeeGroup, recording every change to the mapping between Popular Investor (Guru) status tiers and their assigned cashout fee group.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (ID, ValidFrom, ValidTo) - no formal PK; temporal history semantics |
| **Partition** | No (stored on [PRIMARY] filegroup) |
| **Indexes** | 1 (CLUSTERED on ValidTo ASC, ValidFrom ASC, DATA_COMPRESSION=PAGE) |

---

## 1. Business Meaning

This table is the automatically maintained historical version store for `Billing.GuruStatusToCashoutFeeGroup`. SQL Server's system-versioning manages this table transparently: whenever a row in `Billing.GuruStatusToCashoutFeeGroup` is inserted, updated, or deleted, the previous row state is written here with ValidFrom/ValidTo bracketing the validity window.

`Billing.GuruStatusToCashoutFeeGroup` maps each Popular Investor (Guru) status tier to a cashout fee treatment. Popular Investors at higher tiers - Rising Star, Champion, Elite, and Elite Pro - are categorized as "Exempt" from cashout fees as a reward for their contribution to the platform. Lower tiers - No Guru status, Certified, and Cadet - pay the "Default" cashout fee. This mapping drives the fee treatment applied when a guru requests a withdrawal.

The current mapping (unchanged since initial provisioning on 2021-09-19):

| Guru Status | Status Name | CashoutFeeGroup | Group Name |
|---|---|---|---|
| 0 | No | 1 | Default |
| 1 | Certified | 1 | Default |
| 2 | Cadet | 1 | Default |
| 3 | Rising Star | 2 | Exempt |
| 4 | Champion | 2 | Exempt |
| 5 | Elite | 2 | Exempt |
| 6 | Elite Pro | 2 | Exempt |

History table has 0 rows - the mapping has never been modified since initial setup.

---

## 2. Business Logic

### 2.1 Popular Investor Cashout Fee Exemption

**What**: Guru status tiers above "Cadet" are exempt from cashout fees as part of the Popular Investor rewards program.

**Columns/Parameters Involved**: `GuruStatusID`, `CashoutFeeGroupID`

**Rules**:
- FK to Dictionary.GuruStatus: 0=No, 1=Certified, 2=Cadet, 3=Rising Star, 4=Champion, 5=Elite, 6=Elite Pro, 7=Removed, 8=Rejected (last two not in this mapping - presumably ineligible)
- FK to Dictionary.CashoutFeeGroup: 1=Default (standard cashout fee applies), 2=Exempt (no cashout fee), 3=Discount (reduced fee, not assigned to any status in current config)
- One row per GuruStatusID (7 rows total for statuses 0-6)
- GuruStatusIDs 7 (Removed) and 8 (Rejected) have no entry - these statuses likely fall back to Default fee treatment

### 2.2 Trace Audit Pattern

**Columns/Parameters Involved**: `Trace`

**Rules**:
- Same JSON audit string pattern as Dictionary.FundingType: captures HostName, AppName, SUserName, SPID, DBName, ObjectName at change time
- Computed column in source: `concat('{"HostName": "',host_name(),...)`; materialized as nvarchar(733) in history

---

## 3. Data Overview

| ID | GuruStatusID | CashoutFeeGroupID | ValidFrom | ValidTo | Meaning |
|---|---|---|---|---|---|
| (empty) | (empty) | (empty) | (empty) | (empty) | 0 history rows. The 7-row mapping (GuruStatus 0-6 to fee groups) has been stable since initial provisioning 2021-09-19. Current rows in Billing.GuruStatusToCashoutFeeGroup have ValidTo=9999-12-31. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Surrogate identifier from Billing.GuruStatusToCashoutFeeGroup IDENTITY PK. 7 distinct values (one per guru status 0-6). |
| 2 | GuruStatusID | int | NO | - | VERIFIED | The guru/Popular Investor status tier. FK to Dictionary.GuruStatus: 0=No, 1=Certified, 2=Cadet, 3=Rising Star, 4=Champion, 5=Elite, 6=Elite Pro. Default NULL in source - overridden by application on insert. |
| 3 | CashoutFeeGroupID | int | NO | - | VERIFIED | The cashout fee group assigned to this status tier. FK to Dictionary.CashoutFeeGroup: 1=Default (standard fee), 2=Exempt (no fee), 3=Discount (reduced fee). Statuses 0-2 map to Default; statuses 3-6 map to Exempt. |
| 4 | Trace | nvarchar(733) | NO | - | CODE-BACKED | JSON audit string computed from execution context at change time: HostName, AppName, SUserName, SPID, DBName, ObjectName. Same pattern as Dictionary.FundingType.Trace. Materialized from computed column in source. |
| 5 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this mapping version became active. SQL Server GENERATED ALWAYS AS ROW START. All current rows show 2021-09-19 (initial provisioning). |
| 6 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this version was superseded. CLUSTERED index leading column. Current rows in source have ValidTo=9999-12-31T23:59:59.999 (never changed). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GuruStatusID | Dictionary.GuruStatus | Implicit | Popular Investor status tier. FK enforced on source. 0=No, 1=Certified, 2=Cadet, 3=Rising Star, 4=Champion, 5=Elite, 6=Elite Pro. |
| CashoutFeeGroupID | Dictionary.CashoutFeeGroup | Implicit | Cashout fee treatment group. FK enforced on source. 1=Default, 2=Exempt, 3=Discount. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GuruStatusToCashoutFeeGroup | SYSTEM_VERSIONING | Temporal history source | Superseded versions routed here. No INSERT trigger (pure temporal). |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.GuruStatusToCashoutFeeGroup (table)
- no code-level dependencies (leaf table, temporal history)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GuruStatusToCashoutFeeGroup | Table | Source temporal table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_GuruStatusToCashoutFeeGroup | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | Active (DATA_COMPRESSION=PAGE, on [PRIMARY] filegroup) |

### 7.2 Constraints

None. Temporal history tables have no PK, FK, CHECK, UNIQUE, or DEFAULT constraints.

### 7.3 Notes

- No INSERT trigger - pure SQL Server temporal versioning. New row insertions are NOT captured in history.
- Stored on [PRIMARY] despite source being in Billing schema (no dedicated Billing filegroup).
- FILLFACTOR=95 on source PK (very small stable table - 95% fill is fine for append-only patterns).

---

## 8. Sample Queries

### 8.1 What cashout fee group applied to a guru status on a specific date?

```sql
SELECT
    gsfg.ID,
    gsfg.GuruStatusID,
    gs.Name AS GuruStatusName,
    gsfg.CashoutFeeGroupID,
    cfg.Name AS CashoutFeeGroupName,
    gsfg.ValidFrom,
    gsfg.ValidTo
FROM Billing.GuruStatusToCashoutFeeGroup FOR SYSTEM_TIME AS OF '2024-01-01T00:00:00' gsfg WITH (NOLOCK)
JOIN Dictionary.GuruStatus gs WITH (NOLOCK) ON gs.GuruStatusID = gsfg.GuruStatusID
JOIN Dictionary.CashoutFeeGroup cfg WITH (NOLOCK) ON cfg.CashoutFeeGroupID = gsfg.CashoutFeeGroupID
WHERE gsfg.GuruStatusID = @GuruStatusID;
```

### 8.2 Full current mapping with status and fee group names

```sql
SELECT
    gsfg.ID,
    gsfg.GuruStatusID,
    gs.Name AS GuruStatusName,
    gsfg.CashoutFeeGroupID,
    cfg.Name AS CashoutFeeGroupName
FROM Billing.GuruStatusToCashoutFeeGroup gsfg WITH (NOLOCK)
JOIN Dictionary.GuruStatus gs WITH (NOLOCK) ON gs.GuruStatusID = gsfg.GuruStatusID
JOIN Dictionary.CashoutFeeGroup cfg WITH (NOLOCK) ON cfg.CashoutFeeGroupID = gsfg.CashoutFeeGroupID
ORDER BY gsfg.GuruStatusID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.1/10 (Elements: 9/10, Logic: 9/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.GuruStatusToCashoutFeeGroup | Type: Table | Source: etoro/etoro/History/Tables/History.GuruStatusToCashoutFeeGroup.sql*
