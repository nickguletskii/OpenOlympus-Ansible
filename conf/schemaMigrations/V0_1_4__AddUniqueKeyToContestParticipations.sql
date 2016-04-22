ALTER TABLE public.contest_participation ADD CONSTRAINT contest_participation_unique UNIQUE (user_id,contest_id);
CREATE OR REPLACE FUNCTION insert_new_contest_participations(IN contest_id_p integer)
RETURNS void AS

$BODY$

BEGIN
   INSERT INTO contest_participation (score, user_id, contest_id)
      (SELECT get_user_total_score_in_contest (contest_id_p, u.id),
             u.id,
             contest_id_p
        FROM "USER" u
       WHERE has_contest_permission (contest_id_p, u.id, 'participate'))
	   ON CONFLICT DO NOTHING;
END;

$BODY$

LANGUAGE plpgsql VOLATILE
COST 1
