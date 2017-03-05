set GLOBAL group_replication_bootstrap_group=(select if(@@hostname='node1', 'ON', 'OFF'));
START GROUP_REPLICATION;
SET GLOBAL group_replication_bootstrap_group=OFF;
use performance_schema ;
select sleep(2);
select * from replication_group_members;

