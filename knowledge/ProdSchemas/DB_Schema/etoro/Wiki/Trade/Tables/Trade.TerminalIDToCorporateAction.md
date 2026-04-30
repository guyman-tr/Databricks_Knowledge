# Trade.TerminalIDToCorporateAction

> Maps external clearing/settlement system terminal IDs (from Apex or DTC) to internal corporate action type codes, enabling automated processing of dividends, splits, mergers, staking, and promotional distributions.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | None (heap) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | None (heap table) |

---

## 1. Business Meaning

Trade.TerminalIDToCorporateAction is a static reference table that maps terminal IDs from external clearing and settlement systems (such as Apex Clearing or DTC) to eToro's internal corporate action type codes. When eToro receives corporate action notifications from these external systems, the notification includes a terminal ID (e.g., "$+DIV" for dividend, "REREV" for reverse split). This table translates that ID into CorporateActionTypeID so the platform can route the event to the correct processing logic.

This table exists because external systems use their own coding schemes that differ from eToro's internal Dictionary.CorporateAction taxonomy. Without this mapping, incoming corporate action feeds could not be correctly classified, and dividend payments, stock splits, mergers, ADR fees, staking rewards, and promotional cash would not be processed automatically.

Data flows: Static reference data. Rows are loaded during deployment or configuration; the table is read-only at runtime. When a corporate action notification arrives with TerminalID="$+DIV", the system looks up CorporateActionTypeID=1 (Dividend) and routes to dividend processing. Live data has ~75 rows covering the full range of corporate action types used in production.

---

## 2. Business Logic

### 2.1 Terminal ID to Corporate Action Type Mapping

**What**: Each external terminal ID maps to one internal corporate action type.

**Columns/Parameters Involved**: `TerminalID`, `CorporateActionTypeID`, `Description`

**Rules**:
- TerminalID: The code from the external system (e.g., "$+DIV", "REREV", "STAKING")
- CorporateActionTypeID: FK to Dictionary.CorporateAction or Trade.CorporateInstrumentActions; internal type code
- Description: Human-readable label for the terminal ID (e.g., "Dividend", "Reverse split")
- Multiple TerminalIDs can map to the same CorporateActionTypeID (e.g., "$+ADR" and "$+DIV" both map to 1)
- Lookup is by exact TerminalID match; no wildcards

**Diagram**:
```
External notification: TerminalID="$+DIV"
        |
        v
Lookup Trade.TerminalIDToCorporateAction -> CorporateActionTypeID=1 (Dividend)
        |
        v
Route to dividend processing (Trade.PayCashDividendByPayDate, etc.)
```

### 2.2 Corporate Action Type Coverage

**What**: The table covers dividends, splits, mergers, fees, staking, and promotional types.

**Columns/Parameters Involved**: `CorporateActionTypeID`, `Description`

**Rules**:
- CorporateActionTypeID=1: Dividends, ADR fees, cash distributions ("$+ADR", "$+DIV", "$+CIL", "$+INT")
- CorporateActionTypeID=2: Cash in lieu ("$+CIL")
- CorporateActionTypeID=4: Interest ("$+INT")
- CorporateActionTypeID=8: Cash/stock merger ("REMER")
- CorporateActionTypeID=10: Reverse split ("REREV")
- CorporateActionTypeID=35: Staking ("STAKING")
- CorporateActionTypeID=36: Promotion ("PROMO")
- CorporateActionTypeID=42: Promo - Crypto Holders ("PROMO-CRYPTO-HOLDERS")

---

## 3. Data Overview

| TerminalID | Description | CorporateActionTypeID | Meaning |
|---|---|---|---|
| $+DIV | Dividend | 1 | Standard dividend distribution from external system. Most common corporate action; routes to dividend processing. |
| $+CIL | Cash in Lieu | 2 | Cash payment in lieu of fractional shares. Mapped to type 2 for cash-in-lieu processing. |
| REREV | Reverse split | 10 | Reverse stock split notification from clearing. Mapped to type 10 for split adjustment logic. |
| STAKING | Staking | 35 | Crypto staking rewards. Mapped to type 35 for staking distribution processing. |
| PROMO-CRYPTO-HOLDERS | Promo - Crypto Holders | 42 | Promotional distribution for crypto holders. Mapped to type 42 for promo cash routing. |

**Selection criteria for the 5 rows:**
- Table has ~75 rows. Samples show variety: dividends (1), fees (1), interest (4), splits (10), mergers (8), staking (35), promotions (36, 42).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TerminalID | varchar(100) | NO | - | CODE-BACKED | The terminal/code from the external clearing or settlement system (Apex, DTC, etc.). Examples: "$+DIV" (dividend), "REREV" (reverse split), "STAKING" (crypto staking). Used as lookup key when processing incoming corporate action notifications. |
| 2 | Description | varchar(100) | YES | - | CODE-BACKED | Human-readable label for the terminal ID. Examples: "Dividend", "Reverse split", "Staking". Purely descriptive; not used for processing logic. |
| 3 | CorporateActionTypeID | int | NO | - | CODE-BACKED | FK to Dictionary.CorporateAction or Trade.CorporateInstrumentActions. Internal corporate action type code. 1=Dividend/ADR, 2=Cash in Lieu, 4=Interest, 8=Merger, 10=Reverse split, 35=Staking, 36=Promotion, 42=Promo-Crypto. Routes incoming events to correct processing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CorporateActionTypeID | Trade.CorporateInstrumentActions / Dictionary.CorporateAction | Lookup | Internal corporate action type. Resolves to human-readable type name and drives processing routing. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Corporate action ingestion procedures | - | Lookup | Read TerminalIDToCorporateAction to resolve TerminalID from external notifications to CorporateActionTypeID. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TerminalIDToCorporateAction (table)
(No code-level dependencies - CREATE TABLE has no FROM/JOIN)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Corporate action ingestion - not analyzed in this phase) | Procedure/Application | Lookup by TerminalID to get CorporateActionTypeID when processing external notifications. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| None | Heap | - | - | - | N/A |

Table is a heap on DICTIONARY filegroup. No primary key or indexes defined.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| None | - | No constraints defined. Table relies on application logic for uniqueness. |

---

## 8. Sample Queries

### 8.1 Look up corporate action type by terminal ID

```sql
SELECT TerminalID, Description, CorporateActionTypeID
FROM Trade.TerminalIDToCorporateAction WITH (NOLOCK)
WHERE TerminalID = '$+DIV';
```

### 8.2 List all mappings for a corporate action type

```sql
SELECT TerminalID, Description, CorporateActionTypeID
FROM Trade.TerminalIDToCorporateAction WITH (NOLOCK)
WHERE CorporateActionTypeID = 1
ORDER BY TerminalID;
```

### 8.3 Full mapping list with human-readable type (if Dictionary.CorporateAction exists)

```sql
SELECT t.TerminalID, t.Description, t.CorporateActionTypeID,
       ca.CorporateActionType AS TypeName
FROM Trade.TerminalIDToCorporateAction t WITH (NOLOCK)
LEFT JOIN Dictionary.CorporateAction ca WITH (NOLOCK) ON ca.CorporateActionTypeID = t.CorporateActionTypeID
ORDER BY t.CorporateActionTypeID, t.TerminalID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 7.8/10 (Elements: 9/10, Logic: 8/10, Relationships: 6/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TerminalIDToCorporateAction | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.TerminalIDToCorporateAction.sql*
