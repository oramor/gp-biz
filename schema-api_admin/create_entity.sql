CREATE OR REPLACE PROCEDURE api_admin.create_entity(IN p_public_name text, IN p_pascal_name text, IN p_is_doc boolean)
LANGUAGE plpgsql
AS $procedure$
DECLARE
	l_table_name TEXT := convert_pascal_to_snake(p_pascal_name);
	l_entity_id int;
BEGIN
	-- Try to add new entity
	BEGIN 
		INSERT INTO adm.entity (
			public_name, pascal_name, is_document 
		) VALUES (
			p_public_name, p_pascal_name, p_is_doc
		) RETURNING id INTO l_entity_id;
	EXCEPTION
		WHEN unique_violation THEN
			RAISE EXCEPTION 'Entity with name % has already exist', p_pascal_name;
	END;

	-- Create API schema
	DECLARE
		l_schema_name TEXT := concat('api_', l_table_name);
	BEGIN
		EXECUTE 'CREATE SCHEMA IF NOT EXISTS '||l_schema_name;
	END;
	
	-- Create default entity
	CALL adm.create_entity_default_table(l_entity_id);

	-- Create triggers for object table
	CALL adm.create_entity_log_trigger_bi(l_table_name);
	CALL adm.create_entity_log_trigger_bu(l_table_name);

	-- Fill entity columns
	--CALL adm.fill_entity_columns(l_entity_id);
END;
$procedure$
;
;
