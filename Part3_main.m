%% 
% Car body design and aerodynamics
% a.a. 2025-2026
% Exercise 3 - FEM modeling and modal analysis of a cantilever beam
%

%%
format short e
clear
clc
close all

%% INIT
L               = 280e-3;                                                   % [m]       Length of the beam
b               = 30e-3;                                                    % [m]       Width of the beam
h               = 3e-3;                                                     % [m]       Thickness of the beam
ro              = 2700;                                                     % [kg/m^3]  Density  of the aluminum
massa_trave     = ro*b*h*L;                                                 % [kg]      Mass of the beam
E               = 64500e6;                                                  % [N/m^2]   Young modulus of the aluminum
Poiss           = 0.33;                                                     % [-]       Poisson coefficient
G               = E/(2*(1+Poiss));                                          % [N/m^2]   Shear coefficient
n_el            = 28;                                                       % [-]       Number of elements
l               = L/n_el;                                                   % [m]       Length of a single element

m_acc           = 18e-3;                                                    % [kg]      Mass of the accelerometer
L_acc           = 100e-3;                                                   % [m]       Distance from the clamping point

L_hammer        = 100e-3;                                                   % [-]       Distance hammering point from the clamping end

n_n             = n_el+1;                                                   % [-]       Number of nodes
n_hammer        = L_hammer/l+1;                                             % [-]       Node at which the hammer is applied
n_acc           = L_acc/l+1;                                                % [-]       Node where the accelerometer is applied

A               = b*h;                                                      % [m^2]     Beam section area
I_y             = b*h^3/12;                                                 % [m^4]     Moment of inertia of the section area

chi             = (12+11*Poiss)/10/(1+Poiss);								% [-]       Shear factor of a rectangular section

freq = 0.01:0.01:400;           % [Hz]      Frequency range of interest
%% Mass and stiffness matrix creation
% Behaviour in the plane orthogonal to plane of the beam node and reference node 
PHI1            = 12*E*I_y*chi/G/A/l^2;										% Coefficient which takes into account the shear deformation of the section in the plane orthogonal to plane of the beam node and reference node 
m1              = 156+294*PHI1+140*PHI1^2;
m2              = 22+38.5*PHI1+17.5*PHI1^2;
m3              = 54+126*PHI1+70*PHI1^2;
m4              = 13+31.5*PHI1+17.5*PHI1^2;
m5              = 4+7*PHI1+3.5*PHI1^2;
m6              = 3+7*PHI1+3.5*PHI1^2;
m7              = 36;
m8              = 3-15*PHI1;
m9              = 4+5*PHI1+10*PHI1^2;
m10             = 1+5*PHI1-5*PHI1^2;

m_F1_1          = ro*A*l/(420*(1+PHI1)^2)*[ m1 		l*m2 		m3          -l*m4
                                            l*m2 	l^2*m5      l*m4		-l^2*m6
                                            m3      l*m4        m1          -l*m2
                                            -l*m4   -l^2*m6     -l*m2       l^2*m5];
                          
m_F1_2          = ro*I_y/(30*l*(1+PHI1)^2)*[m7 		l*m8		-m7         l*m8
                                            l*m8    l^2*m9      -l*m8       -l^2*m10
                                            -m7     -l*m8       m7          -l*m8
                                            l*m8    -l^2*m10    -l*m8       l^2*m9];
                                                  
m_F             = m_F1_1+m_F1_2;                            

k_F             = E*I_y/(l^3*(1+PHI1))*[12		6*l				-12         6*l
                                        6*l     (4+PHI1)*l^2	-6*l		(2-PHI1)*l^2
                                        -12     -6*l            12          -6*l
                                        6*l     (2-PHI1)*l^2    -6*l        (4+PHI1)*l^2];
                        
M               = zeros(2*n_n);
MM              = zeros(2*n_n);     
K               = zeros(2*n_n);
KK              = zeros(2*n_n);     
        
for t=1:1:n_el
MM  = zeros(2*n_n);
KK  = zeros(2*n_n);   
qq  = 2*(t-1)+1;       % counter
qq1 = qq+3;			  % counter

