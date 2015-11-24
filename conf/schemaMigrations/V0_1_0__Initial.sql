-- Database generated with pgModeler (PostgreSQL Database Modeler).
-- pgModeler  version: 0.8.1
-- PostgreSQL version: 9.4
-- Project Site: pgmodeler.com.br
-- Model Author: ---

SET check_function_bodies = false;
-- ddl-end --

-- -- object: openolympus | type: ROLE --
-- -- DROP ROLE IF EXISTS openolympus;
-- CREATE ROLE openolympus WITH 
-- 	LOGIN
-- 	UNENCRYPTED PASSWORD 'somesecretpassword';
-- -- ddl-end --
-- 

-- Database creation must be done outside an multicommand file.
-- These commands were put in this file only for convenience.
-- -- object: openolympus | type: DATABASE --
-- -- DROP DATABASE IF EXISTS openolympus;
-- CREATE DATABASE openolympus
-- 	ENCODING = 'UTF8'
-- 	TABLESPACE = pg_default
-- 	OWNER = openolympus
-- ;
-- -- ddl-end --
-- 

-- object: public.get_contest_end | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.get_contest_end(integer) CASCADE;
CREATE FUNCTION public.get_contest_end ( contest_id integer)
	RETURNS timestamp with time zone
	LANGUAGE sql
	VOLATILE 
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 100
	AS $$
 SELECT
(contest.start_time + (contest.duration * INTERVAL '1 MILLISECOND') +
(SELECT
(COALESCE(max(extensions_per_user.duration), 0) * INTERVAL '1 MILLISECOND')
FROM (
SELECT COALESCE (sum(time_extension.duration), 0) as duration
FROM time_extension
WHERE time_extension.contest_id = contest.id
GROUP BY time_extension.user_id ) AS extensions_per_user ) )
FROM contest
WHERE contest.id = contest_id
$$;
-- ddl-end --
ALTER FUNCTION public.get_contest_end(integer) OWNER TO openolympus;
-- ddl-end --

-- object: public.get_contest_end_for_user | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.get_contest_end_for_user(IN integer,IN bigint) CASCADE;
CREATE FUNCTION public.get_contest_end_for_user (IN contest_id integer, IN user_id bigint)
	RETURNS timestamp with time zone
	LANGUAGE sql
	VOLATILE 
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 100
	AS $$
SELECT
(contest.start_time +
(contest.duration * INTERVAL '1 MILLISECOND') +
(SELECT (COALESCE(max(extensions_per_user.duration), 0) * INTERVAL '1 MILLISECOND')
FROM ( SELECT COALESCE (sum(time_extension.duration), 0) as duration
FROM time_extension
WHERE time_extension.contest_id = contest.id
AND time_extension.user_id = user_id
GROUP BY time_extension.user_id ) AS extensions_per_user ) )
FROM contest
WHERE contest.id = contest_id 
$$;
-- ddl-end --
ALTER FUNCTION public.get_contest_end_for_user(IN integer,IN bigint) OWNER TO openolympus;
-- ddl-end --

-- object: public.get_contest_start | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.get_contest_start(integer) CASCADE;
CREATE FUNCTION public.get_contest_start ( contest_id integer)
	RETURNS timestamp with time zone
	LANGUAGE sql
	VOLATILE 
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 100
	AS $$
 SELECT contest.start_time FROM contest WHERE contest.id = contest_id
$$;
-- ddl-end --
ALTER FUNCTION public.get_contest_start(integer) OWNER TO openolympus;
-- ddl-end --

-- object: public.get_contest_start_for_user | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.get_contest_start_for_user(integer,bigint) CASCADE;
CREATE FUNCTION public.get_contest_start_for_user ( contest_id integer,  user_id bigint)
	RETURNS timestamp with time zone
	LANGUAGE sql
	VOLATILE 
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 100
	AS $$
 SELECT contest.start_time FROM contest WHERE contest.id = contest_id 
$$;
-- ddl-end --
ALTER FUNCTION public.get_contest_start_for_user(integer,bigint) OWNER TO openolympus;
-- ddl-end --

-- object: public.get_solution_author | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.get_solution_author(bigint) CASCADE;
CREATE FUNCTION public.get_solution_author ( solution_id bigint)
	RETURNS bigint
	LANGUAGE sql
	VOLATILE 
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 100
	AS $$
 SELECT user_id FROM solution WHERE solution.id = solution_id
$$;
-- ddl-end --
ALTER FUNCTION public.get_solution_author(bigint) OWNER TO openolympus;
-- ddl-end --

-- object: public.get_solution_time_added | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.get_solution_time_added(bigint) CASCADE;
CREATE FUNCTION public.get_solution_time_added ( solution_id bigint)
	RETURNS timestamp with time zone
	LANGUAGE sql
	VOLATILE 
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 100
	AS $$
 SELECT time_added FROM solution WHERE solution.id = solution_id 
$$;
-- ddl-end --
ALTER FUNCTION public.get_solution_time_added(bigint) OWNER TO openolympus;
-- ddl-end --

-- object: public.maintain_contest_rank | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.maintain_contest_rank() CASCADE;
CREATE FUNCTION public.maintain_contest_rank ()
	RETURNS trigger
	LANGUAGE plpgsql
	VOLATILE 
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 100
	AS $$
 BEGIN IF (TG_OP = 'UPDATE') THEN PERFORM update_contest(NEW.id); END IF; RETURN NULL; END; 
$$;
-- ddl-end --
ALTER FUNCTION public.maintain_contest_rank() OWNER TO openolympus;
-- ddl-end --

-- object: public.maintain_contest_rank_with_task | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.maintain_contest_rank_with_task() CASCADE;
CREATE FUNCTION public.maintain_contest_rank_with_task ()
	RETURNS trigger
	LANGUAGE plpgsql
	VOLATILE 
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 100
	AS $$
 BEGIN IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN PERFORM update_contest(NEW.contests_id); END IF; IF (TG_OP = 'DELETE') THEN PERFORM update_contest(OLD.contests_id); END IF; RETURN NULL; END; 
$$;
-- ddl-end --
ALTER FUNCTION public.maintain_contest_rank_with_task() OWNER TO openolympus;
-- ddl-end --

-- object: public.maintain_contest_rank_with_time_extensions | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.maintain_contest_rank_with_time_extensions() CASCADE;
CREATE FUNCTION public.maintain_contest_rank_with_time_extensions ()
	RETURNS trigger
	LANGUAGE plpgsql
	VOLATILE 
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 100
	AS $$
 BEGIN IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN PERFORM update_user_in_contest(NEW.user_id, NEW.contest_id); END IF; IF (TG_OP = 'DELETE') THEN PERFORM update_user_in_contest(OLD.user_id, OLD.contest_id); END IF; RETURN NULL; END; 
$$;
-- ddl-end --
ALTER FUNCTION public.maintain_contest_rank_with_time_extensions() OWNER TO openolympus;
-- ddl-end --

-- object: public.maintain_solution_score | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.maintain_solution_score() CASCADE;
CREATE FUNCTION public.maintain_solution_score ()
	RETURNS trigger
	LANGUAGE plpgsql
	VOLATILE 
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 100
	AS $$
 BEGIN IF (TG_OP = 'DELETE') THEN PERFORM update_solution(OLD.solution_id); END IF; IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN PERFORM update_solution(NEW.solution_id); END IF; RETURN NULL; END; 
$$;
-- ddl-end --
ALTER FUNCTION public.maintain_solution_score() OWNER TO openolympus;
-- ddl-end --

-- object: public.update_contest | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.update_contest(IN integer) CASCADE;
CREATE FUNCTION public.update_contest (IN contest_id_p integer)
	RETURNS void
	LANGUAGE plpgsql
	VOLATILE 
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 100
	AS $$
BEGIN
   PERFORM purge_gargabe_contest_participations(contest_id_p);
   PERFORM insert_new_contest_participations(contest_id_p);

   UPDATE contest_participation cp
      SET score =
             (SELECT get_user_total_score_in_contest (cp.contest_id,
                                                      cp.user_id))
    WHERE cp.contest_id = contest_id_p;
END;
$$;
-- ddl-end --
ALTER FUNCTION public.update_contest(IN integer) OWNER TO openolympus;
-- ddl-end --

