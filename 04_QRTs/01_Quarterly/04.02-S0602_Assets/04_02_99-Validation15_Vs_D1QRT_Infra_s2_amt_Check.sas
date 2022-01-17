proc sql;

create table temp_infra15 as

select 
c0300 , sum(X_SOLVENCY_II_VALUE)as sol2_amt_VALD_15 FORMAT=COMMA21.2
from 
work.s0801_d1_vald15_infra
group by c0300
order by c0300;

create table temp_infrad1 as

select 
c0300 , sum(C0170)as sol2_amt_D1 FORMAT=COMMA21.2
from 
work.S0602_D1_IMT
where c0300 <> '1 - Not an infrastructure investment'
group by c0300
order by c0300;



create table INFRA_S2AMT_CHECK as

select 
A.c0300, 
sol2_amt_VALD_15,
sol2_amt_D1,
sol2_amt_VALD_15-sol2_amt_D1 AS DIFF  FORMAT=COMMA21.2

from 
work.temp_infra15 A, 
WORK.temp_infrad1 B

 WHERE A.C0300 = B.C0300

order by c0300;

quit; 


TITLE BOLD UNDERLIN=2 "Check Infra amount - Validation15 VS D1 QRT";
proc print data=INFRA_S2AMT_CHECK;
run;
