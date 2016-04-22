SET check_function_bodies = false;
SET search_path=public,pg_catalog;

-- object: public.get_contest_end | type: FUNCTION --
-- DROP FUNCTION IF EXISTS public.get_contest_end(IN integer) CASCADE;
CREATE OR REPLACE FUNCTION public.get_contest_end (IN contest_id_p integer)
	RETURNS timestamptz
	LANGUAGE sql
	VOLATILE
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 1
	AS $$
SELECT (  contest.start_time
        + (contest.duration * INTERVAL '1 MILLISECOND')
        + (SELECT (  coalesce (max (contest_participation.time_extension), 0)
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
CREATE OR REPLACE FUNCTION public.get_contest_end_for_user (IN contest_id_p integer, IN user_id_p bigint)
	RETURNS timestamptz
	LANGUAGE sql
	VOLATILE
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 1
	AS $$
SELECT (  contest.start_time
        + (contest.duration * INTERVAL '1 MILLISECOND')
        + (SELECT (  coalesce (contest_participation.time_extension, 0)
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
         + (SELECT (  coalesce (max (contest_participation.time_extension),
                                0)
                    * INTERVAL '1 MILLISECOND')
              FROM contest_participation
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
