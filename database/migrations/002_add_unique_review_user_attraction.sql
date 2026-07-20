USE `jelajahmy`;

-- Do not alter existing data. If duplicate rows exist, the ALTER statement
-- fails safely so they can be reviewed manually before this migration is run.
SET @constraint_exists = (
    SELECT COUNT(*)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'reviews'
      AND index_name = 'uq_reviews_user_attraction'
      AND non_unique = 0
);

SET @migration_sql = IF(
    @constraint_exists > 0,
    'SELECT ''uq_reviews_user_attraction already exists'' AS migration_status',
    'ALTER TABLE reviews ADD CONSTRAINT uq_reviews_user_attraction UNIQUE (user_id, attraction_id)'
);

PREPARE migration_statement FROM @migration_sql;
EXECUTE migration_statement;
DEALLOCATE PREPARE migration_statement;
