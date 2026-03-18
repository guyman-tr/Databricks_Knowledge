# DWH_dbo.Dim_CashoutReason

> Lookup of reasons for customer withdrawals and fund removals — covers standard user requests, operational adjustments, compliance actions, partner payments, and affiliate payouts.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Dimension) |
| **Key Identifier** | CashoutReasonID (int NOT NULL, CLUSTERED INDEX) |
| **Row Count** | 19 rows |
| **Distribution** | REPLICATE |
| **Index** | CLUSTERED INDEX on CashoutReasonID ASC |

---

## 1. Business Meaning

`Dim_CashoutReason` classifies why a withdrawal was initiated. Each cashout transaction references a reason ID to explain the business context behind the fund removal.

**Category groups**:
- **User-initiated**: Requested by User (16), Partners withdraw (2)
- **Operational adjustments**: Adjustment (1), Negative Balance adjustment (4), Withdraw fees adjustment (5), Returned withdraw (9)
- **Compliance/Risk**: Risk Refund (3), 3rd party payment (7), Bonus abuse adjustment (8), Underage (11), Failed Verification (17)
- **Account actions**: Block account – Not communicative (6), Foreclose account (12), ForClose(GAP) (19)
- **Payments**: PI Payment (14), Affiliate Payment (15), Transfered by CryptoWallet (18)
- **Internal**: Test (13), Technical issue – Customer side (10)

---

## 2. ETL Source & Refresh

| Property | Value |
|----------|-------|
| **Production Source** | `etoro.Dictionary.CashoutReason` (etoroDB-REAL) |
| **Staging Table** | `DWH_staging.etoro_Dictionary_CashoutReason` |
| **Load SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Load Pattern** | TRUNCATE + INSERT (daily full reload) |
| **Column Mapping** | 2 passthrough, 1 ETL-generated (`UpdateDate`) |

---

## 3. Elements

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | CashoutReasonID | int | NO | Tier 2 | Reason identifier. Sequential IDs 1–19. |
| 2 | Name | varchar(50) | NO | Tier 2 | Human-readable reason description (e.g., "Requested by User", "Risk Refund", "Foreclose account"). |
| 3 | UpdateDate | datetime | NO | Tier 2 | ETL load timestamp — `GETDATE()`. |

---

*Generated: 2026-03-18 | Quality: 7.5/10 (Elements: 7/10, Logic: 8/10, Relationships: 6/10, Sources: 8/10)*
*Confidence: 0 Tier 1, 3 Tier 2, 0 Tier 4 [UNVERIFIED] | Phases: 1,2,8,11*
*Source: DataPlatform / DWH_dbo / Tables / DWH_dbo.Dim_CashoutReason.sql*
