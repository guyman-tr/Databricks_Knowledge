"""Test parse_wiki_column_catalog against a sample of ProdSchemas wikis."""
import sys
from pathlib import Path
REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / "tools"))
from merge_wiki_column_comments_into_alter import parse_wiki_column_catalog

samples = [
    "knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Currency.md",
    "knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Roles.md",
    "knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.ScheduledTaskState.md",
    "knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Duration.md",
    "knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.EventType.md",
    "knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.DowntimeCloseStatus.md",
    "knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/Dictionary/Tables/Dictionary.CustomerType.md",
    "knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/Dictionary/Tables/Dictionary.AppropriatenessProduct.md",
    "knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/Dictionary/Tables/Dictionary.ApexValidationError.md",
    "knowledge/ProdSchemas/BankingDBs/FiatDwhDB/Wiki/dbo/Tables/dbo.FiatTransactions.md",
]
for s in samples:
    p = REPO / s
    if not p.exists():
        print(f"NOT FOUND: {s}")
        continue
    text = p.read_text(encoding="utf-8")
    cols = parse_wiki_column_catalog(text)
    print(f"{p.name:<45} -> {len(cols):>3} cols parsed", end="")
    if cols:
        first = cols[0]
        print(f" | first: {first[0]} = {first[1][:60]}{'...' if len(first[1])>60 else ''}")
    else:
        print(" | FAILED to parse any columns")
