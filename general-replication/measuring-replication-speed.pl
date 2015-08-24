#!/usr/bin/perl 
# Simple script to measure MySQL replication speed 
# http://datacharmer.blogspot.com/2006/04/measuring-replication-speed.html
use strict;
use warnings;
use Data::Dumper;
use DBI;
use Time::HiRes qw/ usleep gettimeofday tv_interval/;
use English qw( -no_match_vars ); 

my $username1 = 'user1';
my $password1 = 'user2';
my $username2 = 'pass1';
my $password2 = 'pass2';
my $host1     = 'host_IP1';
my $host2     = 'host_IP2';
my $port1     = '3306';
my $port2     = '3306';

my $dbh1=DBI->connect("dbi:mysql:test;host=$host1;port=$port1",
                $username1, $password1,
                {RaiseError => 1}) 
         or die "Can't connect: $DBI::errstr\n"; 

my $dbh2=DBI->connect("dbi:mysql:test;host=$host2;port=$port2",
                $username2, $password2,
                {RaiseError => 1}) 
         or die "Can't connect: $DBI::errstr\n"; 

my $loops                =     10; # how many times we loop (with size increase)
my $num_of_inserts       =      5; # how many records we insert for each loop
my $initial_blob_size    =  1_000; # how big is the record we start with
my $replica_db           = 'test'; # which database we use for testing

my $master_dbh = $dbh1;
my $slave_dbh = $dbh2;

my ( $exists_db ) = $master_dbh->selectrow_array(qq{SHOW DATABASES LIKE '$replica_db'});
unless ($exists_db) {
    eval {$master_dbh->do(qq{CREATE DATABASE $replica_db}) };
    if ( $EVAL_ERROR ) {
        die "execution error $DBI::errstr\n";
    }
} 

# 
# creating the measurement table
#
eval {
    $master_dbh->do( qq{
        CREATE DATABASE IF NOT EXISTS $replica_db});
    $master_dbh->do( qq{ 
        USE $replica_db } );
    $master_dbh->do( qq{ 
        DROP TABLE IF EXISTS replica_speed });
    $master_dbh->do( qq{
       CREATE TABLE replica_speed (
        id int(11) NOT NULL auto_increment,
        insert_sequence int not null,
        seconds bigint(20) default NULL,
        microseconds bigint(20) default NULL,
        ts timestamp(14) NOT NULL,
        big_one longtext,
        PRIMARY KEY  (`id`),
        KEY insert_sequence (insert_sequence)
       ) 
    } );
};
if ($EVAL_ERROR) {
    die "table creation error $DBI::errstr\n";
}

# 
# give some time to the table creation to get replicated
# 
usleep(200_000); 
my $insert_query = qq{ 
    INSERT INTO $replica_db.replica_speed 
        (insert_sequence, seconds, microseconds, big_one) 
       VALUES ( ?, ?, ?, ?) }; 
my $retrieve_query = qq{
    SELECT seconds, microseconds, id, insert_sequence
    FROM $replica_db.replica_speed 
    WHERE insert_sequence = ?
};
my $slave_sth = $slave_dbh->prepare($retrieve_query);

# 
# checking max_allowed_packet to make sure that we are not
# exceeding the limits
#
my ( undef, $master_max_allowed_packet) = $master_dbh->selectrow_array(
        qq{ SHOW VARIABLES LIKE "max_allowed_packet" } );

my ( undef, $slave_max_allowed_packet) = $slave_dbh->selectrow_array(
        qq{ SHOW VARIABLES LIKE "max_allowed_packet" } );

my $max_allowed_packet = $master_max_allowed_packet;
if ( $slave_max_allowed_packet < $master_max_allowed_packet) {
    $max_allowed_packet = $slave_max_allowed_packet;
}
my @results     = ();

LOOP:
for my $loopcount (0 .. $loops )
{
    usleep(200_000);
    
    # 
    # let's start with an empty table 
    # 
    $master_dbh->do( qq{ TRUNCATE $replica_db.replica_speed } );
    
    my $size   = $initial_blob_size * ($loopcount || 1);
    if ($size > $max_allowed_packet) {
        $size  = $max_allowed_packet - 1000;
    }
    my $master_insert_time  = 0.0;
    my $big_blob            = 'a' x $size;

    #
    # inserting several records in the master
    # 
    for my $sequence (1 .. $num_of_inserts ) { 
        my ( $secs, $msecs ) = gettimeofday();
        $master_dbh->do($insert_query, undef, $sequence, $secs, $msecs, $big_blob);
        $master_insert_time = tv_interval( [$secs, $msecs],  [gettimeofday()]);
    }
    my $replication_delay     = 0;
    my $total_retrieval_time  = 0;
    my $baredelay             = undef;
    
    # 
    # fetching data from the slave 
    # 
    RETRIEVAL:
    while ( ! $replication_delay ) # waiting for data to arrive from master to slave
    {
        my $retrieval_start_time = [gettimeofday()];
        $slave_sth->execute( $num_of_inserts);
        my $info                = $slave_sth->fetchrow_arrayref();
        my $retrieval_stop_time = [gettimeofday()];
        my $retrieval_time      = 0.0;
        $retrieval_time         = tv_interval( 
                $retrieval_start_time, 
                $retrieval_stop_time);
        next RETRIEVAL unless $info->[0];
        
        # 
        # retrieval time is counted only after a successful fetch
        # 
        $total_retrieval_time   += $retrieval_time;
        $replication_delay      = tv_interval( [$info->[0], $info->[1]], $retrieval_stop_time); 
        $baredelay              = $replication_delay - $total_retrieval_time - $master_insert_time;
        printf "%4d %5d %5d %12d %12d %12d %12d\n", 
            $loopcount, $info->[2], $info->[3] , $info->[0] , $info->[1] , 
            $retrieval_stop_time->[0], $retrieval_stop_time->[1];
    }

    push @results,
        {
            data_size             => $size,
            master_insert_time    => $master_insert_time,
            slave_retrieval_time  => $total_retrieval_time,
            replication_time      => $replication_delay,
            bare_replication_time => $baredelay,
        }
}

# 
# displaying results
# 
my @header_sizes = qw(4 9 13 15 16 9);
my @headers = ('loop', 'data size', 'master insert', 'slave retrieval', 'total repl. time', 'bare time');
printf "%s %s %s %s %s %s\n" , @headers;
printf "%s %s %s %s %s %s\n" , map { '-' x $_ } @header_sizes;
my $count = 0;
for my $res (@results) 
{
    printf "%4d %9d %13.6f %15.6f %16.6f %9.6f\n" , ++$count, 
        map { $res->{$_} } 
            qw/data_size master_insert_time slave_retrieval_time replication_time bare_replication_time/;
}
