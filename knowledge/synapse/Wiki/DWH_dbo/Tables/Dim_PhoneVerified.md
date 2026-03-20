# DWH_dbo.Dim_PhoneVerified

> Lookup table defining the 6 phone verification lifecycle states -- from NotVerified through AutomaticallyVerified, ManualyVerified (typo preserved from source), Initiated, Rejected, and AbuseFlag -- used in customer KYC tracking across DWH.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.PhoneVerified |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (PhoneVerifiedID ASC) |
| | |
| **UC Target** | _Pending -- resolved during write-objects_ |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

Dim_PhoneVerified is a 6-row dictionary defining the phone number verification lifecycle states used in eToro's KYC (Know Your Customer) process. Phone verification is a key identity check -- customers must prove ownership of their registered phone number to complete account verification and enable certain platform features. The states cover the full lifecycle: from not yet started (ID=0), through initiation (ID=3), to successful outcomes (IDs 1 and 2), to failed outcomes (ID=4) and abuse detection (ID=5).

The data originates from `etoro.Dictionary.PhoneVerified` on the etoroDB-REAL production SQL Server. The Generic Pipeline exports this table daily (Override strategy) to `Bronze/etoro/Dictionary/PhoneVerified/` in the data lake, with UC Bronze table `general.bronze_etoro_dictionary_phoneverified`.

Loaded by `SP_Dictionaries_DL_To_Synapse` via TRUNCATE + INSERT from `DWH_staging.etoro_Dictionary_PhoneVerified`. Refreshes daily. As of 2026-03-19, UpdateDate is 2026-03-11 -- 8 days stale, consistent with the schema-wide ETL freshness issue.

---

## 2. Business Logic

### 2.1 Phone Verification Lifecycle

**What**: Phone numbers move through 6 verification states from initial submission to final outcome.

**Columns Involved**: `PhoneVerifiedID`, `PhoneVerifiedName`

**Rules**:
- **ID=0 (NotVerified)** -- Default state. Customer's phone has not been verified. May restrict certain platform features.
- **ID=1 (AutomaticallyVerified)** -- Phone verified through automated SMS code or callback system. Highest-throughput path.
- **ID=2 (ManualyVerified)** -- Phone verified by a BackOffice agent who called the customer directly. Used when automated verification fails or for high-value customers. **Note: "ManualyVerified" contains a production typo (single 'l') -- preserved verbatim in DWH.**
- **ID=3 (Initiated)** -- Verification started (SMS sent / call placed) but customer has not yet completed it.
- **ID=4 (Rejected)** -- Verification attempt failed (wrong code, number unreachable, mismatch detected).
- **ID=5 (AbuseFlag)** -- Phone flagged for abuse: multiple accounts sharing one number, known fraud number, or manipulation detected. Triggers compliance investigation.