-- object: public.update_solution | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.update_solution(IN bigint) CASCADE;
CREATE FUNCTION public.update_solution (IN solution_id_p bigint)
	RETURNS void
	LANGUAGE plpgsql
	VOLATILE 
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 100
	AS $$
DECLARE
   user_id_v   bigint;
   task_id_v   integer;
BEGIN
   SELECT user_id_v, task_id_v
     FROM solution s
    WHERE s.id = solution_id_p
     INTO user_id_v, task_id_v;


   UPDATE contest_participation cp
      SET score =
             (SELECT get_user_total_score_in_contest (cp.contest_id,
                                                      cp.user_id))
    WHERE     cp.user_id = user_id_v
          AND cp.contest_id IN (SELECT ct.contest_id
                                  FROM contest_tasks ct
                                 WHERE ct.task_id = task_id_v);
END;
$$;
-- ddl-end --
ALTER FUNCTION public.update_solution(IN bigint) OWNER TO openolympus;
-- ddl-end --

-- object: public.update_user_in_contest | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.update_user_in_contest(bigint,bigint) CASCADE;
CREATE FUNCTION public.update_user_in_contest ( _param1 bigint,  _param2 bigint)
	RETURNS void
	LANGUAGE sql
	VOLATILE 
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 100
	AS $$
 UPDATE solutions SET score=(SELECT coalesce(sum(verdicts.score), 0) FROM verdicts WHERE verdicts.solution_id=solutions.id), maximum_score=(SELECT coalesce(sum(verdicts.maximum_score), 0) FROM verdicts WHERE verdicts.solution_id=solutions.id), tested=(SELECT coalesce(every(verdicts.tested), TRUE) FROM verdicts WHERE verdicts.solution_id=solutions.id) WHERE id=$1; UPDATE contest_participation SET score = ( SELECT coalesce(sum(sols.score), 0) FROM( SELECT DISTINCT ON(solutions.task_id) score FROM solutions RIGHT OUTER JOIN contest_tasks ON contest_tasks.tasks_id = solutions.task_id AND contest_tasks.contests_id=contest_participation.contest_id WHERE solutions.user_id=contest_participation.user_id AND ( solutions.time_added BETWEEN (SELECT get_contest_start_for_user(contest_participation.contest_id,contest_participation.user_id)) AND (SELECT get_contest_end_for_user(contest_participation.contest_id,contest_participation.user_id)) ) ORDER BY solutions.task_id asc, solutions.time_added desc ) AS sols ) WHERE contest_participation.user_id = $1 AND contest_participation.contest_id = $2 
$$;
-- ddl-end --
ALTER FUNCTION public.update_user_in_contest(bigint,bigint) OWNER TO openolympus;
-- ddl-end --

-- object: public.general_permission_type | type: TYPE --
-- DROP TYPE IF EXISTS public.general_permission_type CASCADE;
CREATE TYPE public.general_permission_type AS
 ENUM ('create_contests','remove_contests','create_tasks','remove_tasks','view_others_user_details','remove_user','approve_user_registrations','change_other_users_password','change_other_users_personal_info','enumerate_all_users','task_supervisor','view_other_users_personal_info','create_groups','list_groups','manage_principal_permissions','view_all_solutions','view_archive_during_contest','rejudge_tasks');
-- ddl-end --
ALTER TYPE public.general_permission_type OWNER TO openolympus;
-- ddl-end --

-- object: public.contest_participation | type: TABLE --
-- DROP TABLE IF EXISTS public.contest_participation CASCADE;
CREATE TABLE public.contest_participation(
	id bigserial NOT NULL,
	score numeric(19,2),
	user_id bigint NOT NULL,
	contest_id integer NOT NULL,
	CONSTRAINT contest_participation_pkey PRIMARY KEY (id)

);
-- ddl-end --
ALTER TABLE public.contest_participation OWNER TO openolympus;
-- ddl-end --

-- object: public.contest_question | type: TABLE --
-- DROP TABLE IF EXISTS public.contest_question CASCADE;
CREATE TABLE public.contest_question(
	id serial NOT NULL,
	question text,
	response text,
	user_id bigint NOT NULL,
	contest_id integer NOT NULL,
	CONSTRAINT contest_question_pkey PRIMARY KEY (id)

);
-- ddl-end --
ALTER TABLE public.contest_question OWNER TO openolympus;
-- ddl-end --

-- object: public.persistent_logins | type: TABLE --
-- DROP TABLE IF EXISTS public.persistent_logins CASCADE;
CREATE TABLE public.persistent_logins(
	username character varying(64) NOT NULL,
	series character varying(64) NOT NULL,
	token character varying(64) NOT NULL,
	last_used timestamp with time zone NOT NULL,
	CONSTRAINT persistent_logins_pkey PRIMARY KEY (series)

);
-- ddl-end --
ALTER TABLE public.persistent_logins OWNER TO openolympus;
-- ddl-end --

-- object: public.property | type: TABLE --
-- DROP TABLE IF EXISTS public.property CASCADE;
CREATE TABLE public.property(
	id bigint NOT NULL,
	property_key character varying(255),
	property_value bytea,
	CONSTRAINT property_pkey PRIMARY KEY (id),
	CONSTRAINT uk_4b6vatgj30955xsjr51yegxi9 UNIQUE (property_value),
	CONSTRAINT uk_8jytv8tu3pui7ram00b44tn4u UNIQUE (property_key)

);
-- ddl-end --
ALTER TABLE public.property OWNER TO openolympus;
-- ddl-end --

-- object: public.solution | type: TABLE --
-- DROP TABLE IF EXISTS public.solution CASCADE;
CREATE TABLE public.solution(
	id bigserial NOT NULL,
	file character varying(255),
	maximum_score numeric(19,2),
	score numeric(19,2),
	tested boolean NOT NULL,
	time_added timestamp with time zone,
	user_id bigint,
	task_id integer NOT NULL,
	CONSTRAINT solution_pkey PRIMARY KEY (id)

);
-- ddl-end --
ALTER TABLE public.solution OWNER TO openolympus;
-- ddl-end --

-- object: public.time_extension | type: TABLE --
-- DROP TABLE IF EXISTS public.time_extension CASCADE;
CREATE TABLE public.time_extension(
	id bigserial NOT NULL,
	duration bigint,
	reason text,
	user_id bigint NOT NULL,
	contest_id integer NOT NULL,
	CONSTRAINT time_extension_pkey PRIMARY KEY (id)

);
-- ddl-end --
ALTER TABLE public.time_extension OWNER TO openolympus;
-- ddl-end --

-- object: public.contest | type: TABLE --
-- DROP TABLE IF EXISTS public.contest CASCADE;
CREATE TABLE public.contest(
	id serial NOT NULL,
	duration bigint,
	name character varying(255),
	show_full_tests_during_contest boolean NOT NULL,
	start_time timestamp with time zone,
	CONSTRAINT contest_pkey PRIMARY KEY (id),
	CONSTRAINT contest_name_unique UNIQUE (name)

);
-- ddl-end --
ALTER TABLE public.contest OWNER TO openolympus;
-- ddl-end --

-- object: public.task | type: TABLE --
-- DROP TABLE IF EXISTS public.task CASCADE;
CREATE TABLE public.task(
	id serial NOT NULL,
	description_file text NOT NULL,
	name character varying(255),
	task_location text NOT NULL,
	created_date timestamp with time zone,
	CONSTRAINT task_pkey PRIMARY KEY (id),
	CONSTRAINT task_name_unique UNIQUE (name)

);
-- ddl-end --
ALTER TABLE public.task OWNER TO openolympus;
-- ddl-end --

-- object: public.principal_sequence | type: SEQUENCE --
-- DROP SEQUENCE IF EXISTS public.principal_sequence CASCADE;
CREATE SEQUENCE public.principal_sequence
	INCREMENT BY 1
	MINVALUE 0
	MAXVALUE 2147483647
	START WITH 1
	CACHE 1
	NO CYCLE
	OWNED BY NONE;
-- ddl-end --
ALTER SEQUENCE public.principal_sequence OWNER TO openolympus;
-- ddl-end --

