CREATE OR REPLACE PROCEDURE adm.create_db_table_column(OUT p_column_id integer, IN p_db_table_id integer, IN p_column_name text, IN p_logical_data_type integer, IN p_is_nullable boolean, IN p_is_updatable boolean, IN p_is_required boolean, IN p_description text)
 LANGUAGE plpgsql
AS $procedure$
DECLARE
	l_table_name TEXT;
	l_data_type_txt TEXT;
	l_column_name TEXT := lower(p_column_name);
	l_data_type_id int;
	l_is_fk bool := lower(right(p_column_name,3)) = '_id'; --All fk columns contains _id postfix
	l_fk_table_id int;
BEGIN
	SELECT t.inner_name INTO l_table_name FROM db_table t WHERE t.id = p_db_table_id;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'Not found db_table with id %', p_db_table_id;
	END IF;

	-- Get logical data type
	IF NOT EXISTS(SELECT 1 FROM adm.logical_data_type WHERE id = p_logical_data_type) THEN
		RAISE EXCEPTION 'Not found logical data type with id %', p_logical_data_type;
	END IF;	

	-- Get db data type
	l_data_type_id := get_db_data_type_id_by_ldt(p_logical_data_type);

	SELECT t.inner_name INTO l_data_type_txt FROM db_data_type t
	WHERE id = l_data_type_id;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'Logical data type did not mapped to a db data type';
	END IF;
	
	-- Alter table
	DECLARE
		l_sql TEXT;
	BEGIN
		l_sql :=
		'ALTER TABLE biz.'||l_table_name||' ADD COLUMN '||concat(l_column_name, ' ', l_data_type_txt);
	
		IF p_is_nullable THEN
			l_sql := l_sql|| ' NULL';
		ELSE
			l_sql := l_sql|| ' NOT NULL';
		END IF;
	
		l_sql := concat(l_sql,';');
		--RAISE NOTICE '%', l_sql;
		EXECUTE l_sql;
	EXCEPTION
		WHEN duplicate_column THEN
			RAISE EXCEPTION 'Column with name % already exist', l_column_name;
	END;

	-- FK constraint
	IF l_is_fk THEN
		DECLARE
			l_sql TEXT;
			l_fk_table_name TEXT;
			l_constraint_name TEXT;
			l_cnt int;
		BEGIN
			l_fk_table_id := get_fk_table_id(p_column_name);
			IF l_fk_table_id IS NULL THEN
				RAISE EXCEPTION 'Not found fk table for column  %. Did you add alias?', p_column_name;
			END IF;				
		
			SELECT t.inner_name INTO l_fk_table_name FROM db_table t WHERE t.id = l_fk_table_id;
		
			-- Get fk counts
			SELECT count(*)+1 INTO l_cnt FROM information_schema.table_constraints t
			WHERE t.table_name = l_table_name AND lower(t.constraint_type) = 'foreign key';
		
			-- For example: city_fk1_country
			l_constraint_name := concat(l_table_name,'_fk',l_cnt,'_',l_fk_table_name);
		
			l_sql :=
			'ALTER TABLE biz.'||l_table_name||' ADD CONSTRAINT '||l_constraint_name||br(1)||
			' FOREIGN KEY ('||l_column_name||') REFERENCES biz.'||l_fk_table_name||'(id)';
		
			--RAISE NOTICE '%', l_sql;
			EXECUTE l_sql;
		END;
	END IF;

	-- Add column to metadata
	DECLARE
		l_priority int;
	BEGIN
		/* Дефолтный приоритет колонки вычисляем не по количеству строк, а по максимальному значению
		 * Потому что какой смысл, например, добавлять 7, если у всех 6 колонок priority = 1 */ 
		SELECT max(t.priority)+1 INTO l_priority FROM adm.db_table_column t WHERE t.db_data_type_id = p_db_table_id;

		INSERT INTO adm.db_table_column (
			inner_name, db_data_type_id, data_type, is_nullable, db_table_id, priority,
			fk_table_id, is_updatable, description, logical_data_type_id, is_required 
		) VALUES (
			l_column_name, l_data_type_id, l_data_type_txt, p_is_nullable, p_db_table_id, l_priority,
			l_fk_table_id, p_is_updatable, p_description, p_logical_data_type, p_is_required
		) RETURNING id INTO p_column_id;
	END;
END;
$procedure$
;
