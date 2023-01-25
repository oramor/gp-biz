CREATE OR REPLACE PROCEDURE adm.create_db_table_for_entity(IN p_entity_id integer)
 LANGUAGE plpgsql
AS $procedure$
/* Calls from pr_create_entity_n*/
DECLARE
	l_abstract_table_id int;
	l_db_table_id int;
	l_entity_name TEXT := get_entity_name(p_entity_id);
	l_table_name TEXT := convert_pascal_to_snake(l_entity_name);
BEGIN
	IF l_entity_name IS NULL THEN
		RAISE EXCEPTION 'Not found entity with id [ % ]', p_entity_id;
	END IF;

	-- Get abstract_table which current entity type (doc/dic) inherited from
	SELECT a.id INTO l_abstract_table_id FROM abstract_table a
		JOIN biz_object b ON b.biz_object_type_id = a.biz_object_type_id
		JOIN entity e ON e.biz_object_id = b.id AND e.id = p_entity_id;

	-- Check if table already existed
	PERFORM * FROM information_schema."tables" WHERE table_name = l_table_name;
	IF FOUND THEN
		RAISE EXCEPTION 'Table with name [ % ] is already exists', l_table_name;
	END IF;

	-- Create table
	DECLARE
		l_sql TEXT;
		r_column record;
	BEGIN
		l_sql := 'CREATE TABLE biz.'||l_table_name||' ('||br(1);
		
		FOR r_column IN SELECT ac.sql_string AS sql_str FROM abstract_table_column t
			JOIN abstract_column ac ON ac.id = t.abstract_column_id
		WHERE t.abstract_table_id = l_abstract_table_id
		ORDER BY t.priority
		LOOP 
			-- Если добавить переносы, rtrim не сработает!
			l_sql := concat(l_sql,r_column.sql_str,',');
		END LOOP;
		
		-- Remove last comma and close blackets
		l_sql := rtrim(l_sql,',')||');';
	
		-- Excecute
		--RAISE NOTICE 'l_sql: %', l_sql;
		EXECUTE l_sql;
	END;

	-- Create db_table
	INSERT INTO adm.db_table (inner_name, abstract_table_id)
	VALUES (l_table_name, l_abstract_table_id)
	RETURNING id INTO l_db_table_id;

	-- Create triggers
	CALL adm.create_entity_log_trigger_bi(l_table_name);
	CALL adm.create_entity_log_trigger_bu(l_table_name);
	
	-- Set db_table ref to entity
	UPDATE adm.entity SET db_table_id = l_db_table_id
	WHERE id = p_entity_id;

	-- Fill db_table
	DECLARE
		l_abstract_column_id int;
		l_is_for_join bool;
		l_is_for_view bool;
		l_logical_data_type_id int;
		l_fk_table_id int;
		r record;
	BEGIN
		FOR r IN SELECT * FROM information_schema."columns" WHERE table_name = l_table_name
		LOOP
			-- Does it make sence with default Read Committed?
			IF EXISTS(SELECT 1 FROM db_table_column c 
				WHERE c.inner_name = r.column_name AND c.db_table_id = l_db_table_id)
			THEN
				CONTINUE;
			END IF;
		
			/* Здесь тонкий момент. Все колонки, которые добавляются в дефолтную таблицу, являются
			 * наследниками abstract_column, т.к. abstract_table_column, из которой они берутся (см блок выше),
			 * это не более, чем связка abstract_table и abstract_column. По идее, функция
			 * get_abstract_column_id никогда не должна возвращать NULL */
			l_abstract_column_id := get_abstract_column_id(r.column_name);
			IF l_abstract_column_id IS NULL THEN
				CONTINUE;
			END IF;			
			
			-- Fill addition info from abstract columns
			SELECT a.logical_data_type_id, a.is_for_join, a.is_for_view
			INTO l_logical_data_type_id, l_is_for_join, l_is_for_view
			FROM abstract_column a WHERE a.id = l_abstract_column_id;
		
			-- Здесь можно применить enum для логических типов
			IF l_logical_data_type_id = 9 /*ForeignKey*/ THEN
				/* Проверяем, действительно ли колонка является ссылочной. Имена таких колонок
				 * должны в точности совпадать с именем таблицы сущности, на которую
				 * они ссылаются + постфикс _id
				 */
				l_fk_table_id := get_fk_table_id(r.column_name);
				-- Пропускаем, т.к. ссылка на сущность не найден
				IF l_fk_table_id IS NULL THEN
					CONTINUE;
				END IF;		
			END IF;
			
			-- All columns which adds with this cycle will be inherited from abstract_column
			INSERT INTO db_table_column (
				inner_name, data_type, db_data_type_id, is_nullable, db_table_id,
				priority, logical_data_type_id, abstract_column_id,
				is_for_join, is_for_view, camel_name
			) VALUES (
				r.column_name, r.udt_name, get_db_data_type_id(r.udt_name), (r.is_nullable)::bool, l_db_table_id,
				r.ordinal_position, l_logical_data_type_id, l_abstract_column_id,
				l_is_for_join, l_is_for_view, aux.convert_snake_to_camel(r.column_name)
			);
		END LOOP;
	END;
END;
$procedure$
;
