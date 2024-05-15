$title Your Model

*Initializing data

Sets
   i     Units  /AgiDim, Komotini, Kremastra, Sfikia, Stratos/
   j(i)  HydroUnits /Kremastra, Sfikia, Stratos/
   id    Unit Characteristics /Pmax, Pmin, Emax, Emin, b, NLC, SUC, SDC, RU, RD, UT, DT, Pini, Tini, u_ini/
   t     Time steps /0*24/
   
 ;
 
Alias (t,it);

Table    UntDat(i,id)  Unit Data

                        Pmax    Pmin    Emax    Emin    b     NLC       SUC       SDC     RU       RD     UT       DT      Pini      Tini        u_ini                      
    AgiDim              280     160                     34    2500      15000     1200    170      170    12       6       0         -10         0
    Komotini            420     180                     45    1600      3700      300     360      360    4        3       400        4          1
    Kremastra           300     0       1700    100     0     0         0         0       300      300    1        1       150       10          1
    Sfikia              250     0       1250    800     0     0         0         0       250      250    1        1       0         -10         0
    Stratos             250     0       1450    700     0     0         0         0       250      250    1        1       0         -15         0
;

Display UntDat ;

Parameters

         C(t)   Price  /

         0          0
         1        37.9
         2        37.1
         3        35.9
         4        34.9
         5        32.3
         6        31.5
         7        27.8
         8        47.8
         9        64.4
         10       69.7
         11       71.9
         12       75.7
         13        81
         14       87.9
         15       85.2
         16       68.2
         17       63.7
         18       52.4
         19       48.9
         20       62.6
         21       78.5
         22       81.9
         23       70.5
         24       70

  /
;

Display C ;

Scalar

   Tmax       'number of hours of the planning period' /24/
;


*Initializing parameters

Parameters
    
    Pmax(i)      'Maximum power output of unit "i" in MW'
    Pmin(i)      'Minimum power output of unit "i" in MW'
    Emin(i)      'Minimum energy production of hydroelectric unit "i" in MWh'
    Emax(i)      'Maximum energy production of hydroelectric unit "i" in MWh'
    b(i)         'Differential operating cost of unit "i" in Euro per MWh '
    NLC(i)       'Constant operating cost of unit "i" in Euro per hour'
    SDC(i)       'Holding cost of unit "i" in Euro'
    SUC(i)       'start-up cost of unit "i" in Euro'
    UT(i)        'Minimum up time of unit "i" in h'
    DT(i)        'Minimum down time of unit "i" in h'
    RU(i)        'Maximum growth of power output of unit "i" in MW per hour '
    RD(i)        'Maximum reduction pace of power output of unit "i" in MW per hour'
    Pini(i)      'Power output of unit "i" at hour "t=0" in MW'
    Tini(i)      'Number of hours that unit "i" is committed/decommitted at hour "t=0"'
    u_ini(i)     'State of unit "i" (committed/decommitted) at hour "t=0"'
   
;

    Pmax(i) = UntDat(i,"Pmax")  ;
    Pmin(i) = UntDat(i,"Pmin")  ;
    Emin(j) = UntDat(j,"Emin") ;
    Emax(j) = UntDat(j,"Emax") ;
    b(i) = UntDat(i,"b") ;
    NLC(i)= UntDat(i,"NLC");
    SDC(i) = UntDat(i,"SDC") ;
    SUC(i) = UntDat(i,"SUC") ;
    UT(i) = UntDat(i,"UT") ;
    DT(i) = UntDat(i,"DT") ;
    RU(i) = UntDat(i,"RU") ;
    RD(i) = UntDat(i,"RD") ;
    Pini(i) = UntDat(i,"Pini") ;
    Tini(i) = UntDat(i,'Tini') ;
    u_ini(i) = UntDat(i,'u_ini');
    

Display u_ini ;
Display Tmax ;

*Initializing Variables
 
Variables

     p(i,t)       Power Output of unit i at hour t in MW
     u(i,t)       binary variable equal to 1 if unit i is committed at hour t
     y(i,t)       binary variable equal to 1 if unit i is started-up at hour t
     z(i,t)       binary variable equal to 1 if unit i is shut-down at hour t
     Total_Profit Total profit of in EUR
     
     
