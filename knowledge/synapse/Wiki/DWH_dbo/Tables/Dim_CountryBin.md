# DWH_dbo.Dim_CountryBin

> BIN (Bank Identification Number) to country and card issuer mapping — resolves the first 6 digits of a payment card to the issuing bank, card type, country, and 3DS security requirements. ~16.4M rows covering global card issuer data.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Dimension / Reference) |
| **Key Identifier** | BinCode (int NOT NULL, CLUSTERED INDEX) |
| **Row Count** | ~16,359,727 rows |
| **Distribution** | REPLICATE |
| **Index** | CLUSTERED INDEX on BinCode ASC |

---

## 1. Business Meaning

`Dim_CountryBin` is a large reference table mapping Bank Identification Numbers (BINs — the first 6-8 digits of a payment card) to the issuing bank, country, card type, and security configuration. Used in deposit processing to:
- Identify the card issuer and country of origin
- Determine card type (credit, debit, prepaid) and category
- Check 3DS security requirements based on BIN

---

## 2. ETL Source & Refresh

| Property | Value |
|----------|-------|
| **Production Source** | `etoro.Dictionary.CountryBin` (etoroDB-REAL) |
| **Staging Table** | `DWH_staging.etoro_Dictionary_CountryBin` |
| **Load SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Load Pattern** | TRUNCATE + INSERT (daily full reload) |
| **Column Mapping** | 11 passthrough, 1 ETL-generated (`UpdateDate`) |

---

## 3. Elements

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | CountryID | int | NO | Tier 2 | Country where the card was issued. References Dim_Country. |
| 2 | BinCode | int | NO | Tier 2 | Bank Identification Number — first 6-8 digits of a payment card. Clustered index key. |
| 3 | IssuingBank | varchar(100) | YES | Tier 2 | Name of the bank that issued the card. |
| 4 | CardTypeID | int | YES | Tier 2 | Card brand identifier. References Dim_CardType (Visa=1, MasterCard=2, etc.). |
| 5 | CardSubType | varchar(50) | YES | Tier 2 | Card sub-classification (e.g., "Credit", "Debit", "Business"). |
| 6 | CardCategory | varchar(50) | YES | Tier 2 | Card tier/category (e.g., "Classic", "Gold", "Platinum"). |
| 7 | BankWebSite | varchar(50) | YES | Tier 2 | Issuing bank's website URL. |
| 8 | BankInfo | varchar(255) | YES | Tier 2 | Additional bank information (phone numbers, address). |
| 9 | ShouldCheck3ds | tinyint | YES | Tier 2 | Whether 3D Secure verification should be applied for this BIN. |
| 10 | MinAmountFor3ds | int | YES | Tier 2 | Minimum transaction amount that triggers 3DS verification. |
| 11 | IsPrepaid | bit | NO | Tier 2 | Whether the card is a prepaid card. |
| 12 | UpdateDate | datetime | NO | Tier 2 | ETL load timestamp — `GETDATE()`. |

---

## 4. Query Advisory

| Aspect | Detail |
|--------|--------|
| **Distribution** | REPLICATE — despite 16.4M rows, replicated for JOIN performance |
| **Clustered Index** | BinCode ASC — optimized for BIN lookups |
| **Warning** | Large REPLICATE table (~16.4M rows) — may have high replication overhead |

---

*Generated: 2026-03-18 | Quality: 7.5/10 | Confidence: 0 Tier 1, 12 Tier 2 | Phases: 1,2,8,11*
*Source: DataPlatform / DWH_dbo / Tables / DWH_dbo.Dim_CountryBin.sql*
