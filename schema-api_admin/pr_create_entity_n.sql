CREATE OR REPLACE PROCEDURE api_admin.pr_create_entity_n(OUT p_entity_id integer, IN p_obj jsonb)
 LANGUAGE plpgsql
AS $procedure$
DECLARE
	l_pascal_name TEXT := parse_text_req(p_obj, 'pascalName');
	l_public_name TEXT := parse_text_req(p_obj, 'publicName');
	l_is_doc bool := parse_bool_req(p_obj, 'isDocument');
	l_table_name TEXT;
	l_db_schema_id int;
	l_biz_obj_id int;
	l_biz_obj_code TEXT := CASE l_is_doc WHEN TRUE THEN 'doc' ELSE 'dic' END;
BEGIN
	l_table_name := convert_pascal_to_snake(l_pascal_name);

	-- Create biz object
	CALL create_biz_object(l_biz_obj_id, l_biz_obj_code, l_pascal_name);
	
	-- Create API schema
	DECLARE
		l_schema_name TEXT := concat('biz_', l_table_name);
	BEGIN
		CALL create_db_schema(l_db_schema_id, l_schema_name);
	END;

	-- Try to add new entity
	INSERT INTO adm.entity (
		public_name, pascal_name, db_schema_id, biz_object_id
	) VALUES (
		l_public_name, l_pascal_name, l_db_schema_id, l_biz_obj_id
	) RETURNING id INTO p_entity_id;
	
	-- Create table and metadata
	DECLARE
		l_db_table_id int;
	BEGIN
		-- Create default entity
		IF l_is_doc THEN
			CALL adm.create_db_table_for_doc(l_db_table_id,p_entity_id);
		ELSE 
			CALL adm.create_db_table_for_dic(l_db_table_id,p_entity_id);
		END IF;
	
		-- Create triggers for object table
		CALL adm.create_entity_log_trigger_bi(l_table_name);
		CALL adm.create_entity_log_trigger_bu(l_table_name);
	
		-- Fill db columns
		CALL adm.fill_entity_default_table(l_db_table_id);
	END;
END;
$procedure$
;
