# BI_DB_dbo.BI_DB_AML_Multiple_Accounts_SameIP

> AML monitoring summary table — 370,638 rows identifying registration IP addresses shared by multiple verified depositing customers, supporting fraud detection and multi-account abuse investigation. Refreshed daily via SP_AML_Multiple_Accounts (full TRUNCATE + INSERT).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Customer (aggregated by IP) via SP_AML_Multiple_Accounts |
| **Refresh** | Daily (SP_AML_Multiple_Accounts, full TRUNCATE + INSERT) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

`BI_DB_dbo.BI_DB_AML_Multiple_Accounts_SameIP` is an AML (Anti-Money Laundering) monitoring table that identifies registration IP addresses shared by more than one verified, depositing customer. It is part of a suite of "Multiple Accounts" tables populated by `SP_AML_Multiple_Accounts` (authored by Lior Ben Dor, 2023-11-13) that detect potential multi-account fraud through three vectors: shared funding instruments (FundingID), shared device IDs, and shared registration IPs. This table covers the IP vector.

The table is populated from `DWH_dbo.Dim_Customer`, filtering to valid customers (`IsValidCustomer=1`) who have deposited (`IsDepositor=1`) and are fully verified (`VerificationLevelID=3`). It groups by the `IP` column (registration IP address) and retains only IPs where `COUNT(DISTINCT RealCID) > 1`. As of 2025-03-13, the table contains 370,638 rows — each representing one IP address shared by 2 or more customers. The distribution is heavily right-skewed: 66.1% of IPs are shared by exactly 2 clients, with a long tail extending to 374 clients on a single IP.

This is a companion to `BI_DB_AML_Multiple_Accounts_SameIP_FullData`, which provides per-customer detail (CID + hashed IP) for each flagged IP in this summary table.

The ETL pattern is a daily full reload: TRUNCATE the table, then INSERT from a temp table `#SameIP` built in Step 07 of the SP.

---

## 2. Business Logic

### 2.1 Multi-Account IP Detection

**What**: Identifies registration IP addresses used by more than one fully verified depositor.

**Columns Involved**: `NumOfClientsSameIP`, `IP`

**Rules**:
- Only customers with `IsValidCustomer=1`, `IsDepositor=1`, AND `VerificationLevelID=3` (fully verified) are included
- IP addresses with only 1 distinct customer are excluded (`HAVING COUNT(DISTINCT dc.RealCID) > 1`)
- `NumOfClientsSameIP` is the count of distinct `RealCID` values sharing the same registration IP
- The minimum value is always 2 (by definition of the HAVING clause)
- High values (e.g., 374) may indicate shared corporate/VPN IPs rather than fraud — requires analyst investigation

### 2.2 Full Reload Pattern

**What**: The table is fully replaced on each daily run.

**Rules**:
- Step 16 of `SP_AML_Multiple_Accounts`: `TRUNCATE TABLE BI_DB_dbo.BI_DB_AML_Multiple_Accounts_SameIP` followed by `INSERT INTO ... SELECT ... FROM #SameIP`
- `UpdateDate` is set to `GETDATE()` during the #SameIP temp table creation (Step 07), not at insert time
- All rows share the same `UpdateDate` value per load (single batch timestamp)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with HEAP index. At 370K rows this is a small table — full scans are trivial. No distribution key optimization needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Which IPs have the most shared accounts? | `ORDER BY NumOfClientsSameIP DESC` |
| Distribution of sharing (2, 3, 4+ clients) | `GROUP BY NumOfClientsSameIP` or bucket with CASE |
| Get customer details for a flagged IP | JOIN to `BI_DB_AML_Multiple_Accounts_SameIP_FullData` on hashed IP |
| Total flagged IPs | `SELECT COUNT(*) FROM BI_DB_AML_Multiple_Accounts_SameIP` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_AML_Multiple_Accounts_SameIP_FullData | IP-based correlation (FullData uses CHECKSUM(IP) as HashIP) | Per-customer breakdown for flagged IPs |
| DWH_dbo.Dim_Customer | ON dc.IP = sip.IP | Resolve individual customers sharing the IP |

### 3.4 Gotchas

