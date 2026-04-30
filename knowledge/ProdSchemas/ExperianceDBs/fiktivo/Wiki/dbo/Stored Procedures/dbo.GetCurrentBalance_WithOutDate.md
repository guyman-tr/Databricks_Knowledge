# dbo.GetCurrentBalance_WithOutDate

> Calculates an affiliate's total outstanding (unpaid) all-time commission balance across sales, chargebacks, CPA, leads, registrations, and eCost; optimised in June 2024 to use the ClosedPositionDailySummary aggregate table.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A |
| **Author** | Guy Mansano (modified by Amir Moualem, Elad Marom; updated by Noga, Feb 2023 and Jun 2024) |
| **Created** | 2011-12-04 |

---

## 1. Business Meaning

The affiliate portal balance widget must display the total amount currently owed to an affiliate across all time and all commission types. This is the most frequently called balance variant and must be as fast as possible.

To meet that performance requirement, the June 2024 update (PART-3602) replaced the per-row scan of AffiliateCommission.ClosedPosition with a read from AffiliateCommission.ClosedPositionDailySummary, a pre-aggregated daily summary table. This dramatically reduces I/O for affiliates with large closed-position histories.

The procedure sums across six commission streams (sales via daily summary, chargebacks, CPA, leads, registrations, eCost) and returns a single float representing the total unpaid balance. Copy traders and first positions are present in the WithDate variant but are absent here -- they were removed during the PART-1052 migration.

---

## 2. Business Logic

### 2.1 Sales from Daily Summary (PART-3602)

**What**: Reads pre-aggregated unpaid sales commissions from the daily summary table.

**Columns/Parameters Involved**: `AffiliateCommission.ClosedPositionDailySummary`, `AffiliateID`, `PartitionCol`, `Valid`, `Paid`

**Rules**:
- PartitionCol = AffiliateID % 100 is a partition pruning hint that must be applied to leverage the table's partition scheme
- Valid != 0 and Paid = 0 filters ensure only valid, unpaid rows are summed
- This replaces the per-row ClosedPosition scan used in the WithDate variant

### 2.2 Chargeback Commission (CreditTypeID IN (4,5))

**What**: Sums unpaid chargeback credit commissions.

**Rules**:
- Joins AffiliateCommission.Credit to AffiliateCommission.CreditCommission on CreditID
- CreditTypeID IN (4,5) restricts to chargeback credit types
- Valid != 0 and Paid = 0

### 2.3 CPA Commission (CreditTypeID = 1)

**What**: Sums unpaid CPA commissions.

**Rules**:
- CreditTypeID = 1 selects CPA credits
- Valid != 0 and Paid = 0; no date filter

### 2.4 Leads Commission

**What**: Sums unpaid lead commissions from legacy tables.

**Rules**:
- AffiliateSaleAccepted != 0 and Valid != 0 required
- Paid = 0; no date filter

### 2.5 Registrations Commission

**What**: Sums unpaid registration commissions using the new AffiliateCommission schema.

**Rules**:
- Joins AffiliateCommission.Registration to AffiliateCommission.RegistrationCommission (note: WithDate uses dbo.tblaff_Registrations_Commissions; this procedure uses the schema-qualified version)
- Paid = 0; no date filter

### 2.6 eCost Commission

**What**: Sums unpaid eCost commissions.

**Rules**:
- Joins tblaff_eCost to tblaff_eCost_Commissions on eCostID
- Paid = 0; no date filter

### 2.7 Final Summation

**What**: Returns the sum of all six components as a single float.

**Rules**:
- Each component uses ISNULL / IsNull with default 0
- Final SELECT: @resultSales + @resultChargeBacks + @resultCpa + @resultLeads + @resultRegistration + @resultEcost aliased as "float"

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Parameter | Direction | Type | Default | Description |
|---|-----------|-----------|------|---------|-------------|
| 1 | @affiliateId | IN | int | (required) | The AffiliateID for which to calculate the total all-time outstanding balance. |

---

## 5. Relationships

### 5.1 Tables Written

None. Read-only procedure.

### 5.2 Tables Read

