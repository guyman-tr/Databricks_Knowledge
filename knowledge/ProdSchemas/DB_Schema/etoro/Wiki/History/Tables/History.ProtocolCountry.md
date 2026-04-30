# History.ProtocolCountry

> Temporal history backing table for Billing.ProtocolCountry - storing all past versions of the per-country payment protocol whitelist/blacklist provider configuration used in the billing routing system.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - clustered on (ValidTo, ValidFrom) |
| **Partition** | No (ON [PRIMARY] filegroup) |
| **Indexes** | 1 (1 clustered temporal) |

---

## 1. Business Meaning

`History.ProtocolCountry` is the **temporal history backing table** for `Billing.ProtocolCountry`. SQL Server's system-versioned temporal tables automatically move old rows here whenever the live table is updated or deleted. This table is never written to directly.

The live table `Billing.ProtocolCountry` controls which payment protocols are available for each country - the core routing table for the billing system. Each row maps a payment protocol (e.g., a credit card processor, bank transfer method, or digital wallet) to a specific country, optionally flagging whether providers using that protocol in that country are whitelisted or blacklisted for routing purposes.

With 13,043 history rows and very high churn (multiple changes observed within the same day), this table reflects active operational management of payment method availability by country. Changes are driven by regulatory requirements, fraud prevention, or provider onboarding/offboarding events.

The temporal columns use `ValidFrom`/`ValidTo` naming (rather than the standard `SysStartTime`/`SysEndTime`) and are declared HIDDEN on the live table - they do not appear in `SELECT *` queries, reducing accidental exposure of temporal metadata.

---

## 2. Business Logic

### 2.1 SQL Server Temporal Table - Automatic Versioning (HIDDEN Period Columns)

**What**: Every change to Billing.ProtocolCountry automatically writes the previous version here.

**Columns/Parameters Involved**: `ValidFrom`, `ValidTo`

**Rules**:
- `ValidFrom` = UTC timestamp when this protocol-country mapping became active
- `ValidTo` = UTC timestamp when this mapping was superseded
- Columns declared as `GENERATED ALWAYS AS ROW START/END HIDDEN` on the live table - not visible in SELECT *
- Query via `FOR SYSTEM_TIME AS OF` on the live table to reconstruct past states

**Diagram**:
```
Billing.ProtocolCountry (live - current protocol/country routing rules)
    SYSTEM_VERSIONING = ON (HISTORY_TABLE = History.ProtocolCountry)
    ValidFrom/ValidTo are HIDDEN period columns
    |
    v
History.ProtocolCountry (this table - past routing configurations)
```

### 2.2 Provider Whitelist/Blacklist Control

**What**: IsWhitelistedProvider and IsBlacklistedProvider flags control provider routing eligibility for each protocol-country pair.

**Columns/Parameters Involved**: `ProtocolID`, `CountryID`, `IsWhitelistedProvider`, `IsBlacklistedProvider`

**Rules**:
- Both flags NULL = standard routing (no explicit white/blacklist override)
- IsWhitelistedProvider=1: providers using this protocol in this country are explicitly approved
- IsBlacklistedProvider=1: providers using this protocol in this country are blocked
- Both NULL is the most common state (from live data: IsWhitelistedProvider and IsBlacklistedProvider both NULL for observed rows)
- The billing routing procedures (Billing.GetCCProcessingBundle, Billing.GetCountryProtocols) read these flags to determine valid payment paths

---

## 3. Data Overview

13,043 rows. High churn - multiple changes per day observed. Active regulatory management.

| ProtocolID | CountryID | ValidFrom | ValidTo | IsWhitelistedProvider | IsBlacklistedProvider | Context |
|---|---|---|---|---|---|---|
| 23 | 79 | 2026-03-21 04:54:01 | 2026-03-21 04:55:03 | NULL | NULL | Protocol 23/Country 79 mapping active for ~62 seconds |
| 23 | 79 | 2026-03-21 02:02:34 | 2026-03-21 04:54:01 | NULL | NULL | Prior configuration active for ~2.9 hours |
| 43 | 79 | 2026-03-20 04:52:04 | 2026-03-21 02:02:34 | NULL | NULL | Different protocol (43) for same country, next day |

