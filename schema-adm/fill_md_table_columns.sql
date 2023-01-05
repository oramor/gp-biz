CREATE OR REPLACE PROCEDURE adm.fill_md_table_columns(IN p_md_table_id integer)
 LANGUAGE plpgsql
AS $procedure$
DECLARE
	l_table_name TEXT;
	l_fk_table_id int;
	r record;
BEGIN
	--Get table_name
	SELECT inner_name INTO l_table_name FROM md_table WHERE id = p_md_table_id;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'Not found table with id %', p_md_table_id;
	END IF;
	
	FOR r IN SELECT * FROM information_schema."columns"
		WHERE table_name = l_table_name
	LOOP
		-- Skip if exists
		IF EXISTS(SELECT 1 FROM md_table_column c WHERE c.inner_name = r.column_name AND c.md_table_id = p_md_table_id) THEN
			CONTINUE;
		END IF;
		
		/* Проверяем, является ли колонка ссылочной. Имена таких колонок
		 * должны в точности совпадать с именем таблицы сущности, на которую
		 * они ссылаются + постфикс _id
		 */
		l_fk_table_id := get_fk_table_id(r.column_name);
		
		INSERT INTO md_table_column (
			inner_name, data_type, supported_data_type_id, is_nullable, md_table_id,
			priority, fk_table_id
		) VALUES (
			r.column_name, r.udt_name, get_supported_data_type_id(r.udt_name), (r.is_nullable)::bool, p_md_table_id,
			r.ordinal_position, l_fk_table_id
		);
	END LOOP;
END;
$procedure$
;
