--
-- Tests for Oracle-compatible BULK COLLECT INTO and TYPE IS TABLE OF
--

-- Create test tables
CREATE TABLE test_bulk_emp (id integer, name text, salary numeric);
INSERT INTO test_bulk_emp VALUES (1, 'Alice', 5000.00);
INSERT INTO test_bulk_emp VALUES (2, 'Bob', 6000.50);
INSERT INTO test_bulk_emp VALUES (3, 'Charlie', 7500.75);
INSERT INTO test_bulk_emp VALUES (4, 'Diana', 4500.25);

--
-- Test 1: TYPE IS TABLE OF with BULK COLLECT INTO (SELECT)
--
DO $$
DECLARE
    TYPE int_table IS TABLE OF integer;
    TYPE text_table IS TABLE OF text;
    TYPE numeric_table IS TABLE OF numeric;
    v_ids int_table;
    v_names text_table;
    v_salaries numeric_table;
BEGIN
    SELECT id, name, salary BULK COLLECT INTO v_ids, v_names, v_salaries
    FROM test_bulk_emp ORDER BY id;

    RAISE NOTICE 'Test 1 - Row count: %', array_length(v_ids, 1);
    RAISE NOTICE 'Test 1 - IDs: %', v_ids;
    RAISE NOTICE 'Test 1 - Names: %', v_names;
    RAISE NOTICE 'Test 1 - Salaries: %', v_salaries;
END;
$$;

--
-- Test 2: BULK COLLECT INTO with standard PostgreSQL array variables
--
DO $$
DECLARE
    v_ids integer[];
    v_names text[];
BEGIN
    SELECT id, name BULK COLLECT INTO v_ids, v_names
    FROM test_bulk_emp WHERE id <= 2 ORDER BY id;

    RAISE NOTICE 'Test 2 - IDs: %', v_ids;
    RAISE NOTICE 'Test 2 - Names: %', v_names;
END;
$$;

--
-- Test 3: BULK COLLECT INTO with empty result
--
DO $$
DECLARE
    TYPE int_table IS TABLE OF integer;
    v_ids int_table;
BEGIN
    SELECT id BULK COLLECT INTO v_ids
    FROM test_bulk_emp WHERE id > 100;

    RAISE NOTICE 'Test 3 - Empty array: %', v_ids;
    RAISE NOTICE 'Test 3 - Length is NULL: %', (array_length(v_ids, 1) IS NULL);
END;
$$;

--
-- Test 4: BULK COLLECT INTO with NULL values
--
DO $$
DECLARE
    v_ids integer[];
    v_names text[];
BEGIN
    CREATE TEMP TABLE test_nulls_bc (id integer, name text);
    INSERT INTO test_nulls_bc VALUES (1, 'Alice');
    INSERT INTO test_nulls_bc VALUES (NULL, 'Bob');
    INSERT INTO test_nulls_bc VALUES (3, NULL);

    SELECT id, name BULK COLLECT INTO v_ids, v_names
    FROM test_nulls_bc ORDER BY name NULLS LAST;

    RAISE NOTICE 'Test 4 - IDs: %', v_ids;
    RAISE NOTICE 'Test 4 - Names: %', v_names;

    DROP TABLE test_nulls_bc;
END;
$$;

--
-- Test 5: FETCH ... BULK COLLECT INTO with cursor
--
DO $$
DECLARE
    TYPE int_table IS TABLE OF integer;
    TYPE text_table IS TABLE OF text;
    v_ids int_table;
    v_names text_table;
    cur CURSOR FOR SELECT id, name FROM test_bulk_emp ORDER BY id;
BEGIN
    OPEN cur;
    FETCH cur BULK COLLECT INTO v_ids, v_names;
    CLOSE cur;

    RAISE NOTICE 'Test 5 - FETCH count: %', array_length(v_ids, 1);
    RAISE NOTICE 'Test 5 - IDs: %', v_ids;
    RAISE NOTICE 'Test 5 - Names: %', v_names;
END;
$$;

--
-- Test 6: Element access after BULK COLLECT (Oracle-like indexing)
--
DO $$
DECLARE
    TYPE text_table IS TABLE OF text;
    v_names text_table;
    i integer;
BEGIN
    SELECT name BULK COLLECT INTO v_names
    FROM test_bulk_emp ORDER BY id;

    FOR i IN 1..array_length(v_names, 1) LOOP
        RAISE NOTICE 'Test 6 - Element[%]: %', i, v_names[i];
    END LOOP;
END;
$$;

--
-- Test 7: TYPE IS TABLE OF with varchar(n)
--
DO $$
DECLARE
    TYPE varchar_table IS TABLE OF varchar(50);
    v_data varchar_table;
BEGIN
    SELECT name::varchar(50) BULK COLLECT INTO v_data
    FROM test_bulk_emp ORDER BY id;

    RAISE NOTICE 'Test 7 - varchar data: %', v_data;
END;
$$;

--
-- Test 8: Single column BULK COLLECT
--
DO $$
DECLARE
    v_ids integer[];
BEGIN
    SELECT id BULK COLLECT INTO v_ids
    FROM test_bulk_emp ORDER BY id;

    RAISE NOTICE 'Test 8 - Single column: %', v_ids;
END;
$$;

--
-- Test 9: BULK COLLECT with FOREACH iteration
--
DO $$
DECLARE
    TYPE text_table IS TABLE OF text;
    v_names text_table;
    v_name text;
BEGIN
    SELECT name BULK COLLECT INTO v_names
    FROM test_bulk_emp ORDER BY name;

    FOREACH v_name IN ARRAY v_names LOOP
        RAISE NOTICE 'Test 9 - Name: %', v_name;
    END LOOP;
END;
$$;

-- Clean up
DROP TABLE test_bulk_emp;
