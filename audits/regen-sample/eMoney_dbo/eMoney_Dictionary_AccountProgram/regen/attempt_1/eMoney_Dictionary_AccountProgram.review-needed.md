# Review Needed: eMoney_dbo.eMoney_Dictionary_AccountProgram

## Review Items

### 1. UpdateDate Staleness

**Severity**: Low
**Details**: All 3 rows have identical UpdateDate = 2023-06-12 03:48:01. Despite the Generic Pipeline running daily (Override, 1440 min), the data appears unchanged since initial load. Confirm whether:
- The upstream Dictionary.AccountPrograms has not been updated since June 2023
- The Override strategy is re-loading the same 3 values each day (expected for static dictionaries)

### 2. Column Type Narrowing

**Severity**: Low
**Details**: Upstream `Name` is `nvarchar(32-50)` (Unicode); Synapse `AccountProgram` is `varchar(50)` (non-Unicode). If any future Account Program name contains non-ASCII characters, data loss could occur during the type narrowing.

### 3. Nullable Primary Key

**Severity**: Low
**Details**: `AccountProgramID` is nullable in Synapse (no PK constraint) even though the upstream `Id` is a non-nullable clustered PK. This is a common Synapse pattern (no PK enforcement) but could allow NULL rows if ETL errors occur.

---

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 2 | AccountProgramID, AccountProgram |
| Tier 2 | 1 | UpdateDate |

## Upstream Wiki Used

- FiatDwhDB.Dictionary.AccountPrograms (`C:\Users\guyman\Documents\github\BankingDBs\FiatDwhDB\Wiki\Dictionary\Tables\Dictionary.AccountPrograms.md`)

---

*Generated: 2026-04-27 | Object: eMoney_dbo.eMoney_Dictionary_AccountProgram*
