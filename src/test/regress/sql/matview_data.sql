-- disable ORCA
SET optimizer TO off;
create schema matview_data_schema;
set search_path to matview_data_schema;

create table t1(a int, b int);
create table t2(a int, b int);
insert into t1 select i, i+1 from generate_series(1, 5) i;
insert into t1 select i, i+1 from generate_series(1, 3) i;
create materialized view mv0 as select * from t1;
create materialized view mv1 as select a, count(*), sum(b) from t1 group by a;
create materialized view mv2 as select * from t2;
-- all mv are up to date
select mvname, datastatus from gp_matview_aux where mvname in ('mv0','mv1', 'mv2');

-- truncate in self transaction
begin;
create table t3(a int, b int);
create materialized view mv3 as select * from t3;
select datastatus from gp_matview_aux where mvname = 'mv3';
truncate t3;
select datastatus from gp_matview_aux where mvname = 'mv3';
end;

-- trcuncate
refresh materialized view mv3;
select datastatus from gp_matview_aux where mvname = 'mv3';
truncate t3;
select datastatus from gp_matview_aux where mvname = 'mv3';

-- insert and refresh
select datastatus from gp_matview_aux where mvname = 'mv0';
select datastatus from gp_matview_aux where mvname = 'mv1';
insert into t1 values (1, 2); 
select datastatus from gp_matview_aux where mvname = 'mv0';
select datastatus from gp_matview_aux where mvname = 'mv1';

-- insert but no rows changes
refresh materialized view mv0;
refresh materialized view mv1;
select datastatus from gp_matview_aux where mvname = 'mv0';
select datastatus from gp_matview_aux where mvname = 'mv1';
insert into t1 select * from t3; 
select datastatus from gp_matview_aux where mvname = 'mv0';
select datastatus from gp_matview_aux where mvname = 'mv1';

-- update
refresh materialized view mv0;
refresh materialized view mv1;
select datastatus from gp_matview_aux where mvname = 'mv0';
select datastatus from gp_matview_aux where mvname = 'mv1';
update t1 set a = 10 where a = 1;
select datastatus from gp_matview_aux where mvname = 'mv0';
select datastatus from gp_matview_aux where mvname = 'mv1';

-- delete
refresh materialized view mv0;
refresh materialized view mv1;
select datastatus from gp_matview_aux where mvname = 'mv0';
select datastatus from gp_matview_aux where mvname = 'mv1';
delete from t1 where a = 10;
select datastatus from gp_matview_aux where mvname = 'mv0';
select datastatus from gp_matview_aux where mvname = 'mv1';

-- vacuum
refresh materialized view mv0;
refresh materialized view mv1;
select datastatus from gp_matview_aux where mvname = 'mv0';
select datastatus from gp_matview_aux where mvname = 'mv1';
vacuum t1;
select datastatus from gp_matview_aux where mvname = 'mv0';
select datastatus from gp_matview_aux where mvname = 'mv1';
vacuum full t1;
select datastatus from gp_matview_aux where mvname = 'mv0';
select datastatus from gp_matview_aux where mvname = 'mv1';
-- insert after vacuum full 
insert into t1 values(1, 2);
select datastatus from gp_matview_aux where mvname = 'mv0';
select datastatus from gp_matview_aux where mvname = 'mv1';
-- vacuum full after insert
refresh materialized view mv0;
refresh materialized view mv1;
select datastatus from gp_matview_aux where mvname = 'mv0';
select datastatus from gp_matview_aux where mvname = 'mv1';
insert into t1 values(1, 2);
select datastatus from gp_matview_aux where mvname = 'mv0';
select datastatus from gp_matview_aux where mvname = 'mv1';
vacuum full t1;
select datastatus from gp_matview_aux where mvname = 'mv0';
select datastatus from gp_matview_aux where mvname = 'mv1';

-- Refresh With No Data
refresh materialized view mv2;
select datastatus from gp_matview_aux where mvname = 'mv2';
refresh materialized view mv2 with no data;
select datastatus from gp_matview_aux where mvname = 'mv2';

-- Copy
refresh materialized view mv2;
select datastatus from gp_matview_aux where mvname = 'mv2';
-- 0 rows
COPY t2 from stdin;
\.
select datastatus from gp_matview_aux where mvname = 'mv2';

COPY t2 from stdin;
1	1
\.
select datastatus from gp_matview_aux where mvname = 'mv2';

--
-- test issue https://github.com/cloudberrydb/cloudberrydb/issues/582
-- test inherits
--
begin;
create table tp_issue_582(i int, j int);
create table tc_issue_582(i int) inherits (tp_issue_582);
insert into tp_issue_582 values(1, 1), (2, 2);
insert into tc_issue_582 values(1, 1);
create materialized view mv_tp_issue_582 as select * from tp_issue_582;
-- should be null.
select mvname, datastatus from gp_matview_aux where mvname = 'mv_tp_issue_582';
abort;

-- test drop table
select mvname, datastatus from gp_matview_aux where mvname in ('mv0','mv1', 'mv2', 'mv3');
drop materialized view mv2;
drop table t1 cascade;
select mvname, datastatus from gp_matview_aux where mvname in ('mv0','mv1', 'mv2', 'mv3');

--
-- test issue https://github.com/cloudberrydb/cloudberrydb/issues/582
-- test rules
begin;
create table t1_issue_582(i int, j int);
create table t2_issue_582(i int, j int);
create table t3_issue_582(i int, j int);
create materialized view mv_t2_issue_582 as select j from t2_issue_582 where i = 1;
create rule r1 as on insert TO t1_issue_582 do also insert into t2_issue_582 values(1,1);
select count(*) from t1_issue_582;
select count(*) from t2_issue_582;
select mvname, datastatus from gp_matview_aux where mvname = 'mv_t2_issue_582';
insert into t1_issue_582 values(1,1);
select count(*) from t1_issue_582;
select count(*) from t2_issue_582;
select mvname, datastatus from gp_matview_aux where mvname = 'mv_t2_issue_582';
abort;

--
-- test issue https://github.com/cloudberrydb/cloudberrydb/issues/582
-- test writable CTE
--
begin;
create table t_cte_issue_582(i int, j int);
create materialized view mv_t_cte_issue_582 as select j from t_cte_issue_582 where i = 1;
select mvname, datastatus from gp_matview_aux where mvname = 'mv_t_cte_issue_582';
with mod1 as (insert into t_cte_issue_582 values(1, 1) returning *) select * from mod1;
select mvname, datastatus from gp_matview_aux where mvname = 'mv_t_cte_issue_582';
abort;

drop schema matview_data_schema cascade;
reset enable_answer_query_using_materialized_views;
reset optimizer;