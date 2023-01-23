CREATE OR REPLACE FUNCTION adm.is_dic(p_entity_id integer)
 RETURNS boolean
 LANGUAGE sql
AS $function$
	SELECT EXISTS(SELECT 1 FROM entity t1
	WHERE t1.biz_object_id IN (SELECT t2.id FROM biz_object t2 WHERE t2.biz_object_type_id = 1)
		AND t1.id = p_entity_id
	)
$function$
;