| Table | Operation | Notes |
|-------|-----------|-------|
| AffiliateCommission.ClosedPositionDailySummary | SELECT | Pre-aggregated daily sales summary; replaces per-row scan (PART-3602) |
| AffiliateCommission.Credit | SELECT | CPA and chargeback credit events |
| AffiliateCommission.CreditCommission | SELECT (INNER JOIN) | Commission amounts for credits |
| dbo.tblaff_Leads | SELECT | Lead events |
| dbo.tblaff_Leads_Commissions | SELECT (LEFT JOIN) | Lead commission amounts |
| AffiliateCommission.Registration | SELECT | Registration events |
| AffiliateCommission.RegistrationCommission | SELECT (INNER JOIN) | Registration commission amounts |
| dbo.tblaff_eCost | SELECT | eCost events |
| dbo.tblaff_eCost_Commissions | SELECT (LEFT JOIN) | eCost commission amounts |

### 5.3 Result Set

| Column | Source | Description |
|--------|--------|-------------|
| float | Calculated | Total all-time outstanding unpaid commission balance for the affiliate |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetCurrentBalance_WithOutDate (stored procedure)
+-- AffiliateCommission.ClosedPositionDailySummary (table) [partitioned scan]
+-- AffiliateCommission.Credit / CreditCommission (tables)
+-- dbo.tblaff_Leads / tblaff_Leads_Commissions (tables)
+-- AffiliateCommission.Registration / RegistrationCommission (tables)
+-- dbo.tblaff_eCost / tblaff_eCost_Commissions (tables)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.ClosedPositionDailySummary | Table | Optimised sales commission aggregate |
| AffiliateCommission.Credit | Table | CPA and chargeback events |
| AffiliateCommission.CreditCommission | Table | Credit commission amounts |
| dbo.tblaff_Leads | Table | Lead events |
| dbo.tblaff_Leads_Commissions | Table | Lead commission amounts |
| AffiliateCommission.Registration | Table | Registration events |
| AffiliateCommission.RegistrationCommission | Table | Registration commission amounts |
| dbo.tblaff_eCost | Table | eCost events |
| dbo.tblaff_eCost_Commissions | Table | eCost commission amounts |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.GetCurrentBalance | Stored Procedure | Calls this procedure when both @FromDate and @ToDate are NULL |
| Affiliate portal balance widget | Application | Displays current outstanding balance |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Notes

- SET NOCOUNT ON suppresses rowcount messages
- All table accesses use WITH (NOLOCK) or with(nolock)
- PART-1052 (Feb 2023, Noga): migrated to new AffiliateCommission schema, fixed balance bug, removed bonuses
- PART-3602 (Jun 2024, Noga): switched sales source from AffiliateCommission.ClosedPosition to AffiliateCommission.ClosedPositionDailySummary for performance; PartitionCol = AffiliateID % 100 is a mandatory partition filter
- Copy traders (@resultCopyTraders) and first positions are not included in this procedure -- they were present in earlier versions but were removed during the PART-1052 migration

---

## 8. Sample Queries

### 8.1 Get an affiliate's full all-time outstanding balance

```sql
EXEC dbo.GetCurrentBalance_WithOutDate @affiliateId = 1001;
```

### 8.2 Verify the sales component directly

```sql
SELECT ISNULL(SUM(Commission), 0) AS UnpaidSales
FROM AffiliateCommission.ClosedPositionDailySummary WITH (NOLOCK)
WHERE AffiliateID = 1001
  AND PartitionCol = 1001 % 100
  AND Valid <> 0
  AND Paid = 0;
```

### 8.3 Verify the eCost component directly

```sql
SELECT ISNULL(SUM(ec_comm.Commission), 0) AS UnpaidEcost
FROM dbo.tblaff_eCost ec WITH (NOLOCK)
JOIN dbo.tblaff_eCost_Commissions ec_comm WITH (NOLOCK) ON ec.eCostID = ec_comm.eCostID
WHERE ec_comm.AffiliateID = 1001
  AND ec_comm.Paid = 0;
```

---

## 9. Atlassian Knowledge Sources

- PART-1052 (Feb 2023, Noga): Migrated to new AffiliateCommission schema, fixed outstanding balance bug, removed bonuses from balance calculation.
- PART-3602 (Jun 2024, Noga): Changed sales source to AffiliateCommission.ClosedPositionDailySummary to improve performance at scale.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10*
*Object: dbo.GetCurrentBalance_WithOutDate | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetCurrentBalance_WithOutDate.sql*
