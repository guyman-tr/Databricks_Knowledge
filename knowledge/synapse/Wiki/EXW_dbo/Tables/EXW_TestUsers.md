# EXW_dbo.EXW_TestUsers

> 958-row curated list of test/internal user accounts in the eToro Wallet (EXW) system, refreshed periodically from DWH_dbo.Dim_Customer. Identifies users by username patterns (redeemprod, betatester, walletprod, etc.), specific named accounts, and Beta users (email LIKE %test@test.com% AND PlayerLevelID=4). Used by SP_DimUser to set the IsTestAccount flag in EXW_DimUser.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Customer.CustomerStatic (via DWH_dbo.Dim_Customer) |
| **Writer SP** | EXW_dbo.SP_EXW_TestUsers |
| **Refresh** | Periodic (incremental merge — INSERT new, UPDATE changed, DELETE duplicates) |
| **Row Count** | 958 rows |
| **Date Range** | UpdateDate: 2020-09-29 to 2026-03-20 |
| **Synapse Distribution** | HASH(GCID) |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — utility table, not exported to data lake |

---

## 1. Business Meaning

This table is a curated allowlist of test and internal users operating in the eToro Wallet (EXW) environment. It is maintained automatically by SP_EXW_TestUsers, which queries DWH_dbo.Dim_Customer and filters to accounts that match known test-user patterns (username substrings like `redeemprod`, `betatester`, `walletprod`, `internalprod`, `nowalletprod`), specific named individuals, or Beta tester accounts (email LIKE %test@test.com% with PlayerLevelID=4).

The table holds 958 rows as of the last refresh (March 2026), spanning users inserted from 2020 onwards. Its primary consumer is SP_DimUser, which LEFT JOINs on GCID to mark users as test accounts within EXW_DimUser. This ensures that analytics built on EXW_DimUser can easily exclude test traffic from production metrics.

The SP uses an UPSERT pattern: it inserts new test users discovered in Dim_Customer, updates existing rows when UserName or Email changes, and removes duplicates via a ROW_NUMBER() dedup step.

---

## 2. Business Logic

### 2.1 Test User Classification Criteria

**What**: Two disjoint sets of users are classified as test users, combined via UNION.

**Columns Involved**: UserName, Email, GCID (filter inputs); RealCID, GCID, UserName, Email (output)

**Rules**:
- **Set A — Username pattern matching**: Any Dim_Customer row where LOWER(UserName) contains `redeemprod`, `betatester`, `walletprod`, `internalprod`, or ends with `nowalletprod`; or specific named users (`RonaMaltz`, `DanGanon`) or GCID=43163939
- **Set B — Beta users**: Dim_Customer rows where LOWER(Email) LIKE '%test@test.com%' AND PlayerLevelID=4
- UNION deduplicates by GCID before any INSERT

### 2.2 Incremental Merge Pattern

**What**: The SP does not truncate-reload — it merges changes incrementally, preserving the history of UpdateDate per row.

**Columns Involved**: GCID (join key), UserName, Email, UpdateDate

**Rules**:
- UPDATE existing rows only when UserName or Email has changed; sets UpdateDate = GETDATE()
- INSERT new test users not yet in the table; sets UpdateDate = GETDATE() at insert time
- DELETE duplicates: rows where ROW_NUMBER() OVER (PARTITION BY RealCID, GCID, UserName, Email) = 2 are removed (keeps the first occurrence)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(GCID) with HEAP. EXW_DimUser is also distributed on HASH(GCID), ensuring co-located JOINs in SP_DimUser with zero data movement. HEAP is appropriate for this small utility table (958 rows).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Is a specific user a test account? | `SELECT 1 FROM EXW_dbo.EXW_TestUsers WHERE GCID = @gcid` |
| All test users | `SELECT GCID, UserName, Email FROM EXW_dbo.EXW_TestUsers` |
| Exclude test users from a wallet query | `LEFT JOIN EXW_dbo.EXW_TestUsers tu ON t.GCID = tu.GCID WHERE tu.GCID IS NULL` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_dbo.EXW_DimUser | `EXW_DimUser.GCID = EXW_TestUsers.GCID` (via IsTestAccount) | Identify test users in the main dimension |
| DWH_dbo.Dim_Customer | `Dim_Customer.GCID = EXW_TestUsers.GCID` | Enrich test user records with DWH attributes |

### 3.4 Gotchas

