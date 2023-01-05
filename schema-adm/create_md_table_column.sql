CREATE OR REPLACE PROCEDURE adm.create_md_table_column(IN p_md_table_id integer, IN p_column_name text, IN p_data_type_id integer, IN p_is_nullable boolean, IN p_fk_table_id integer, IN p_description text)
 LANGUAGE plpgsql
AS $procedure$
DECLARE
	l_table_name TEXT;
	l_data_type_txt TEXT;
	l_column_name TEXT := lower(p_column_name);
BEGIN
	SELECT t.inner_name INTO l_table_name FROM md_table t WHERE t.id = p_md_table_id;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'Not found md table with id %', p_md_table_id;
	END IF;

	-- Get data type
	SELECT t.inner_name INTO l_data_type_txt FROM supported_data_type t WHERE id = p_data_type_id;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'Not found supported data type with id %', p_data_type_id;
	END IF;
	
	-- Check table exists
	IF NOT EXISTS(
		SELECT * FROM information_schema."tables" t
		WHERE t.table_name = l_table_name
			AND t.table_schema = 'biz')
	THEN
		RAISE EXCEPTION 'Not found entity with id %', p_entity_id;
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
	IF p_fk_table_id IS NOT NULL THEN
		DECLARE
			l_sql TEXT;
			l_fk_table_name TEXT;
			l_constraint_name TEXT;
			l_cnt int;
		BEGIN
			SELECT t.inner_name INTO l_fk_table_name FROM md_table t WHERE t.id = p_fk_table_id;
			IF NOT FOUND THEN
				RAISE EXCEPTION 'Not found fk table with id %', p_fk_table_id;
			END IF;
		
			/* Проверяем, что имя колонки со ссылкой на другую сущность соответствует гайдлайну
			 * (оно должно оканиваться на _id)*/
			IF regexp_like(l_column_name,'_id$') != TRUE THEN
				RAISE EXCEPTION 'You should use _id postfix for names of columns with fk';
			END IF;
		
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
		SELECT count(*)+1 INTO l_priority FROM adm.md_table t WHERE t.id = p_md_table_id;

		INSERT INTO adm.md_table_column (
			inner_name, supported_data_type_id, data_type, is_nullable, md_table_id, priority,
			fk_table_id, is_updatable, description
		) VALUES (
			l_column_name, p_data_type_id, l_data_type_txt, p_is_nullable, p_md_table_id, l_priority,
			p_fk_table_id, TRUE, p_description
		);
	END;
END;
$procedure$
;
