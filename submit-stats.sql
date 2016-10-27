-- Tristan Née
-- Problem Set 4
-- Part A

-- [Problem 1]
DROP FUNCTION IF EXISTS min_submit_interval;
DELIMITER !

/* This function takes in an INTEGER argument specifying the ID of the
submission being investigated. This function returns an INTEGER result
that specifies the minimum amount of time that passed between resubmissions
for the assignment specified by submission_id. 
The return value is in seconds. */
CREATE FUNCTION min_submit_interval(submission_id INTEGER) 
RETURNS INTEGER BEGIN
   DECLARE seconds INTEGER; -- Used to store time interval between a and b
   /* min keeps track of the minimum interval. We initialize it to be very
    * large (larger than the largest interval) for the purpose of the
    * calculations below. */
   DECLARE min INTEGER DEFAULT 10000000;
   -- Variables a and b will be used to compute intervals. 
   DECLARE a INTEGER; -- Left bound of time interval
   DECLARE b INTEGER; -- Right bound of time interval

   -- Cursor, and flag for when fetching is done
   DECLARE done INT DEFAULT 0;
   DECLARE cur CURSOR FOR
      SELECT UNIX_TIMESTAMP(sub_date) AS sub_date
      FROM fileset
      -- Need to order by sub_date so our intervals chronological
      WHERE sub_id = submission_id ORDER BY sub_date;
      /* When fetch is complete, handler sets flag
       * 02000 is MySQL error for "zero rows fetched" */
      DECLARE CONTINUE HANDLER FOR SQLSTATE '02000'
      SET done = 1;
      
   OPEN cur;
   FETCH cur INTO a; -- Store next sub_date in a
   REPEAT -- Repeat until we have no more rows to fetch
      FETCH cur INTO b;
         IF NOT done THEN
            SET seconds = b - a;
         IF seconds < min THEN SET min = seconds; -- Update min if needed
         END IF;
         SET a = b; -- Increment lower bound of interval
      END IF;
   UNTIL done END REPEAT; -- Stop fetching when we run out of rows
   CLOSE cur;
   /* If min is still 0, then we had a submission with less
   * than two file sets, so we set min to NULL */
   IF min = 0 THEN SET min = NULL;
   END IF;
   RETURN min;
END!

DELIMITER ;

-- [Problem 2]
DROP FUNCTION IF EXISTS max_submit_interval;
DELIMITER !

/* This function takes in an INTEGER argument specifying the ID of the
submission being investigated. This function returns an INTEGER result
that specifies the maximum amount of time that passed between resubmissions
for the assignment specified by submission_id. 
The return value is in seconds. */
CREATE FUNCTION max_submit_interval(submission_id INTEGER) 
RETURNS INTEGER
BEGIN
   DECLARE seconds INTEGER; -- Used to store time interval between a and b
   /* max keeps track of the maximum interval. We initialize it to be 0 */
   DECLARE max INTEGER DEFAULT 0;
   -- Variables a and b will be used to compute intervals. 
   DECLARE a INTEGER; -- Left bound of time interval
   DECLARE b INTEGER; -- Right bound of time interval

   -- Cursor, and flag for when fetching is done
   DECLARE done INT DEFAULT 0;
   DECLARE cur CURSOR FOR
      SELECT UNIX_TIMESTAMP(sub_date) AS sub_date
      FROM fileset
      -- Need to order by sub_date so our intervals chronological
      WHERE sub_id = submission_id ORDER BY sub_date;
      /* When fetch is complete, handler sets flag
       * 02000 is MySQL error for "zero rows fetched" */
      DECLARE CONTINUE HANDLER FOR SQLSTATE '02000'
      SET done = 1;
      
   OPEN cur;
   FETCH cur INTO a; -- Store next sub_date in a
   REPEAT -- Repeat until we have no more rows to fetch
      FETCH cur INTO b;
         IF NOT done THEN
            SET seconds = b - a;
         IF seconds > max THEN SET max = seconds; -- Update max if needed
         END IF;
         SET a = b; -- Increment lower bound of interval
      END IF;
   UNTIL done END REPEAT; -- Stop fetching when we run out of rows
   CLOSE cur;
   /* If max is still 0, then we had a submission with less
   * than two file sets, so we set max to NULL */
   IF max = 0 THEN SET max = NULL;
   END IF;
   RETURN max;
END!

DELIMITER ;

-- [Problem 3]
DROP FUNCTION IF EXISTS avg_submit_interval;
DELIMITER !

/* This function computes the average time interval for a specific
 * submission_id. We pass in an INTEGER denoting the submission_id,
 * and we return a DOUBLE representing the average time in seconds. */
CREATE FUNCTION avg_submit_interval(submission_id INTEGER) 
RETURNS DOUBLE 
BEGIN
   DECLARE min INTEGER; -- Minimum date for submission_id
   DECLARE max INTEGER; -- Maximum date for submission_id
   DECLARE num_filesets INTEGER; -- Amount of dates
   DECLARE average DOUBLE; -- Average time interval

   -- Collect minimum and maximum dates
   SELECT UNIX_TIMESTAMP(MIN(sub_date)), UNIX_TIMESTAMP(MAX(sub_date)) 
      INTO min, max
      FROM fileset
      WHERE sub_id = submission_id;

   -- Count the number of dates
   SELECT count(sub_date) INTO num_filesets
      FROM fileset
      WHERE sub_id = submission_id;

   -- The average interval is just the max_date minus the min_date divided
   -- by the number of intervals.
   SET average = (max - min) / (num_filesets - 1);

RETURN average;
END!

DELIMITER ;

-- [Problem 4]
/* Create an index on fileset for sub_id's so that we can check if a particular
 * id submission_id matches sub_id more efficiently. */
CREATE INDEX idx_sub_id ON fileset(sub_id);