- **IP is the registration IP (varchar), not a numeric representation**: Unlike `Fact_BillingDeposit.IPAddress` (numeric(18,0)), this column stores the human-readable IPv4 string from `Dim_Customer.IP` (varchar(15) widened to nvarchar(250) in this table).
- **Only fully verified depositors**: `VerificationLevelID=3` is stricter than the VerificationLevelID >= 2 filter used in the FundingID companion tables. This means fewer customers qualify, and the IP flagging is more targeted.
- **Single UpdateDate per load**: All 370K rows have the same timestamp. This is not per-IP freshness — it's the batch execution time.
- **Companion table uses CHECKSUM(IP)**: `BI_DB_AML_Multiple_Accounts_SameIP_FullData` stores `CHECKSUM(ss.IP) AS HashIP`, not the raw IP. Cross-referencing requires joining back to Dim_Customer by IP or recomputing the checksum.
- **VPN/corporate IPs**: High NumOfClientsSameIP values do not automatically indicate fraud. Shared office or VPN exit nodes can legitimately produce high counts.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Tag |
|------|-----|
| Tier 1 — upstream wiki verbatim | (Tier 1 — Customer.CustomerStatic) |
| Tier 2 — SP ETL code | (Tier 2 — SP_AML_Multiple_Accounts) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | NumOfClientsSameIP | int | YES | Number of distinct verified depositing customers (RealCID) who registered from this IP address. Computed as COUNT(DISTINCT dc.RealCID) from Dim_Customer WHERE IsValidCustomer=1 AND IsDepositor=1 AND VerificationLevelID=3, grouped by IP. Minimum value is 2 (HAVING clause). Range in current data: 2–374; 66.1% of rows have value 2. (Tier 2 — SP_AML_Multiple_Accounts) |
| 2 | IP | nvarchar(250) | YES | Registration IP address. (Tier 1 — Customer.CustomerStatic) |
| 3 | UpdateDate | datetime | YES | ETL load timestamp. Set to GETDATE() at temp table creation time in SP Step 07. All rows share the same value per daily load. Not a business event timestamp. (Tier 2 — SP_AML_Multiple_Accounts) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| NumOfClientsSameIP | DWH_dbo.Dim_Customer | RealCID | COUNT(DISTINCT) grouped by IP, HAVING > 1 |
| IP | DWH_dbo.Dim_Customer (← Customer.CustomerStatic) | IP | Passthrough (GROUP BY key) |
| UpdateDate | — | — | ETL-computed: GETDATE() |

### 5.2 ETL Pipeline

```
Customer.CustomerStatic (etoroDB-REAL)
  → Generic Pipeline (daily)
  → DWH_staging.etoro_Customer_Customer
  → SP_Dim_Customer_DL_To_Synapse / SP_Dim_Customer
  → DWH_dbo.Dim_Customer (IP column passthrough)
       |
       v [SP_AML_Multiple_Accounts — Step 07]
         SELECT COUNT(DISTINCT dc.RealCID), dc.IP, GETDATE()
         FROM Dim_Customer dc
         WHERE IsValidCustomer=1 AND IsDepositor=1 AND VerificationLevelID=3
         GROUP BY dc.IP HAVING COUNT(DISTINCT dc.RealCID) > 1
       → #SameIP (temp table)
       |
       v [SP_AML_Multiple_Accounts — Step 16]
         TRUNCATE + INSERT
       → BI_DB_dbo.BI_DB_AML_Multiple_Accounts_SameIP (370,638 rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| IP | DWH_dbo.Dim_Customer.IP | Registration IP from customer master |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| BI_DB_dbo.BI_DB_AML_Multiple_Accounts_SameIP_FullData | IP (via CHECKSUM) | Per-customer detail rows for flagged IPs |

---

## 7. Sample Queries

### 7.1 Top 20 most-shared registration IPs

```sql
SELECT TOP 20
    NumOfClientsSameIP,
    IP,
    UpdateDate
FROM [BI_DB_dbo].[BI_DB_AML_Multiple_Accounts_SameIP]
ORDER BY NumOfClientsSameIP DESC;
```

### 7.2 Distribution of sharing levels

```sql
SELECT
    CASE
        WHEN NumOfClientsSameIP = 2 THEN '2'
        WHEN NumOfClientsSameIP BETWEEN 3 AND 5 THEN '3-5'
        WHEN NumOfClientsSameIP BETWEEN 6 AND 10 THEN '6-10'
        WHEN NumOfClientsSameIP BETWEEN 11 AND 50 THEN '11-50'
        ELSE '50+'
    END AS SharingBucket,
    COUNT(*) AS IPCount,
    SUM(NumOfClientsSameIP) AS TotalCustomers
FROM [BI_DB_dbo].[BI_DB_AML_Multiple_Accounts_SameIP]
GROUP BY
    CASE
        WHEN NumOfClientsSameIP = 2 THEN '2'
        WHEN NumOfClientsSameIP BETWEEN 3 AND 5 THEN '3-5'
        WHEN NumOfClientsSameIP BETWEEN 6 AND 10 THEN '6-10'
        WHEN NumOfClientsSameIP BETWEEN 11 AND 50 THEN '11-50'
        ELSE '50+'
    END
ORDER BY MIN(NumOfClientsSameIP);
```

### 7.3 Customers behind a specific flagged IP

```sql
SELECT dc.RealCID, dc.UserName, dc.RegisteredReal, dc.CountryID, dc.VerificationLevelID
FROM [DWH_dbo].[Dim_Customer] dc
WHERE dc.IP = '46.114.0.201'
  AND dc.IsValidCustomer = 1
  AND dc.IsDepositor = 1
  AND dc.VerificationLevelID = 3
ORDER BY dc.RegisteredReal;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped — Atlassian MCP not available.)

---

*Generated: 2026-04-28 | Quality: 8.5/10 | Phases: 11/14 (P7 skipped — no views; P10 skipped — no Atlassian)*
*Tiers: 1 T1, 2 T2, 0 T3, 0 T4 | Elements: 3/3, Logic: 9/10, Relationships: 7/10, Sources: 9/10*
*Object: BI_DB_dbo.BI_DB_AML_Multiple_Accounts_SameIP | Type: Table | Production Source: DWH_dbo.Dim_Customer (aggregated)*
