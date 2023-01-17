CREATE OR REPLACE PROCEDURE api_admin.pr_remove_entity_(IN p_entity_id integer)
 LANGUAGE plpgsql
AS $procedure$
DECLARE
	l_entity_id int := req(p_entity_id);
	l_db_table_id int;
BEGIN
	SELECT db_table_id INTO l_db_table_id FROM adm.entity WHERE id = l_entity_id;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'Not found entity with id %', l_entity_id;
	END IF;
	
	-- Remove entity table
	DECLARE
		l_sql TEXT;
		l_table_name TEXT := get_entity_table_name(l_entity_id);
	BEGIN
		IF l_table_name IS NOT NULL THEN
			l_sql := 'DROP TABLE IF EXISTS biz.'||l_table_name||';';
			EXECUTE l_sql;
		ELSE
			RAISE NOTICE 'Table did not removed because metadata not found';
		END IF;
	END;

	-- Remove schema
	DECLARE
		l_sql TEXT;
		l_schema_name TEXT := get_entity_schema_name(l_entity_id);
	BEGIN
		IF l_schema_name IS NOT NULL THEN
			l_sql := 'DROP SCHEMA IF EXISTS '||l_schema_name||';';
			EXECUTE l_sql;
		ELSE
			RAISE NOTICE 'Schema did not removed';
		END IF;		
	END;

	-- Remove entity
	DELETE FROM entity WHERE id = l_entity_id;

	-- Remove entity table metadata
	DELETE FROM db_table_column c WHERE c.db_table_id = l_db_table_id;
	DELETE FROM db_table WHERE id = l_db_table_id;
END;
$procedure$
;
