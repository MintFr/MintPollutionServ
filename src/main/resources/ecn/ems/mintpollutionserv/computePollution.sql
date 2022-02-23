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
create table wayspolluted2 as select w.*, avg(no2) from public.ways w join public.pointwithid p on w.gid=p.gid Group by w.gid;