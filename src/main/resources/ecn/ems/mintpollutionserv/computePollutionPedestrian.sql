/* 
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
/**
 * Author:  Lucas Deswarte
 * Created: 21 févr. 2022
 */

-- Supressing existing table of existing points, buffer ways and final table to be used to recreate them properly
  DROP TABLE IF EXISTS public.buffer_ways;
  DROP TABLE IF EXISTS public.pointwithid;
  DROP TABLE IF EXISTS public.wayspolluted2;

--Create a buffer for the ways to see which point to conserve
create table buffer_ways as SELECT ST_BUFFER(the_geom, 0.00005) AS the_geom, gid FROM public.ways;

--Create a table of the relevant points to compute the pollution on each ways 
create table pointwithid as select distinct p.* , b.gid from public.pollution p, public.buffer_ways b where st_contains(b.the_geom,p.the_geom);

--Create a table with computed pollution on each ways (here the average of each points)
--If more polluant need to add them here in the avg
create table wayspolluted2 as select w.*, avg(no2) as conc_no2,avg(nox) as conc_nox,avg(pm10) as conc_pm10,avg(pm2p5) as conc_pm2p5 from public.ways w join public.pointwithid p on w.gid=p.gid Group by w.gid;

--Update the table to calculate index, assigning a value depending on the concentration for each polluant, see how the indexes are calculated in other document 

ALTER TABLE public.wayspolluted2
 ADD COLUMN value_no2 int;
ALTER TABLE public.wayspolluted2
 ADD COLUMN value_pm10 int;
ALTER TABLE public.wayspolluted2
 ADD COLUMN value_pm2p5 int;
ALTER TABLE public.wayspolluted2
 ADD COLUMN index double precision;


UPDATE public.wayspolluted2
SET value_no2 =
           (CASE
            WHEN       conc_no2 <= 29  THEN 1
            WHEN 29  < conc_no2 and conc_no2 <= 54  THEN 2
            WHEN 54  < conc_no2 and conc_no2<= 84  THEN 3
            WHEN 84  < conc_no2 and conc_no2<= 109 THEN 4
            WHEN 109 < conc_no2 and conc_no2<= 134 THEN 5
            WHEN 134 < conc_no2 and conc_no2<= 164 THEN 6
            WHEN 164 < conc_no2 and conc_no2<= 199 THEN 7
            WHEN 199 < conc_no2 and conc_no2<= 274 THEN 8
            WHEN 274 < conc_no2 and conc_no2<= 399 THEN 9
            WHEN 399 < conc_no2        THEN 10
            ELSE conc_no2
            END);
UPDATE public.wayspolluted2
   SET value_pm10 =
           (CASE
            WHEN       conc_pm10 <= 6   THEN 1
            WHEN 6   < conc_pm10 and conc_pm10<= 13  THEN 2
            WHEN 13  < conc_pm10 and conc_pm10<= 20  THEN 3
            WHEN 20  < conc_pm10 and conc_pm10<= 27  THEN 4
            WHEN 27  < conc_pm10 and conc_pm10<= 34  THEN 5
            WHEN 34  < conc_pm10 and conc_pm10<= 41  THEN 6
            WHEN 41  < conc_pm10 and conc_pm10<= 49  THEN 7
            WHEN 49  < conc_pm10 and conc_pm10<= 64  THEN 8
            WHEN 64  < conc_pm10 and conc_pm10<= 79  THEN 9
            WHEN 79  < conc_pm10        THEN 10
            ELSE conc_pm10
            END);
UPDATE public.wayspolluted2

   SET value_pm2p5 =
            (CASE
             WHEN       conc_pm2p5 <= 3   THEN 1
             WHEN 3   < conc_pm2p5 and conc_pm2p5<= 7   THEN 2
             WHEN 7   < conc_pm2p5 and conc_pm2p5<= 11  THEN 3
             WHEN 11  < conc_pm2p5 and conc_pm2p5<= 15  THEN 4
             WHEN 15  < conc_pm2p5 and conc_pm2p5<= 19  THEN 5
             WHEN 19  < conc_pm2p5 and conc_pm2p5<= 23  THEN 6
             WHEN 23  < conc_pm2p5 and conc_pm2p5<= 27  THEN 7
             WHEN 27  < conc_pm2p5 and conc_pm2p5<= 31  THEN 8
             WHEN 31  < conc_pm2p5 and conc_pm2p5<= 35  THEN 9
             WHEN 35  < conc_pm2p5        THEN 10
             ELSE conc_pm10
             END);
UPDATE public.wayspolluted2
    SET index = (value_no2+value_pm10+value_pm2p5) * 3.6*length_m/6;
            