**Diagram**:
```
Phone Verification Lifecycle
  0 = NotVerified (default)
      |
      v (verification initiated)
  3 = Initiated (SMS sent / call placed)
      |
      +-- Success (auto)  --> 1 = AutomaticallyVerified
      +-- Success (manual) -> 2 = ManualyVerified (BO agent)
      +-- Fail            --> 4 = Rejected
      +-- Abuse detected  --> 5 = AbuseFlag
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with a CLUSTERED INDEX on `PhoneVerifiedID`. With only 6 rows, REPLICATE is optimal -- every compute node holds a full copy, making JOIN operations zero-shuffle-cost. Always join on `PhoneVerifiedID` as the integer key.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table lands as `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_phoneverified`. With 6 rows, no partitioning or Z-ORDER is needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What does a PhoneVerifiedID mean? | JOIN Dim_PhoneVerified ON PhoneVerifiedID for the label |
| Count customers by phone verification state | GROUP BY with Dim_PhoneVerified for readable labels |
| Find customers with abuse-flagged phone numbers | Filter PhoneVerifiedID = 5 |
| Find customers not yet verified | Filter PhoneVerifiedID = 0 |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON dc.PhoneVerifiedID = dpv.PhoneVerifiedID | Resolve phone verification label per customer |
| DWH_dbo.Fact_SnapshotCustomer | ON fsc.PhoneVerifiedID = dpv.PhoneVerifiedID | Phone verification in daily snapshots |
| DWH_dbo.Fact_SnapshotCustomerCloseYear | ON fsc.PhoneVerifiedID = dpv.PhoneVerifiedID | Year-end snapshot phone verification state |

### 3.4 Gotchas

- **Typo in production data**: `PhoneVerifiedName` for ID=2 is `"ManualyVerified"` (single 'l' -- missing second 'l'). This typo originates in the production database and is preserved in DWH. Do not correct it in queries or reporting unless explicitly instructed, as fixing it in the DWH would cause a mismatch with upstream.
- **ID=0 exists**: Unlike Dim_PendingClosureStatus, this table DOES have an ID=0 row (NotVerified). Standard INNER JOIN is safe.
- **Only 6 rows**: Pure enum lookup -- always load the full table, never filter by date.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| **** | Tier 1 - upstream wiki verbatim | (Tier 1 - upstream wiki, Dictionary.PhoneVerified) |
| *** | Tier 2 - Synapse SP code | (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PhoneVerifiedID | int | NO | Primary key identifying the phone verification state. 0=NotVerified (default), 1=AutomaticallyVerified, 2=ManualyVerified (BO agent -- note production typo), 3=Initiated (in-progress), 4=Rejected (failed), 5=AbuseFlag (fraud detected). Stored in Dim_Customer. Referenced by 20+ procedures across BackOffice, Customer, SalesForce, and dbo schemas. (Tier 1 - upstream wiki, Dictionary.PhoneVerified) |
| 2 | PhoneVerifiedName | varchar(50) | NO | Human-readable verification state label. Note: ID=2 has value "ManualyVerified" -- a production typo (single 'l') preserved verbatim from etoro.Dictionary.PhoneVerified. Displayed in customer cards, verification reports, and compliance dashboards. (Tier 1 - upstream wiki, Dictionary.PhoneVerified) |
| 3 | UpdateDate | datetime | NO | ETL load timestamp -- set to GETDATE() on each daily reload by SP_Dictionaries_DL_To_Synapse. Does not reflect production data modification time. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| PhoneVerifiedID | etoro.Dictionary.PhoneVerified | PhoneVerifiedID | passthrough |
| PhoneVerifiedName | etoro.Dictionary.PhoneVerified | PhoneVerifiedName | passthrough (typo preserved) |
| UpdateDate | -- | -- | ETL-computed: GETDATE() on each reload |

Full production documentation: see upstream wiki `Dictionary/Tables/Dictionary.PhoneVerified.md`

### 5.2 ETL Pipeline

```
etoro.Dictionary.PhoneVerified
  -> Generic Pipeline (daily, Override/full-load)
  -> Bronze/etoro/Dictionary/PhoneVerified/
  -> DWH_staging.etoro_Dictionary_PhoneVerified
  -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT)
  -> DWH_dbo.Dim_PhoneVerified
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.PhoneVerified | Production phone verification state dictionary (etoroDB-REAL) |
| Lake | Bronze/etoro/Dictionary/PhoneVerified/ | Daily full export via Generic Pipeline (Override, 1440 min) |
| Staging | DWH_staging.etoro_Dictionary_PhoneVerified | Raw staging import |
| ETL | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT; UpdateDate overridden to GETDATE() |
| Target | DWH_dbo.Dim_PhoneVerified | 6-row enum lookup, REPLICATE distributed |

---

## 6. Relationships

### 6.1 References To (this object points to)

N/A -- leaf dictionary table with no outgoing foreign key references.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Customer | PhoneVerifiedID | Customer-level phone verification state |
| DWH_dbo.Fact_SnapshotCustomer | PhoneVerifiedID | Daily customer snapshot phone verification state |
| DWH_dbo.Fact_SnapshotCustomerCloseYear | PhoneVerifiedID | Year-end closed-account snapshot verification state |

---

## 7. Sample Queries

### 7.1 List all phone verification states

```sql
SELECT PhoneVerifiedID,
       PhoneVerifiedName
FROM   [DWH_dbo].[Dim_PhoneVerified]
ORDER BY PhoneVerifiedID;
```

### 7.2 Count customers by phone verification state

```sql
SELECT  dpv.PhoneVerifiedName,
        COUNT(*) AS CustomerCount
FROM    [DWH_dbo].[Dim_Customer] dc
JOIN    [DWH_dbo].[Dim_PhoneVerified] dpv
        ON dc.PhoneVerifiedID = dpv.PhoneVerifiedID
GROUP BY dpv.PhoneVerifiedName
ORDER BY CustomerCount DESC;
```

### 7.3 Find customers with abuse-flagged or rejected phone numbers

```sql
SELECT  dc.CID,
        dpv.PhoneVerifiedName
FROM    [DWH_dbo].[Dim_Customer] dc
JOIN    [DWH_dbo].[Dim_PhoneVerified] dpv
        ON dc.PhoneVerifiedID = dpv.PhoneVerifiedID
WHERE   dc.PhoneVerifiedID IN (4, 5);
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 8.5/10 (****) | Phases: 7/14 (simple-dict fast-path)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 6/10, Relationships: 8/10, Sources: 9/10*
*Object: DWH_dbo.Dim_PhoneVerified | Type: Table | Production Source: etoro.Dictionary.PhoneVerified*
