# BI_DB_dbo.BI_DB_AML_Multiple_Accounts_SameIP_FullData

> AML same-IP detection detail table — 1,102,688 rows listing every verified depositor customer who shares a registration IP address with at least one other verified depositor. Each row maps a CID to a hashed IP (CHECKSUM) for privacy-safe multi-account clustering. Refreshed daily via SP_AML_Multiple_Accounts (TRUNCATE + INSERT).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Customer (IP + RealCID) via SP_AML_Multiple_Accounts |
| **Refresh** | Daily (SP_AML_Multiple_Accounts @Date, TRUNCATE + INSERT) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| | |
| **UC Target** | _Pending -- resolved during write-objects_ |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

`BI_DB_AML_Multiple_Accounts_SameIP_FullData` is one of six output tables produced by `SP_AML_Multiple_Accounts`, a daily AML (Anti-Money Laundering) dashboard pipeline authored by Lior Ben Dor (2023-11-13). This specific table provides the **per-customer detail** for the same-IP detection use case: it identifies every valid, verified depositor customer (IsValidCustomer=1, IsDepositor=1, VerificationLevelID=3) whose registration IP address is shared by at least one other customer meeting the same criteria.

The table contains 1,102,688 rows as of 2025-03-13, with each CID appearing exactly once (1:1 customer grain). There are 353,336 distinct HashIP values, meaning an average of ~3.1 customers per shared IP cluster. The IP address is stored as a CHECKSUM integer hash for privacy (the raw IP is not persisted).

**ETL pattern**: The SP builds a `#SameIP` temp table by grouping `Dim_Customer` on IP (filtered to valid, depositor, fully verified customers) with `HAVING COUNT(DISTINCT RealCID) > 1`. Then `#SameIP_Fulldata` joins back to `Dim_Customer` on IP to get each individual CID and hashes the IP. Step 17 performs `TRUNCATE TABLE` followed by `INSERT INTO` from the temp table.

**Sibling tables** in the same SP:
- `BI_DB_AML_Multiple_Accounts_SameIP` — aggregate level (count of customers per IP)
- `BI_DB_AML_Multiple_Accounts_Dep` / `_Withdraw` — shared FundingID detection (deposit/withdraw)
- `BI_DB_AML_Multiple_Accounts_Dep_fulldata` / `_Withdrawfulldata` — FundingID detail
- `BI_DB_AML_Multiple_Accounts_DeviceID` / `_DeviceID_FullData` — shared device ID detection

---

## 2. Business Logic

### 2.1 Same-IP Customer Clustering

**What**: Identifies customers who registered with the same IP address as at least one other verified depositor — a potential indicator of multi-account fraud or linked accounts.

**Columns Involved**: `CID`, `HashIP`

**Rules**:
- Only customers meeting ALL three filters are included: `IsValidCustomer = 1`, `IsDepositor = 1`, `VerificationLevelID = 3` (fully verified)
- An IP must be shared by at least 2 distinct RealCIDs (`HAVING COUNT(DISTINCT dc.RealCID) > 1`)
- The raw IP is hashed via `CHECKSUM(IP)` before storage — the original IP string is NOT persisted in this table
- Each CID appears exactly once (DISTINCT in Step 8 query)

### 2.2 IP Hashing for Privacy

**What**: The IP address is stored as a CHECKSUM hash rather than the raw string, enabling grouping without exposing PII.

**Columns Involved**: `HashIP`

**Rules**:
- `HashIP = CHECKSUM(Dim_Customer.IP)` — a deterministic T-SQL integer hash
- Same IP always produces the same HashIP, enabling GROUP BY on the hashed value
- CHECKSUM is NOT cryptographically secure — it is a fast hash for grouping, not for security
- CHECKSUM collisions are possible but rare for IP-length strings

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with HEAP — no distribution key optimization. The table is 1.1M rows, small enough for full scans. No clustered or nonclustered indexes exist.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| How many customers share the same IP? | GROUP BY HashIP, COUNT(CID) |
| Which IP clusters have the most accounts? | GROUP BY HashIP ORDER BY COUNT(CID) DESC |
| Is a specific CID in a shared-IP cluster? | WHERE CID = @cid |
| Join with customer attributes | JOIN DWH_dbo.Dim_Customer ON CID = RealCID |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON CID = RealCID | Customer demographics, country, regulation, status |
| BI_DB_dbo.BI_DB_AML_Multiple_Accounts_SameIP | ON HashIP = IP (note: parent table stores raw IP, not hash) | Aggregate counts per IP |

### 3.4 Gotchas

