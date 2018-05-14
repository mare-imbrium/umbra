#!/usr/bin/env bash 

sqlite3 tennis.sqlite <<!
.mode csv
.import atp_matches_2018.csv matches 
!

sqlite3 tennis.sqlite <<!
DELETE from matches WHERE tourney_id = 'tourney_id';
!
sqlite3 tennis.sqlite <<!
select count(1) from matches;
!
