SET CONSTRAINTS ALL DEFERRED;
-- Database diff generated with pgModeler (PostgreSQL Database Modeler).
-- pgModeler  version: 0.8.2-beta1
-- PostgreSQL version: 9.5

-- [ Diff summary ]
-- Dropped objects: 38
-- Created objects: 37
-- Changed objects: 11
-- Truncated tables: 0

SET check_function_bodies = false;
-- ddl-end --

SET search_path=public,pg_catalog;
-- ddl-end --


-- [ Dropped objects ] --
ALTER TABLE public.task_permission DROP CONSTRAINT IF EXISTS principal_fk CASCADE;
-- ddl-end --
ALTER TABLE public.task_permission DROP CONSTRAINT IF EXISTS task_fk CASCADE;
-- ddl-end --
ALTER TABLE public.task_permission DROP CONSTRAINT IF EXISTS task_permission_pk CASCADE;
-- ddl-end --
ALTER TABLE public.time_extension DROP CONSTRAINT IF EXISTS contest_fk CASCADE;
-- ddl-end --
ALTER TABLE public.contest_tasks DROP CONSTRAINT IF EXISTS task_fk CASCADE;
-- ddl-end --
ALTER TABLE public.contest_tasks DROP CONSTRAINT IF EXISTS contest_fk CASCADE;
-- ddl-end --
ALTER TABLE public.time_extension DROP CONSTRAINT IF EXISTS "USER_fk" CASCADE;
-- ddl-end --
DROP FUNCTION IF EXISTS public.remove_from_group(bigint,bigint) CASCADE;
-- ddl-end --
DROP FUNCTION IF EXISTS public.add_to_group(bigint,bigint) CASCADE;
-- ddl-end --
DROP FUNCTION IF EXISTS public.insert_new_contest_participations(integer) CASCADE;
-- ddl-end --
DROP FUNCTION IF EXISTS public.purge_gargabe_contest_participations(integer) CASCADE;
-- ddl-end --
DROP FUNCTION IF EXISTS public.get_user_total_score_in_contest(integer,bigint) CASCADE;
-- ddl-end --
DROP FUNCTION IF EXISTS public.check_immutability(text,anyelement,anyelement) CASCADE;
-- ddl-end --
DROP FUNCTION IF EXISTS public.get_participants_group_id_from_contest_id(integer) CASCADE;
-- ddl-end --
DROP RULE IF EXISTS user_keep_principal_delete ON public."USER" CASCADE;
-- ddl-end --
DROP RULE IF EXISTS user_keep_principal_update ON public."USER" CASCADE;
-- ddl-end --
DROP RULE IF EXISTS user_keep_principal_insert ON public."USER" CASCADE;
-- ddl-end --
DROP FUNCTION IF EXISTS public.has_group_permission(bigint,bigint,public.group_permission_type) CASCADE;
-- ddl-end --
DROP FUNCTION IF EXISTS public.get_contests_that_intersect(timestamp with time zone,timestamp with time zone) CASCADE;
-- ddl-end --
DROP TRIGGER IF EXISTS contest_intersection_consistency_check ON public.contest CASCADE;
-- ddl-end --
DROP FUNCTION IF EXISTS public.permission_applies_to_principal(bigint,bigint) CASCADE;
-- ddl-end --
DROP FUNCTION IF EXISTS public.has_task_permission(integer,bigint,public.task_permission_type) CASCADE;
-- ddl-end --
DROP FUNCTION IF EXISTS public.has_contest_permission(integer,bigint,public.contest_permission_type) CASCADE;
-- ddl-end --
DROP FUNCTION IF EXISTS public.has_general_permission(bigint,public.general_permission_type) CASCADE;
-- ddl-end --
DROP TABLE IF EXISTS public.time_extension CASCADE;
-- ddl-end --
DROP SEQUENCE IF EXISTS public.time_extension_id_seq CASCADE;
-- ddl-end --
DROP TABLE IF EXISTS public.property CASCADE;
-- ddl-end --
DROP FUNCTION IF EXISTS public.update_solution(bigint) CASCADE;
-- ddl-end --
DROP FUNCTION IF EXISTS public.update_contest(integer) CASCADE;
-- ddl-end --
DROP FUNCTION IF EXISTS public.get_contest_start_for_user(integer,bigint) CASCADE;
-- ddl-end --
DROP FUNCTION IF EXISTS public.get_contest_start(integer) CASCADE;
-- ddl-end --
DROP FUNCTION IF EXISTS public.get_contest_end_for_user(integer,bigint) CASCADE;
-- ddl-end --
DROP FUNCTION IF EXISTS public.get_contest_end(integer) CASCADE;
-- ddl-end --


