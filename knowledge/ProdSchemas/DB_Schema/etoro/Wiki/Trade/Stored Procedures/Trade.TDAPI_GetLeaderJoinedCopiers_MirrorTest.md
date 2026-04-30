# Trade.TDAPI_GetLeaderJoinedCopiers_MirrorTest

> Test copy of Trade.TDAPI_GetLeaderJoinedCopiers with identical SQL body. Used for isolated testing of the mirror-based PnL approach (#MirrorPnL temp table, PnLInDollars) without affecting the production procedure.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ParentCID INT (test copy of TDAPI_GetLeaderJoinedCopiers, identical SQL) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is a test copy of `Trade.TDAPI_GetLeaderJoinedCopiers` (the production baseline). The SQL body is identical: same `#MirrorPnL` temp table pipeline, same two result sets, same privacy masking, same dynamic sort and pagination, same @MinCopiersToDisplay commented-out guard.

The `_MirrorTest` suffix indicates this was likely used to test the mirror-based PnL approach (loading Trade.PnL.PnLInDollars at the MirrorID level into a clustered temp table with OPTION RECOMPILE) as an alternative to the PositionTbl+PositionTreeInfo approach used in older variants.

For full documentation of the business logic, parameters, and output columns, see: **[Trade.TDAPI_GetLeaderJoinedCopiers](Trade.TDAPI_GetLeaderJoinedCopiers.md)**

---

## 2. Business Logic

Identical to `Trade.TDAPI_GetLeaderJoinedCopiers`. See parent document for full details.

Key characteristics (same as base):
- **#MirrorPnL temp table**: Pre-materializes PnLInDollars per MirrorID from Trade.PnL, with CIX on MirrorID and OPTION(RECOMPILE) on INSERT
- **RS1**: ActiveJoiners count (non-internal copiers within date window)
- **RS2**: Paginated copier list with privacy masking (OperationTypeID=3 -> Anonymous User)
- **Formulas**: InvestedPercentage (equity allocation %), NetProfitPercentage (return on invested %)
- **Sort/Pagination**: @OrderColumn 1-6, max 50 rows/page
- **Date window**: @StartDate defaults to 1 month ago; 1-year hard cap enforced

---

## 3-9. All Other Sections

See **[Trade.TDAPI_GetLeaderJoinedCopiers](Trade.TDAPI_GetLeaderJoinedCopiers.md)** - this procedure is an exact copy.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TDAPI_GetLeaderJoinedCopiers_MirrorTest | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TDAPI_GetLeaderJoinedCopiers_MirrorTest.sql*
