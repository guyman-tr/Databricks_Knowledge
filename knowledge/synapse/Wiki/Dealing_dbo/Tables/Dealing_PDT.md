# Dealing_dbo.Dealing_PDT

> Daily Pattern Day Trader (PDT) round trip tracking — identifies US-regulated customers approaching or exceeding the PDT threshold.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | `ExternalOperations.Trade.PdtOperations` (Apex clearing) |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX on Date |

---

## 1. Business Meaning

This table tracks customers who have triggered Pattern Day Trader (PDT) rules. PDT is a US SEC/FINRA regulation: customers who execute 4+ day-trades (round trips) within 5 business days in a margin account with less than $25,000 equity are flagged. This table records customers with 3+ round trips per day who are in a non-OK status.

Each row represents one customer on one day with their round trip count and PDT status. On days with no qualifying customers, a single row with NULL values (except Date and UpdateDate) is inserted to confirm the SP ran.

Source: `Dealing_staging.External_ExternalOperations_Trade_PdtOperations` (Apex clearing broker PDT operations data). Status resolved via `External_ExternalOperations_Dictionary_PdtStatus`. ApexID from `etoro_Customer_CustomerStatic`.

Author: Sarah Benchitrit, created 2021-08-05. ROW_NUMBER PARTITION BY CID ORDER BY Occurred DESC ensures latest occurrence per customer per day.

---

## 2. Business Logic

### 2.1 PDT Threshold Filtering

**What**: Only customers with 3+ round trips AND non-OK status are included.

**Rules**:
- `TotalRoundTrips >= 3` (approaching the 4-round-trip PDT trigger)
- `PdtStatus.Name <> 'OK'` (only warning/flagged states)
- Latest occurrence per customer per day (ROW_NUMBER=1)

### 2.2 Empty Day Handling

**What**: On days with no qualifying customers, a placeholder row is inserted.

**Rules**: LEFT JOIN from Dim_Date ensures Date + UpdateDate are populated; all other columns NULL. This confirms the SP executed successfully.

---

## 3. Query Advisory

### 3.1 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Today's PDT warnings | `WHERE Date = @date AND CID IS NOT NULL` |
| Customer PDT history | `WHERE CID = @cid ORDER BY Date` |
| PDT warning trend | `SELECT Date, COUNT(*) WHERE CID IS NOT NULL GROUP BY Date` |

### 3.2 Gotchas

- **NULL rows**: Days with no PDT-flagged customers have one row where only Date and UpdateDate are populated. Filter `WHERE CID IS NOT NULL` for actual PDT events.
- **Status 'OK' excluded**: Customers in OK status are not recorded, even if they have 3+ round trips.
- **Apex-specific**: PDT tracking is via Apex clearing broker. Only applies to US-regulated customers using Apex.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Report date. (Tier 2 — SP_PDT) |
| 2 | RoundTripsCounter | int | YES | Number of day-trade round trips for this customer on this date. Only values ≥ 3 are recorded. NULL on empty days. (Tier 2 — SP_PDT) |
| 3 | CID | int | YES | Customer ID. NULL on empty days (no qualifying customers). (Tier 2 — SP_PDT) |
| 4 | ApexID | varchar(30) | YES | Apex clearing broker account ID. Customer's external identifier in the Apex system. Format: alphanumeric (e.g., "3EW35324"). (Tier 2 — SP_PDT) |
| 5 | UpdateDate | datetime | YES | ETL load timestamp. `GETDATE()`. (Tier 2 — SP_PDT) |
| 6 | Status | varchar(50) | YES | PDT status label from PdtStatus dictionary. Values observed: 'WARN'. Status 'OK' is excluded. NULL on empty days. (Tier 2 — SP_PDT) |

---

## 5. Lineage

### 5.1 ETL Pipeline

```
ExternalOperations.Trade.PdtOperations → Dealing_staging → SP_PDT → Dealing_PDT
```

---

*Generated: 2026-03-21 | Quality: 7.0/10 (★★★☆☆) | Phases: 7/14*
*Tiers: 0 T1, 6 T2, 0 T3, 0 T4, 0 T5 | Elements: 10/10, Logic: 8/10, Relationships: 5/10, Sources: 7/10*
*Object: Dealing_dbo.Dealing_PDT | Type: Table | Production Source: External (Apex clearing)*
