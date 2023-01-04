CREATE OR REPLACE FUNCTION adm.log_trigger_bu()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	p_obj_name varchar := TG_ARGV[0];
	l_before jsonb;
	l_after jsonb;
BEGIN
	NEW.ver = NEW.ver + 1;
	NEW.updated := coalesce(NEW.updated, now());
	NEW.updated_by := current_user;
	
	--Log fields update
	DECLARE
		l_col record;
		l_old_value varchar;
		l_new_value varchar;
		l_cnt int :=0; --Счетчик обновленных полей
	BEGIN		
		FOR l_col IN SELECT * FROM information_schema.COLUMNS
			WHERE table_name = p_obj_name
				AND column_name NOT IN ('id', 'ver', 'created', 'created_user', 'updated', 'updated_user')
				AND data_type NOT IN ('serial')
		LOOP 
			EXECUTE 'SELECT $1.'||(l_col.column_name)::text USING OLD INTO l_old_value;
			EXECUTE 'SELECT $1.'||(l_col.column_name)::text USING NEW INTO l_new_value;
		
			--TODO check null
			IF l_old_value != l_new_value THEN
				-- Json не складывается с SQL NULL (на выходе будет получаться NULL), поэтому приводим к {}			
				SELECT COALESCE(l_before, '{}'::jsonb) || jsonb_build_object(l_col.column_name, l_old_value) INTO l_before;
				SELECT COALESCE(l_after, '{}'::jsonb) || jsonb_build_object(l_col.column_name, l_new_value) INTO l_after;
				l_cnt := l_cnt + 1;
			END IF;
		END LOOP;
	
		--If even one field was changed, add to log
		IF l_cnt > 0 THEN
			INSERT INTO log.changelog (
				obj_name, obj_id, obj_ver, log_action, context_user_name, session_user_name, session_ip, state_before, state_after
			) VALUES (
				p_obj_name, NEW.id, NEW.ver, 'update', current_user, SESSION_USER, inet_server_addr(), l_before, l_after
			);
		END IF;
	END;
		
	RETURN NEW;
END;
$function$
;
;
