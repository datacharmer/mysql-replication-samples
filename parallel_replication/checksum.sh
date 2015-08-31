#!/bin/bash

for NODE in m s1 s2
do
    rm -f $NODE.txt
    for D in $(./$NODE -BN -e 'show schemas like "db%"') test
    do
        for T in $(./$NODE -BN -e "show tables from $D" ) 
        do
            ./$NODE -BN -e "checksum table $T" $D >> $NODE.txt
        done
    done
done

for SLAVE in s1 s2
do
    echo -n "Checksum between m and $SLAVE: "
    diff -q m.txt $SLAVE.txt > /dev/null 2>&1
    if [ "$?" == "0" ]
    then
        echo "OK"
    else
        echo "FAILED"
    fi
done
