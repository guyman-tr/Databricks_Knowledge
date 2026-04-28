# BI_DB_dbo.BI_DB_AffData

> **DORMANT — 0 rows, no writer SP.** Legacy affiliate data table with customer-to-affiliate mapping, contract details, and marketing channel attribution. Has PII masking on email. PK on (RealCID, AffiliateID). No ETL process exists in Synapse SSDT — likely a migration artifact from on-prem BI_DB that was never re-implemented in the cloud DWH. Only referenced in permission/masking scripts.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Unknown — no writer SP in SSDT repository |
| **Refresh** | **DORMANT** — no ETL process populates this table |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **Row Count** | 0 |
| **Primary Key** | (RealCID, AffiliateID) NOT ENFORCED |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_AffData` was designed to store **customer-to-affiliate mapping** data — linking each customer (RealCID) to their referring affiliate (AffiliateID) with affiliate metadata including registration date, login credentials, contract details, language, group classification, and marketing channel.

The table is currently **empty (0 rows)** and has **no writer stored procedure** in the Synapse SSDT repository. It is only referenced in PII masking permission scripts (DataplatformPII role for Aff_Email masking) and the Admin_PostRestore sanitization procedure. This strongly suggests the table was migrated from the on-prem BI_DB SQL Server but the corresponding ETL was never re-implemented in Synapse.

The affiliate data this table was intended to hold is likely now served by other BI_DB affiliate tables (BI_DB_AffID_Dictionary, BI_DB_Affiliate_Report, BI_DB_AffiliateLifeCycle) which ARE actively populated.

---

## 2. Business Logic

### 2.1 Customer-Affiliate Mapping (Inferred from Schema)

**What**: Maps customers to their referring affiliates with a composite primary key.
**Columns Involved**: RealCID, AffiliateID
**Rules**:
- Composite PK suggests one customer can have multiple affiliate relationships
- RealCID follows the standard "original customer ID" pattern used across the DWH

### 2.2 PII Protection

**What**: Email column is protected with dynamic data masking.
**Columns Involved**: Aff_Email
**Rules**:
- Masked with `FUNCTION = 'default()'` — returns 'XXXX' for unauthorized users
- DataplatformPII role has UNMASK permission

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP with NOT ENFORCED primary key on (RealCID, AffiliateID). No performance considerations as table is empty.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Affiliate data for a customer | Use BI_DB_AffID_Dictionary or BI_DB_Affiliate_Report instead — this table is empty |
| Historical affiliate contracts | Check if on-prem BI_DB still serves this data |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| DWH_dbo.Dim_Customer | RealCID = RealCID | Customer details (theoretical) |
| BI_DB_AffID_Dictionary | AffiliateID = AffiliateID | Affiliate name/details (theoretical) |

### 3.4 Gotchas

- **Table is empty**: 0 rows — do not rely on this table for any reporting
- **No writer SP**: No ETL process exists to populate this table in Synapse
- **Use alternatives**: BI_DB_AffID_Dictionary, BI_DB_Affiliate_Report, BI_DB_AffiliateLifeCycle are actively populated affiliate tables
- **PII masking**: Aff_Email requires DataplatformPII role for unmasked access

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 4 | Inferred from column name and DDL context | Medium — no data or SP to verify |
| Tier 5 | Standard ETL metadata | Canonical description |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | NO | Original customer ID (the real/root CID before any account migration or merge). PK part 1. Standard DWH customer identifier. (Tier 4 — inferred from naming convention) |
| 2 | AffiliateID | int | NO | Affiliate partner identifier from the fiktivo affiliate system. PK part 2. One customer can map to multiple affiliates. (Tier 4 — inferred from naming convention) |
| 3 | Aff_Registration | datetime | YES | Date when the affiliate registered in the partner program. (Tier 4 — inferred from column name) |
| 4 | Aff_LoginName | nvarchar(50) | YES | Affiliate's login username in the partner portal. (Tier 4 — inferred from column name) |
| 5 | Aff_Email | varchar(50) | YES | Affiliate's email address. Protected with dynamic data masking (default function). Requires DataplatformPII role for unmasked access. (Tier 4 — inferred from column name) |
| 6 | ContractName | varchar(100) | YES | Name of the affiliate's commission contract (e.g., CPA, Revenue Share, Hybrid). (Tier 4 — inferred from column name) |
| 7 | ContractType | varchar(20) | YES | Classification of the contract arrangement type. (Tier 4 — inferred from column name) |
| 8 | Aff_eLanguage | nvarchar(255) | YES | Affiliate's preferred language for communications and portal interface. (Tier 4 — inferred from column name) |
| 9 | AffGroup | nvarchar(50) | YES | Affiliate group or tier classification (e.g., VIP, Standard, Premium). (Tier 4 — inferred from column name) |
| 10 | Channel | varchar(50) | NO | Marketing channel through which the affiliate operates (e.g., web, social, email). (Tier 4 — inferred from column name) |
| 11 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Tier 5 — standard ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| All columns | Unknown | Unknown | No writer SP exists in SSDT — source cannot be traced |

### 5.2 ETL Pipeline

```
Unknown Production Source (likely fiktivo affiliate system)
  |-- [NO ETL PIPELINE EXISTS IN SYNAPSE] ---|
  v
BI_DB_dbo.BI_DB_AffData (0 rows — DORMANT)

NOTE: Table structure exists but no SP, External Table, or COPY INTO
      process populates it. Likely a legacy on-prem migration artifact.
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| RealCID | DWH_dbo.Dim_Customer | Customer dimension (theoretical — table is empty) |
| AffiliateID | BI_DB_dbo.BI_DB_AffID_Dictionary | Affiliate lookup (theoretical) |

### 6.2 Referenced By (other objects point to this)

No known consumers — table is empty and has no active ETL.

---

## 7. Sample Queries

### 7.1 Verify Table Is Still Empty

```sql
SELECT COUNT(*) AS row_count
FROM [BI_DB_dbo].[BI_DB_AffData]
```

### 7.2 Check Masking Configuration (Admin)

```sql
SELECT c.name AS column_name, mc.masking_function
FROM sys.masked_columns mc
JOIN sys.columns c ON mc.object_id = c.object_id AND mc.column_id = c.column_id
WHERE mc.object_id = OBJECT_ID('BI_DB_dbo.BI_DB_AffData')
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this dormant table.

---

*Generated: 2026-04-27 | Quality: 7.0/10 | Phases: 14/14*
*Tiers: 0 T1, 0 T2, 0 T3, 10 T4, 1 T5 | Elements: 11/11, Logic: 5/10, Completeness: 7/10*
*Object: BI_DB_dbo.BI_DB_AffData | Type: Table | Production Source: Unknown (dormant)*
