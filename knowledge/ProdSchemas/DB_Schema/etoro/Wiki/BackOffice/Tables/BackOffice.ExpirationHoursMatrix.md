# BackOffice.ExpirationHoursMatrix

> Empty configuration matrix (0 rows) designed to specify payment expiration windows in hours, keyed by CID parity (even/odd), payment provider, and white-label brand. Used exclusively by ExpirationHoursCalc - if no row matches, the fallback is expiration date of '3000-01-01' (never expires). PK constraint named "PK_SomeTable" reveals a placeholder left from development.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | (CID_MODE, RealProviderID, LabelID) - composite CLUSTERED PK |
| **Partition** | No (stored ON [PRIMARY] filegroup) |
| **Indexes** | 1 active (1 clustered composite PK) |

---

## 1. Business Meaning

BackOffice.ExpirationHoursMatrix is a configuration table intended to define how many hours a payment instrument or transaction remains valid before expiring, differentiated by:

- **CID_MODE**: Customer ID parity (CID % 2 = 0 for even CIDs, 1 for odd CIDs) - enables A/B testing or phased rollouts of different expiration windows.
- **RealProviderID**: The payment provider (no declared FK - resolved at runtime).
- **LabelID**: The white-label brand (FK to Dictionary.Label - eToro, RetailFX, eToroUSA, etc.).

The consuming procedure ExpirationHoursCalc uses this table as a lookup: if a matching (CID_MODE, RealProviderID, LabelID) row is found, ExpirationDate = NOW + ExpirationHours. If no row matches, the fallback is '3000-01-01' - effectively "this payment never expires."

The table is currently empty (0 rows as of 2026-03-17). ExpirationHoursCalc therefore always returns '3000-01-01' in production (plus two server-specific bypasses that also return '3000-01-01' unconditionally). This suggests the expiration matrix was designed for a feature that was never activated, or was used briefly and then cleared.

**Notable**: The PK constraint is named "PK_SomeTable" - a developer placeholder that was never corrected, indicating the table was created quickly and possibly never reached production use.

---

## 2. Business Logic

### 2.1 Expiration Hours Lookup (ExpirationHoursCalc)

**What**: Calculates an expiration DateTime for a given customer + provider + brand combination.

**Columns Involved**: `CID_MODE`, `RealProviderID`, `LabelID`, `ExpirationHours`

**Rules**:
- ExpirationHoursCalc(@CID, @RealProviderID, @LabelID, @ExpirationDate OUTPUT):
  1. **Demo server bypass**: If running on AMS-QUAD-SQL-1 (QUADFOOT demo server) with database 'tradonomi' AND customer has positive net deposits (Billing.GetSumAmountByCID) -> set @ExpirationDate = '3000-01-01', RETURN. (Table not consulted.)
  2. **BIGFOOT bypass**: If running on AMS-BIG-SQL-1 -> set @ExpirationDate = '3000-01-01', RETURN. (Table not consulted.)
  3. **Matrix lookup**: SELECT ExpirationHours WHERE CID_MODE = @CID % 2 AND RealProviderID = @RealProviderID AND LabelID = @LabelID.
  4. **Row found**: @ExpirationDate = DATEADD(hour, ExpirationHours, GETDATE()).
  5. **No row found**: @ExpirationDate = '3000-01-01' (never expires - current behavior since table is empty).
- CID_MODE = @CID % 2 partitions customers into two cohorts (even/odd CID), allowing different expiration rules per cohort.

---

## 3. Data Overview

0 rows as of 2026-03-17. The table is empty - no expiration rules are configured. ExpirationHoursCalc always returns '3000-01-01' for all requests (payments never expire).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID_MODE | smallint | NO | - | VERIFIED | Customer ID parity bucket. Computed as CID % 2 at query time. 0 = even CIDs, 1 = odd CIDs. Enables split-testing expiration configurations between two customer cohorts. Leading key of composite PK. SMALLINT - only values 0 and 1 are valid. |
| 2 | RealProviderID | int | NO | - | CODE-BACKED | Payment provider identifier. Part of composite PK. No FK constraint declared - references a payment provider lookup resolved by the calling application. Allows different expiration windows per payment method. |
| 3 | LabelID | int | NO | - | VERIFIED | White-label brand identifier. Part of composite PK. FK (WITH CHECK) to Dictionary.Label. Values include: 0/1/9=eToro, 2=RetailFX, 14=eToroUSA, 27=eToro-Partners, 29=eToroRussia, 31=eToroChina, and 20+ white-label partners (JCLyons, ICMarkets, BT, Euroforex, etc.). Allows different expiration rules per brand. |
| 4 | ExpirationHours | int | NO | - | VERIFIED | Number of hours from the current time until the transaction/payment expires. Used in DATEADD(hour, ExpirationHours, GETDATE()). Never NULL (NOT NULL constraint). If no row is found, fallback is '3000-01-01' (never expires). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LabelID | Dictionary.Label | FK (WITH CHECK) | White-label brand (eToro, RetailFX, eToroUSA, etc.) |
| RealProviderID | (payment provider table) | Implicit | Payment provider - no declared FK |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.ExpirationHoursCalc | CID_MODE, RealProviderID, LabelID | READER | Looks up expiration window; falls back to '3000-01-01' if no row |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.ExpirationHoursMatrix (config table)
- FK target: Dictionary.Label (LabelID)
- Reader: BackOffice.ExpirationHoursCalc
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Label | Table | FK on LabelID (white-label brand) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.ExpirationHoursCalc | Procedure | READER - looks up ExpirationHours by (CID%2, RealProviderID, LabelID) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Status |
|-----------|------|-------------|--------|
| PK_SomeTable | CLUSTERED PK | CID_MODE ASC, RealProviderID ASC, LabelID ASC | Active (FILLFACTOR=90, ON [PRIMARY]) |

Note: The PK constraint name "PK_SomeTable" is a developer placeholder that was never renamed - indicating the table was created rapidly and possibly never productionized.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_SomeTable | PK | Uniqueness of (CID_MODE, RealProviderID, LabelID) |
| FK_BEHM_DILA | FK (WITH CHECK) | LabelID -> Dictionary.Label(LabelID) |

---

## 8. Sample Queries

### 8.1 Get expiration hours for a given customer + provider + brand
```sql
SELECT ExpirationHours
FROM BackOffice.ExpirationHoursMatrix WITH (NOLOCK)
WHERE CID_MODE = @CID % 2
  AND RealProviderID = @RealProviderID
  AND LabelID = @LabelID
```

### 8.2 View all configured expiration rules with labels
```sql
SELECT ehm.CID_MODE,
       ehm.RealProviderID,
       dl.Name AS Label,
       ehm.ExpirationHours,
       CAST(ehm.ExpirationHours / 24.0 AS DECIMAL(10,1)) AS ExpirationDays
FROM BackOffice.ExpirationHoursMatrix ehm WITH (NOLOCK)
JOIN Dictionary.Label dl WITH (NOLOCK) ON dl.LabelID = ehm.LabelID
ORDER BY ehm.LabelID, ehm.RealProviderID, ehm.CID_MODE
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. The empty table state and placeholder PK name suggest this feature was designed but never deployed to production.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.ExpirationHoursMatrix | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.ExpirationHoursMatrix.sql*