*Rapid transitions (seconds apart) suggest automated or high-frequency routing updates.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProtocolID | int | NO | - | CODE-BACKED | Payment protocol ID. FK to Dictionary.Protocol(ProtocolID) via the live Billing.ProtocolCountry table. Identifies the payment method type (credit card processor, bank transfer, etc.) in the billing routing system. |
| 2 | CountryID | int | NO | - | CODE-BACKED | Country for which this protocol is configured. FK to Dictionary.Country(CountryID) via the live table. Drives country-specific payment method availability. |
| 3 | ValidFrom | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this protocol-country mapping became active in Billing.ProtocolCountry. Declared as GENERATED ALWAYS AS ROW START HIDDEN on the live table. Starting boundary of validity period (inclusive). |
| 4 | ValidTo | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this mapping was superseded. Declared as GENERATED ALWAYS AS ROW END HIDDEN on the live table. Ending boundary of validity period (exclusive). Clustered index leading column for temporal queries. |
| 5 | IsWhitelistedProvider | bit | YES | - | CODE-BACKED | When 1, providers using this protocol in this country are explicitly approved for routing. NULL = no explicit whitelist (standard routing applies). Checked by billing routing procedures. |
| 6 | IsBlacklistedProvider | bit | YES | - | CODE-BACKED | When 1, providers using this protocol in this country are blocked from routing. NULL = no explicit blacklist. Overrides standard routing to prevent use of specific protocol-country combinations. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProtocolID | Dictionary.Protocol | Implicit (FK on live table) | The payment protocol type |
| CountryID | Dictionary.Country | Implicit (FK on live table) | The country these routing rules apply to |
| (all columns) | Billing.ProtocolCountry | Temporal | This is the history backing table for the live Billing table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Server temporal engine | (auto) | System | Rows moved here automatically when Billing.ProtocolCountry is modified |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ProtocolCountry (table)
(temporal history backing table - no code-level dependencies)
```

---

### 6.1 Objects This Depends On

No dependencies. Written entirely by SQL Server temporal table engine.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.ProtocolCountry | Table | Live table - SQL Server moves expired rows here automatically |
| Billing.GetCCProcessingBundle | Stored Procedure | Reads live table (may use FOR SYSTEM_TIME) for payment routing |
| Billing.GetCCProcessingBundleByBin | Stored Procedure | Reads live table for BIN-based routing decisions |
| Billing.GetCountryProtocols | Stored Procedure | Reads live table to retrieve valid protocols for a country |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_ProtocolCountry | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | Active |

*DATA_COMPRESSION=PAGE. Clustered on (ValidTo, ValidFrom) - standard temporal history pattern. ValidFrom/ValidTo use non-standard naming (vs SysStartTime/SysEndTime) but serve the same purpose.*

### 7.2 Constraints

None (FK constraints enforced on live Billing.ProtocolCountry table).

---

## 8. Sample Queries

### 8.1 Point-in-time protocol-country configuration (via live table)

```sql
SELECT ProtocolID, CountryID, IsWhitelistedProvider, IsBlacklistedProvider
FROM Billing.ProtocolCountry
FOR SYSTEM_TIME AS OF '2025-01-01 00:00:00'
WHERE CountryID = @CountryID
```

### 8.2 Full change history for a specific protocol-country pair

```sql
SELECT ProtocolID, CountryID, ValidFrom, ValidTo, IsWhitelistedProvider, IsBlacklistedProvider,
    DATEDIFF(SECOND, ValidFrom, ValidTo) AS ActiveDurationSeconds
FROM History.ProtocolCountry WITH (NOLOCK)
WHERE ProtocolID = @ProtocolID AND CountryID = @CountryID
ORDER BY ValidFrom ASC
```

### 8.3 Most recently changed protocol-country mappings

```sql
SELECT TOP 20 ProtocolID, CountryID, ValidFrom, ValidTo, IsWhitelistedProvider, IsBlacklistedProvider
FROM History.ProtocolCountry WITH (NOLOCK)
ORDER BY ValidTo DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ProtocolCountry | Type: Table | Source: etoro/etoro/History/Tables/History.ProtocolCountry.sql*
