CREATE OR REPLACE FUNCTION adm.get_fk_table_id(p_column_name text)
 RETURNS integer
 LANGUAGE sql
AS $function$
	SELECT t.id FROM md_table t WHERE t.inner_name = lower(replace(p_column_name,'_id',''));
$function$
;
