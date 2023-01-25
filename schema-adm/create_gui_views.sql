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

	-- Make a scratch for joint columns 
	CREATE TEMP TABLE IF NOT EXISTS tmp_joint_columns ON COMMIT DELETE ROWS AS
	SELECT * FROM db_table_column WITH NO DATA;

	/* For each abstract view that associates whit db_table (see abstract_table_views) */
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
	
		-- Fill view columns
		DECLARE
			r_col record;
			l_current_priority int;
			l_cnt int;
		BEGIN
			FOR r_col IN SELECT * FROM db_table_column t
			WHERE t.db_table_id = p_db_table_id ORDER BY t.priority --TODO priority 
			LOOP		
				INSERT INTO gui_view_column (
					gui_view_id, db_table_column_id, camel_name, logical_data_type_id,
					abstract_column_id, is_updatable, is_required, default_priority,
					default_size, default_gui_name, default_gui_short_name
				)
				SELECT l_gui_view_id, id, camel_name, logical_data_type_id,
					abstract_column_id, is_updatable, is_required, default_priority,
					default_size, default_gui_name, default_gui_short_name
				FROM tmp_joint_columns;
				
				-- Remove from stack
				TRUNCATE tmp_joint_columns;

				-- Skip if prohibit in abstract column
				IF is_column_for_view(r_col.inner_name) = FALSE THEN
					CONTINUE;
				END IF;
			
				-- Search and fill joint columns
				IF r_col.fk_table_id IS NOT NULL AND r_av.is_joinable THEN
					/* Simply coping joint columns because structure of joint
					 * table is similar with db_table_column */
					INSERT INTO tmp_joint_columns SELECT * FROM db_table_column t
					WHERE t.db_table_id = r_col.fk_table_id
						AND t.is_for_join
					ORDER BY t.priority;
				
					/* Update column name: ext_order_id + doc_name = extOrderDocName */
					UPDATE tmp_joint_columns
					SET camel_name = get_column_joint_name(r_col.inner_name,inner_name),
						default_priority = l_current_priority;
				END IF;
							
				INSERT INTO gui_view_column (
					gui_view_id, db_table_column_id, camel_name, logical_data_type_id,
					abstract_column_id, is_updatable, is_required, default_priority,
					default_size, default_gui_name, default_gui_short_name
				)
				SELECT l_gui_view_id, id, camel_name, logical_data_type_id,
					abstract_column_id, is_updatable, is_required, default_priority,
					default_size, default_gui_name, default_gui_short_name
				FROM adm.db_table_column WHERE id = r_col.id
				RETURNING default_priority INTO l_current_priority;
			END LOOP;
		END;
	END LOOP;
END;
$procedure$
;
