
%% 
load Tech0p18.mat
%% load the initial condition
Rf2 = 400*(10^3);
Rf1 = 100*(10^3);
Id = 5/1000;%%current flowing through the pass PMOS
I0 = 12.5*10^(-6); %% current flowing through the inout mosfet
B = Rf2/(Rf2+Rf1);%% beta factor
gmp = 2*Id/0.2; %% gm=2Id/Vov V0v=0.2 for optimization
RL = 1.2/Id; %% Rout can be approximately equal to RL
p = 10^(-12);
Co = 200*p; %% the Load capacitor
gmo = 2*I0/0.2;%%125*(10^(-6));
Reamp = 8*(10^(6));
C_c = 0*p;%% the miller compensator for initial condition
%%desired_fre = 15943806*2; 
Lpass = 0.18*10^(-6);%% 0.18u
L_in = 0.5*10^(-6); %% 0.5u
Delta_M2 = 0.2;%% this is the over drive voltage



%% find the predicted capacitor
CgsW_pmos_Lpass = lookupDevParam(Tech0p18,'pmos',Delta_M2,'CgsW', ...
'L',Lpass); 
CgsW_input_mos = lookupDevParam(Tech0p18,'nmos',Delta_M2,'CgsW', ...
'L',L_in); 
CgdW_pmos_Lpass = lookupDevParam(Tech0p18,'pmos',Delta_M2,'CgdW', ...
'L',Lpass); 
gmpr0 = lookupDevParam(Tech0p18,'pmos', Delta_M2,'gmr0',...
    'L',Lpass);
width_pass = 1/(lookupDevParam(Tech0p18,'pmos',Delta_M2,'IdW', ...
'L',Lpass)/Id); %%the width of the pass PMOS
width_in = 1/(lookupDevParam(Tech0p18,'nmos',Delta_M2,'IdW', ...
'L',L_in)/I0); %% the width of the input mosfet
rds = gmpr0/gmp; %% find the rds of pass PMOS
C_gs_pass = width_pass * CgsW_pmos_Lpass;%% find the gain_source capacitor of the pass PMOS
C_gd_pass_sub = width_pass * CgdW_pmos_Lpass;%% find the gain_drain capacitor of the pass PMOS
C_gs_input_mos = width_in*CgsW_input_mos;
C_gd_pass = C_gd_pass_sub+C_c;%% the capacitor between the gate and drain of the Pass pmos in total



%% generate the bode plot based on the predicted capacitor
Rout = 1/(1/RL+1/(Rf1+Rf2)+1/rds);
R_sub = 1/(gmp*(C_gd_pass/(C_gd_pass+C_gs_pass)));
Reff = Rout*R_sub/(Rout+R_sub);
Ceff = Co+(C_gs_pass*C_gd_pass)/(C_gs_pass+C_gd_pass);
p1 = ((C_gs_pass)+(1+gmp*Rout)*C_gd_pass)*Reamp*2*pi;
p2 = Reff*Ceff*2*pi;
p3 = (Rf1*Rf2/(Rf1+Rf2))*C_gs_input_mos*2*pi;%%2.66*10^(-9);
%R_c = 1/(desired_fre*2*pi*C_gd_pass) +1/gmp;
%R_c = 0;
pz = (C_gd_pass)*(1/gmp-R_c)* 2*pi;
numerator = [-B*gmp*Rout*Reamp*gmo*pz , B*gmp*Rout*Reamp*gmo];
%%denominator = [p1*p2 p1+p2 1];revise here
denominator = [p1*p2*p3 p1*p2+p2*p3+p3*p1 p1+p2+p3 1];
sys = tf(numerator,denominator);
w = logspace(0, 12, 1000); % From 100 rad/s to 1000 rad/s, with a total of 1000 points
bode(sys,w);


%% function help to find out the phase margin
[mag, phase, wout] = bode(sys, w);
mag = squeeze(mag);
wout = squeeze(wout);
mag_dB = 20 * log10(mag);
data = [wout, mag_dB];
csvwrite('bode_data_pole3_comp.csv', data);
mag_cross_index = find(mag_dB >= 0, 1, 'last');
if ~isempty(mag_cross_index)
    mag_cross_freq = wout(mag_cross_index);
    disp(['Magnitude crossover frequency: ', num2str(mag_cross_freq), ' hz']);
else
    disp('No magnitude crossover frequency found.');
end

if ~isempty(mag_cross_index)
    phase_at_cross_freq = phase(mag_cross_index);
    phase_margin = phase_at_cross_freq-180;
    disp([' expected Phase margin: ', num2str(phase_margin), ' degrees']);
else
    disp('No phase margin can be calculated.');
end