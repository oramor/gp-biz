CREATE OR REPLACE PROCEDURE adm.remove_view(IN p_schema_nm text, IN p_view_nm text)
 LANGUAGE plpgsql
AS $procedure$
/* Call from pr_remove_entity */
BEGIN
	EXECUTE format('DROP VIEW IF EXISTS %s.%s',p_schema_nm,p_view_nm);
END;
$procedure$
;
