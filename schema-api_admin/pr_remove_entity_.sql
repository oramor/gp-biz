CREATE OR REPLACE PROCEDURE api_admin.pr_remove_entity_(IN p_entity_id integer)
 LANGUAGE plpgsql
AS $procedure$
DECLARE
	l_entity_id int := req(p_entity_id);
	l_db_table_id int;
	r_table_column record;
	l_schema_id int;
	l_biz_object_id int;
BEGIN
	SELECT db_table_id INTO l_db_table_id FROM adm.entity WHERE id = l_entity_id;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'Not found entity with id %', l_entity_id;
	END IF;

	-- Get db_schema before entity will be deleted
	SELECT e.db_schema_id, e.biz_object_id INTO l_schema_id, l_biz_object_id
	FROM entity e WHERE e.id = l_entity_id;
	
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

	-- Remove entity schema (with views and routines which depends on abstract_view)
	DECLARE
		l_schema_name TEXT := get_entity_schema_name(l_entity_id);
	BEGIN
		IF l_schema_name IS NOT NULL THEN
			EXECUTE format('DROP SCHEMA IF EXISTS %s', l_schema_name);
		ELSE
			RAISE NOTICE 'Schema did not removed';
		END IF;		
	END;

	-- Remove entity metadata
	DELETE FROM entity WHERE id = l_entity_id;

	-- Remove all routines metadata which refs to entity schema
	DELETE FROM db_routine t WHERE t.db_schema_id = l_schema_id;
	
	-- Remove schema (past because db_routines and views have ref to)
	DELETE FROM db_schema WHERE id = l_schema_id;

	-- Remove gui views for entity db_table
	DECLARE
		r_view record;
	BEGIN
		FOR r_view IN SELECT * FROM gui_view v WHERE v.db_table_id = l_db_table_id
		LOOP 
			-- At first remove columns, then view
			DELETE FROM gui_view_column c WHERE c.gui_view_id = r_view.id;
			DELETE FROM gui_view v WHERE v.id = r_view.id;
		END LOOP;
	END;
	
	-- Remove entity db_table, columns and aliases
	DELETE FROM db_table_column t WHERE t.db_table_id = l_db_table_id;
	DELETE FROM db_table_alias t WHERE t.db_table_id = l_db_table_id;
	DELETE FROM db_table WHERE id = l_db_table_id;

	-- Remove biz object
	DELETE FROM biz_object WHERE id = l_biz_object_id;
END;
$procedure$
;
