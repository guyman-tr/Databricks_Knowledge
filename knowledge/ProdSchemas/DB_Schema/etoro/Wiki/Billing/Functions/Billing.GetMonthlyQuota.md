# Billing.GetMonthlyQuota

> Multi-statement TVF that returns the monthly quota for all dynamic-routing CC protocols for a given year/month, zero-filling any dynamic protocol that has no quota entry recorded - ensuring callers always receive a complete row per dynamic protocol.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Multi-Statement Table-Valued Function (TVF) |
| **Key Identifier** | Returns @Result TABLE (ProtocolID, Year, Month, Amount decimal(18,2)) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.GetMonthlyQuota provides the monthly quota dataset consumed by the credit card routing selection logic. eToro's dynamic-routing CC protocols (WorldPay, Checkout, IxopayNuvei, etc.) are volume-capped per month to stay within processing agreements. The quota for each protocol is stored in Billing.MonthlyQuota and updated as transactions are processed.

The critical behavior is the **zero-fill**: if a dynamic protocol exists in Dictionary.Protocol (IsDynamicRouting=1) but has no quota record for the requested month yet, this function synthesizes a row with Amount=0. This ensures consumers like GetCCProcessingBundle never encounter a missing row - they always receive one Amount value per dynamic protocol, which prevents NULL-related routing failures when a new month begins before the first quota update runs.

As of 2026-03-17, 6 protocols are marked IsDynamicRouting=1: WireCard (18), WorldPay (23), Adyen (31), Proxy (40), Checkout (43), IxopayNuvei (46). Only 3 (WorldPay=23, Checkout=43, IxopayNuvei=46) have active monthly quota entries; the remaining 3 would receive Amount=0 rows from this function.

---

## 2. Business Logic

### 2.1 Complete Monthly Quota Result Set

**What**: Returns all historical quota rows plus zero-amount rows for dynamic protocols missing a quota entry for the requested month.

**Columns/Parameters Involved**: `@Year`, `@Month`, Billing.MonthlyQuota, Dictionary.Protocol.IsDynamicRouting

**Rules**:
- **Branch 1 (actual quotas)**: SELECT all rows from Billing.MonthlyQuota regardless of year/month. Returns the complete quota history across all periods.
- **Branch 2 (zero-fill)**: For each IsDynamicRouting=1 protocol in Dictionary.Protocol, if there is NO existing row in Billing.MonthlyQuota for the given @Year/@Month, insert a synthetic row with Amount=0.
- `NOT EXISTS (SELECT 1 FROM Billing.MonthlyQuota WHERE Year=@Year AND Month=@Month AND ProtocolID=dp.ProtocolID)` - zero-fill condition.
- Both branches combined via UNION ALL into the single @Result TABLE variable, then returned.
- Note: Branch 1 returns ALL years/months of quota history, not just @Year/@Month. Callers filter by Year/Month in their consuming queries.

**Diagram**:
```
GetMonthlyQuota(@Year=2026, @Month=3)
    |
    +-- Billing.MonthlyQuota (all rows, any year/month)
    |   ProtocolID=23, Year=2026, Month=3, Amount=13847992.84
    |   ProtocolID=43, Year=2026, Month=3, Amount=16951242.85
    |   ProtocolID=46, Year=2026, Month=3, Amount=2483786.50
    |   + all historical rows...
    |
    +-- Zero-fill: IsDynamicRouting=1 protocols NOT in MonthlyQuota for 2026-03:
    |   ProtocolID=18 (WireCard), 2026, 3, Amount=0
    |   ProtocolID=31 (Adyen),    2026, 3, Amount=0
    |   ProtocolID=40 (Proxy),    2026, 3, Amount=0
    |
    = @Result TABLE (complete set)
```

---

## 3. Data Overview

**Billing.MonthlyQuota**: 127 rows. 5 distinct ProtocolIDs. Active year range: 2018-2026 (5 distinct years with data).

Sample (most recent month, 2026-03):

| ProtocolID | Protocol | Year | Month | Amount (USD) |
|------------|----------|------|-------|-------------|
| 23 | WorldPay | 2026 | 3 | 13,847,992.84 |
| 43 | Checkout | 2026 | 3 | 16,951,242.85 |
| 46 | IxopayNuvei | 2026 | 3 | 2,483,786.50 |

