CREATE OR REPLACE PROCEDURE adm.create_db_table_for_doc(OUT p_db_table_id integer, IN p_entity_id integer)
 LANGUAGE plpgsql
AS $procedure$
/* Смысл разделять на отдельные процедуры создания документов и справочников в возможности
 * переопределения некоторых абстрактных колонок. К тому же общая канва предусматривает
 * create_db_table_for_reg и т.д.
 * 
 * Calls from pr_create_entity_n*/
DECLARE
	l_sql TEXT;
	l_table_name TEXT;
	r_column record;
BEGIN
	-- Check exists end get entity
	SELECT convert_pascal_to_snake(pascal_name) INTO l_table_name FROM adm.entity t
	WHERE id = p_entity_id AND t.is_document = true;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'Not found entity with id % and doc true', p_entity_id;
	END IF;

	-- Check if table already existed
	PERFORM * FROM information_schema."tables" WHERE table_name = l_table_name;
	IF FOUND THEN
		RAISE EXCEPTION 'Table with name % is already exists', l_table_name;
	END IF;

	-- Create table SQL
	l_sql := 'CREATE TABLE biz.'||l_table_name||' ('||br(1);
	
	FOR r_column IN SELECT * FROM abstract_column t WHERE t.is_for_doc = TRUE
	ORDER BY t.priority
	LOOP 
		-- Если добавить переносы, rtrim не сработает!
		l_sql := concat(l_sql,r_column.sql_string,',');
	END LOOP;
	
	-- Remove last comma and close blackets
	l_sql := rtrim(l_sql,',')||');';

	-- Excecute
	--RAISE NOTICE 'l_sql: %', l_sql;
	EXECUTE l_sql;

	-- Fill db_table
	INSERT INTO adm.db_table (
		inner_name
	) VALUES (
		l_table_name
	) RETURNING id INTO p_db_table_id;
	
	UPDATE adm.entity SET db_table_id = p_db_table_id
	WHERE id = p_entity_id;
END;
$procedure$
;
