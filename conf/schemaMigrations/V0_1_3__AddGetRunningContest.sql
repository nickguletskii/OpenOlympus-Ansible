-- object: public.get_running_contest | type: FUNCTION --
DROP FUNCTION IF EXISTS public.get_running_contest() CASCADE;
CREATE FUNCTION public.get_running_contest ()
	RETURNS SETOF public.contest
	LANGUAGE sql
	VOLATILE
	CALLED ON NULL INPUT
	SECURITY INVOKER
	COST 1
	ROWS 1
	AS $$
SELECT *
FROM contest
WHERE current_timestamp <@ tstzrange(get_contest_start(contest.id), get_contest_end(contest.id))
$$;
-- ddl-end --
ALTER FUNCTION public.get_running_contest() OWNER TO openolympus;
-- ddl-end --