- **RealCID can be NULL**: GCID is the reliable join key. SP writes RealCID from Dim_Customer but it is nullable.
- **Dedup uses ROW_NUMBER() DELETE**: The SP deletes `WHERE RN = 2` — this removes the second occurrence but retains the first. If rows are inadvertently duplicated during an out-of-order run, re-running the SP will clean them.
- **SP uses NOLOCK on Dim_Customer** (`WITH (NOLOCK)`) — not needed in Synapse (snapshot isolation), but harmless.
- **958 rows only**: This is a small list. It does NOT include all internal users — only those matching the specific patterns in SP_EXW_TestUsers. New test account patterns require SP code changes.
- **No automatic removal**: If a test user changes their username so it no longer matches a pattern, they remain in EXW_TestUsers indefinitely (the SP only adds/updates, never removes due to pattern mismatch).

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production DB wiki |
| Tier 2 | Derived from SP code (source-to-target mapping confirmed in code) |
| Tier 3 | Inferred from column name, type, and surrounding context |
| Tier 4 | Best available — limited lineage confidence |
| Tier 5 | Glossary or domain knowledge only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) |
| 2 | GCID | int | YES | Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. HASH distribution key for this table. (Tier 1 — Customer.CustomerStatic) |
| 3 | UserName | varchar(100) | YES | Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). (Tier 1 — Customer.CustomerStatic) |
| 4 | Email | varchar(100) | YES | Customer email address. Unique (case-insensitive via LowerEmail computed column). Email changes trigger Customer.LastChanges update via trigger. (Tier 1 — Customer.CustomerStatic) |
| 5 | UpdateDate | datetime | YES | ETL timestamp set to GETDATE() at INSERT time; refreshed on UPDATE when UserName or Email changes. Reflects last SP write for this row. Range: 2020-09-29 to 2026-03-20. (Tier 2 — SP_EXW_TestUsers) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| RealCID | etoro.Customer.CustomerStatic (via DWH_dbo.Dim_Customer) | RealCID | Passthrough; filtered to test users |
| GCID | etoro.Customer.CustomerStatic (via DWH_dbo.Dim_Customer) | GCID | Passthrough; HASH distribution key |
| UserName | etoro.Customer.CustomerStatic (via DWH_dbo.Dim_Customer) | UserName | Passthrough; updated when changed |
| Email | etoro.Customer.CustomerStatic (via DWH_dbo.Dim_Customer) | Email | Passthrough; updated when changed |
| UpdateDate | — | — | GETDATE() — ETL timestamp |

### 5.2 ETL Pipeline

```
etoro.Customer.CustomerStatic (production OLTP)
  |-- Generic Pipeline (Bronze export) ---|
  v
DWH_staging.etoro_Customer_CustomerStatic
  |-- SP_Dim_Customer ---|
  v
DWH_dbo.Dim_Customer (relay — full customer dimension)
  |-- SP_EXW_TestUsers (filter: username patterns + Beta users) ---|
  v
EXW_dbo.EXW_TestUsers (958 rows, test-user subset)
  |-- SP_DimUser (LEFT JOIN on GCID → IsTestAccount flag) ---|
  v
EXW_dbo.EXW_DimUser

Note: No UC export (UC Target: _Not_Migrated)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| GCID | DWH_dbo.Dim_Customer | Source of all customer attributes; this table is a filtered subset |
| RealCID | DWH_dbo.Dim_Customer | Source FK; same customer, alternate ID |

### 6.2 Referenced By (other objects point to this)

| Object | Usage |
|--------|-------|
| EXW_dbo.SP_DimUser | LEFT JOIN on GCID to populate IsTestAccount flag in EXW_DimUser |

---

## 7. Sample Queries

### Check if a user is a test account

```sql
SELECT CASE WHEN tu.GCID IS NOT NULL THEN 1 ELSE 0 END AS IsTestAccount,
       tu.UserName, tu.Email, tu.UpdateDate
FROM (SELECT @gcid AS GCID) q
LEFT JOIN [EXW_dbo].[EXW_TestUsers] tu ON tu.GCID = q.GCID;
```

### All wallet queries excluding test users

```sql
SELECT t.*
FROM [EXW_dbo].[EXW_FactTransactions] t
LEFT JOIN [EXW_dbo].[EXW_TestUsers] tu ON t.GCID = tu.GCID
WHERE tu.GCID IS NULL;  -- exclude test users
```

### Review current test user list with DWH customer details

```sql
SELECT tu.GCID, tu.RealCID, tu.UserName, tu.Email, tu.UpdateDate,
       dc.PlayerLevelID, dc.RegulationID, dc.CountryID
FROM [EXW_dbo].[EXW_TestUsers] tu
JOIN [DWH_dbo].[Dim_Customer] dc ON tu.GCID = dc.GCID
ORDER BY tu.UpdateDate DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table. It is a utility support table with no dedicated documentation.

---

*Generated: 2026-04-20 | Quality: 8.0/10 | Phases: 12/14*
*Tiers: 4 T1, 1 T2, 0 T3, 0 T4, 0 T5 | Elements: 5/5, Logic: 8/10, Source: etoro.Customer.CustomerStatic*
*Object: EXW_dbo.EXW_TestUsers | Type: Table | Production Source: Customer.CustomerStatic (via Dim_Customer)*
