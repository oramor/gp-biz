CREATE OR REPLACE PROCEDURE adm.fill_entity_default_table(IN p_db_table_id integer)
 LANGUAGE plpgsql
AS $procedure$
DECLARE
	l_table_name TEXT;
	l_logical_data_type_id int;
	l_fk_table_id int;
	r record;
BEGIN
	--Get table_name
	SELECT inner_name INTO l_table_name FROM db_table WHERE id = p_db_table_id;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'Not found table with id %', p_db_table_id;
	END IF;

	--Is this an entity table?
	IF NOT EXISTS(SELECT 1 FROM db_table t WHERE t.id IN (SELECT db_table_id FROM entity e WHERE e.db_table_id = t.id)) THEN
		RAISE EXCEPTION 'The table % is not an entity table', l_table_name;
	END IF;
	
	FOR r IN SELECT * FROM information_schema."columns"
		WHERE table_name = l_table_name
	LOOP
		-- Skip if exists
		IF EXISTS(SELECT 1 FROM db_table_column c WHERE c.inner_name = r.column_name AND c.db_table_id = p_db_table_id) THEN
			CONTINUE;
		END IF;
	
		-- Пропускаем, если не удалось определить логический тип колонки
		l_logical_data_type_id := get_logical_data_type_id(r.column_name);
		IF l_logical_data_type_id IS NULL THEN
			CONTINUE;
		END IF;			
		
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
		
		INSERT INTO db_table_column (
			inner_name, data_type, db_data_type_id, is_nullable, db_table_id,
			priority, logical_data_type_id 
		) VALUES (
			r.column_name, r.udt_name, get_db_data_type_id(r.udt_name), (r.is_nullable)::bool, p_db_table_id,
			r.ordinal_position, l_logical_data_type_id
		);
	END LOOP;
END;
$procedure$
;