-- object: public.principal | type: TABLE --
-- DROP TABLE IF EXISTS public.principal CASCADE;
CREATE TABLE public.principal(
	id bigint NOT NULL DEFAULT nextval('public.principal_sequence'::regclass),
	permissions public.general_permission_type[] NOT NULL DEFAULT ARRAY[]::public.general_permission_type[],
	CONSTRAINT principal_pk PRIMARY KEY (id)

);
-- ddl-end --
ALTER TABLE public.principal OWNER TO openolympus;
-- ddl-end --

-- object: public."USER" | type: TABLE --
-- DROP TABLE IF EXISTS public."USER" CASCADE;
CREATE TABLE public."USER"(
	id bigint NOT NULL DEFAULT nextval('public.principal_sequence'::regclass),
	username character varying(255),
	first_name_main character varying(255),
	address_city character varying(255),
	address_country character varying(255),
	address_line1 text,
	address_line2 text,
	address_state character varying(255),
	approval_email_sent boolean NOT NULL,
	birth_date date,
	email_address character varying(255),
	email_confirmation_token character varying(255),
	enabled boolean NOT NULL,
	first_name_localised character varying(255),
	landline character varying(255),
	last_name_localised character varying(255),
	last_name_main character varying(255),
	middle_name_localised character varying(255),
	middle_name_main character varying(255),
	mobile character varying(255),
	password character varying(255),
	school character varying(255),
	teacher_first_name character varying(255),
	teacher_last_name character varying(255),
	teacher_middle_name character varying(255),
	superuser boolean NOT NULL DEFAULT false,
	approved boolean NOT NULL DEFAULT false,
	CONSTRAINT user_pk PRIMARY KEY (id),
	CONSTRAINT uk_r43af9ap4edm43mmtq01oddj6 UNIQUE (username)

);
-- ddl-end --
ALTER TABLE public."USER" OWNER TO openolympus;
-- ddl-end --

-- object: public."group" | type: TABLE --
-- DROP TABLE IF EXISTS public."group" CASCADE;
CREATE TABLE public."group"(
	id bigint NOT NULL DEFAULT nextval('public.principal_sequence'::regclass),
	name text NOT NULL,
	CONSTRAINT group_pk PRIMARY KEY (id),
	CONSTRAINT group_name_unique UNIQUE (name)

);
-- ddl-end --
ALTER TABLE public."group" OWNER TO openolympus;
-- ddl-end --

-- object: public.contest_message | type: TABLE --
-- DROP TABLE IF EXISTS public.contest_message CASCADE;
CREATE TABLE public.contest_message(
	id serial NOT NULL,
	question text,
	response text,
	user_id bigint NOT NULL,
	contest_id integer NOT NULL,
	CONSTRAINT contest_messages_pkey PRIMARY KEY (id)

);
-- ddl-end --
ALTER TABLE public.contest_message OWNER TO openolympus;
-- ddl-end --

-- object: "USER_fk" | type: CONSTRAINT --
-- ALTER TABLE public.time_extension DROP CONSTRAINT IF EXISTS "USER_fk" CASCADE;
ALTER TABLE public.time_extension ADD CONSTRAINT "USER_fk" FOREIGN KEY (user_id)
REFERENCES public."USER" (id) MATCH FULL
ON DELETE RESTRICT ON UPDATE CASCADE;
-- ddl-end --

-- object: "USER_fk" | type: CONSTRAINT --
-- ALTER TABLE public.contest_message DROP CONSTRAINT IF EXISTS "USER_fk" CASCADE;
ALTER TABLE public.contest_message ADD CONSTRAINT "USER_fk" FOREIGN KEY (user_id)
REFERENCES public."USER" (id) MATCH FULL
ON DELETE CASCADE ON UPDATE CASCADE;
-- ddl-end --

-- object: "USER_fk" | type: CONSTRAINT --
-- ALTER TABLE public.solution DROP CONSTRAINT IF EXISTS "USER_fk" CASCADE;
ALTER TABLE public.solution ADD CONSTRAINT "USER_fk" FOREIGN KEY (user_id)
REFERENCES public."USER" (id) MATCH FULL
ON DELETE CASCADE ON UPDATE CASCADE;
-- ddl-end --

-- object: solution_by_user | type: INDEX --
-- DROP INDEX IF EXISTS public.solution_by_user CASCADE;
CREATE INDEX solution_by_user ON public.solution
	USING btree
	(
	  user_id ASC NULLS LAST
	);
-- ddl-end --

-- object: task_by_date_desc | type: INDEX --
-- DROP INDEX IF EXISTS public.task_by_date_desc CASCADE;
CREATE INDEX task_by_date_desc ON public.task
	USING btree
	(
	  created_date ASC NULLS LAST
	);
-- ddl-end --

-- object: "USER_fk" | type: CONSTRAINT --
-- ALTER TABLE public.contest_question DROP CONSTRAINT IF EXISTS "USER_fk" CASCADE;
ALTER TABLE public.contest_question ADD CONSTRAINT "USER_fk" FOREIGN KEY (user_id)
REFERENCES public."USER" (id) MATCH FULL
ON DELETE CASCADE ON UPDATE CASCADE;
-- ddl-end --

-- object: public.verdict_status_type | type: TYPE --
-- DROP TYPE IF EXISTS public.verdict_status_type CASCADE;
CREATE TYPE public.verdict_status_type AS
 ENUM ('waiting','being_tested','ok','wrong_answer','runtime_error','cpu_time_limit_exceeded','real_time_limit_exceeded','memory_limit_exceeded','disk_limit_exceeded','security_violated','internal_error','presentation_error','output_limit_exceeded','compile_error');
-- ddl-end --
ALTER TYPE public.verdict_status_type OWNER TO openolympus;
-- ddl-end --

-- object: public.verdict | type: TABLE --
-- DROP TABLE IF EXISTS public.verdict CASCADE;
CREATE TABLE public.verdict(
	id bigserial NOT NULL,
	score numeric(19,2),
	maximum_score numeric(19,2) NOT NULL,
	status public.verdict_status_type NOT NULL,
	viewable_during_contest boolean NOT NULL,
	path text NOT NULL,
	cpu_time bigint,
	real_time bigint,
	memory_peak bigint,
	additional_information text,
	solution_id bigint,
	CONSTRAINT verdict_pk PRIMARY KEY (id)

);
-- ddl-end --
ALTER TABLE public.verdict OWNER TO openolympus;
-- ddl-end --

-- object: solution_fk | type: CONSTRAINT --
-- ALTER TABLE public.verdict DROP CONSTRAINT IF EXISTS solution_fk CASCADE;
ALTER TABLE public.verdict ADD CONSTRAINT solution_fk FOREIGN KEY (solution_id)
REFERENCES public.solution (id) MATCH FULL
ON DELETE CASCADE ON UPDATE CASCADE;
-- ddl-end --

-- object: public.contest_tasks | type: TABLE --
-- DROP TABLE IF EXISTS public.contest_tasks CASCADE;
CREATE TABLE public.contest_tasks(
	contest_id integer,
	task_id integer,
	CONSTRAINT contest_tasks_pk PRIMARY KEY (contest_id,task_id)

);
-- ddl-end --

-- object: contest_fk | type: CONSTRAINT --
-- ALTER TABLE public.contest_tasks DROP CONSTRAINT IF EXISTS contest_fk CASCADE;
ALTER TABLE public.contest_tasks ADD CONSTRAINT contest_fk FOREIGN KEY (contest_id)
REFERENCES public.contest (id) MATCH FULL
ON DELETE RESTRICT ON UPDATE CASCADE;
-- ddl-end --

-- object: task_fk | type: CONSTRAINT --
-- ALTER TABLE public.contest_tasks DROP CONSTRAINT IF EXISTS task_fk CASCADE;
ALTER TABLE public.contest_tasks ADD CONSTRAINT task_fk FOREIGN KEY (task_id)
REFERENCES public.task (id) MATCH FULL
ON DELETE RESTRICT ON UPDATE CASCADE;
-- ddl-end --

-- object: contest_fk | type: CONSTRAINT --
-- ALTER TABLE public.contest_message DROP CONSTRAINT IF EXISTS contest_fk CASCADE;
ALTER TABLE public.contest_message ADD CONSTRAINT contest_fk FOREIGN KEY (contest_id)
REFERENCES public.contest (id) MATCH FULL
ON DELETE CASCADE ON UPDATE CASCADE;
-- ddl-end --

