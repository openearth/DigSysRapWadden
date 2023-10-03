create table zoetwaterafvoeren.hunzeenaas_daggemiddelden as
select extract(day from to_timestamp(datumtijd,'YYY-MM-DD HH24:MI:SSTZH')::timestamptz) 
    || '-' || extract(month from to_timestamp(datumtijd,'YYY-MM-DD HH24:MI:SSTZH')::timestamptz) 
    || '-' || extract(year from to_timestamp(datumtijd,'YYY-MM-DD HH24:MI:SSTZH')::timestamptz) as datum,
avg(numeriekewaarde),
"locatie.naam",
"locatie.origineel",
"eenheid.code"
geom 
from zoetwaterafvoeren.hunzeenaas
group by datum,"locatie.naam","locatie.origineel","eenheid.code", geom
order by datum,"locatie.naam","locatie.origineel","eenheid.code", geom