-- [ Created objects ] --
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

-- object: time_extension | type: COLUMN --
-- ALTER TABLE public.contest_participation DROP COLUMN IF EXISTS time_extension CASCADE;
ALTER TABLE public.contest_participation ADD COLUMN time_extension bigint NOT NULL DEFAULT 0;
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

-- object: contest_intersection_consistency_check | type: TRIGGER --
-- DROP TRIGGER IF EXISTS contest_intersection_consistency_check ON public.contest CASCADE;
CREATE TRIGGER contest_intersection_consistency_check
	BEFORE INSERT OR UPDATE
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

-- object: user_keep_principal_insert | type: RULE --
-- DROP RULE IF EXISTS user_keep_principal_insert ON public."USER" CASCADE;
CREATE RULE user_keep_principal_insert AS ON INSERT
	TO public."USER"
	DO ALSO (INSERT INTO principal(id) VALUES (NEW.id));
-- ddl-end --

-- object: user_keep_principal_update | type: RULE --
-- DROP RULE IF EXISTS user_keep_principal_update ON public."USER" CASCADE;
CREATE RULE user_keep_principal_update AS ON UPDATE
	TO public."USER"
	DO ALSO (UPDATE principal SET (id) = (NEW.id) WHERE principal.id=OLD.id);
-- ddl-end --

-- object: user_keep_principal_delete | type: RULE --
-- DROP RULE IF EXISTS user_keep_principal_delete ON public."USER" CASCADE;
CREATE RULE user_keep_principal_delete AS ON DELETE
	TO public."USER"
	DO ALSO (DELETE FROM principal WHERE principal.id = OLD.id);
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

-- object: task_permission_pk | type: CONSTRAINT --
-- ALTER TABLE public.task_permission DROP CONSTRAINT IF EXISTS task_permission_pk CASCADE;
ALTER TABLE public.task_permission ADD CONSTRAINT task_permission_pk PRIMARY KEY (permission,task_id,principal_id);
-- ddl-end --

-- object: public.get_contest_start_for_user | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.get_contest_start_for_user(IN integer,IN bigint) CASCADE;
CREATE FUNCTION public.get_contest_start_for_user (IN contest_id_p integer, IN user_id_p bigint)
	RETURNS timestamptz
	LANGUAGE sql
	VOLATILE
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 1
	AS $$
SELECT contest.start_time
     FROM contest
    WHERE contest.id = contest_id_p
$$;
-- ddl-end --
ALTER FUNCTION public.get_contest_start_for_user(IN integer,IN bigint) OWNER TO openolympus;
-- ddl-end --

-- object: public.get_contest_start | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.get_contest_start(IN integer) CASCADE;
CREATE FUNCTION public.get_contest_start (IN contest_id_p integer)
	RETURNS timestamptz
	LANGUAGE sql
	VOLATILE
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 1
	AS $$
SELECT contest.start_time
     FROM contest
    WHERE contest.id = contest_id_p
$$;
-- ddl-end --
ALTER FUNCTION public.get_contest_start(IN integer) OWNER TO openolympus;
-- ddl-end --

-- object: public.get_contest_end | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.get_contest_end(IN integer) CASCADE;
CREATE FUNCTION public.get_contest_end (IN contest_id_p integer)
	RETURNS timestamptz
	LANGUAGE sql
	VOLATILE
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 1
	AS $$
SELECT (  contest.start_time
           + (contest.duration * INTERVAL '1 MILLISECOND')
           + (SELECT (  max (contest_participation.time_extension)
                      * INTERVAL '1 MILLISECOND')
                FROM contest_participation
               WHERE contest_participation.contest_id = contest_id_p))
     FROM contest
    WHERE contest.id = contest_id_p
$$;
-- ddl-end --
ALTER FUNCTION public.get_contest_end(IN integer) OWNER TO openolympus;
-- ddl-end --

