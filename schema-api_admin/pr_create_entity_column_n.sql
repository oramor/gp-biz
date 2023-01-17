CREATE OR REPLACE PROCEDURE api_admin.pr_create_entity_column_n(OUT p_id integer, IN p_obj jsonb)
 LANGUAGE plpgsql
AS $procedure$
DECLARE
	l_entity_id int := parse_int_req(p_obj,'entityId');
	l_column_name TEXT := parse_text_req(p_obj,'columnName');
	l_is_required bool := parse_bool(p_obj,'isRequired');
	l_descr TEXT := parse_text(p_obj,'description');
	l_logical_data_type_id int := prase_int(p_obj,'logicalDataType');
	l_table_id int;
BEGIN
	SELECT t.id INTO l_table_id FROM db_table t
	WHERE t.id IN (SELECT e.db_table_id FROM entity e WHERE e.id = l_entity_id);
	IF NOT FOUND THEN
		RAISE EXCEPTION 'Not found entity with id % or table for this', l_entity_id;
	END IF;
	
	IF l_logical_data_type_id IS NULL THEN
		l_logical_data_type_id := adm.get_logical_data_type_id(l_column_name);
	
		IF l_logical_data_type_id IS NULL THEN
			RAISE EXCEPTION 'Did not resolve logical type by column name. Cast it explicitly.';
		END IF;
	END IF;
	
	CALL adm.create_db_table_column(p_id, l_db_table_id,l_column_name,l_logical_data_type_id,true,true,l_is_required,l_descr);
END;
$procedure$
;
