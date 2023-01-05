CREATE OR REPLACE PROCEDURE api_admin.remove_entity(IN p_entity_id integer)
 LANGUAGE plpgsql
AS $procedure$
DECLARE
	l_md_table_id int;
BEGIN
	SELECT md_table_id INTO l_md_table_id FROM adm.entity WHERE id = p_entity_id;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'Not found entity with id %', p_entity_id;
	END IF;
	
	-- Remove entity table
	DECLARE
		l_sql TEXT;
		l_table_name TEXT := get_entity_table_name(p_entity_id);
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
		l_schema_name TEXT := get_entity_schema_name(p_entity_id);
	BEGIN
		IF l_schema_name IS NOT NULL THEN
			l_sql := 'DROP SCHEMA IF EXISTS '||l_schema_name||';';
			EXECUTE l_sql;
		ELSE
			RAISE NOTICE 'Schema did not removed';
		END IF;		
	END;

	-- Remove entity
	DELETE FROM entity WHERE id = p_entity_id;

	-- Remove entity table metadata
	DELETE FROM md_table_column c WHERE c.md_table_id = l_md_table_id;
	DELETE FROM md_table WHERE id = l_md_table_id;
END;
$procedure$
;
