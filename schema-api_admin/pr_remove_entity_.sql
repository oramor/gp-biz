CREATE OR REPLACE PROCEDURE api_admin.pr_remove_entity_(IN p_entity_id integer)
 LANGUAGE plpgsql
AS $procedure$
DECLARE
	l_entity_id int := req(p_entity_id);
	l_db_table_id int;
	r_table_column record;
	l_schema_id int;
BEGIN
	SELECT db_table_id INTO l_db_table_id FROM adm.entity WHERE id = l_entity_id;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'Not found entity with id %', l_entity_id;
	END IF;

	-- Get db_schema before entity will be deleted
	SELECT e.db_schema_id INTO l_schema_id FROM entity e WHERE e.id = l_entity_id;
	
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

	-- Remove view pattern columns which have refs to db_table_column
	FOR r_table_column IN SELECT * FROM db_table_column t WHERE t.db_table_id = l_db_table_id
	LOOP 
		DELETE FROM abstract_view_column v WHERE v.db_table_column_id = r_table_column.id;
	END LOOP;
	
	/* Remove all views metadata which depends on view patterns (before this view patterns will
	 * be dropped. At current moment database views have benn already dropped with entity schema */ 
	DELETE FROM db_view v WHERE v.id IN (SELECT db_view_id FROM abstract_view t WHERE t.db_view_id = v.id);

	-- Remove all routines metadata which refs to entity schema
	DELETE FROM db_routine t WHERE t.db_schema_id = l_schema_id;
	
	-- Remove all view patterns which refs to entity db table
	DELETE FROM abstract_view t WHERE t.db_table_id = l_db_table_id;

	-- Remove schema (past because db_routines and views have ref to)
	DELETE FROM db_schema WHERE id = l_schema_id;

	-- Remove entity table metadata, columns and aliases
	DELETE FROM db_table_column t WHERE t.db_table_id = l_db_table_id;
	DELETE FROM db_table_alias t WHERE t.db_table_id = l_db_table_id;
	DELETE FROM db_table WHERE id = l_db_table_id;
END;
$procedure$
;
