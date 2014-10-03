What is it?
===========

A simple script that splits a MySQL dump into lots of smaller files.
It works both with data definitions and data only dumps.

Install:

```shell
gem install mysq-dump-split
```

Usage:
------

First you need a mysqldump file, put it into the directory you want
all the split files in:

```shell
$ ruby split-mysql-dump.rb db.sql
Found a new db: app
Found a new table: administrator_log
    writing line: 229 200.494MB in 4 seconds 50.124MB/sec

    Found a new table: auth_strings
        writing line: 239 205.482MB in 6 seconds 34.247MB/sec
```

Alternatively, you can pipe in via STDIN in using '-s'. Great
for working with large gzipped backups:

```shell
$ gunzip -c db.sql.gz | ruby split-mysql-dump.rb -s
```

You can also limit the dump to particular tables using '-t'
or exclude tables using '-i'.

```shell
$ ruby split-mysql-dump.rb -t auth_strings, administrator_log db.sql
```

and

```shell
$ ruby split-mysql-dump.rb -i auth_strings
```

When you're done you should have lots of files like this:

```
-rw-r--r-- 1 rip rip   210233252 May 17 18:06 administrator_log.sql
-rw-r--r-- 1 rip rip   215463582 May 17 18:06 auth_strings.sql
```

The first bit of the files will be the database that the tables are in
based on the _USE_ statements in the dump.

Contact:
--------
You can contact me on rip@devco.net or follow my blog at http://www.devco.net I am also on twitter as ripienaar

