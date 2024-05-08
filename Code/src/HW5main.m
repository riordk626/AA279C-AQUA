%% Initialization
clc, clear
close all

projectStartup;
exportflag = true;
figurePath = '../../Images/PS5/';

[rcm, Itotal_b, Itotal_p, A_ptob] = aquaMassProps();

load('orbitConstants.mat')

[r0, v0] = keplerian2ECI(a_float, e_float, i_float, Omega_float, omega_float, nu_float, mu_float);

orbitStruct.orbitType = "num";
orbitStruct.dataSource = 'MAT-File';
% orbitStruct.dataSource = 'MATLAB File';

plantStruct.I_sim = Itotal_p;
plantStruct.axesFlag = 0;
plantStruct.dynamicsType = "default";
plantStruct.attitudeType = "euler";
plantStruct.sequence = "313";

ICstruct.r0 = r0; ICstruct.v0 = v0;

%% Problem 1 - Analytical and Plotting

Ixyz = diag(Itotal_p); Ixa = Ixyz(1); Iya = Ixyz(2); Iza = Ixyz(3);

% Nominal - Stable (a)
kNa = (Iya - Ixa)/Iza
kTa = (Iza - Ixa)/Iya
kRa = (Iza - Iya)/Ixa


% Unstsable Pitch (b)
Ixb = Iya;
Iyb = Ixa;
Izb = Iza;
Ib = diag([Ixb Iyb Izb]);

kNb = (Iyb - Ixb)/Izb
kTb = (Izb - Ixb)/Iyb
kRb = (Izb - Iyb)/Ixb

% Unstable Yaw, Roll, and Pitch (c)

Ic = diag(flip(Ixyz));
Ixc = Ixyz(3);
Iyc = Ixyz(2);
Izc = Ixyz(1);

kNc = (Iyc - Ixc)/Izc
kTc = (Izc - Ixc)/Iyc
kRc = (Izc - Iyc)/Ixc

% Unstable Yaw and Roll (d)

kTd = 0.5;
kRd = -0.25;
Ixyd = [1 kTd;kRd 1]\[Iza;Iza];
Ixd = Ixyd(1);
Iyd = Ixyd(2);

Id = diag([Ixd Iyd Iza]);
% Id = Id./(Iza*1e-4)


% Stability in Narrow Region

kTe = -0.05;
kRe = -0.25;
Ixye = [1 kTe;kRe 1]\[Iza;Iza];
Ixe = Ixye(1);
Iye = Ixye(2);

Ie = diag([Ixe Iye Iza]);
% Ie = Ie./(Iza*1e-4)
%% Problem 1 - Simulation

% Simulation Verification of Stability/Instability
omx = 0;
omy = 0;
omz = n_float;

om0 = [omx omy omz].';
om0 = om0 + 0.01.*omz.*rand([3 1]);
R_ECItoRTN = eci2rtn(r0, v0);
% R_RTNtoP = [0 0 -1;0 1 0;1 0 0];
R_RTNtoP = eye(3);
R0 = R_RTNtoP * R_ECItoRTN;
R0 = perturbDCM(R0);

ICstruct.om0 = om0; ICstruct.R0 = R0;

distStruct.disturbance = "grav";

Tfinal = 5*T;

inertiaArray = {Itotal_p;Ib;Ic;Id;Ie};
inertiaNames = {'a', 'b', 'c', 'd', 'e'};

for i=1:length(inertiaArray)
    plantStruct.I_sim = inertiaArray{i};
    simIn = initAqua(Tfinal, ICstruct, orbitStruct, plantStruct, distStruct);

    simOut = sim(simIn);

    t = simOut.t;
    R_ItoP = simOut.yout{1}.Values.Data;
    M_grav = squeeze(simOut.M_grav);
    om_p = squeeze(simOut.om_p);
    R_ECItoRTN = simOut.rtn.Data; % ORBIT DCM OUTPUT
    % u = attitudeECItoRTN(R_ItoP, R_ECItoRTN, "313");
    u = squeeze(simOut.u);
    values = {om_p, u, M_grav};
    valueNames = {'\omega [rad/s]', 'u [rad]', 'M_{grav} [Nm]'};
    valueLabels = {{'\omega_x';'\omega_y';'\omega_z'}, {'\phi'; '\theta'; '\psi'}, ...
                    {'M_x';'M_y';'M_z'}};
    figureName = [figurePath, 'point_', inertiaNames{i} ,'_grav_stability.png'];
    
    timeHistoryPlot(t,values,valueNames,valueLabels,figureName,exportflag)

    % figure()
    % plot(t, M_grav)
end