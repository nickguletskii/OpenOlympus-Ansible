CREATE OR REPLACE FUNCTION update_solution (IN solution_id_p bigint)
   RETURNS void
AS
$BODY$

DECLARE
   user_id_v   bigint;
   task_id_v   integer;
BEGIN
   SELECT user_id, task_id_v
     FROM solution s
    WHERE s.id = solution_id_p
     INTO user_id_v, task_id_v;

   UPDATE solution
      SET score = scrs.scr, maximum_score = scrs.mscr
     FROM (SELECT coalesce (sum (v.score), 0) AS scr,
                  coalesce (sum (v.maximum_score), 0) AS mscr
             FROM verdict v
            WHERE v.solution_id = solution_id_p) AS scrs
    WHERE solution.id = solution_id_p;

   UPDATE contest_participation cp
      SET score =
             (SELECT get_user_total_score_in_contest (cp.contest_id,
                                                      cp.user_id))
    WHERE     cp.user_id = user_id_v
          AND cp.contest_id IN (SELECT ct.contest_id
                                  FROM contest_tasks ct
                                 WHERE ct.task_id = task_id_v);
END;
$BODY$
   LANGUAGE plpgsql
   VOLATILE
   COST 100
