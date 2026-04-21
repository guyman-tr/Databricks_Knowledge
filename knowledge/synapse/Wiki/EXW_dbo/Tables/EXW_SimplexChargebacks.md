# EXW_dbo.EXW_SimplexChargebacks

> 5-row historical archive of Simplex-processed card chargebacks for eToro Wallet, covering 5 fraud disputes from 2019 (Feb–May) that were loaded in a single bulk operation in March 2020. All records are fraud chargebacks processed through ECP Bank with Simplex bearing full liability. Table is frozen — no new data expected.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table |
| **Production Source** | Simplex external chargeback report (one-time bulk load) |
| **Refresh** | Frozen — single bulk load 2020-03-15; Simplex decommissioned ~2022 |
| **Synapse Distribution** | HASH(Payment_ID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

EXW_SimplexChargebacks is a micro reference table holding 5 historical chargeback disputes processed through the Simplex payment provider for eToro Wallet crypto purchases. Each row represents a single card chargeback filed against a Simplex-facilitated transaction, tracking the chargeback type, card network reason code, acquirer reference (ARN), Simplex's liability determination, and the fund settlement narrative.

All 5 records are from 2019 (February to May), were loaded in a single bulk operation on 2020-03-15, and have not been updated since. All disputes are classified as card fraud (CNP fraud), all are processor ECP Bank, and Simplex bore full liability in all cases. The `CB Funds Status` field contains free-text notes from Simplex describing the settlement timeline (e.g., "Funds and fees returned by Simplex on 2019-09").

This table serves as a historical audit trail of chargeback liability for the Simplex integration. With only 5 rows and no new data, its operational value is archival.

---

## 2. Business Logic

### 2.1 Chargeback Liability Model

**What**: Simplex assumed full liability (Is_Simplex_Liable = 1) for all 5 chargebacks.  
**Columns Involved**: Is_Simplex_Liable, CB Funds Status, Chbk_AMT ($)  
**Rules**:
- `Is_Simplex_Liable = 1` → Simplex repays the full chargeback amount to eToro/ECP Bank
- `Is_Simplex_Liable = 0` (not observed) → eToro would bear the loss
- `CB Funds Status` contains the settlement narrative: states which party returned funds and in which period

### 2.2 Card Network Reason Codes

**What**: Chargebacks are categorized by card network reason codes.  
**Columns Involved**: Reason_Code, Reason_Description, Card_Brand  
**Rules**:
- Reason code `10.4` (Visa): "Other Fraud-Card Absent Environment" — CNP (card-not-present) fraud
- Reason code `4837` (Mastercard): "Fraudulent Transaction - No cardholder auth." — CNP fraud
- `Card_Brand` stored in lowercase: "visa", "master"

### 2.3 Transaction Identity Linkage

**What**: `Payment_ID` (GUID) links to EXW_SimplexMapping; `Simplex_ID` (bigint) is Simplex's internal numeric ID.  
**Columns Involved**: Payment_ID, Simplex_ID, ARN  
**Rules**:
- `Payment_ID` format: UUID string — matches `long_id` in EXW_SimplexMapping
- `ARN` (Acquirer Reference Number): 23-digit bank network reference used for tracing transactions through the card network settlement chain
- `Processor_Name = ECP` — all 5 chargebacks routed through ECP Bank (see EXW_ECPBank)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(Payment_ID) distribution with CLUSTERED COLUMNSTORE INDEX. With only 5 rows, distribution strategy is theoretical — the table fits entirely in a single partition. CCI is appropriate for potential future growth if chargeback data were ever backfilled.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Total chargeback amount across all disputes | `SELECT SUM([Chbk_AMT ($)]) FROM [EXW_dbo].[EXW_SimplexChargebacks]` |
| Join chargebacks to original Simplex transactions | `JOIN EXW_SimplexMapping sm ON sm.long_id = ec.Payment_ID` (GUID match) |
| Cross-reference with ECP Bank transactions | `JOIN EXW_ECPBank ecb ON ecb.uti = ec.ARN` (ARN to UTI match) |
| All records (micro table) | `SELECT * FROM [EXW_dbo].[EXW_SimplexChargebacks]` — only 5 rows |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_dbo.EXW_SimplexMapping | `EXW_SimplexMapping.long_id = Payment_ID` | Link chargeback to original Simplex payment record |
| EXW_dbo.EXW_ECPBank | `EXW_ECPBank.uti = ARN` | Link chargeback to ECP Bank transaction record |

### 3.4 Gotchas

- **5 rows only** — this is not a production-scale table; treat as a reference document, not an analytics table
- **Card_Brand lowercase** — "visa" and "master" (not "Visa"/"Mastercard"); filter accordingly
- **CB Funds Status is free text** — no structured enum; contains date references like "2019-09" as part of narrative prose
- **Comments field is empty** in all 5 rows — do not rely on it
- **ARN uniqueness** — all 5 ARNs are 23-digit strings; Visa ARN (74537...) and Mastercard ARN (85301...) follow different issuer prefix patterns

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description copied verbatim from upstream production wiki |
| Tier 2 | Derived from SP/ETL code analysis |
| Tier 3 | Inferred from column name, type, and data samples |
| Tier 4 | Best-available inference — no upstream wiki, external source |
| Tier 5 | Placeholder — domain knowledge only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Payment_ID | nvarchar(216) | YES | Simplex payment transaction GUID (UUID format). Primary link to EXW_SimplexMapping.long_id. Distributed on this column. (Tier 4 — Simplex chargeback report) |
| 2 | Transaction_Date | datetime | YES | Original transaction datetime when the payment was processed. Not the chargeback date — see Chbk_Posting_Date. (Tier 4 — Simplex chargeback report) |
| 3 | Chbk_Posting_Date | date | YES | Date the chargeback was officially posted by the card network or acquiring bank. (Tier 4 — Simplex chargeback report) |
| 4 | Chbk_AMT ($) | money | YES | Chargeback amount in the transaction currency (USD approximation). Values range 125–565 in this dataset. (Tier 4 — Simplex chargeback report) |
| 5 | Chargeback_Type | nvarchar(256) | YES | Category of chargeback. Value: "fraud" (all 5 records). Indicates CNP (card-not-present) fraud disputes. (Tier 4 — Simplex chargeback report) |
| 6 | Is_Simplex_Liable | nvarchar(256) | YES | Liability determination. Value: "1" (all 5 records) = Simplex bears full liability. "0" (not observed) would indicate eToro liability. (Tier 4 — Simplex chargeback report) |
| 7 | Final Decision Date | date | YES | Date when the chargeback dispute was resolved and a final determination was reached. (Tier 4 — Simplex chargeback report) |
| 8 | CB Funds Status | nvarchar(3256) | YES | Free-text narrative describing fund settlement outcome. Examples: "1. Funds and fees returned by Simplex on 2019-09", "2. Funds returned by the AB - fee on Simplex 2019_10". (Tier 4 — Simplex chargeback report) |
| 9 | ARN | nvarchar(256) | YES | Acquirer Reference Number — unique 23-digit identifier assigned by the card network for tracing the transaction through the banking settlement chain. Used for cross-referencing with ECP Bank. (Tier 4 — Simplex chargeback report) |
| 10 | Reason_Code | nvarchar(256) | YES | Card network reason code for the chargeback. Values: 10.4 (Visa CNP fraud), 4837 (Mastercard no-auth fraud). (Tier 4 — Simplex chargeback report) |
| 11 | Reason_Description | nvarchar(256) | YES | Human-readable description of the reason code. Values: "Other Fraud-Card Absent Environment" (code 10.4), "Fraudulent Transaction - No cardholder auth." (code 4837). (Tier 4 — Simplex chargeback report) |
| 12 | Card_Brand | nvarchar(256) | YES | Card network brand in lowercase. Values: "visa", "master". (Tier 4 — Simplex chargeback report) |
| 13 | Processor_Name | nvarchar(256) | YES | Payment processor that handled the original transaction. Value: "ECP" (all 5 records) — ECP Bank (same provider as EXW_ECPBank). (Tier 4 — Simplex chargeback report) |
| 14 | Simplex_ID | bigint | YES | Simplex's internal numeric transaction ID. Corresponds to the Payment_ID in a different format. (Tier 4 — Simplex chargeback report) |
| 15 | Comments | nvarchar(256) | YES | Free-text comments field. Empty in all 5 rows in this dataset. (Tier 4 — Simplex chargeback report) |
| 16 | UpdateDate | datetime | YES | ETL-managed load timestamp. All 5 rows show 2020-03-15 (single bulk load date). Not a business date. (Tier 2 — external ETL) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| All 15 data columns | Simplex chargeback report (external) | API/report fields | Passthrough |
| UpdateDate | ETL pipeline | — | Load timestamp |

### 5.2 ETL Pipeline

```
Simplex Chargeback Report (external, 2019 fraud disputes)
  |-- One-time bulk load (2020-03-15) ---|
  v
EXW_dbo.EXW_SimplexChargebacks (5 rows, historical archive)
  |-- No updates since 2020 — Simplex decommissioned ~2022 ---|
  v
No UC Generic Pipeline mapping (_Not_Migrated)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| Payment_ID | EXW_dbo.EXW_SimplexMapping.long_id | Links chargeback to original Simplex payment attempt |
| ARN | EXW_dbo.EXW_ECPBank.uti | Links chargeback to ECP Bank settlement record via ARN/UTI |

### 6.2 Referenced By

No objects currently reference this table (micro archive table with 5 rows).

---

## 7. Sample Queries

### List All Chargebacks with Original Transaction Details

```sql
SELECT
    cb.Payment_ID,
    cb.Transaction_Date,
    cb.[Chbk_AMT ($)],
    cb.Reason_Code,
    cb.Reason_Description,
    cb.Is_Simplex_Liable,
    cb.Final_Decision_Date,
    cb.[CB Funds Status],
    sm.country,
    sm.crypto_currency,
    CAST(sm.total_amount_usd AS float) AS original_usd_amount
FROM [EXW_dbo].[EXW_SimplexChargebacks] cb
LEFT JOIN [EXW_dbo].[EXW_SimplexMapping] sm
    ON sm.long_id = cb.Payment_ID
ORDER BY cb.Transaction_Date;
```

### Total Chargeback Exposure

```sql
SELECT
    Card_Brand,
    Processor_Name,
    COUNT(*) AS chargeback_count,
    SUM([Chbk_AMT ($)]) AS total_chargeback_amount
FROM [EXW_dbo].[EXW_SimplexChargebacks]
GROUP BY Card_Brand, Processor_Name;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian (Confluence/Jira) sources found for EXW_SimplexChargebacks. This is an external provider report with only 5 rows; no internal documentation expected.

---

*Generated: 2026-04-20 | Quality: 8.5/10 | Phases: 11/14*  
*Tiers: 0 T1, 1 T2, 0 T3, 15 T4, 0 T5 | Elements: 16/16, Logic: 3/10, Data Evidence: P2+P3 PASS*  
*Object: EXW_dbo.EXW_SimplexChargebacks | Type: Table | Production Source: Simplex chargeback report (external)*
