# Billing.PlayerLevelToCashoutFeeGroup

> System-versioned temporal mapping table assigning each eToro Club loyalty tier to a cashout fee group, determining whether a customer's withdrawal fees use the default schedule, exempt pricing, or a discount tier.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table (SYSTEM_VERSIONED temporal - current state) |
| **Key Identifier** | ID (INT IDENTITY, PK CLUSTERED) - natural key: (PlayerLevelID) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK clustered, FILLFACTOR=95) |
| **History Table** | History.PlayerLevelToCashoutFeeGroup |

---

## 1. Business Meaning

Billing.PlayerLevelToCashoutFeeGroup maps each eToro Club tier (Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond) to a cashout fee group, determining which withdrawal fee schedule applies when a customer of that loyalty tier requests a cashout. Higher loyalty tiers (Platinum, Platinum Plus, Diamond) are mapped to CashoutFeeGroupID=2 (Exempt) - they pay no/reduced withdrawal fees as a loyalty benefit. Lower tiers (Bronze, Silver, Gold) map to CashoutFeeGroupID=1 (Default) - standard fee schedule applies.

This table is used by ProcessCashoutFeeGroupUpdate, which also queries Billing.GuruStatusToCashoutFeeGroup - for Popular Investors (gurus), the higher of the two fee group IDs is selected (taking MAX). This means a Bronze-tier Popular Investor still gets the better fee treatment if their guru status warrants it.

The table is system-versioned (temporal): any change to a tier's fee group assignment is preserved in History.PlayerLevelToCashoutFeeGroup, enabling audit of when fee group assignments changed. The Trace computed column records which application/service made each modification.

---

## 2. Business Logic

### 2.1 Fee Group Assignment (Tier-Based)

**What**: Each player level has one active cashout fee group assignment.

**Columns/Parameters Involved**: `PlayerLevelID`, `CashoutFeeGroupID`

**Rules**:
- Current assignments (live data):
  - PlayerLevelID=1 (Bronze) -> CashoutFeeGroupID=1 (Default): Standard withdrawal fees apply.
  - PlayerLevelID=2 (Platinum) -> CashoutFeeGroupID=2 (Exempt): No/reduced withdrawal fees.
  - PlayerLevelID=3 (Gold) -> CashoutFeeGroupID=1 (Default): Standard fees.
  - PlayerLevelID=5 (Silver) -> CashoutFeeGroupID=1 (Default): Standard fees.
  - PlayerLevelID=6 (Platinum Plus) -> CashoutFeeGroupID=2 (Exempt): No/reduced fees.
  - PlayerLevelID=7 (Diamond) -> CashoutFeeGroupID=2 (Exempt): No/reduced fees.
  - PlayerLevelID=4 (Internal): No row - internal accounts handled separately.
- CashoutFeeGroupID=3 (Discount) exists in Dictionary.CashoutFeeGroup but is not currently assigned to any tier.

### 2.2 Guru Status Override (MAX Selection)

**What**: ProcessCashoutFeeGroupUpdate takes the higher of PlayerLevel fee group and GuruStatus fee group.

**Columns/Parameters Involved**: `CashoutFeeGroupID`, `PlayerLevelID`

**Rules**:
- ProcessCashoutFeeGroupUpdate: `SELECT MAX(FeeGroup) FROM PlayerLevelToCashoutFeeGroup UNION GuruStatusToCashoutFeeGroup`.
- If a Popular Investor (guru) has a higher fee group from their guru status, that overrides their player level assignment.
- @CountriesExcludedCashoutFeeGroupCalculation: Comma-separated country IDs where the fee group calculation does not apply. Customers from these countries retain their existing CashoutFeeGroupID unchanged.
- The result is written to BackOffice.Customer.CashoutFeeGroupID.

### 2.3 Temporal Audit Trail

**What**: All changes to fee group assignments are preserved in History.PlayerLevelToCashoutFeeGroup.

**Columns/Parameters Involved**: `ValidFrom`, `ValidTo`

**Rules**:
- ValidFrom/ValidTo: SQL Server system-versioning timestamps. ValidTo=9999-12-31 for current rows.
- On UPDATE: old values move to history with ValidTo=change timestamp.
- Trace column: records which app/SP made the change for accountability.

---

## 3. Data Overview

| PlayerLevelID | Level Name | CashoutFeeGroupID | Fee Group | Withdrawal Fee Treatment |
|--------------|------------|------------------|-----------|--------------------------|
| 1 | Bronze | 1 | Default | Standard withdrawal fees |
| 2 | Platinum | 2 | Exempt | No/reduced fees (loyalty benefit) |
| 3 | Gold | 1 | Default | Standard withdrawal fees |
| 5 | Silver | 1 | Default | Standard withdrawal fees |
| 6 | Platinum Plus | 2 | Exempt | No/reduced fees |
| 7 | Diamond | 2 | Exempt | No/reduced fees |