**Dynamic routing protocols** (6 total, IsDynamicRouting=1):
WireCard (18), WorldPay (23), Adyen (31), Proxy (40), Checkout (43), IxopayNuvei (46)

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Year | int | NO | - | VERIFIED | Calendar year for the zero-fill check. Used in the NOT EXISTS subquery to identify which dynamic protocols lack a quota record for this year. |
| 2 | @Month | int | NO | - | VERIFIED | Calendar month (1-12) for the zero-fill check. Used in the NOT EXISTS subquery alongside @Year to identify protocols needing zero-fill rows. |
| RETURN: ProtocolID | int | NO | - | VERIFIED | CC processing protocol identifier. FK to Dictionary.Protocol. Active dynamic protocols: 23=WorldPay, 43=Checkout, 46=IxopayNuvei (have quota history); 18=WireCard, 31=Adyen, 40=Proxy (zero-filled for months without entries). |
| RETURN: Year | int | NO | - | VERIFIED | Calendar year of the quota row. For actual rows: the year the quota was recorded. For zero-fill rows: @Year parameter value. |
| RETURN: Month | int | NO | - | VERIFIED | Calendar month (1-12) of the quota row. For actual rows: the month the quota was recorded. For zero-fill rows: @Month parameter value. |
| RETURN: Amount | decimal(18,2) | NO | - | VERIFIED | Cumulative transaction volume (USD) processed via this protocol in the given month. 0.00 for zero-fill rows (protocol exists but no quota entry for requested month yet). Updated throughout the month as transactions are processed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProtocolID | Billing.MonthlyQuota | Data Source | Reads all quota rows for return as actual data. |
| ProtocolID + IsDynamicRouting | Dictionary.Protocol | Lookup | Finds all IsDynamicRouting=1 protocols for zero-fill logic. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetCCProcessingBundle | @Year, @Month | Caller | Uses monthly quota data in CC routing selection logic. |
| Billing.GetCCProcessingBundleByBin | @Year, @Month | Caller | Uses monthly quota data for BIN-based CC routing. |
| Billing.GetCCProcessingBundleByBinUS | @Year, @Month | Caller | Uses monthly quota data for US BIN-based CC routing. |
| Billing.GetCCProtocolQuotas | @Year, @Month | Caller | Retrieves quota data for reporting/display of protocol capacity. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetMonthlyQuota (multi-statement TVF)
├── Billing.MonthlyQuota (table)
└── Dictionary.Protocol (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.MonthlyQuota | Table | Primary data source - all historical quota rows included in result. |
| Dictionary.Protocol | Table | Source of IsDynamicRouting=1 protocol list for zero-fill logic. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetCCProcessingBundle | Stored Procedure | Queries monthly quota for routing decisions. |
| Billing.GetCCProcessingBundleByBin | Stored Procedure | Queries monthly quota for BIN-based routing decisions. |
| Billing.GetCCProcessingBundleByBinUS | Stored Procedure | Queries monthly quota for US BIN-based routing decisions. |
| Billing.GetCCProtocolQuotas | Stored Procedure | Queries monthly quota for quota capacity reporting. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Table-Valued Function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SCHEMABINDING | None | NOT schema-bound. Multi-statement TVF (cannot be schema-bound in SQL Server). |
| Branch 1 returns all history | Design | Branch 1 does NOT filter by @Year/@Month - returns the full quota history. Consumers filter by Year/Month in their WHERE clause. This is intentional but means the function returns more rows than just the requested month. |
| Zero-fill scope | Design | Zero-fill only applies to IsDynamicRouting=1 protocols. Static/non-dynamic protocols are not zero-filled even if they have no quota record. |
| Amount data type | Design | DECIMAL(18,2) - quota amounts are stored with cent precision. Monthly volumes in the tens of millions USD. |

---

## 8. Sample Queries

### 8.1 Get quota for current month (including zero-fills)

```sql
SELECT * FROM Billing.GetMonthlyQuota(2026, 3)
WHERE Year = 2026 AND Month = 3
ORDER BY ProtocolID;
-- Returns all 6 dynamic protocols: 3 with real amounts, 3 with Amount=0
```

### 8.2 Check which protocols are zero-filled for a given month

```sql
SELECT mq.ProtocolID, dp.Name, mq.Amount
FROM Billing.GetMonthlyQuota(2026, 3) mq
JOIN Dictionary.Protocol dp WITH (NOLOCK) ON dp.ProtocolID = mq.ProtocolID
WHERE mq.Year = 2026 AND mq.Month = 3 AND mq.Amount = 0
ORDER BY mq.ProtocolID;
-- Shows which dynamic protocols have no quota recorded for 2026-03
```

### 8.3 Historical quota trend for Checkout protocol

```sql
SELECT Year, Month, Amount
FROM Billing.GetMonthlyQuota(2026, 3)
WHERE ProtocolID = 43  -- Checkout
ORDER BY Year DESC, Month DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetMonthlyQuota | Type: Multi-Statement TVF | Source: etoro/etoro/Billing/Functions/Billing.GetMonthlyQuota.sql*
