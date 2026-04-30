"""UC bronze leg tooling: generate ALTER COMMENT scripts for bronze tables
from Tier 1 production wikis under knowledge/ProdSchemas/.

Contract:
  build_bronze_scope.py    -> _bronze_scope.json  (mapping x synced wikis)
  generate_bronze_alters.py -> .alter.sql + _deploy-index.md per database
"""