-- object: contest_fk | type: CONSTRAINT --
-- ALTER TABLE public.contest_question DROP CONSTRAINT IF EXISTS contest_fk CASCADE;
ALTER TABLE public.contest_question ADD CONSTRAINT contest_fk FOREIGN KEY (contest_id)
REFERENCES public.contest (id) MATCH FULL
ON DELETE CASCADE ON UPDATE CASCADE;
-- ddl-end --

-- object: contest_fk | type: CONSTRAINT --
-- ALTER TABLE public.contest_participation DROP CONSTRAINT IF EXISTS contest_fk CASCADE;
ALTER TABLE public.contest_participation ADD CONSTRAINT contest_fk FOREIGN KEY (contest_id)
REFERENCES public.contest (id) MATCH FULL
ON DELETE CASCADE ON UPDATE CASCADE;
-- ddl-end --

-- object: contest_fk | type: CONSTRAINT --
-- ALTER TABLE public.time_extension DROP CONSTRAINT IF EXISTS contest_fk CASCADE;
ALTER TABLE public.time_extension ADD CONSTRAINT contest_fk FOREIGN KEY (contest_id)
REFERENCES public.contest (id) MATCH FULL
ON DELETE CASCADE ON UPDATE CASCADE;
-- ddl-end --

-- object: task_fk | type: CONSTRAINT --
-- ALTER TABLE public.solution DROP CONSTRAINT IF EXISTS task_fk CASCADE;
ALTER TABLE public.solution ADD CONSTRAINT task_fk FOREIGN KEY (task_id)
REFERENCES public.task (id) MATCH FULL
ON DELETE RESTRICT ON UPDATE CASCADE;
-- ddl-end --

-- object: public.task_permission_type | type: TYPE --
-- DROP TYPE IF EXISTS public.task_permission_type CASCADE;
CREATE TYPE public.task_permission_type AS
 ENUM ('view','view_during_contest','modify','manage_acl','rejudge','add_to_contest');
-- ddl-end --
ALTER TYPE public.task_permission_type OWNER TO openolympus;
-- ddl-end --

-- object: public.acl_permission_type | type: TYPE --
-- DROP TYPE IF EXISTS public.acl_permission_type CASCADE;
CREATE TYPE public.acl_permission_type AS
 ENUM ('manage_acl','write','read','manage_participants','answer_questions','make_announcements');
-- ddl-end --
ALTER TYPE public.acl_permission_type OWNER TO openolympus;
-- ddl-end --

-- object: public.contest_permission_type | type: TYPE --
-- DROP TYPE IF EXISTS public.contest_permission_type CASCADE;
CREATE TYPE public.contest_permission_type AS
 ENUM ('edit','view_tasks_before_contest_started','delete','add_task','list_tasks','extend_time','know_about','manage_acl','participate','view_participants','remove_task','view_results_during_contest','view_results_after_contest','view_all_solutions','view_tasks_after_contest_started');
-- ddl-end --
ALTER TYPE public.contest_permission_type OWNER TO openolympus;
-- ddl-end --

-- object: public.keep_user_as_principal | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.keep_user_as_principal() CASCADE;
CREATE FUNCTION public.keep_user_as_principal ()
	RETURNS trigger
	LANGUAGE plpgsql
	VOLATILE 
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 1
	AS $$
BEGIN
	IF (TG_OP = 'DELETE') THEN
		DELETE FROM principal WHERE principal.id = OLD.id;
		RETURN OLD;
	ELSIF (TG_OP = 'UPDATE') THEN
		UPDATE principal SET (id) = (NEW.id) WHERE principal.id=OLD.id;
		RETURN NEW;
	ELSIF (TG_OP = 'INSERT') THEN
		INSERT INTO principal(id) VALUES (NEW.id);
		RETURN NEW;
	END IF;
END;
$$;
-- ddl-end --
ALTER FUNCTION public.keep_user_as_principal() OWNER TO openolympus;
-- ddl-end --

-- object: public.task_permission | type: TABLE --
-- DROP TABLE IF EXISTS public.task_permission CASCADE;
CREATE TABLE public.task_permission(
	task_id integer,
	principal_id bigint,
	permission public.task_permission_type NOT NULL,
	CONSTRAINT task_permission_pk PRIMARY KEY (task_id,principal_id,permission)

);
-- ddl-end --

-- object: task_fk | type: CONSTRAINT --
-- ALTER TABLE public.task_permission DROP CONSTRAINT IF EXISTS task_fk CASCADE;
ALTER TABLE public.task_permission ADD CONSTRAINT task_fk FOREIGN KEY (task_id)
REFERENCES public.task (id) MATCH FULL
ON DELETE NO ACTION ON UPDATE NO ACTION;
-- ddl-end --

-- object: principal_fk | type: CONSTRAINT --
-- ALTER TABLE public.task_permission DROP CONSTRAINT IF EXISTS principal_fk CASCADE;
ALTER TABLE public.task_permission ADD CONSTRAINT principal_fk FOREIGN KEY (principal_id)
REFERENCES public.principal (id) MATCH FULL
ON DELETE NO ACTION ON UPDATE NO ACTION;
-- ddl-end --

-- object: public.keep_user_as_member_of_groups | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.keep_user_as_member_of_groups() CASCADE;
CREATE FUNCTION public.keep_user_as_member_of_groups ()
	RETURNS trigger
	LANGUAGE plpgsql
	VOLATILE 
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 1
	AS $$
DECLARE
   superuser_group   bigint;
   all_users_group   bigint;
   approved_users_group   bigint;
BEGIN

superuser_group := (SELECT id FROM "group" WHERE name='#{superusers}');
all_users_group := (SELECT id FROM "group" WHERE name='#{allUsers}');
approved_users_group := (SELECT id FROM "group" WHERE name='#{approvedUsers}');

IF (TG_OP = 'UPDATE') THEN
	IF (NEW.superuser = TRUE AND OLD.superuser = FALSE) THEN
		PERFORM add_to_group(superuser_group, NEW.id);
	END IF;
	IF (NEW.superuser = FALSE AND OLD.superuser = TRUE) THEN
		PERFORM remove_from_group(superuser_group, NEW.id);
	END IF;
	IF (NEW.approved = TRUE AND OLD.approved = FALSE) THEN
		PERFORM add_to_group(superuser_group, NEW.id);
	END IF;
	IF (NEW.approved = FALSE AND OLD.approved = TRUE) THEN
		PERFORM remove_from_group(superuser_group, NEW.id);
	END IF;
	RETURN NEW;
ELSIF (TG_OP = 'INSERT') THEN
	PERFORM add_to_group(all_users_group, NEW.id);
	IF(NEW.approved=TRUE) THEN
		PERFORM add_to_group(approved_users_group, NEW.id);
	END IF;
	IF(NEW.superuser=TRUE) THEN
		PERFORM add_to_group(superuser_group, NEW.id);
	END IF;
	RETURN NEW;
ELSIF (TG_OP = 'DELETE') THEN
	DELETE FROM group_users
	WHERE user_id=OLD.id;
	RETURN OLD;
END IF;

END;
$$;
-- ddl-end --
ALTER FUNCTION public.keep_user_as_member_of_groups() OWNER TO openolympus;
-- ddl-end --

-- object: public.keep_group_as_principal | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.keep_group_as_principal() CASCADE;
CREATE FUNCTION public.keep_group_as_principal ()
	RETURNS trigger
	LANGUAGE plpgsql
	VOLATILE 
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 1
	AS $$
BEGIN
	IF (TG_OP = 'DELETE') THEN
		DELETE FROM principal WHERE principal.id = OLD.id;
		RETURN OLD;
	ELSIF (TG_OP = 'UPDATE') THEN
		UPDATE principal SET (id) = (NEW.id) WHERE principal.id=OLD.id;
		RETURN NEW;
	ELSIF (TG_OP = 'INSERT') THEN
		INSERT INTO principal(id) VALUES (NEW.id);
		RETURN NEW;
	END IF;
END;
$$;
-- ddl-end --
ALTER FUNCTION public.keep_group_as_principal() OWNER TO openolympus;
-- ddl-end --

-- object: keep_group_as_principal_trigger | type: TRIGGER --
-- DROP TRIGGER IF EXISTS keep_group_as_principal_trigger ON public."group"  ON public."group" CASCADE;
CREATE TRIGGER keep_group_as_principal_trigger
	BEFORE INSERT OR DELETE OR UPDATE
	ON public."group"
	FOR EACH ROW
	EXECUTE PROCEDURE public.keep_group_as_principal();
