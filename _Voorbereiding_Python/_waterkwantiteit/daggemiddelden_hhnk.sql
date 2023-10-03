create table zoetwaterafvoeren.hhnk_daggemiddelde as
select extract(day from to_timestamp(datum,'DD-MM-YYYY HH24-MI')) 
    || '-' || extract(month from to_timestamp(datum,'DD-MM-YYYY HH24-MI')) 
    || '-' || extract(year from to_timestamp(datum,'DD-MM-YYYY HH24-MI')) as datum,
avg(numeriekewaarde) as daggemiddelde, 
"locatie.naam",
"locatie.origineel",
geom 
from zoetwaterafvoeren.hhnk 
where "kwaliteitsoordeel.code" = 'betrouwbaar'
group by datum, "locatie.naam", "locatie.origineel",geom
order by datum, "locatie.naam", "locatie.origineel", geom
