CREATE OR REPLACE PROCEDURE adm.create_entity_default_table(IN p_entity_id integer)
 LANGUAGE plpgsql
AS $procedure$
DECLARE
	l_sql TEXT;
	l_table_name TEXT;
	l_is_doc bool;
BEGIN
	-- Check exists end get entity
	SELECT convert_pascal_to_snake(pascal_name), is_document INTO l_table_name, l_is_doc
	FROM adm.entity t WHERE id = p_entity_id;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'Not found entity with id %', p_entity_id;
	END IF;

	-- Check if table already existed
	PERFORM * FROM information_schema."tables" WHERE table_name = l_table_name;
	IF FOUND THEN
		RAISE EXCEPTION 'Table with name % is already exists', l_table_name;
	END IF;

	-- Create table SQL
	l_sql :=
	'CREATE TABLE biz.'||l_table_name||' ('||br(1)||
	'	id int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,'||br(1)||
	'	state state_tp NOT NULL DEFAULT '||concat('(',quote_literal('active'),')','::state_tp,')||br(1)||
	'	ver int2 NOT NULL DEFAULT 1,'||br(1)||
	'	created timestamptz NOT NULL DEFAULT now(),'||br(1)||
	'	created_user text NULL,'||br(1)||
	'	created_sid uuid NULL,'||br(1)||
	'	updated timestamptz NULL,'||br(1)||
	'	updated_user text NULL,'||br(1)||
	'	updated_sid uuid NULL,'||br(1)||
	'	is_for_test bool NOT NULL DEFAULT false,'||br(1)||
	'	notes varchar(1000) NULL,';

	-- Specify doc columns
	IF l_is_doc THEN
		l_sql := l_sql||br(1)||
		'	doc_number text NOT NULL DEFAULT now(),'||br(1)||
		'	doc_date timestamptz NOT NULL DEFAULT now(),'||br(1)||
		'	tax_date timestamptz NOT NULL DEFAULT now(),'||br(1)||
		'	is_commited bool,';
	END IF;

	-- Public name
	l_sql := l_sql||br(1)||
	'	public_name varchar(500) NULL';

	-- Finalize sql
	l_sql := l_sql||br(1)||');';

	-- Excecute
	--RAISE NOTICE 'l_sql: %', l_sql;
	EXECUTE l_sql;

	-- Fill md_table
	DECLARE
		l_md_table_id int;
	BEGIN
		INSERT INTO adm.md_table (
			inner_name
		) VALUES (
			l_table_name
		) RETURNING id INTO l_md_table_id;
	
		UPDATE adm.entity SET md_table_id = l_md_table_id
		WHERE id = p_entity_id;
	END;

END;
$procedure$
;
