CREATE OR REPLACE PROCEDURE adm.create_gui_views(OUT p_gui_views_arr integer[], IN p_db_table_id integer)
 LANGUAGE plpgsql
AS $procedure$
DECLARE
	l_table_nm TEXT;
	l_abstract_table_id int;
	l_view_name TEXT;
	r_av record;
	l_gui_view_id int;
BEGIN
	SELECT t.inner_name, t.abstract_table_id INTO l_table_nm, l_abstract_table_id
	FROM db_table t WHERE t.id = p_db_table_id;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'Not found db_table for id [ % ]', p_db_table_id;
	END IF;
		--RAISE EXCEPTION '!!!!!!';
	/* Single table can be produced a couple of views (see abstract_table_views) */
	FOR r_av IN SELECT * FROM abstract_table_view t 
		JOIN abstract_view v ON v.id  = t.abstract_view_id 
	WHERE t.abstract_table_id = l_abstract_table_id
	LOOP 
		/* Since there are db_table names are unique, we can get unique view name
		 * as a concatenation of table name and abstract_view name */ 
		l_view_name := concat(convert_snake_to_pascal(l_table_nm),r_av.public_name);
	
		-- Create gui_view
		INSERT INTO gui_view (abstract_view_id, gui_view_name, db_table_id)
		VALUES (r_av.id,l_view_name,p_db_table_id) RETURNING id INTO l_gui_view_id;
	
		p_gui_views_arr := array_append(p_gui_views_arr, l_gui_view_id);
	
		-- Fill columns
		DECLARE
			r_col record;
			r_joint record;
			r_fk_col record;
			l_abstract_colum_id int;
			l_cur_priority int;
			l_logical_data_type_id int;
			l_camel_name TEXT;
			l_gui_name TEXT;
			l_gui_short_name TEXT;
			l_size int;
			l_priority int;
		BEGIN
			CREATE TEMP TABLE IF NOT EXISTS tmp_joint_columns (
				id int NOT NULL GENERATED ALWAYS AS IDENTITY,
				parent_column_nm TEXT,
				camel_name TEXT,
				gui_name TEXT,
				gui_short_name TEXT,
				logical_data_type_id int,
				column_size int,
				priority int
			);
			
			FOR r_col IN SELECT * FROM db_table_column t
			WHERE t.db_table_id = p_db_table_id ORDER BY t.priority --TODO priority 
			LOOP
				-- Adding joint columns 
				FOR r_joint IN SELECT * FROM tmp_joint_columns ORDER BY priority
				LOOP
					INSERT INTO gui_view_column (
						gui_view_id
					) VALUES (
						l_gui_view_id
					);
				
					-- Remove from stack
					DELETE FROM tmp_joint_columns WHERE id = r_joint.id;
				END LOOP;
				
				-- Skip if prohibit in abstract column
				IF is_column_for_view(r_col.inner_name) = FALSE THEN
					CONTINUE;
				END IF;
			
				-- Search and fill joint columns
				IF r_col.fk_table_id IS NOT NULL AND r_av.is_joinable THEN
					FOR r_fk_col IN SELECT * FROM db_table_column t WHERE t.db_table_id = r_col.fk_table_id
					LOOP
						IF is_column_for_join(r_fk_col.inner_name) THEN
							INSERT INTO tmp_joint_columns(
								parent_column_nm, camel_name
							) SELECT (
								r_col.inner_name, a.camel_name 
							) FROM abstract_column a WHERE a.snake_name = r_fk_col.inner_name;
						END IF;
					END LOOP;
				END IF;
			
				-- Try to get abstract column by name
				--l_abstract_colum_id := adm.get_abstract_column_id(r_col.inner_name);
				
				SELECT c.logical_data_type_id, c.camel_name, c.gui_name, c.gui_short_name, 
					c.default_size, c.default_priority
				INTO l_logical_data_type_id, l_camel_name, l_gui_name, l_gui_short_name
					l_size, l_priority
				FROM abstract_column c WHERE c.id = r_col.abstract_column_id;
			
				INSERT INTO gui_view_column (
					gui_view_id
				) VALUES (
					l_gui_view_id
				) RETURNING priority INTO l_cur_priority;
			END LOOP;
		
			DROP TABLE IF EXISTS tmp_joint_columns;
		END;
	
	END LOOP;
	
END;
$procedure$
;
