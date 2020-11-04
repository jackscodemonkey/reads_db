#!/bin/bash

RUNFILE=firstrun

/usr/sbin/sshd -D & 

clean_shutdown(){
	su -l gpadmin -c 'gpstop -M fast -a'
}

trap clean_shutdown SIGTERM;

if [ -f $RUNFILE ]; then
	echo "Greenplum previously initialized in this container. Starting Greenplum."
	su - gpadmin -c 'gpstart -a'
else
	echo "The is the containers first run. Initializing Greenplum."
	su -l gpadmin -c 'ssh localhost "gpinitsystem -c /home/gpadmin/gp_init_config -a"'
	su -l gpadmin -c 'psql -c "create database gpadmin;" postgres'
	su -l gpadmin -c $'psql -c "alter user gpadmin password \'changeme\'" postgres'
	su -l gpadmin -c $'psql -c "create role app login createdb; alter role app password \'app123\'" postgres'
	echo "host all all 0.0.0.0/0 md5" >> /data/master/gpseg-1/pg_hba.conf
	su -l gpadmin -c 'gpstop -u'  
    touch $RUNFILE	
fi

tail -f /dev/null