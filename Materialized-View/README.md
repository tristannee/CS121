# Materialized-View

Uses a bank database specified in *make-banking.sql*.
*make-branch_stats.sql* creates a materialized view that reports various statistics about
bank branches with associated accounts. Uses triggers to handle inserts, deletes, and updates.
Uses an index on branch_name to speed up SELECT statements (makes queries run up to 5x faster).
