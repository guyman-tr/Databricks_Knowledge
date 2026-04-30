# Billing.GetCountryNameById

> Returns the country name for a given CountryID from Dictionary.Country. Simple single-row lookup used by the CashoutTool for displaying country names in withdrawal processing.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CountryID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetCountryNameById` is a minimal lookup procedure: given a CountryID, it returns the country's full name. Used by the CashoutTool to display the human-readable country name during withdrawal processing (e.g., for wire transfer destination country display).

Created by Evgeny Semenchenko, 10/11/2022, MIMOPSA-7819.

---

## 2. Business Logic

### 2.1 Country Name Lookup

**What**: Returns the Name column from Dictionary.Country for a specific CountryID.

**Rules**:
- Single row expected (CountryID is PK of Dictionary.Country)
- Returns empty result set if CountryID not found (no error)
- `WITH(NOLOCK)` - dirty read acceptable for static reference data

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CountryID | int | NO | - | VERIFIED | The country ID to look up. References Dictionary.Country.CountryID. |

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Name | varchar | NO | - | VERIFIED | Full country name (e.g., "United States", "United Kingdom"). From Dictionary.Country.Name. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CountryID | Dictionary.Country | Read | Single-row lookup by primary key. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CashoutTool (role) | EXECUTE permission | Permission | Withdrawal processing tool for country name display. |

---

## 6. Dependencies

```
Billing.GetCountryNameById (procedure)
└── Dictionary.Country (table)
```

---

## 7. Technical Details

N/A for Stored Procedure.

---

## 8. Sample Queries

```sql
EXEC Billing.GetCountryNameById @CountryID = 1
-- Returns: Name = "United States" (or equivalent)

SELECT Name FROM Dictionary.Country WITH (NOLOCK) WHERE CountryID = 1
-- Direct equivalent
```

---

## 9. Atlassian Knowledge Sources

MIMOPSA-7819 is the creation ticket (November 2022, Evgeny Semenchenko).

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetCountryNameById | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetCountryNameById.sql*