-- object: public.get_contest_end_for_user | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.get_contest_end_for_user(IN integer,IN bigint) CASCADE;
CREATE FUNCTION public.get_contest_end_for_user (IN contest_id_p integer, IN user_id_p bigint)
	RETURNS timestamptz
	LANGUAGE sql
	VOLATILE
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 1
	AS $$
SELECT (  contest.start_time
           + (contest.duration * INTERVAL '1 MILLISECOND')
           + (SELECT (  contest_participation.time_extension
                      * INTERVAL '1 MILLISECOND')
                FROM contest_participation
               WHERE     contest_participation.contest_id = contest_id_p
                     AND contest_participation.user_id = user_id_p))
     FROM contest
    WHERE contest.id = contest_id_p
$$;
-- ddl-end --
ALTER FUNCTION public.get_contest_end_for_user(IN integer,IN bigint) OWNER TO openolympus;
-- ddl-end --

-- object: contest_participation_by_user_and_contest | type: INDEX --
-- DROP INDEX IF EXISTS public.contest_participation_by_user_and_contest CASCADE;
CREATE INDEX contest_participation_by_user_and_contest ON public.contest_participation
	USING btree
	(
	  contest_id,
	  user_id
	);
-- ddl-end --

-- object: contest_participation_by_contest_and_score | type: INDEX --
-- DROP INDEX IF EXISTS public.contest_participation_by_contest_and_score CASCADE;
CREATE INDEX contest_participation_by_contest_and_score ON public.contest_participation
	USING btree
	(
	  contest_id,
	  score DESC NULLS LAST
	);
-- ddl-end --

-- object: contest_by_time | type: INDEX --
-- DROP INDEX IF EXISTS public.contest_by_time CASCADE;
CREATE INDEX contest_by_time ON public.contest
	USING btree
	(
	  start_time ASC NULLS LAST
	);
-- ddl-end --

-- object: verdict_by_solution_id | type: INDEX --
-- DROP INDEX IF EXISTS public.verdict_by_solution_id CASCADE;
CREATE INDEX verdict_by_solution_id ON public.verdict
	USING btree
	(
	  solution_id
	);
-- ddl-end --

-- object: solution_by_time_added | type: INDEX --
-- DROP INDEX IF EXISTS public.solution_by_time_added CASCADE;
CREATE INDEX solution_by_time_added ON public.solution
	USING btree
	(
	  time_added DESC NULLS LAST
	);
-- ddl-end --

-- object: solution_by_score | type: INDEX --
-- DROP INDEX IF EXISTS public.solution_by_score CASCADE;
CREATE INDEX solution_by_score ON public.solution
	USING btree
	(
	  score DESC NULLS LAST
	);
-- ddl-end --

-- object: solution_by_user_and_score | type: INDEX --
-- DROP INDEX IF EXISTS public.solution_by_user_and_score CASCADE;
CREATE INDEX solution_by_user_and_score ON public.solution
	USING btree
	(
	  user_id,
	  score
	);
-- ddl-end --

-- object: user_by_username | type: INDEX --
-- DROP INDEX IF EXISTS public.user_by_username CASCADE;
CREATE INDEX user_by_username ON public."USER"
	USING btree
	(
	  username
	);
-- ddl-end --



-- [ Changed objects ] --
ALTER TABLE public.principal ALTER COLUMN permissions SET DEFAULT ARRAY[]::public.general_permission_type[];
-- ddl-end --
-- object: public.raise_contest_intersects_error | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.raise_contest_intersects_error() CASCADE;
CREATE OR REPLACE FUNCTION public.raise_contest_intersects_error ()
	RETURNS trigger
	LANGUAGE plpgsql
	VOLATILE
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 1
	AS $$
DECLARE
   end_time   timestamp WITH TIME ZONE;
