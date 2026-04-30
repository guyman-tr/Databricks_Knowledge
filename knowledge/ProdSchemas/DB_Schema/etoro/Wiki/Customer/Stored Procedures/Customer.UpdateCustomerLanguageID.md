# Customer.UpdateCustomerLanguageID

> Updates a customer's language preference (LanguageID) on Customer.Customer by CID.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - customer to update; @languageID - new language |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpdateCustomerLanguageID is a targeted setter for a single field: the customer's preferred language. LanguageID in Customer.Customer controls the UI language shown to the customer and may affect email template language selection. This procedure provides a focused, auditable entry point for language changes - avoiding the need for callers to call the broader UpdateBasicUserInfo/UpdateBasicUserInfoRemote procedures when only language is changing.

The procedure is used by language preference settings in the UI or by automated locale-detection flows that update language after the customer selects it during onboarding.

---

## 2. Business Logic

### 2.1 Direct Language Update

**Rules**:
- UPDATE Customer.Customer SET LanguageID = @languageID WHERE CID = @CID
- No validation that @languageID exists in any language lookup table
- SET NOCOUNT ON suppresses row-count messages

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | Customer identifier. The customer whose LanguageID will be updated in Customer.Customer. |
| 2 | @languageID | int | NO | - | CODE-BACKED | Language identifier. Maps to Customer.Customer.LanguageID. Controls the UI language and email language for the customer. No existence validation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | Modifier | Updates LanguageID for the specified customer |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external caller) | - | - | No intra-DB callers found; called from language settings UI or locale-detection flow |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpdateCustomerLanguageID (procedure)
└── Customer.Customer (view - UPDATE target)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | UPDATE target for LanguageID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No intra-DB callers found. | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No validation | Design | Any integer accepted for @languageID |

---

## 8. Sample Queries

### 8.1 Set customer language to English (languageID=1)
```sql
EXEC Customer.UpdateCustomerLanguageID @CID = 12345, @languageID = 1;
```

### 8.2 Check current language
```sql
SELECT CID, LanguageID FROM Customer.Customer WITH (NOLOCK) WHERE CID = 12345;
```

### 8.3 Find customers with a specific language setting
```sql
SELECT CID, LanguageID FROM Customer.Customer WITH (NOLOCK)
WHERE LanguageID = 1 ORDER BY CID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.UpdateCustomerLanguageID | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.UpdateCustomerLanguageID.sql*