-- ddl-end --

-- object: public.has_general_permission | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.has_general_permission(IN bigint,IN public.general_permission_type) CASCADE;
CREATE FUNCTION public.has_general_permission (IN principal_id_p bigint, IN permission_p public.general_permission_type)
	RETURNS boolean
	LANGUAGE plpgsql
	VOLATILE 
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 1
	AS $$
BEGIN 
	IF (SELECT 1 FROM principal
		WHERE 
		(
			principal.id = principal_id_p
			OR
			principal.id IN (SELECT group_id FROM group_users
			WHERE group_users."user_id"=principal_id_p)
		)
		AND
	 	principal.permissions @>
	 		ARRAY[permission_p]::public.general_permission_type[]
	 	) THEN
		RETURN TRUE;
	END IF;
	RETURN FALSE;
END;
$$;
-- ddl-end --
ALTER FUNCTION public.has_general_permission(IN bigint,IN public.general_permission_type) OWNER TO openolympus;
-- ddl-end --

-- object: public.has_contest_permission | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.has_contest_permission(IN integer,IN bigint,IN public.contest_permission_type) CASCADE;
CREATE FUNCTION public.has_contest_permission (IN contest_id_p integer, IN principal_id_p bigint, IN permission_p public.contest_permission_type)
	RETURNS boolean
	LANGUAGE plpgsql
	VOLATILE 
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 1
	AS $$
BEGIN 
	IF EXISTS (SELECT 1 FROM contest_permission WHERE
		permission_applies_to_principal(principal_id_p, contest_permission.principal_id) AND
		contest_permission.contest_id=contest_id_p AND
		contest_permission.permission=permission_p
		) THEN
		RETURN TRUE;
	END IF;
	RETURN FALSE;
END;
$$;
-- ddl-end --
ALTER FUNCTION public.has_contest_permission(IN integer,IN bigint,IN public.contest_permission_type) OWNER TO openolympus;
-- ddl-end --

-- object: public.group_permission_type | type: TYPE --
-- DROP TYPE IF EXISTS public.group_permission_type CASCADE;
CREATE TYPE public.group_permission_type AS
 ENUM ('view_members','add_member','remove_member','know_about','edit','manage_acl');
-- ddl-end --
ALTER TYPE public.group_permission_type OWNER TO openolympus;
-- ddl-end --

-- object: public.has_task_permission | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.has_task_permission(IN integer,IN bigint,IN public.task_permission_type) CASCADE;
CREATE FUNCTION public.has_task_permission (IN task_id_p integer, IN principal_id_p bigint, IN permission_p public.task_permission_type)
	RETURNS boolean
	LANGUAGE plpgsql
	VOLATILE 
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 1
	AS $$
BEGIN 
	IF EXISTS (SELECT 1 FROM task_permission WHERE
		permission_applies_to_principal(principal_id_p, task_permission.principal_id) AND
		task_permission.task_id=task_id_p AND
		task_permission.permission=permission_p
		) THEN
		RETURN TRUE;
	END IF;
	RETURN FALSE;
END;
$$;
-- ddl-end --
ALTER FUNCTION public.has_task_permission(IN integer,IN bigint,IN public.task_permission_type) OWNER TO openolympus;
-- ddl-end --

-- object: public.permission_applies_to_principal | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.permission_applies_to_principal(IN bigint,IN bigint) CASCADE;
CREATE FUNCTION public.permission_applies_to_principal (IN principal_id_p bigint, IN permission_principal_id_p bigint)
	RETURNS boolean
	LANGUAGE plpgsql
	VOLATILE 
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 1
	AS $$
BEGIN
	RETURN permission_principal_id_p = principal_id_p OR
	permission_principal_id_p IN (SELECT group_id FROM group_users
			WHERE group_users."user_id"=principal_id_p);
END;
$$;
-- ddl-end --
ALTER FUNCTION public.permission_applies_to_principal(IN bigint,IN bigint) OWNER TO openolympus;
-- ddl-end --

-- object: public.raise_contest_intersects_error | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.raise_contest_intersects_error() CASCADE;
CREATE FUNCTION public.raise_contest_intersects_error ()
	RETURNS trigger
	LANGUAGE plpgsql
	VOLATILE 
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 1
	AS $$
DECLARE end_time timestamp WITH time ZONE;
BEGIN
    end_time = (
        SELECT (
                NEW.start_time + (
                    NEW.duration * interval '1 MILLISECOND' )
            + (
                SELECT (
                        COALESCE (
                            max (
                                extensions_per_user.duration ),
                        0 )
            * interval '1 MILLISECOND' )
FROM (
        SELECT
            COALESCE (
                sum (
                    time_extension.duration ),
            0 ) AS duration
FROM
    time_extension
WHERE
    time_extension.contest_id = NEW.id
GROUP BY
    time_extension.user_id ) AS extensions_per_user ) ) );
RAISE NOTICE 'end time is %', end_time;
IF EXISTS (
    SELECT
        1
    FROM
        contest
    WHERE
        tstzrange (
            get_contest_start (
                contest.id ),
        get_contest_end (
            contest.id ) )
&& tstzrange (
    NEW.start_time,
    end_time )
AND contest.id != NEW.id )
THEN RAISE EXCEPTION 'contest intersects';
END IF;
RETURN NULL;
END;
$$;
-- ddl-end --
ALTER FUNCTION public.raise_contest_intersects_error() OWNER TO openolympus;
-- ddl-end --

-- object: contest_intersection_consistency_check | type: TRIGGER --
-- DROP TRIGGER IF EXISTS contest_intersection_consistency_check ON public.contest  ON public.contest CASCADE;
CREATE TRIGGER contest_intersection_consistency_check
	AFTER INSERT OR UPDATE
	ON public.contest
	FOR EACH ROW
	EXECUTE PROCEDURE public.raise_contest_intersects_error();
-- ddl-end --

-- object: public.get_contests_that_intersect | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.get_contests_that_intersect(IN timestamp with time zone,IN timestamp with time zone) CASCADE;
CREATE FUNCTION public.get_contests_that_intersect (IN time_range_start timestamp with time zone, IN time_range_end timestamp with time zone)
	RETURNS SETOF public.contest
	LANGUAGE sql
	VOLATILE 
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 1
	ROWS 1
	AS $$
SELECT * FROM contest WHERE tstzrange(get_contest_start(contest.id), get_contest_end(contest.id)) && tstzrange(time_range_start, time_range_end)
$$;
-- ddl-end --
ALTER FUNCTION public.get_contests_that_intersect(IN timestamp with time zone,IN timestamp with time zone) OWNER TO openolympus;
-- ddl-end --

-- object: public.has_group_permission | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.has_group_permission(IN bigint,IN bigint,IN public.group_permission_type) CASCADE;
CREATE FUNCTION public.has_group_permission (IN group_id_p bigint, IN principal_id_p bigint, IN permission_p public.group_permission_type)
	RETURNS boolean
	LANGUAGE plpgsql
	VOLATILE 
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 1
	AS $$
BEGIN 
	IF EXISTS (SELECT 1 FROM group_permission WHERE
		permission_applies_to_principal(principal_id_p, group_permission.principal_id) AND
		group_permission.group_id=group_id_p AND
		group_permission.permission=permission_p
		) THEN
		RETURN TRUE;
	END IF;
	RETURN FALSE;
END;
$$;
-- ddl-end --
ALTER FUNCTION public.has_group_permission(IN bigint,IN bigint,IN public.group_permission_type) OWNER TO openolympus;
-- ddl-end --

-- object: "USER_fk" | type: CONSTRAINT --
-- ALTER TABLE public.contest_participation DROP CONSTRAINT IF EXISTS "USER_fk" CASCADE;
ALTER TABLE public.contest_participation ADD CONSTRAINT "USER_fk" FOREIGN KEY (user_id)
REFERENCES public."USER" (id) MATCH FULL
ON DELETE CASCADE ON UPDATE CASCADE;
-- ddl-end --

