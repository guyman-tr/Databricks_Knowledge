# BI_DB_dbo.BI_DB_AML_PI_Abuse_SameIP

## 1. Summary

Daily full-refresh satellite table from the `SP_AML_PI_Abuse` suite. Each row represents one **IP address** that is shared by **2 or more active copiers** of a given Popular Investor (PI) at snapshot time. The table supports AML detection of coordinated copy activity where multiple copiers operate from the same IP — a strong signal of shared infrastructure (VPN exit nodes, same household, or coordinated account farm).

- **Row count**: 2,621 (as of 2026-04-12)
- **Distinct PIs (ParentCID)**: 563
- **Average rows per PI**: ~4.65 (one row per suspicious IP cluster)
- **Distribution**: ROUND_ROBIN
- **Index**: HEAP
- **ETL pattern**: TRUNCATE + INSERT (daily full refresh)
- **Writer SP**: `BI_DB_dbo.SP_AML_PI_Abuse @Date [DATE]`
- **OpsDB Priority**: 0 (base layer)
- **UC Migration**: Not Migrated
- **PII Sensitivity**: LOW — contains IP addresses only (no direct customer PII)

---

## 2. Column Reference

| # | Column | Type | Tier | Source | Description |
|---|--------|------|------|--------|-------------|
| 1 | ParentCID | int | T1 | `general.etoroGeneral_History_GuruCopiers.ParentCID` | The Popular Investor's customer ID — the PI whose copier base is being analyzed. Join to `BI_DB_AML_PI_Abuse.CID` for PI details. (Tier 1 — Customer.CustomerStatic via Fact_SnapshotCustomer) |
| 2 | IP | nvarchar(max) | T2 | `DWH_dbo.Dim_Customer.IP` (copier) | The shared IP address (IPv4 string). This is the copier's **registration IP** from Dim_Customer — not a session or login IP. Only IPs with ≥2 distinct copiers per PI are included. (Tier 2 — SP_AML_PI_Abuse via Dim_Customer.IP) |
| 3 | NumCopiers | int | T2 | Computed: `COUNT(DISTINCT CopierCID)` | Number of distinct copiers of this PI who registered from this IP address. Always ≥ 2 (HAVING COUNT ≥ 2 filter). Higher values indicate larger potential coordinated clusters. (Tier 2 — SP_AML_PI_Abuse) |
| 4 | CopierList | nvarchar(max) | T2 | `general.etoroGeneral_History_GuruCopiers.CID` | Comma-delimited list of copier CIDs sharing this IP, sorted ascending: `STRING_AGG(CAST(CopierCID AS NVARCHAR(20)), ', ') WITHIN GROUP (ORDER BY CopierCID)`. Use for cross-referencing with `BI_DB_AML_PI_Abuse_CopierTable` for full copier PII. (Tier 2 — SP_AML_PI_Abuse) |
| 5 | UpdateDate | datetime | Propagation | ETL metadata | SP execution timestamp: `GETDATE()` at INSERT time. Not a business date. (Propagation) |

**Tier summary**: 1 T1 | 3 T2 | 1 Propagation

---

## 3. Business Context

Shared IP addresses between copiers of the same PI indicate one of:
1. **Household/family accounts**: Legitimate — family members copying the same PI from a home network
2. **VPN / exit node collision**: Ambiguous — common VPN exit nodes can create false positives
3. **Coordinated account farm**: High-risk — multiple artificial copier accounts controlled from the same machine or network

