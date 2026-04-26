# BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_SameIP

> IP-sharing risk table for AML affiliate abuse monitoring — 1,178,451 rows of affiliate × IP group records showing how many customers per affiliate share each registration IP, written by SP_AML_Affiliate_Abuse (disabled 2024-12-31); data is frozen.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Customer + V_Liabilities (via Dim_Affiliate + enrichment chain) |
| **Refresh** | DISABLED (SP_AML_Affiliate_Abuse disabled 2024-12-31 per BI team request) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **Writer SP** | SP_AML_Affiliate_Abuse |
| **UC Target** | Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **OpsDB Priority** | Not in OpsDB |

---

## 1. Business Meaning

`BI_DB_AML_Affiliate_Abuse_SameIP` measures the concentration of customers sharing a registration IP address within each affiliate's portfolio. Multiple customers from the same IP — especially when brought in by the same affiliate — is a classic money laundering indicator: coordinated synthetic accounts, household farming, or a fraudster operating a mule network from one location.

The table contains **1,178,451 rows** as of 2024-12-31. Unlike `BI_DB_AML_Affiliate_Abuse_SameDeviceID` (which has a COUNT > 1 threshold), SameIP includes all IP groups, even singletons — enabling the `%SameIP` calculation which measures what share of an affiliate's total customer base comes from shared IPs.

The core metric is `%SameIP`: the percentage of customers within an affiliate that share an IP address with at least one other customer. The IP is hashed via `CHECKSUM(IP)` into an integer `Group` key for grouping, preserving privacy while enabling aggregation.

**The SP was permanently disabled on 2024-12-31** at the request of Lior Ben Dor from the BI team. The table is a frozen historical snapshot.

The ETL pipeline:

```
DWH_dbo.Dim_Customer + Dim_Affiliate (SubChannelID filter)
  |-- #cidlevel (activated affiliate customers) ---|
  v
DWH_dbo.V_Liabilities (DateID=@DateID) INNER JOIN
  |-- #final_CID (CID-level enriched snapshot, equity-joined) ---|
  v
PARTITION BY AffiliateID ORDER BY AffiliateID
  |-- #SameIP → #calSameIP (NumOfClientsSameIP per IP group, TotalClients per affiliate) ---|
  v
#finalSameIP: %SameIP = ROUND(NumOfClientsSameIP * 100.0 / TotalClients, 2)
  |-- TRUNCATE + INSERT (SP disabled 2024-12-31) ---|
  v
BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_SameIP (1,178,451 rows, frozen)
```

---

## 2. Business Logic

### 2.1 IP Concentration Metric (%SameIP)

**What**: Measures what percentage of an affiliate's customers share an IP with another customer in the same affiliate.

**Columns Involved**: NumOfClientsSameIP, TotalClients, [%SameIP]

**Rules**:
- `NumOfClientsSameIP`: COUNT DISTINCT CID per affiliate per IP group (CHECKSUM-hashed IP)
- `TotalClients`: SUM(NumOfClientsSameIP) OVER (PARTITION BY AffiliateID) — total customers for this affiliate
- `%SameIP`: ROUND(NumOfClientsSameIP * 100.0 / TotalClients, 2) — stored as decimal(18,0), so rounded to nearest integer percent
- High `%SameIP` (e.g., >30%) suggests systematic IP clustering — potential mule network
- Singleton IPs (NumOfClientsSameIP=1) appear in the table with %SameIP reflecting their share of total clients

### 2.2 IP Anonymisation via CHECKSUM

**What**: The raw IP address is not stored; only its CHECKSUM hash is retained.

**Columns Involved**: [Group]

**Rules**:
- `[Group]` = CHECKSUM(IP) — produces a signed 32-bit integer hash of the registration IP string
- CHECKSUM is not collision-free (two different IPs can produce the same integer), but collision probability is low for this use case
- Allows IP-based grouping without storing PII (raw IP string) in this reporting table