- **HashIP is CHECKSUM, not the raw IP**: You cannot reverse-engineer the IP from HashIP. To match back to raw IPs, join to Dim_Customer and compute CHECKSUM(IP) at query time.
- **Only fully verified depositors**: Customers with VerificationLevelID < 3, non-depositors, or invalid customers are excluded. This is NOT a complete same-IP list.
- **Stale data**: UpdateDate = 2025-03-13 for all rows — the table appears to not have refreshed since that date. Verify SP execution schedule.
- **HashIP is nvarchar(250) but holds an int**: The CHECKSUM function returns int, but the column is nvarchar(250). The value is stored as a string representation of the integer.
- **CHECKSUM collisions**: Two different IPs could theoretically produce the same HashIP. Do not assume HashIP uniquely identifies an IP.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Tag |
|------|-----|
| Tier 1 — upstream wiki verbatim | (Tier 1 — Customer.CustomerStatic) |
| Tier 2 — SP ETL code | (Tier 2 — SP_AML_Multiple_Accounts) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Dim_Customer.RealCID. Only includes customers where IsValidCustomer=1, IsDepositor=1, and VerificationLevelID=3 whose registration IP is shared by at least one other qualifying customer. (Tier 1 — Customer.CustomerStatic) |
| 2 | HashIP | nvarchar(250) | YES | CHECKSUM hash of the customer's registration IP address (Dim_Customer.IP). Deterministic integer hash stored as nvarchar — same IP always produces the same hash, enabling same-IP grouping without exposing the raw IP string. Multiple CIDs sharing the same HashIP value indicates they registered from the same IP address. (Tier 2 — SP_AML_Multiple_Accounts) |
| 3 | UpdateDate | datetime | YES | ETL load timestamp. Set to GETDATE() at SP_AML_Multiple_Accounts execution time. All rows share the same value per refresh (TRUNCATE + INSERT pattern). Not a business event timestamp. (Tier 2 — SP_AML_Multiple_Accounts) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CID | DWH_dbo.Dim_Customer | RealCID | Rename (RealCID → CID) |
| HashIP | DWH_dbo.Dim_Customer | IP | CHECKSUM(IP) — integer hash of registration IP |
| UpdateDate | — | — | ETL-computed: GETDATE() |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer (dc)
  WHERE IsValidCustomer=1 AND IsDepositor=1 AND VerificationLevelID=3
  |
  v [Step 7: GROUP BY dc.IP, HAVING COUNT(DISTINCT RealCID) > 1]
#SameIP (NumOfClientsSameIP, IP, UpdateDate=GETDATE())
  |
  v [Step 8: JOIN Dim_Customer dc ON ss.IP = dc.IP, same filters]
#SameIP_Fulldata (CID=dc.RealCID, HashIP=CHECKSUM(ss.IP), UpdateDate)
  |
  v [Step 17: TRUNCATE + INSERT]
BI_DB_dbo.BI_DB_AML_Multiple_Accounts_SameIP_FullData (1,102,688 rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer who appears in a shared-IP cluster |

### 6.2 Referenced By (other objects point to this)

No downstream consumers identified. This table is a terminal AML dashboard output.

---

## 7. Sample Queries

### 7.1 Largest shared-IP clusters

```sql
SELECT HashIP,
       COUNT(*) AS CustomersSharing,
       MIN(UpdateDate) AS AsOfDate
FROM [BI_DB_dbo].[BI_DB_AML_Multiple_Accounts_SameIP_FullData]
GROUP BY HashIP
ORDER BY CustomersSharing DESC;
```

### 7.2 Check if a specific customer is in a shared-IP cluster

```sql
SELECT sip.CID, sip.HashIP,
       dc.UserName, dc.CountryID, dc.RegisteredReal
FROM [BI_DB_dbo].[BI_DB_AML_Multiple_Accounts_SameIP_FullData] sip
JOIN [DWH_dbo].[Dim_Customer] dc ON sip.CID = dc.RealCID
WHERE sip.CID = 12345;
```

### 7.3 All customers sharing the same IP as a target CID

```sql
SELECT other.CID, dc.UserName, dc.RegisteredReal, dc.CountryID
FROM [BI_DB_dbo].[BI_DB_AML_Multiple_Accounts_SameIP_FullData] target
JOIN [BI_DB_dbo].[BI_DB_AML_Multiple_Accounts_SameIP_FullData] other
  ON target.HashIP = other.HashIP
JOIN [DWH_dbo].[Dim_Customer] dc ON other.CID = dc.RealCID
WHERE target.CID = 12345
  AND other.CID <> 12345;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian MCP available this session. Phase 10 skipped.

---

*Generated: 2026-04-28 | Quality: 8.0/10*
*Tiers: 1 T1, 2 T2, 0 T3, 0 T4 | Phases: 1,2,3,4,5,6,7,8,9,9B,10A,10B,11*
*Object: BI_DB_dbo.BI_DB_AML_Multiple_Accounts_SameIP_FullData | Type: Table | Production Source: DWH_dbo.Dim_Customer via SP_AML_Multiple_Accounts*
