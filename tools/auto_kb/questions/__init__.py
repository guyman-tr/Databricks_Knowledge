"""Question-interest analysis helpers for the auto_kb questions watcher.

Two pure-Python modules:
  normalize.py -- denoise raw NL questions and cluster them into intent
                  signatures (metrics first, classifiers second).
  coverage.py  -- score how well the current skill corpus covers each intent
                  cluster (reusing MCP gateway skill scores + the local router).
"""