PlayerLevelID=4 (Internal): Not present - internal accounts not subject to this fee grouping.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate PK. Business lookups use PlayerLevelID. |
| 2 | PlayerLevelID | int | YES | NULL | VERIFIED | eToro Club loyalty tier. FK to Dictionary.PlayerLevel. Values: 1=Bronze, 2=Platinum, 3=Gold, 5=Silver, 6=Platinum Plus, 7=Diamond. Nullable (DEFAULT NULL) per constraint naming, but all 6 rows have values. |
| 3 | CashoutFeeGroupID | int | YES | NULL | VERIFIED | Cashout fee schedule group. FK to Dictionary.CashoutFeeGroup (WITH CHECK). Values: 1=Default (standard fees), 2=Exempt (no/reduced fees), 3=Discount (available but not currently assigned). Nullable per DEFAULT NULL constraint. |
| 4 | Trace | computed | - | - | CODE-BACKED | Non-persisted diagnostic JSON: host_name(), app_name(), suser_name(), @@spid, db_name(), object_name(@@procid). Identifies the application/SP that last modified the row. eToro's standard audit pattern. |
| 5 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | System-versioning temporal column (PERIOD START). UTC timestamp when this fee group assignment became active. Set by SQL Server. Used for point-in-time queries. |
| 6 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | System-versioning temporal column (PERIOD END). 9999-12-31 for current rows. Set to change timestamp when a row is updated/deleted. Old versions stored in History.PlayerLevelToCashoutFeeGroup. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PlayerLevelID | Dictionary.PlayerLevel | FK (FK__PlayerLev__Playe__5D3AE85B_TPL) | References eToro Club tier. WITH CHECK. |
| CashoutFeeGroupID | Dictionary.CashoutFeeGroup | FK (FK__PlayerLev__Casho__5F2330CD_TPL) | References fee schedule group. WITH CHECK. |
| (table) | History.PlayerLevelToCashoutFeeGroup | Temporal History | SQL Server writes old versions here on UPDATE/DELETE. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.ProcessCashoutFeeGroupUpdate | PlayerLevelID, CashoutFeeGroupID | SELECT reader | Resolves fee group for a customer's player level. Takes MAX with GuruStatusToCashoutFeeGroup. Updates BackOffice.Customer.CashoutFeeGroupID. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.PlayerLevelToCashoutFeeGroup (table)
  -> Dictionary.PlayerLevel (FK)
  -> Dictionary.CashoutFeeGroup (FK)
  -> History.PlayerLevelToCashoutFeeGroup (temporal history - auto-maintained)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.PlayerLevel | Table | FK target for PlayerLevelID |
| Dictionary.CashoutFeeGroup | Table | FK target for CashoutFeeGroupID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.ProcessCashoutFeeGroupUpdate | Stored Procedure | Reads fee group by PlayerLevelID to determine customer cashout fee tier |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PlayerLevelToCashoutFeeGroup | CLUSTERED PK | ID ASC | - | - | Active (FILLFACTOR=95) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_PlayerLevelToCashoutFeeGroup | PRIMARY KEY | ID clustered |
| FK__PlayerLev__Playe__5D3AE85B_TPL | FOREIGN KEY | PlayerLevelID -> Dictionary.PlayerLevel WITH CHECK |
| FK__PlayerLev__Casho__5F2330CD_TPL | FOREIGN KEY | CashoutFeeGroupID -> Dictionary.CashoutFeeGroup WITH CHECK |
| FK_PlayerLevelToCashoutFeeGroup_PlayerLevelID_TPL | DEFAULT | NULL for PlayerLevelID |
| FK_PlayerLevelToCashoutFeeGroup_CashoutFeeGroupID_TPL | DEFAULT | NULL for CashoutFeeGroupID |
| SYSTEM_VERSIONING = ON | Temporal | History table: History.PlayerLevelToCashoutFeeGroup |

---

## 8. Sample Queries

### 8.1 Get current fee group assignments with names

```sql
SELECT pl.PlayerLevelID, pl.PlayerLevelName, cfg.Name AS FeeGroup
FROM Billing.PlayerLevelToCashoutFeeGroup pltcfg WITH (NOLOCK)
JOIN Dictionary.PlayerLevel pl WITH (NOLOCK) ON pltcfg.PlayerLevelID = pl.PlayerLevelID
JOIN Dictionary.CashoutFeeGroup cfg WITH (NOLOCK) ON pltcfg.CashoutFeeGroupID = cfg.CashoutFeeGroupID
ORDER BY pl.PlayerLevelID
```

### 8.2 Get fee group for a specific player level

```sql
SELECT CashoutFeeGroupID
FROM Billing.PlayerLevelToCashoutFeeGroup WITH (NOLOCK)
WHERE PlayerLevelID = @PlayerLevelID
```

---

## 9. Atlassian Knowledge Sources

Code comment in Billing.ProcessCashoutFeeGroupUpdate references Shay Oren, 9/8/2020 - "Update CashoutFeeGroupID for customer according to PlayerLevel or GuruStatus".

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.PlayerLevelToCashoutFeeGroup | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.PlayerLevelToCashoutFeeGroup.sql*