BEGIN
   IF TG_OP = 'UPDATE'
   THEN
      end_time =
           NEW.start_time
         + (NEW.duration * INTERVAL '1 MILLISECOND')
         + (SELECT (  max (contest_participation.time_extension)
                    * INTERVAL '1 MILLISECOND')
             WHERE contest_participation.contest_id = NEW.id);
   ELSE
      end_time = NEW.start_time + (NEW.duration * INTERVAL '1 MILLISECOND');
   END IF;

   IF EXISTS
         (SELECT *
            FROM contest
           WHERE         tstzrange (get_contest_start (contest.id),
                                    get_contest_end (contest.id))
                     && tstzrange (NEW.start_time, end_time)
                 AND contest.id != NEW.id)
   THEN
       RAISE EXCEPTION 'contest intersects';
   END IF;

   RETURN NEW;
END;
$$;
-- ddl-end --
ALTER FUNCTION public.raise_contest_intersects_error() OWNER TO openolympus;
-- ddl-end --

-- ddl-end --
ALTER TABLE public.group_users ALTER COLUMN can_add_others_to_group TYPE bool;
-- ddl-end --
ALTER TABLE public.contest_participation ALTER COLUMN id TYPE bigint;
-- ddl-end --
ALTER TABLE public.contest_participation ALTER COLUMN id SET DEFAULT nextval('public.contest_participation_id_seq'::regclass);
-- ddl-end --
ALTER TABLE public.contest_question ALTER COLUMN id TYPE integer;
-- ddl-end --
ALTER TABLE public.contest_question ALTER COLUMN id SET DEFAULT nextval('public.contest_question_id_seq'::regclass);
-- ddl-end --
ALTER TABLE public.solution ALTER COLUMN id TYPE bigint;
-- ddl-end --
ALTER TABLE public.solution ALTER COLUMN id SET DEFAULT nextval('public.solution_id_seq'::regclass);
-- ddl-end --
ALTER TABLE public.contest ALTER COLUMN id TYPE integer;
-- ddl-end --
ALTER TABLE public.contest ALTER COLUMN id SET DEFAULT nextval('public.contest_id_seq'::regclass);
-- ddl-end --
ALTER TABLE public.task ALTER COLUMN id TYPE integer;
-- ddl-end --
ALTER TABLE public.task ALTER COLUMN id SET DEFAULT nextval('public.task_id_seq'::regclass);
-- ddl-end --
ALTER TABLE public.contest_message ALTER COLUMN id TYPE integer;
-- ddl-end --
ALTER TABLE public.contest_message ALTER COLUMN id SET DEFAULT nextval('public.contest_message_id_seq'::regclass);
-- ddl-end --
ALTER TABLE public.verdict ALTER COLUMN id TYPE bigint;
-- ddl-end --
ALTER TABLE public.verdict ALTER COLUMN id SET DEFAULT nextval('public.verdict_id_seq'::regclass);
-- ddl-end --


-- [ Created foreign keys ] --
-- object: task_fk | type: CONSTRAINT --
-- ALTER TABLE public.task_permission DROP CONSTRAINT IF EXISTS task_fk CASCADE;
ALTER TABLE public.task_permission ADD CONSTRAINT task_fk FOREIGN KEY (task_id)
REFERENCES public.task (id) MATCH FULL
ON DELETE CASCADE ON UPDATE CASCADE;
-- ddl-end --

-- object: principal_fk | type: CONSTRAINT --
-- ALTER TABLE public.task_permission DROP CONSTRAINT IF EXISTS principal_fk CASCADE;
ALTER TABLE public.task_permission ADD CONSTRAINT principal_fk FOREIGN KEY (principal_id)
REFERENCES public.principal (id) MATCH FULL
ON DELETE CASCADE ON UPDATE CASCADE;
-- ddl-end --

-- object: contest_fk | type: CONSTRAINT --
-- ALTER TABLE public.contest_tasks DROP CONSTRAINT IF EXISTS contest_fk CASCADE;
ALTER TABLE public.contest_tasks ADD CONSTRAINT contest_fk FOREIGN KEY (contest_id)
REFERENCES public.contest (id) MATCH FULL
ON DELETE CASCADE ON UPDATE CASCADE;
-- ddl-end --

-- object: task_fk | type: CONSTRAINT --
-- ALTER TABLE public.contest_tasks DROP CONSTRAINT IF EXISTS task_fk CASCADE;
ALTER TABLE public.contest_tasks ADD CONSTRAINT task_fk FOREIGN KEY (task_id)
REFERENCES public.task (id) MATCH FULL
ON DELETE CASCADE ON UPDATE CASCADE;
-- ddl-end --
