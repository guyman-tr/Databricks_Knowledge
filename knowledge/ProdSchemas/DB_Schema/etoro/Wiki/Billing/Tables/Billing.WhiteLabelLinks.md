# Billing.WhiteLabelLinks

> Localized promotional banner configuration for white-label partners - stores image, click, and text URLs for cashier promotional banners, keyed by link type, partner label, and language.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | (LinkID, LabelID, LanguageID) (INT composite, CLUSTERED PK) |
| **Partition** | No ([PRIMARY] filegroup) |
| **Indexes** | 1 (PK only) |
| **Temporal** | No |

---

## 1. Business Meaning

Billing.WhiteLabelLinks stores the promotional banner URL configuration shown in the eToro cashier (deposit/payment UI) for different white-label partner brands and language markets. Each row defines three URLs for a given banner slot (LinkID) in a specific partner's (LabelID) cashier, for a specific language:

- **ImageURL**: The banner image displayed to the customer (hosted on cashier.etoro-trading.com)
- **ClickURL**: The destination when the customer clicks the banner (localized eToro marketing page)
- **TextURL**: Supplementary text link (currently NULL for most rows)

**34 rows** across 4 partner labels and 2 banner slots (LinkIDs 1 and 2), with 14 language variants for LabelID=1 and English-only (LanguageID=1) for LabelIDs 10, 22, and 23.

This table is queried directly by the cashier web application - no stored procedures wrap it in the Billing schema.

---

## 2. Data Overview

| LabelID | LinkID | Languages | Description |
|---------|--------|-----------|-------------|
| 1 | 1 | 14 (all languages) | Main eToro brand - Banner slot 1 |
| 1 | 2 | 14 (all languages) | Main eToro brand - Banner slot 2 |
| 10 | 1 | 1 (English only) | White-label partner 10 - Banner slot 1 |
| 10 | 2 | 1 (English only) | White-label partner 10 - Banner slot 2 |
| 22 | 1 | 1 (English only) | White-label partner 22 - Banner slot 1 |
| 22 | 2 | 1 (English only) | White-label partner 22 - Banner slot 2 |
| 23 | 1 | 1 (English only) | White-label partner 23 - Banner slot 1 |
| 23 | 2 | 1 (English only) | White-label partner 23 - Banner slot 2 |

**Sample data** (LabelID=1, LinkID=1):
- LanguageID=6 (Spanish): ImageURL=`.../es-ES/champ_banner3.gif`, ClickURL=`http://www.etoro.es/why-etoro/etoro-promotions.aspx`
- LanguageID=5 (Russian): ImageURL=`.../ru-RU/champ_banner3.gif`, ClickURL=`http://www.etoro.ru/...`
- LanguageID=4 (Chinese): ImageURL=`.../zh-CN/champ_banner3.gif`, ClickURL=`http://www.etoro.com.cn/...`

---

## 3. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LinkID | INT | NO | - | CODE-BACKED | Part of composite PK. Banner slot identifier within the cashier. 1=primary banner, 2=secondary banner. Not an IDENTITY - values are predefined by the application. |
| 2 | LabelID | INT | NO | - | CODE-BACKED | FK to Dictionary.Label(LabelID). Partner/brand identifier. LabelID=1 is the main eToro brand (14 languages configured); LabelIDs 10, 22, 23 are white-label partners (English only). Part of composite PK. |
| 3 | LanguageID | INT | NO | DEFAULT(1) | CODE-BACKED | FK to Dictionary.Language(LanguageID). Language for this banner entry. DEFAULT=1 (English). LabelID=1 has all 14 languages configured. Part of composite PK. |
| 4 | ImageURL | VARCHAR(300) | YES | - | CODE-BACKED | URL to the banner image file, hosted on cashier.etoro-trading.com. Path includes locale code (e.g., `/es-ES/`, `/zh-CN/`). NULL means no banner image for this combination. |
| 5 | ClickURL | VARCHAR(300) | YES | - | CODE-BACKED | URL the banner links to when clicked. Localized eToro marketing/promotions page. Includes regional TLD (etoro.es, etoro.de, etoro.ru, etoro.com.cn, etoro.ae) for language-specific routing. |
| 6 | TextURL | VARCHAR(100) | YES | - | CODE-BACKED | Supplementary text link URL. Currently NULL for all rows with LabelID=1 - not in active use. Smaller capacity (100) than ImageURL/ClickURL (300). |

---

## 4. Relationships

### 4.1 References To

| Element | Related Object | Relationship Type |
|---------|---------------|-------------------|
| LabelID | Dictionary.Label | FK (FK_BillingWhiteLabelLinks_DictionaryLable_LableID) - note: typo "Lable" in constraint name |
| LanguageID | Dictionary.Language | FK (FK_BillingWhiteLabelLinks_DictionaryLanguage) |

---

## 5. Technical Details

### 5.1 Indexes

| Index Name | Type | Key Columns | Status |
|-----------|------|-------------|--------|
| PK_Test | CLUSTERED PK | LinkID ASC, LabelID ASC, LanguageID ASC | Active |

Note: PK name "PK_Test" is a legacy artifact from initial development - the constraint was never renamed to a production-standard name.

---

## 6. Notes

- No stored procedures reference this table - the cashier web application queries it directly via `SELECT ... WHERE LabelID = @LabelID AND LanguageID = @LanguageID` pattern.
- FK constraint name contains typo: `DictionaryLable_LableID` (should be "Label" / "LabelID").
- The cashier domain `cashier.etoro-trading.com` hosts the banner images; the click URLs point to localized eToro marketing sites.
- TextURL is unused (all NULL for main eToro brand rows) - may have been intended for a text-only fallback banner.

---

*Generated: 2026-03-17 | Quality: 7.8/10 | Phases: 7/11 | CODE-BACKED: 6 | Sources: 0*
*Object: Billing.WhiteLabelLinks | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.WhiteLabelLinks.sql*