Positive Variables   p ;
Binary Variables     u, y, z   ;

*Initial Conditions

p.fx(i, '0') = Pini(i)    ;
u.fx(i, '0') = u_ini(i)   ;
y.fx(i, '0') $ (Tini(i)= 1) = 1   ;
z.fx(i, '0') $ (Tini(i)= -1)= 1   ;

Parameters  L(i), F(i);

L(i) = min(Tmax,(UT(i)-Tini(i))*u_ini(i));
F(i) = min(Tmax,(DT(i)+Tini(i))*(1-u_ini(i)));

u.fx(i,t)$(ord(t) > 0 and ord(t) < L(i) and L(i) > 0 and Tini(i) > 0) = 1;
u.fx(i,t)$(ord(t) > 0 and ord(t) < F(i) and F(i) > 0 and Tini(i) < 0) = 0;

*Initializing the equations for the constraints that need to be followed and for the Profit function.

Equations

*Minimum operating time for Unit i
MinimumUpTime

*Minimum time that Unit i does not operate
MinimumDownTime

*Moving Unit i from offline mode to online mode and vice versa
OnlineOffline


*Unit i can not be in a starting nor in a desynchronization position at the same time
StartUpShutDownConstraints

*Every hour t that unit i is operating, output power greater or equal than Pmin
PminConstraint

*The constraint PmaxConstraint specifies that if unit 'i' is within operation at time 't':
*1. If it is not going to desynchronize at time 't+1' (0), the output power at time 't' will be less than or equal to the maximum output power Pimax.
*2. If it is going to desynchronize at time 't+1', the output power at time 't' is 'required' to be less than or equal to the corresponding limit RDi.
PmaxConstraint

*Increase of output power from (t-1) to t time is constrained by RU
COM_LOG1

*Reduction of output power from (t-1) to t time is constrained by RD
COM_LOG2

*HydroElectric power of unit j should be between Emin and Emax
HydroMin
HydroMax

Profit


;

MinimumUpTime(i,t)$(ord(t)>0).. sum((it)$(ord(it) >= ord(t) - UT(i) + 1 and ord(it) <= ord(t)), y(i, it)) =l= u(i, t);

MinimumDownTime(i,t)$(ord(t)>0).. Sum((it)$(ord(it) >= ord(t) - DT(i) + 1 and ord(it) <= ord(t)), z(i, it)) =l= 1 - u(i, t);

OnlineOffline(i,t)$(ord(t)>0).. y(i, t) - z(i, t) =e= u(i, t) - u(i, t-1);

StartUpShutDownConstraints(i,t)$(ord(t)>0).. y(i, t) + z(i, t) =l= 1;

PminConstraint(i, t)$(ord(t)>0).. p(i, t) =g= Pmin(i) * u(i, t);

PmaxConstraint(i, t)$(ord(t)>0).. p(i, t) =l= Pmax(i) * (u(i, t) - z(i, t+1)) + RD(i) * z(i, t+1);

COM_LOG1(i,t)$(ord(t)>1).. p(i, t) =l= p(i,t-1) + RU(i);

COM_LOG2(i,t)$(ord(t)>1).. p(i, t-1) =l= p(i, t) + RD(i);

HydroMax(j).. sum(t, p(j,t)) =l= Emax(j);

HydroMin(j).. sum(t, p(j,t)) =g= Emin(j);


Profit..Total_Profit =e= Sum((i,t)$(ord(t)>0), C(t)*p(i,t)-(NLC(i)*u(i,t)+b(i)*p(i,t)+SUC(i)*y(i,t)+SDC(i)*z(i,t)));

*Solving the above Model maximizing the Profit Equation.
Model YourModel /all/;

Option mip = cplex ;

Option Optcr = 0.0 ;

Solve YourModel  maximizing Total_Profit using mip ;


Display "Profit", Total_Profit.l ;
Display "Unit Power Output", p.l ;
Display "Unit Status", u.l ;
Display "Unit Commitment", y.l ;
Display "Unit Decommitment", z.l ;
