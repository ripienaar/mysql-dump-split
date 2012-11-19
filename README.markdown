What is it?
===========

A simple script that splits a MySQL dump into lots of smaller files.
It works both with data definitions and data only dumps.

Usage:
------

First you need a mysqldump file, put it into the directory you want
all the split files in:

<pre>
$ ruby split-mysql-dump.rb db.sql
Found a new db: app
Found a new table: administrator_log
    writing line: 229 200.494MB in 4 seconds 50.124MB/sec

    Found a new table: auth_strings
        writing line: 239 205.482MB in 6 seconds 34.247MB/sec
</pre>

Alternatively, you can pipe in via STDIN in using '-s'. Great
for working with large gzipped backups:

<pre>
$ gunzip -c db.sql.gz | ruby split-mysql-dump.rb -s
</pre>

You can also limit the dump to particular tables using '-t' 
or exclude tables using '-i'. 

<pre>
$ ruby split-mysql-dump.rb -t auth_strings, administrator_log db.sql
</pre>

and

<pre>
$ ruby split-mysql-dump.rb -i auth_strings
</pre>

When you're done you should have lots of files like this:

<pre>
-rw-r--r-- 1 rip rip   210233252 May 17 18:06 administrator_log.sql
-rw-r--r-- 1 rip rip   215463582 May 17 18:06 auth_strings.sql
</pre>

The first bit of the files will be the database that the tables are in
based on the _USE_ statements in the dump.

Contact:
--------
You can contact me on rip@devco.net or follow my blog at http://www.devco.net I am also on twitter as ripienaar