-- object: keep_user_as_principal_trigger | type: TRIGGER --
-- DROP TRIGGER IF EXISTS keep_user_as_principal_trigger ON public."USER"  ON public."USER" CASCADE;
CREATE TRIGGER keep_user_as_principal_trigger
	BEFORE INSERT OR DELETE OR UPDATE
	ON public."USER"
	FOR EACH ROW
	EXECUTE PROCEDURE public.keep_user_as_principal();
-- ddl-end --

-- object: keep_user_as_member_of_groups_trigger | type: TRIGGER --
-- DROP TRIGGER IF EXISTS keep_user_as_member_of_groups_trigger ON public."USER"  ON public."USER" CASCADE;
CREATE TRIGGER keep_user_as_member_of_groups_trigger
	AFTER INSERT OR UPDATE
	ON public."USER"
	FOR EACH ROW
	EXECUTE PROCEDURE public.keep_user_as_member_of_groups();
-- ddl-end --

-- object: user_keep_principal_insert | type: RULE --
-- DROP RULE IF EXISTS user_keep_principal_insert ON public."USER"  ON public."USER" CASCADE;
CREATE RULE user_keep_principal_insert AS ON INSERT
	TO public."USER"
	DO ALSO (INSERT INTO principal(id) VALUES (NEW.id));
-- ddl-end --

-- object: user_keep_principal_update | type: RULE --
-- DROP RULE IF EXISTS user_keep_principal_update ON public."USER"  ON public."USER" CASCADE;
CREATE RULE user_keep_principal_update AS ON UPDATE
	TO public."USER"
	DO ALSO (UPDATE principal SET (id) = (NEW.id) WHERE principal.id=OLD.id);
-- ddl-end --

-- object: user_keep_principal_delete | type: RULE --
-- DROP RULE IF EXISTS user_keep_principal_delete ON public."USER"  ON public."USER" CASCADE;
CREATE RULE user_keep_principal_delete AS ON DELETE
	TO public."USER"
	DO ALSO (DELETE FROM principal WHERE principal.id = OLD.id);
-- ddl-end --

-- object: public.group_permission | type: TABLE --
-- DROP TABLE IF EXISTS public.group_permission CASCADE;
CREATE TABLE public.group_permission(
	principal_id bigint NOT NULL,
	group_id bigint NOT NULL,
	permission public.group_permission_type NOT NULL,
	CONSTRAINT group_permission_pk PRIMARY KEY (principal_id,group_id,permission)

);
-- ddl-end --
ALTER TABLE public.group_permission OWNER TO openolympus;
-- ddl-end --

-- object: public.get_participants_group_id_from_contest_id | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.get_participants_group_id_from_contest_id(IN integer) CASCADE;
CREATE FUNCTION public.get_participants_group_id_from_contest_id (IN contest_id_p integer)
	RETURNS bigint
	LANGUAGE plpgsql
	VOLATILE 
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 1
	AS $$
BEGIN
    RETURN (
        SELECT
            participants_group
        FROM
            contest
        WHERE
            contest.id = contest_id_p);
END;
$$;
-- ddl-end --
ALTER FUNCTION public.get_participants_group_id_from_contest_id(IN integer) OWNER TO openolympus;
-- ddl-end --

-- object: public.group_users | type: TABLE --
-- DROP TABLE IF EXISTS public.group_users CASCADE;
CREATE TABLE public.group_users(
	can_add_others_to_group bool NOT NULL DEFAULT false,
	group_id bigint,
	user_id bigint,
	CONSTRAINT group_users_pk PRIMARY KEY (group_id,user_id)

);
-- ddl-end --
ALTER TABLE public.group_users OWNER TO openolympus;
-- ddl-end --

-- object: group_fk | type: CONSTRAINT --
-- ALTER TABLE public.group_users DROP CONSTRAINT IF EXISTS group_fk CASCADE;
ALTER TABLE public.group_users ADD CONSTRAINT group_fk FOREIGN KEY (group_id)
REFERENCES public."group" (id) MATCH FULL
ON DELETE CASCADE ON UPDATE CASCADE;
-- ddl-end --

-- object: "USER_fk" | type: CONSTRAINT --
-- ALTER TABLE public.group_users DROP CONSTRAINT IF EXISTS "USER_fk" CASCADE;
ALTER TABLE public.group_users ADD CONSTRAINT "USER_fk" FOREIGN KEY (user_id)
REFERENCES public."USER" (id) MATCH FULL
ON DELETE CASCADE ON UPDATE CASCADE;
-- ddl-end --

-- object: public.user_immutable_columns | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.user_immutable_columns() CASCADE;
CREATE FUNCTION public.user_immutable_columns ()
	RETURNS trigger
	LANGUAGE plpgsql
	VOLATILE 
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 1
	AS $$
BEGIN
    PERFORM check_immutability('id', OLD.id, NEW.id);
    RETURN NEW;
END;
$$;
-- ddl-end --
ALTER FUNCTION public.user_immutable_columns() OWNER TO openolympus;
-- ddl-end --

-- object: user_immutable_columns | type: TRIGGER --
-- DROP TRIGGER IF EXISTS user_immutable_columns ON public."USER"  ON public."USER" CASCADE;
CREATE TRIGGER user_immutable_columns
	BEFORE UPDATE
	ON public."USER"
	FOR EACH ROW
	EXECUTE PROCEDURE public.user_immutable_columns();
-- ddl-end --

-- object: public.group_immutable_columns | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.group_immutable_columns() CASCADE;
CREATE FUNCTION public.group_immutable_columns ()
	RETURNS trigger
	LANGUAGE plpgsql
	VOLATILE 
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 1
	AS $$
BEGIN
    PERFORM check_immutability('id', OLD.id, NEW.id);
    RETURN NEW;
END;
$$;
-- ddl-end --
ALTER FUNCTION public.group_immutable_columns() OWNER TO openolympus;
-- ddl-end --

-- object: group_immutable_columns | type: TRIGGER --
-- DROP TRIGGER IF EXISTS group_immutable_columns ON public."group"  ON public."group" CASCADE;
CREATE TRIGGER group_immutable_columns
	BEFORE UPDATE
	ON public."group"
	FOR EACH ROW
	EXECUTE PROCEDURE public.group_immutable_columns();
-- ddl-end --

-- object: public.principal_immutable_columns | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.principal_immutable_columns() CASCADE;
CREATE FUNCTION public.principal_immutable_columns ()
	RETURNS trigger
	LANGUAGE plpgsql
	VOLATILE 
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 1
	AS $$
BEGIN
    PERFORM check_immutability('id', OLD.id, NEW.id);
    RETURN NEW;
END;
$$;
-- ddl-end --
ALTER FUNCTION public.principal_immutable_columns() OWNER TO openolympus;
-- ddl-end --

-- object: public.group_users_immutable_columns | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.group_users_immutable_columns() CASCADE;
CREATE FUNCTION public.group_users_immutable_columns ()
	RETURNS trigger
	LANGUAGE plpgsql
	VOLATILE 
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 1
	AS $$
BEGIN
    PERFORM check_immutability('user_id', OLD.user_id, NEW.user_id);
    PERFORM check_immutability('group_id', OLD.group_id, NEW.group_id);
    RETURN NEW;
END;
$$;
-- ddl-end --
ALTER FUNCTION public.group_users_immutable_columns() OWNER TO openolympus;
-- ddl-end --

-- object: group_users_immutable_columns | type: TRIGGER --
-- DROP TRIGGER IF EXISTS group_users_immutable_columns ON public.group_users  ON public.group_users CASCADE;
CREATE TRIGGER group_users_immutable_columns
	BEFORE UPDATE
	ON public.group_users
	FOR EACH ROW
	EXECUTE PROCEDURE public.group_users_immutable_columns();
-- ddl-end --

-- object: principal_immutable_columns | type: TRIGGER --
-- DROP TRIGGER IF EXISTS principal_immutable_columns ON public.principal  ON public.principal CASCADE;
CREATE TRIGGER principal_immutable_columns
	BEFORE UPDATE
	ON public.principal
	FOR EACH ROW
	EXECUTE PROCEDURE public.principal_immutable_columns();
-- ddl-end --

-- object: public.contest_participation_immutable_columns | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.contest_participation_immutable_columns() CASCADE;
CREATE FUNCTION public.contest_participation_immutable_columns ()
	RETURNS trigger
	LANGUAGE plpgsql
	VOLATILE 
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 1
	AS $$
