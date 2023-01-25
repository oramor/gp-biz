CREATE OR REPLACE FUNCTION adm.get_column_joint_name(p_fk_column_nm TEXT, p_column_nm TEXT)
RETURNS text
LANGUAGE sql
AS $function$
	/* For example. If fk_column has name src_city_id and joining column has name
	 * public_name this func will produces srcCityPublicName (_id will be removed)*/
	SELECT convert_snake_to_camel(concat(rtrim(p_fk_column_nm,'_id'),'_',p_column_nm));
$function$
;
