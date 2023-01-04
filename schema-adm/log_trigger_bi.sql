CREATE OR REPLACE FUNCTION adm.log_trigger_bi()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
	l_after jsonb;
	p_obj_name varchar := TG_ARGV[0];
BEGIN
	NEW.ver = 1;
	NEW.created := coalesce(NEW.created, now());
	NEW.created_user := current_user;

	l_after := to_jsonb(NEW.*);
	INSERT INTO log.changelog (
		obj_name, obj_id, obj_ver, log_action, context_user_name, session_user_name, session_ip, state_after
	) VALUES (
		p_obj_name, NEW.id, NEW.ver, 'create', current_user, SESSION_USER, inet_server_addr(), l_after
	);
	
	RETURN NEW;
END;
$function$
;