CREATE OR REPLACE PROCEDURE api_admin.pr_create_entity_n(OUT p_entity_id integer, IN p_obj jsonb)
 LANGUAGE plpgsql
AS $procedure$
DECLARE
	l_pascal_name TEXT := parse_text_req(p_obj, 'pascalName');
	l_public_name TEXT := parse_text_req(p_obj, 'publicName');
	l_is_doc bool := parse_bool_req(p_obj, 'isDocument');
	l_table_name TEXT;
BEGIN
	l_table_name := convert_pascal_to_snake(l_pascal_name);
	
	-- Try to add new entity
	BEGIN 
		INSERT INTO adm.entity (
			public_name, pascal_name, is_document 
		) VALUES (
			l_public_name, l_pascal_name, l_is_doc
		) RETURNING id INTO p_entity_id;
	EXCEPTION
		WHEN unique_violation THEN
			RAISE EXCEPTION 'Entity with name % has already exist', l_pascal_name;
	END;

	-- Create API schema
	DECLARE
		l_schema_name TEXT := concat('api_', l_table_name);
	BEGIN
		EXECUTE 'CREATE SCHEMA IF NOT EXISTS '||l_schema_name;
	END;
	
	-- Create table and metadata
	DECLARE
		l_db_table_id int;
	BEGIN
		-- Create default entity
		CALL adm.create_entity_default_table(l_db_table_id, p_entity_id);
	
		-- Create triggers for object table
		CALL adm.create_entity_log_trigger_bi(l_table_name);
		CALL adm.create_entity_log_trigger_bu(l_table_name);
	
		-- Fill md columns
		CALL adm.fill_db_table_columns(l_db_table_id);
	END;
END;
$procedure$
;