MM(qq:qq1,qq:qq1) = m_F;
KK(qq:qq1,qq:qq1) = k_F;
M=M+MM;
K=K+KK;
end

% Addition of the accelerometer mass at the proper node
M(2*n_acc-1,2*n_acc-1) = M(2*n_acc-1,2*n_acc-1)+m_acc;

% constraints of the degrees of freedom
nf              = size(K,1);
Mc              = M(3:nf,3:nf);                                             % Constrained mass matrix
Kc              = K(3:nf,3:nf);                                             % Constrained stiffness matrix
% 

%% MODE SHAPES
[phi, lambda] = eig(inv(Mc)*Kc);        % compute eigenvalues (lambda) and eigenvectors (phi)  solve Kc * Phi = Mc * Phi * lambda
eigenvalues = diag (lambda);        % eigenvalues = omega^2
omega = sqrt(eigenvalues);
f_natural = omega/(2*pi);

N_modes = 5;   % number of modes to plot

x_nodes = 1 : 1 : 28;    % positions along the beam
figure(1)

for i = 51:56
    
    % Mode shape vertical displacement only (DOF odd indices)
    y_mode = [ phi(1:2:end, i)];   

    plot(x_nodes, y_mode, '-','LineWidth',1.5); 
    hold on
    xlabel('nodes');
    ylabel('Vertical displacement [m]');
    title('Modes of vibration - vertical displacement','FontSize',20)
    grid on; box on
end
legend('VI','V','IV','III','II','I')

figure
for i = 51:56
    
    % Mode shape rotation only (DOF even indices)
    y_mode = [ phi(2:2:end, i)];   
    plot(x_nodes, y_mode, '-','LineWidth',1.5); 
    hold on
    xlabel('nodes');
    ylabel('Relative rotations');
    title('Modes of vibration - rotation','FontSize',20)
    grid on; box on
end
legend('VI','V','IV','III','II','I')
%% MODAL ANALYSIS

M_modal = diag(phi' * Mc * phi);          % transform M and k in modal field
K_modal = diag(phi' * Kc * phi);

Cc = 2* sqrt(K_modal .* M_modal);
zeta = 19e-3;                           % for tuning  if you increase zeta peaks reduce
C_mod = diag(zeta * Cc);                  % compute C in modal coordinates

C_modal = phi' * C_mod * phi;        % convert C in original coordinates 

%% State Space
M_inv= inv(Mc);
K_inv= Kc;
A               = [-M_inv*C_modal   -M_inv*Kc; eye(length(Kc))   zeros(length(Kc))];   % dynamic matrix
B               = [M_inv; zeros(length(Kc))];                                      % input matrix
idx_hammer      = 2*n_hammer-3;                                                    % vertical DOF of the hammer/accelerometer node in the constrained system (the 2 DOFs of the clamped node are removed)
C               = A(idx_hammer,:);                                                 % output matrix (acceleration at the hammer node)
D               = B(idx_hammer,:);                                                  % direct input/output link matrix


system = ss (A, B, C, D) ;  % state space
sys = system(idx_hammer);   % input: force at the hammer node
w0 = freq * 2 * pi;
[mag, phase,wout] = bode (sys, w0);  % plot at a single freq
mag1 = squeeze(mag);
figure
loglog(freq, mag1,'m');   % Plot in log-log scale
grid on;
title('Bode Diagram of the Beam System','FontSize',20);
%% Comparison with Experimental data
% use the file Sq11_sn.mat to load experimental results
load('Sq11_sn.mat');  % Load experimental results for comparison
x= (FRF_Point2_Point1.x_values.start_value : FRF_Point2_Point1.x_values.increment : FRF_Point2_Point1.x_values.increment * (FRF_Point2_Point1.x_values.number_of_values-1));
y = abs(FRF_Point2_Point1.y_values.values);
hold on
grid on
loglog(x,y)
xlabel ('Frequency [Hz]')
ylabel ('Accelerance [(m/s^2)/N]')
legend('FEM model', 'experimental data')