AML analysts use this table in conjunction with the main `BI_DB_AML_PI_Abuse` table (which carries the `Same_IP_AS_PI` count — copiers sharing the PI's OWN IP) to assess network topology. This table focuses on copier-to-copier IP sharing (not copier-to-PI), which reveals the internal structure of potential account networks.

### Grain

One row per `(ParentCID, IP)` pair where `COUNT(DISTINCT CopierCID) ≥ 2`. A PI with 3 suspicious IPs will have 3 rows. There is no total/summary row — the `NumCopiers` in `BI_DB_AML_PI_Abuse.Same_IP_AS_PI` is aggregated at PI level across all IPs.

### Copier Qualification

Copiers included are those active at `@DateTime` in `etoroGeneral_History_GuruCopiers` whose Dim_Customer.IP is NOT NULL. No additional validity filtering (unlike the main copier population gate).

---

## 4. Data Shape and Distributions

| Metric | Value |
|--------|-------|
| Total rows | 2,621 (2026-04-12) |
| Distinct PIs (ParentCID) | 563 |
| Average rows per PI | ~4.65 |
| Snapshot | 2026-04-12 (single-day full refresh) |

Only 563 of the ~5,131 active PIs (≈11%) have any copiers sharing an IP. The majority of PIs have a geographically diverse copier base with no IP overlap.

---

## 5. Usage Notes

### Join to PI Details

```sql
SELECT s.ParentCID, s.IP, s.NumCopiers, s.CopierList, a.GuruStatusName, a.Country
FROM BI_DB_dbo.BI_DB_AML_PI_Abuse_SameIP s
JOIN (
    SELECT CID, GuruStatusName, Country,
           ROW_NUMBER() OVER (PARTITION BY CID ORDER BY UpdateDate DESC) rn
    FROM BI_DB_dbo.BI_DB_AML_PI_Abuse
) a ON a.CID = s.ParentCID AND a.rn = 1
WHERE s.NumCopiers >= 5  -- only clusters of 5+ copiers sharing an IP
ORDER BY s.NumCopiers DESC
```

### Parse CopierList

`CopierList` is a CSV of CIDs. To parse in Synapse:

```sql
-- Note: Synapse doesn't natively support STRING_SPLIT in all contexts.
-- For downstream analysis, join to BI_DB_AML_PI_Abuse_CopierTable on ParentCID
-- and filter by CID IN the CopierList values.
SELECT ct.ParentCID, ct.CID, ct.UserName, ct.Country, ct.AUC
FROM BI_DB_dbo.BI_DB_AML_PI_Abuse_CopierTable ct
JOIN BI_DB_dbo.BI_DB_AML_PI_Abuse_SameIP ip ON ct.ParentCID = ip.ParentCID
WHERE ip.NumCopiers >= 3
-- Then manually cross-reference ct.CID against ip.CopierList
```

### IP Privacy Note

IP addresses are PII-adjacent. Handle according to data handling policies. The `IP` column in Dim_Customer is masked in the `main.dwh.gold_..._dim_customer_masked` UC table.

---

## 6. Source Objects

| # | Source | Type | Role |
|---|--------|------|------|
| 1 | `general.etoroGeneral_History_GuruCopiers` | Hist Table | Active copy relationships at @DateTime; provides copier CIDs per PI |
| 2 | `DWH_dbo.Dim_Customer` | Dim | Copier registration IP address (dc.IP) |
| 3 | `#pis` | Temp Table | PI population gate |

---

## 7. Known Issues

1. **Registration IP only**: The `IP` column comes from `Dim_Customer.IP` — the IP at account registration, not a session or login IP. Registration IP data can be stale (IP assigned years ago) and does not reflect current user location.

2. **VPN false positives**: Common VPN or proxy exit nodes can create large clusters of unrelated users sharing an IP. Context (geographic dispersion of CopierList CIDs, account ages, AUC patterns) is essential for distinguishing real coordination from VPN coincidence.

3. **NULL IP exclusion**: Copiers with NULL registration IP (`WHERE dc.IP IS NOT NULL` in the SP) are excluded. No count is available for how many copiers had NULL IPs and were thus excluded from IP analysis.

---

## 8. Metadata

| Field | Value |
|-------|-------|
| Schema | BI_DB_dbo |
| Object Type | Table |
| Distribution | ROUND_ROBIN |
| Index | HEAP |
| Writer SP | SP_AML_PI_Abuse |
| ETL Pattern | TRUNCATE + INSERT (daily full refresh) |
| OpsDB Priority | 0 |
| UC Status | Not Migrated |
| Columns | 5 (1 T1, 3 T2, 1 Propagation) |
| Rows | 2,621 (2026-04-12) |
| Distinct PIs | 563 |
| PII | LOW (IP addresses only) |
| Suite | SP_AML_PI_Abuse (11 tables total) |
| Batch | 47 |
| Generated | 2026-04-22 |