BEGIN
    PERFORM check_immutability('id', OLD.id, NEW.id);
    PERFORM check_immutability('user_id', OLD.user_id, NEW.user_id);
    PERFORM check_immutability('contest_id', OLD.contest_id, NEW.contest_id);
    RETURN NEW;
END;
$$;
-- ddl-end --
ALTER FUNCTION public.contest_participation_immutable_columns() OWNER TO openolympus;
-- ddl-end --

-- object: contest_participation_immutable_columns | type: TRIGGER --
-- DROP TRIGGER IF EXISTS contest_participation_immutable_columns ON public.contest_participation  ON public.contest_participation CASCADE;
CREATE TRIGGER contest_participation_immutable_columns
	BEFORE UPDATE
	ON public.contest_participation
	FOR EACH ROW
	EXECUTE PROCEDURE public.contest_participation_immutable_columns();
-- ddl-end --

-- object: public.check_immutability | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.check_immutability(IN text,IN anyelement,IN anyelement) CASCADE;
CREATE FUNCTION public.check_immutability (IN name_v text, IN old_v anyelement, IN new_v anyelement)
	RETURNS void
	LANGUAGE plpgsql
	VOLATILE 
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 1
	AS $$
BEGIN
    IF new_v IS DISTINCT FROM old_v THEN
        RAISE EXCEPTION 'Attempted to update immutable column %: Old: %, New: %', name_v, old_v, new_v;
    END IF;
END;
$$;
-- ddl-end --
ALTER FUNCTION public.check_immutability(IN text,IN anyelement,IN anyelement) OWNER TO openolympus;
-- ddl-end --

-- object: public.keep_group_member_in_contest_participations_list | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.keep_group_member_in_contest_participations_list() CASCADE;
CREATE FUNCTION public.keep_group_member_in_contest_participations_list ()
	RETURNS trigger
	LANGUAGE plpgsql
	VOLATILE 
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 1
	AS $$
BEGIN
   IF (TG_OP = 'INSERT')
   THEN
      INSERT INTO contest_participation (score, user_id, contest_id)
         SELECT get_user_total_score_in_contest (contest_id, NEW.user_id),
                NEW.user_id,
                contest_id
           FROM "group"
                INNER JOIN contest_permission
                   ON contest_permission.principal_id = "group".id
          WHERE     contest_permission.permission = 'participate'
                AND NOT EXISTS
                       (SELECT 1
                          FROM contest_participation cp
                         WHERE     cp.user_id = NEW.user_id
                               AND cp.contest_id =
                                      contest_permission.contest_id);
   END IF;

   IF (TG_OP = 'DELETE')
   THEN
      DELETE FROM contest_participation
            WHERE     contest_participation.user_id = OLD.user_id
                  AND NOT has_contest_permission (contest_participation.contest_id,
                                                  OLD.user_id,
                                                  'participate');
      RETURN OLD;
   END IF;
   RETURN NEW;
END;
$$;
-- ddl-end --
ALTER FUNCTION public.keep_group_member_in_contest_participations_list() OWNER TO openolympus;
-- ddl-end --

-- object: keep_group_member_in_contest_participants_list | type: TRIGGER --
-- DROP TRIGGER IF EXISTS keep_group_member_in_contest_participants_list ON public.group_users  ON public.group_users CASCADE;
CREATE TRIGGER keep_group_member_in_contest_participants_list
	AFTER INSERT OR DELETE 
	ON public.group_users
	FOR EACH ROW
	EXECUTE PROCEDURE public.keep_group_member_in_contest_participations_list();
-- ddl-end --

-- object: public.get_user_total_score_in_contest | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.get_user_total_score_in_contest(IN integer,IN bigint) CASCADE;
CREATE FUNCTION public.get_user_total_score_in_contest (IN contest_id_p integer, IN user_id_p bigint)
	RETURNS numeric(19,2)
	LANGUAGE plpgsql
	VOLATILE 
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 1
	AS $$
BEGIN
   RETURN (SELECT coalesce (sum (sols.score), 0)
             FROM (  SELECT DISTINCT ON (s.task_id) s.score
                       FROM contest_tasks ct
                            INNER JOIN solution s
                               ON     ct.task_id = s.task_id
                                  AND ct.contest_id = contest_id_p
                      WHERE     s.user_id = user_id_p
                            AND (s.time_added BETWEEN (SELECT get_contest_start_for_user (
                                                                 contest_id_p,
                                                                 user_id_p))
                                                  AND (SELECT get_contest_end_for_user (
                                                                 contest_id_p,
                                                                 user_id_p)))
                   ORDER BY s.task_id ASC, s.time_added DESC) AS sols);
END;
$$;
-- ddl-end --
ALTER FUNCTION public.get_user_total_score_in_contest(IN integer,IN bigint) OWNER TO openolympus;
-- ddl-end --

-- object: public.purge_gargabe_contest_participations | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.purge_gargabe_contest_participations(IN integer) CASCADE;
CREATE FUNCTION public.purge_gargabe_contest_participations (IN contest_id_p integer)
	RETURNS void
	LANGUAGE plpgsql
	VOLATILE 
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 1
	AS $$
BEGIN
   DELETE FROM contest_participation cp
         WHERE     cp.contest_id = contest_id_p
               AND NOT has_contest_permission (contest_id_p, cp.user_id, 'participate');
END;
$$;
-- ddl-end --
ALTER FUNCTION public.purge_gargabe_contest_participations(IN integer) OWNER TO openolympus;
-- ddl-end --

-- object: public.insert_new_contest_participations | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.insert_new_contest_participations(IN integer) CASCADE;
CREATE FUNCTION public.insert_new_contest_participations (IN contest_id_p integer)
	RETURNS void
	LANGUAGE plpgsql
	VOLATILE 
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 1
	AS $$
BEGIN
   INSERT INTO contest_participation (score, user_id, contest_id)
      SELECT get_user_total_score_in_contest (contest_id_p, u.id),
             u.id,
             contest_id_p
        FROM "USER" u
       WHERE has_contest_permission (contest_id_p, u.id, 'participate');
END;
$$;
-- ddl-end --
ALTER FUNCTION public.insert_new_contest_participations(IN integer) OWNER TO openolympus;
-- ddl-end --

-- object: public.trgr_verdict_update | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.trgr_verdict_update() CASCADE;
CREATE FUNCTION public.trgr_verdict_update ()
	RETURNS trigger
	LANGUAGE plpgsql
	VOLATILE 
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 1
	AS $$
BEGIN
   IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE'
   THEN
    PERFORM update_solution(NEW.solution_id);
    RETURN NEW;
   ELSIF TG_OP = 'DELETE'
   THEN
    PERFORM update_solution(OLD.solution_id);
    RETURN OLD;
   END IF;
END;
$$;
-- ddl-end --
ALTER FUNCTION public.trgr_verdict_update() OWNER TO openolympus;
-- ddl-end --

-- object: trgr_verdict_maintain_totals | type: TRIGGER --
-- DROP TRIGGER IF EXISTS trgr_verdict_maintain_totals ON public.verdict  ON public.verdict CASCADE;
CREATE TRIGGER trgr_verdict_maintain_totals
	AFTER INSERT OR DELETE OR UPDATE
	ON public.verdict
	FOR EACH ROW
	EXECUTE PROCEDURE public.trgr_verdict_update();
-- ddl-end --

-- object: public.trgr_solution_updated | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.trgr_solution_updated() CASCADE;
CREATE FUNCTION public.trgr_solution_updated ()
	RETURNS trigger
	LANGUAGE plpgsql
	VOLATILE 
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 1
	AS $$
DECLARE
   user_id_v   bigint;
   task_id_v   integer;
BEGIN
   SELECT user_id_v, task_id_v
     FROM solution s
    WHERE s.id = NEW.id
     INTO user_id_v, task_id_v;

   UPDATE contest_participation cp
      SET score =
             (SELECT get_user_total_score_in_contest (cp.contest_id,
                                                      cp.user_id))
    WHERE     cp.user_id = user_id_v
          AND cp.contest_id IN (SELECT ct.contest_id
                                  FROM contest_tasks ct
                                 WHERE ct.task_id = task_id_v);
    IF TG_OP='DELETE' THEN
    	return OLD;
    END IF;
    RETURN NEW;