### 2.3 V_Liabilities INNER JOIN Effect

**What**: Only customers with a record in V_Liabilities (as of @DateID = 2024-12-30) appear in this table.

**Columns Involved**: (implicit — filters #cidlevel to #final_CID scope)

**Rules**:
- SP Step 04 JOINs #cidlevel to V_Liabilities with INNER JOIN — drops customers with no liability record
- Customers who registered but never had any financial activity may be absent
- This means 1,178,451 rows represents financially-active affiliate customers only

### 2.4 Grain

**What**: One row per affiliate × IP hash group.

**Columns Involved**: AffiliateID, [Group]

**Rules**:
- An AffiliateID appears in as many rows as distinct IP groups (CHECKSUMs) its customers span
- No deduplication at customer level — each IP group contributes one row to the table

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP. 1,178,451 rows — moderate size but still fast for full scans in Synapse. No distribution key means aggregation queries distribute evenly.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Affiliates with highest IP concentration | `GROUP BY AffiliateID, SELECT MAX([%SameIP]) or AVG` |
| All IP groups for an affiliate | `WHERE AffiliateID = @id ORDER BY NumOfClientsSameIP DESC` |
| Affiliates where >50% share IPs | Filter on aggregated `%SameIP` at affiliate level |
| IP groups with many customers | `WHERE NumOfClientsSameIP >= 10 ORDER BY NumOfClientsSameIP DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_AML_Affiliate_Abuse_Users | ON AffiliateID | Get CID-level detail; SameIP has no CID column |
| DWH_dbo.Dim_Affiliate | ON AffiliateID | Add affiliate name and contact info |

### 3.4 Gotchas

- **Data is frozen**: No refreshes since 2024-12-31. Do NOT use for current monitoring.
- **%SameIP stored as decimal(18,0)**: Despite SP computing ROUND(..., 2), the DDL stores as integer — values are truncated to whole percent. Do not expect decimal precision.
- **CHECKSUM collisions**: `[Group]` is CHECKSUM(IP) — rare but possible collisions mean two different IPs could share the same Group value. Cross-validate against `BI_DB_AML_Affiliate_Abuse_Users.IP` if precision is critical.
- **V_Liabilities INNER JOIN**: Customers with no equity record are excluded from the IP analysis. The denominator `TotalClients` reflects equity-filtered customers only, not all registrants.
- **No raw IP**: The registration IP string is not in this table. Use `BI_DB_AML_Affiliate_Abuse_Users.IP` for CID-to-IP lookup.
- **Singleton IPs included**: Unlike SameDeviceID, there is no HAVING > 1 filter. All IP groups appear, enabling the percentage denominator to be correct.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 2 | Derived from SP code analysis |
| Tier 5 | ETL infrastructure — canonical description applies universally |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | AffiliateID | int | YES | Unique affiliate partner identifier from AffWizz system. Groups IP concentration analysis by affiliate channel. (Tier 2 — SP_AML_Affiliate_Abuse Step 09 via Dim_Customer+Dim_Affiliate) |
| 2 | NumOfClientsSameIP | int | YES | Count of distinct customers (RealCID) sharing the same registration IP (CHECKSUM group) within this affiliate. Includes singletons (value=1). (Tier 2 — SP_AML_Affiliate_Abuse Step 09 via #final_CID) |
| 3 | TotalClients | int | YES | Total count of distinct customers for this affiliate (sum of all NumOfClientsSameIP values for this AffiliateID). Used as the denominator for %SameIP. Computed via SUM OVER (PARTITION BY AffiliateID). (Tier 2 — SP_AML_Affiliate_Abuse Step 09 via #calSameIP) |
| 4 | [Group] | int | YES | Integer hash of the registration IP address: CHECKSUM(IP). Acts as an anonymised IP group identifier. Customers with the same [Group] value share (or collide on) the same IP hash. (Tier 2 — SP_AML_Affiliate_Abuse Step 09 via Dim_Customer.IP) |
| 5 | [%SameIP] | decimal(18,0) | YES | Percentage of this affiliate's total customers who share this IP group: ROUND(NumOfClientsSameIP * 100.0 / TotalClients, 2). Stored as decimal(18,0) — integer precision only despite 2-decimal SP computation. Higher values indicate IP clustering risk. (Tier 2 — SP_AML_Affiliate_Abuse Step 09) |
| 6 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last inserted. All rows show 2024-12-31 — the date the SP was last run before being disabled. (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| AffiliateID | DWH_dbo.Dim_Customer + Dim_Affiliate | AffiliateID | passthrough via JOIN |
| NumOfClientsSameIP | #final_CID | CID | COUNT DISTINCT per IP CHECKSUM per AffiliateID |
| TotalClients | #calSameIP | NumOfClientsSameIP | SUM OVER (PARTITION BY AffiliateID) |
| [Group] | DWH_dbo.Dim_Customer | IP | CHECKSUM(IP) |
| [%SameIP] | #finalSameIP | NumOfClientsSameIP / TotalClients | ROUND(* 100.0 / TotalClients, 2) → stored decimal(18,0) |
| UpdateDate | ETL | — | GETDATE() |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer + Dim_Affiliate (SubChannelID filter)
  |-- #cidlevel (activated affiliate customers, RegisteredReal>=2023) ---|
  v
DWH_dbo.V_Liabilities (DateID=@DateID, INNER JOIN → drops no-equity customers)
  |-- #final_CID (CID-level enriched, equity-filtered) ---|
  v
CHECKSUM(IP) as [Group] → GROUP BY AffiliateID, [Group]
  |-- #SameIP (NumOfClientsSameIP per group) ---|
  v
SUM OVER (PARTITION BY AffiliateID) → TotalClients
  |-- #calSameIP ---|
  v
ROUND(NumOfClientsSameIP * 100.0 / TotalClients, 2) as [%SameIP]
  |-- #finalSameIP ---|
  v
TRUNCATE + INSERT (SP disabled 2024-12-31)
  v
BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_SameIP (1,178,451 rows, frozen)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| AffiliateID | DWH_dbo.Dim_Affiliate | Affiliate partner master |
| AffiliateID | BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_Users | CID-level companion; provides raw IP for reverse-lookup |

### 6.2 Referenced By (other objects point to this)

No known downstream consumers (SP was disabled; AML monitoring suite decommissioned).

---

## 7. Sample Queries

### Affiliates with high IP clustering (potential mule networks)

```sql
SELECT
    AffiliateID,
    COUNT(*) AS distinct_ip_groups,
    SUM(NumOfClientsSameIP) AS total_customers,
    MAX(NumOfClientsSameIP) AS max_clients_per_ip,
    MAX([%SameIP]) AS max_ip_share_pct
FROM [BI_DB_dbo].[BI_DB_AML_Affiliate_Abuse_SameIP]
WHERE NumOfClientsSameIP > 1
GROUP BY AffiliateID
ORDER BY max_clients_per_ip DESC
```

### IP groups with many customers for a specific affiliate

```sql
SELECT
    [Group],
    NumOfClientsSameIP,
    TotalClients,
    [%SameIP]
FROM [BI_DB_dbo].[BI_DB_AML_Affiliate_Abuse_SameIP]
WHERE AffiliateID = @affiliate_id
  AND NumOfClientsSameIP > 1
ORDER BY NumOfClientsSameIP DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table. The AML Affiliate Abuse suite was internally tracked — refer to BI team communications with Lior Ben Dor (2024-12-31 disable request).

---

*Generated: 2026-04-23 | Quality: 8.0/10 | Phases: 11/14*
*Tiers: 0 T1, 5 T2, 0 T3, 0 T4, 1 T5 | Elements: 6/6*
*Object: BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_SameIP | Type: Table | Production Source: SP_AML_Affiliate_Abuse (DISABLED 2024-12-31)*
