create schema if not exists test ;
use test ;
drop table if exists t1;
create table t1 (i int not null primary key, msg varchar(50), d date, t time, dt datetime, ts timestamp);
insert into t1 values (1, 'test1', '2014-01-11', '11:23:41','2014-01-11 12:34:51', null);