END;
$$;
-- ddl-end --
ALTER FUNCTION public.trgr_solution_updated() OWNER TO openolympus;
-- ddl-end --

-- object: trgr_solution_updated | type: TRIGGER --
-- DROP TRIGGER IF EXISTS trgr_solution_updated ON public.solution  ON public.solution CASCADE;
CREATE TRIGGER trgr_solution_updated
	AFTER INSERT OR UPDATE
	ON public.solution
	FOR EACH ROW
	EXECUTE PROCEDURE public.trgr_solution_updated();
-- ddl-end --

-- object: public.trgr_contest_updated | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.trgr_contest_updated() CASCADE;
CREATE FUNCTION public.trgr_contest_updated ()
	RETURNS trigger
	LANGUAGE plpgsql
	VOLATILE 
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 1
	AS $$
BEGIN
	PERFORM update_contest(NEW.id);
	RETURN NEW;
END;
$$;
-- ddl-end --
ALTER FUNCTION public.trgr_contest_updated() OWNER TO openolympus;
-- ddl-end --

-- object: trgr_contest_updated | type: TRIGGER --
-- DROP TRIGGER IF EXISTS trgr_contest_updated ON public.contest  ON public.contest CASCADE;
CREATE TRIGGER trgr_contest_updated
	AFTER UPDATE
	ON public.contest
	FOR EACH ROW
	EXECUTE PROCEDURE public.trgr_contest_updated();
-- ddl-end --

-- object: public.contest_permission | type: TABLE --
-- DROP TABLE IF EXISTS public.contest_permission CASCADE;
CREATE TABLE public.contest_permission(
	permission public.contest_permission_type NOT NULL,
	contest_id integer NOT NULL,
	principal_id bigint NOT NULL,
	CONSTRAINT contest_permission_pk PRIMARY KEY (permission,contest_id,principal_id)

);
-- ddl-end --

-- object: public.trgr_contest_permissions_changed | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.trgr_contest_permissions_changed() CASCADE;
CREATE FUNCTION public.trgr_contest_permissions_changed ()
	RETURNS trigger
	LANGUAGE plpgsql
	VOLATILE 
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 1
	AS $$
DECLARE
   is_group_v       bool;
   principal_id_v   bigint;
BEGIN
   IF (TG_OP = 'INSERT')
   THEN
      principal_id_v := NEW.principal_id;
   END IF;

   IF (TG_OP = 'DELETE')
   THEN
      principal_id_v := OLD.principal_id;
   END IF;

   SELECT EXISTS
             (SELECT 1
                FROM "group"
               WHERE "group".id = principal_id_v)
     INTO is_group_v;

   IF (TG_OP = 'DELETE') AND OLD.permission = 'participate'
   THEN
      IF is_group_v
      THEN
    PERFORM purge_gargabe_contest_participations(OLD.contest_id);
      ELSE
         DELETE FROM contest_participation cp
               WHERE     cp.user_id = OLD.principal_id
                     AND cp.contest_id = OLD.contest_id
                     AND NOT has_contest_permission (OLD.contest_id,
                                                     OLD.principal_id,
                                                     'participate');
      END IF;
   ELSIF (TG_OP = 'INSERT') AND NEW.permission = 'participate'
   THEN
      IF is_group_v
      THEN
    PERFORM insert_new_contest_participations(NEW.contest_id);
      ELSE
         INSERT INTO contest_participation (score, user_id, contest_id)
            SELECT get_user_total_score_in_contest (NEW.contest_id,
                                                    NEW.principal_id),
                   NEW.principal_id,
                   NEW.contest_id
              FROM "USER" u
             WHERE NOT has_contest_permission (NEW.contest_id, u.id, 'participate');
      END IF;
   END IF;

   IF TG_OP = 'DELETE'
   THEN
      RETURN OLD;
   END IF;

   RETURN NEW;
END;

$$;
-- ddl-end --
ALTER FUNCTION public.trgr_contest_permissions_changed() OWNER TO openolympus;
-- ddl-end --

-- object: trgr_contest_permissions_changed | type: TRIGGER --
-- DROP TRIGGER IF EXISTS trgr_contest_permissions_changed ON public.contest_permission  ON public.contest_permission CASCADE;
CREATE TRIGGER trgr_contest_permissions_changed
	AFTER INSERT OR DELETE 
	ON public.contest_permission
	FOR EACH ROW
	EXECUTE PROCEDURE public.trgr_contest_permissions_changed();
-- ddl-end --

-- object: public.add_to_group | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.add_to_group(IN bigint,IN bigint) CASCADE;
CREATE FUNCTION public.add_to_group (IN group_id_p bigint, IN user_id_p bigint)
	RETURNS void
	LANGUAGE sql
	VOLATILE 
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 1
	AS $$
INSERT INTO group_users(group_id, "user_id",can_add_others_to_group) VALUES
	(group_id_p, user_id_p, FALSE)
$$;
-- ddl-end --
ALTER FUNCTION public.add_to_group(IN bigint,IN bigint) OWNER TO openolympus;
-- ddl-end --

-- object: public.remove_from_group | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.remove_from_group(IN bigint,IN bigint) CASCADE;
CREATE FUNCTION public.remove_from_group (IN user_id_p bigint, IN group_id_p bigint)
	RETURNS void
	LANGUAGE sql
	VOLATILE 
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 1
	AS $$
DELETE FROM group_users
	WHERE group_users.user_id = user_id_p
	AND group_users.group_id=group_id_p
$$;
-- ddl-end --
ALTER FUNCTION public.remove_from_group(IN bigint,IN bigint) OWNER TO openolympus;
-- ddl-end --

-- object: user_principal_id_mapping | type: CONSTRAINT --
-- ALTER TABLE public."USER" DROP CONSTRAINT IF EXISTS user_principal_id_mapping CASCADE;
ALTER TABLE public."USER" ADD CONSTRAINT user_principal_id_mapping FOREIGN KEY (id)
REFERENCES public.principal (id) MATCH FULL
ON DELETE CASCADE ON UPDATE CASCADE;
-- ddl-end --

-- object: group_principal_id_mapping | type: CONSTRAINT --
-- ALTER TABLE public."group" DROP CONSTRAINT IF EXISTS group_principal_id_mapping CASCADE;
ALTER TABLE public."group" ADD CONSTRAINT group_principal_id_mapping FOREIGN KEY (id)
REFERENCES public.principal (id) MATCH FULL
ON DELETE CASCADE ON UPDATE CASCADE;
-- ddl-end --

-- object: group_permission_principal_fk | type: CONSTRAINT --
-- ALTER TABLE public.group_permission DROP CONSTRAINT IF EXISTS group_permission_principal_fk CASCADE;
ALTER TABLE public.group_permission ADD CONSTRAINT group_permission_principal_fk FOREIGN KEY (principal_id)
REFERENCES public.principal (id) MATCH FULL
ON DELETE CASCADE ON UPDATE CASCADE;
-- ddl-end --

-- object: group_permission_group_fk | type: CONSTRAINT --
-- ALTER TABLE public.group_permission DROP CONSTRAINT IF EXISTS group_permission_group_fk CASCADE;
ALTER TABLE public.group_permission ADD CONSTRAINT group_permission_group_fk FOREIGN KEY (group_id)
REFERENCES public."group" (id) MATCH FULL
ON DELETE CASCADE ON UPDATE CASCADE;
-- ddl-end --

-- object: contest_permission_contest_id_fk | type: CONSTRAINT --
-- ALTER TABLE public.contest_permission DROP CONSTRAINT IF EXISTS contest_permission_contest_id_fk CASCADE;
ALTER TABLE public.contest_permission ADD CONSTRAINT contest_permission_contest_id_fk FOREIGN KEY (contest_id)
REFERENCES public.contest (id) MATCH FULL
ON DELETE CASCADE ON UPDATE NO ACTION;
-- ddl-end --

-- object: contest_permission_principal_id_fk | type: CONSTRAINT --
-- ALTER TABLE public.contest_permission DROP CONSTRAINT IF EXISTS contest_permission_principal_id_fk CASCADE;
ALTER TABLE public.contest_permission ADD CONSTRAINT contest_permission_principal_id_fk FOREIGN KEY (principal_id)
REFERENCES public.principal (id) MATCH FULL
ON DELETE CASCADE ON UPDATE NO ACTION;
-- ddl-end --


