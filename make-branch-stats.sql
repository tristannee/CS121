-- Tristan Née
-- Problem Set 4
-- Part B

-- [Problem 1]
/* Create index on account for branch names so that we can check if a
 * certain branch name matches branch_name more efficiently. */
CREATE INDEX idx_branch_name ON account(branch_name);


-- [Problem 2]
DROP TABLE IF EXISTS mv_branch_account_stats;
/* This table reports various statistics about bank branches
 * with associated accounts. */
CREATE TABLE mv_branch_account_stats (
   branch_name    VARCHAR(15) PRIMARY KEY,
   num_accounts   INTEGER NOT NULL DEFAULT 0,
   total_deposits INTEGER NOT NULL DEFAULT 0,
   min_balance    NUMERIC(12, 2) NOT NULL DEFAULT 0,
   max_balance    NUMERIC(12, 2) NOT NULL DEFAULT 0
);

-- [Problem 3]
/* The following DML statement populates the initial state of
 * the materialized view. */
INSERT INTO mv_branch_account_stats
   SELECT branch_name,
      COUNT(*) AS num_accounts,
      SUM(balance) AS total_deposits,
      MIN(balance) AS min_balance,
      MAX(balance) AS max_balance
   FROM account GROUP BY branch_name;
    
-- [Problem 4]
DROP VIEW IF EXISTS branch_account_stats;
/* This view contains various statistics about bank branches with
 * associated accounts */
CREATE VIEW branch_account_stats AS
   SELECT branch_name,
      num_accounts,
      total_deposits,
      (total_deposits / num_accounts) AS avg_balance,
      min_balance,
      max_balance
   FROM mv_branch_account_stats GROUP BY branch_name;
   
-- [Problem 5]
DELIMITER !

DROP PROCEDURE IF EXISTS sp_insert!
/* Helper procedure for the trg_insert trigger. Updates mv_branch_account_stats
 * with every input sp_branch_name and sp_balance by inserting the
 * corresponding row into the table. */
CREATE PROCEDURE sp_insert (
   IN sp_branch_name VARCHAR(15),
   IN sp_balance NUMERIC(12, 2)
)

BEGIN
   IF sp_branch_name NOT IN (SELECT branch_name FROM mv_branch_account_stats)
   THEN -- If that branch name is the first account for a particular branch
      INSERT INTO mv_branch_account_stats
      -- Create value with a new branch name
	  VALUES (sp_branch_name, 1, sp_balance, sp_balance, sp_balance);
   ELSE -- If there already exists accounts for that branch name
      UPDATE mv_branch_account_stats
	  SET num_accounts = num_accounts + 1,
	  total_deposits = total_deposits + sp_balance,
      -- Update min_balance only if sp_balance is less than min_balance
      min_balance = LEAST(min_balance, sp_balance),
      -- Update max_balance only if sp_balance is more than max_balance
      max_balance = GREATEST(max_balance, sp_balance)
      WHERE branch_name = sp_branch_name; -- Optimized with index
   END IF;
END!

DROP TRIGGER IF EXISTS trg_insert!
/* Trigger change on mv_branch_account_stats after each insert on account.
 * Uses helper procedure sp_insert. */
CREATE TRIGGER trg_insert AFTER INSERT ON account FOR EACH ROW
BEGIN
   CALL sp_insert(NEW.branch_name, NEW.balance);
END!

DELIMITER ;

-- [Problem 6]
DELIMITER !

DROP PROCEDURE IF EXISTS sp_delete!
/* Helper procedure for the trg_delete trigger. Updates mv_branch_account_stats
 * with every input sp_branch_name and sp_balance by deleting the corresponding
 * row from the table. */
CREATE PROCEDURE sp_delete (
    IN sp_branch_name VARCHAR(15),
    IN sp_balance NUMERIC(12, 2)
)
BEGIN
   IF 0 IN (SELECT num_accounts FROM mv_branch_account_stats WHERE
   branch_name = sp_branch_name) THEN
      /* If record is deleted from account table, and it is the last account
       * from that branch, remove the summary information for that branch. */
      DELETE FROM mv_branch_account_stats WHERE branch_name = sp_branch_name;
   ELSE -- If there are more than 1 accounts in that branch
      UPDATE mv_branch_account_stats
      SET num_accounts = num_accounts - 1,
      total_deposits = total_deposits - sp_balance,
      min_balance = (SELECT MIN(balance) FROM 
         account WHERE branch_name = sp_branch_name),
      max_balance = (SELECT MAX(balance) FROM 
         account WHERE branch_name = sp_branch_name)
      WHERE branch_name = sp_branch_name;
    END IF;
END!

DROP TRIGGER IF EXISTS trg_delete!
/* Trigger change on mv_branch_account_stats after each delete on account. 
 * Uses helper procedure sp_delete. */
CREATE TRIGGER trg_delete AFTER DELETE ON account FOR EACH ROW
BEGIN
   CALL sp_delete(OLD.branch_name, OLD.balance);
END!

DELIMITER ;

-- [Problem 7]
DELIMITER !

DROP PROCEDURE IF EXISTS sp_update!
/* Helper procedure for the trg_update trigger. Updates mv_branch_account_stats
 * with every update by updating the corresponding row in the table */
CREATE PROCEDURE sp_update (
   IN old_branch_name VARCHAR(15),
   IN old_balance NUMERIC(12, 2),
   IN new_branch_name VARCHAR(15),
   IN new_balance NUMERIC(12, 2)
)
BEGIN
   -- If update was performed that doesn't change branch name
   IF  old_branch_name = new_branch_name THEN
      UPDATE mv_branch_account_stats
         SET total_deposits = total_deposits - old_balance + new_balance,
         min_balance = (SELECT MIN(balance) FROM account WHERE
            branch_name = old_branch_name),
		 max_balance = (SELECT MAX(balance) FROM account WHERE
            branch_name = old_branch_name)
	     WHERE branch_name = old_branch_name;
   ELSE -- When the update was performed that changes the branch_name
      CALL sp_delete(old_branch_name, old_balance);
      CALL sp_insert(new_branch_name, new_balance);
   END IF;
END!

DROP TRIGGER IF EXISTS trg_update!
-- Trigger change on mv_branch_account_stats after each update on account.
CREATE TRIGGER trg_update AFTER UPDATE ON account FOR EACH ROW
BEGIN
   CALL sp_update(OLD.branch_name, OLD.balance, NEW.branch_name, NEW.balance);
END!
DELIMITER ;

/******* TEST CASES BELOW ********/
-- Test Insert Trigger
-- Insert account with a branch name already in the view:
-- INSERT INTO account VALUES ('A-515', 'Downtown', 5039.22);
-- Insert account with branch name not yet in the view
-- INSERT INTO account VALUES ('A-999', 'Cupertino', 20322.29);


