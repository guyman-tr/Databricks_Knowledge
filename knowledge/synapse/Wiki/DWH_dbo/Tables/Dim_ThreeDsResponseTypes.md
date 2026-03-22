# DWH_dbo.Dim_ThreeDsResponseTypes

> Lookup dimension classifying the 15 possible 3D Secure (3DS) authentication response outcomes for credit card deposit transactions — from Unspecified through Success, Timeout, Failed Authentication, and Bypass scenarios. Sourced daily from etoro.Dictionary.ThreeDsResponseTypes via SP_Dictionaries_DL_To_Synapse.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.ThreeDsResponseTypes |
| **Refresh** | Daily (SP_Dictionaries_DL_To_Synapse, TRUNCATE + INSERT) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED (ThreeDsResponseTypeID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_threedsresponsetypes` |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

`DWH_dbo.Dim_ThreeDsResponseTypes` is a 15-row reference table classifying the outcomes of 3D Secure (3DS) credit card authentication during deposit transactions. 3DS is the industry standard for strong customer authentication (Visa Secure, Mastercard Identity Check). When customers make credit card deposits, the platform runs a two-phase 3DS flow: an **Enrollment** phase checking if the card supports 3DS, and an **Authentication** phase where the cardholder verifies their identity.

Source: `etoro.Dictionary.ThreeDsResponseTypes` on etoroDB-REAL. The Generic Pipeline exports this daily to the Bronze data lake, where it is staged into `DWH_staging.etoro_Dictionary_ThreeDsResponseTypes`. `SP_Dictionaries_DL_To_Synapse` loads from that staging table using a TRUNCATE + INSERT pattern.

In DWH, this dimension supports deposit analytics — categorizing card declines by 3DS reason (fraud monitoring, PSP troubleshooting, risk reporting). The column name differs from source: `Name` in `Dictionary.ThreeDsResponseTypes` is stored as `ThreeDsResponseTypesName` in DWH. Unlike most DWH Dims, no ID=0 ETL placeholder row is added because ID 0 (Unspecified) already exists in the production source.

---

## 2. Business Logic

### 2.1 Two-Phase 3DS Classification

**What**: The 15 response codes cover two distinct authentication phases plus bypass/skip states.

**Columns Involved**: `ThreeDsResponseTypeID`, `ThreeDsResponseTypesName`

**Rules**:
- **ID 0** — Unspecified: no 3DS response recorded or not applicable (default state)
- **IDs 1** — Success: authentication passed, cardholder verified
- **IDs 2-6** — Enrollment phase outcomes (card-level checks): 2=Failed Signature, 3=Not Enrolled, 4=Enrollment Unavailable, 5=Bypassed Enrollment, 6=Enrollment Error
- **IDs 7-12** — Authentication phase outcomes (challenge results): 7=Timeout, 8=Failed Authentication, 9=Authentication Error, 10=Authentication Unavailable, 11=Bypassed Authentication, 12=Missing Authentication
- **IDs 13-14** — Special states: 13=Skipped 3ds (recurring/trusted-merchant exemption), 14=Unexpected (unclassified response)

**Diagram**:
```
Deposit submitted
      |
      v
Phase 1: Enrollment
  3=Not Enrolled / 4=Unavailable / 5=Bypassed / 6=Error
      |
      v  (enrolled)
Phase 2: Authentication
  7=Timeout / 8=Failed / 9=Error / 10=Unavailable / 11=Bypassed / 12=Missing
      |
      v  (passed)
  1=Success --> deposit proceeds
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

REPLICATE is optimal for this 15-row table — every node holds a local copy, eliminating data movement when joining to `Fact_BillingDeposit`. Clustered index on `ThreeDsResponseTypeID` supports point lookups.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Deposit count by 3DS outcome | LEFT JOIN Fact_BillingDeposit ON TRY_CAST(ThreeDsResponseType AS INT) = ThreeDsResponseTypeID |
| Authentication failure rate | Filter ThreeDsResponseTypeID IN (2,7,8,9,12) |
| Bypassed 3DS deposits | Filter ThreeDsResponseTypeID IN (5,11,13) |
| 3DS impact on approval rate | Compare PaymentStatusID=2 rate across ThreeDsResponseTypeID groups |

### 3.3 Gotchas

- **Column name rename**: Source `Name` → DWH `ThreeDsResponseTypesName` (pluralized schema naming convention)
- **Fact_BillingDeposit join**: `ThreeDsResponseType` column in `Fact_BillingDeposit` is `nvarchar(max)` (XML-extracted) — requires `TRY_CAST(... AS INT)` for joining
- **No ETL placeholder**: ID 0 (Unspecified) exists in source; ETL does not add an extra placeholder row unlike many other Dims

---

## 4. Elements

### Confidence Tier Legend

| Tier | Tag |
|------|-----|
| Tier 1 — upstream wiki verbatim | (Tier 1 — upstream wiki, Dictionary.ThreeDsResponseTypes) |
| Tier 2 — SP ETL code | (Tier 2 — SP_Dictionaries_DL_To_Synapse) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ThreeDsResponseTypeID | int | NOT NULL | Primary key for the 3DS authentication outcome. Clustered index key. 0=Unspecified, 1=Success, 2=Failed Signature, 3=Not Enrolled, 4=Enrollment Unavailable, 5=Bypassed Enrollment, 6=Enrollment Error, 7=Timeout, 8=Failed Authentication, 9=Authentication Error, 10=Authentication Unavailable, 11=Bypassed Authentication, 12=Missing Authentication, 13=Skipped 3ds, 14=Unexpected. Referenced via the XML-extracted `ThreeDsResponseType` column in Fact_BillingDeposit. (Tier 1 — upstream wiki, Dictionary.ThreeDsResponseTypes) |
| 2 | ThreeDsResponseTypesName | varchar(50) | YES | Human-readable label for the 3DS outcome. Source column is `Name` in Dictionary.ThreeDsResponseTypes; renamed in DWH with plural suffix. Used in deposit reporting to display authentication outcomes. All 15 rows are populated despite nullable DDL. (Tier 1 — upstream wiki, Dictionary.ThreeDsResponseTypes) |
| 3 | UpdateDate | datetime | NOT NULL | ETL load timestamp. Set to GETDATE() on each daily reload by SP_Dictionaries_DL_To_Synapse. Not a production change timestamp — use for ETL freshness monitoring only. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| ThreeDsResponseTypeID | etoro.Dictionary.ThreeDsResponseTypes | ThreeDsResponseTypeID | Passthrough |
| ThreeDsResponseTypesName | etoro.Dictionary.ThreeDsResponseTypes | Name | Renamed (DWH adds plural suffix) |
| UpdateDate | — | — | ETL-computed: GETDATE() at load time |

### 5.2 ETL Pipeline

```
etoro.Dictionary.ThreeDsResponseTypes (etoroDB-REAL, 15 rows)
  |
  v [Generic Pipeline — daily, Override, 1440 min, parquet]
Bronze/etoro/Dictionary/ThreeDsResponseTypes/
  |
  v [staging]
DWH_staging.etoro_Dictionary_ThreeDsResponseTypes
  |
  v [SP_Dictionaries_DL_To_Synapse — TRUNCATE + INSERT]
DWH_dbo.Dim_ThreeDsResponseTypes (15 rows)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.ThreeDsResponseTypes | 15-row 3DS classification table (etoroDB-REAL) |
| Lake | Bronze/etoro/Dictionary/ThreeDsResponseTypes/ | Daily full export (Override, parquet) |
| Staging | DWH_staging.etoro_Dictionary_ThreeDsResponseTypes | Raw staging import |
| ETL | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT; UpdateDate=GETDATE() |
| Target | DWH_dbo.Dim_ThreeDsResponseTypes | 15 rows |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| ThreeDsResponseTypeID | etoro.Dictionary.ThreeDsResponseTypes | Production source (upstream reference) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Fact_BillingDeposit | ThreeDsResponseType (nvarchar) | 3DS outcome per deposit (XML-extracted, needs TRY_CAST for join) |

---

## 7. Sample Queries

### 7.1 List all 3DS response types

```sql
SELECT ThreeDsResponseTypeID, ThreeDsResponseTypesName
FROM [DWH_dbo].[Dim_ThreeDsResponseTypes]
ORDER BY ThreeDsResponseTypeID
-- Returns 15 rows: 0=Unspecified through 14=Unexpected
```

### 7.2 Deposit count by 3DS outcome (last 7 days)

```sql
SELECT
    COALESCE(t.ThreeDsResponseTypesName, 'Unknown/Null') AS ThreeDsOutcome,
    COUNT(*) AS DepositCount
FROM [DWH_dbo].[Fact_BillingDeposit] f
LEFT JOIN [DWH_dbo].[Dim_ThreeDsResponseTypes] t
    ON TRY_CAST(f.ThreeDsResponseType AS INT) = t.ThreeDsResponseTypeID
WHERE f.ModificationDateID >= CONVERT(INT, CONVERT(varchar(8), DATEADD(day,-7,GETDATE()), 112))
GROUP BY t.ThreeDsResponseTypesName
ORDER BY DepositCount DESC
```

### 7.3 ETL freshness check

```sql
SELECT ThreeDsResponseTypeID, ThreeDsResponseTypesName, UpdateDate
FROM [DWH_dbo].[Dim_ThreeDsResponseTypes]
ORDER BY ThreeDsResponseTypeID
-- UpdateDate should equal today's date if ETL ran successfully
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped — simple-dict fast-path.)

---

*Generated: 2026-03-19 | Quality: 8.5/10 | Phases: 7/14 (simple-dict fast-path: P3/P5/P6/P7/P9B/P10 skipped)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4-Inferred | Elements: 10.0/10, Logic: 8.0/10, Relationships: 7.0/10, Sources: 8.0/10*
*Object: DWH_dbo.Dim_ThreeDsResponseTypes | Type: Table | Production Source: etoro.Dictionary.ThreeDsResponseTypes*
