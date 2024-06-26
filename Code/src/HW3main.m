clc, clear

close all

[rcm, Itotal_b, Itotal_p, A_ptob] = aquaMassProps();
disturbance="none";
orbitType = "num";


%% Axis Symmetric

I_sim = Itotal_p;

I_sim(2,2) = I_sim(1,1);


om0_deg = [-7, 2, 5].';
om0 = deg2rad(om0_deg);
Tfinal = 300;
axesFlag = 0;
dynamicsType="wheel";
Ir = 0;
r = ones([3 1])./sqrt(3);
omr = 0;
M = timeseries(zeros([3 2]), [0 Tfinal]);
simIn = Simulink.SimulationInput('eulerPropagate');
simIn.ExternalInput = M;

load_system("eulerPropagate")
% open_system("eulerPropagate")

simOut = sim(simIn);

om_p = squeeze(simOut.om_p);
t = simOut.t;

om_sim = om_p;

Ix = I_sim(1,1); Iy = Ix;
Iz = I_sim(3,3);

lambda = (Iz - Ix)/Iy * om0(3);
om_al = zeros(size(om_sim));

om_al(3,:) = om0(3).*ones(size(om_al(3,:)));
om_al(1,:) = om0(1).*cos(lambda.*t) - om0(2).*sin(lambda.*t);
om_al(2,:) = om0(1).*sin(lambda.*t) + om0(2).*cos(lambda.*t);

error = om_al - om_sim;

figure()
subplot(2,1,1)
splot = plot(t, om_sim, 'LineWidth',2);
set(splot, {'DisplayName'}, {'\omega_x';'\omega_y'; '\omega_z'})
ax = gca();
ax.FontSize = 14;
% xlabel('t [sec]')
ylabel('\omega_{sim} [rad/s]')
subplot(2,1,2)
aplot = plot(t, om_al, 'LineWidth', 2);
set(aplot, {'DisplayName'}, {'\omega_x';'\omega_y'; '\omega_z'})
ax = gca();
ax.FontSize = 14;
xlabel('t [sec]')
ylabel('\omega_{analytical} [rad/s]')
legend
exportgraphics(gcf, '../Images/sim_vs_anlt_magnitude.png')


figure()
aplot = plot(t, error, 'LineWidth',2);
set(aplot, {'DisplayName'}, {'r_x';'r_y'; 'r_z'})
ax = gca();
ax.FontSize = 14;
xlabel('t [sec]')
ylabel('Error [rad/s]')
legend
exportgraphics(gcf, '../Images/sim_vs_anlt_error.png')

L_as = I_sim * om_p;
L_as_mag = vecnorm(L_as,2,1);
L_as = (L_as./vecnorm(L_as,2,1));
% L_as = L_as.*0.1067;
L_as = L_as.*(om_p(3,end)/L_as(3,end));
% L_as = om_p(3,end).*(L_as./vecnorm(L_as,2,1));
figure()
xlim([-0.15 0.15])
ylim([-0.15 0.15])
zlim([0 0.1])
axis equal
view([1 1 0.5])
hold on
plot3(om_p(1,:), om_p(2,:), om_p(3,:), 'DisplayName', 'Polhode')
plot3(L_as(1, :), L_as(2, :), L_as(3, :), 'DisplayName', 'Angular Momentum')
legend
exportgraphics(gcf, '../Images/axis_symmetric_polhode.png')
%% Asymmetric

I_sim = Itotal_p;


q0 = [1 0 0 0].';
u0 = [0.1 0.1 0.1].';

simIn = Simulink.SimulationInput('aquaMasterModel');
simIn.ExternalInput = M;

legendNames = {{'\phi', '\theta', '\psi'}, {'q_0', 'q_1', 'q_2', 'q_3'}};
stateNames = {'u', 'q'};
unitNames = {'[rad]', ''};
imageNames = {'EA.png', 'quat.png'};
gifNames = {'EA.gif', 'quat.gif'};

attitudeTypes = {"euler", "quat"};

for Type = 1:2
    attitudeType = attitudeTypes{Type};

    % Orbital Elements
    e_float = 0.0000979; % eccentricity 
    a_float = 7080.6; % km
    i_float = deg2rad(98.2); %degrees
    omega_float = deg2rad(120.4799); % arguement of perigee // degrees
    Omega_float = deg2rad(95.2063); % ascending node // degrees
    nu_float = 0; % True Anomaly (in radians)
    mu_float = 3.986004418e5; % Gravitational parameter of the Earth in km^3/s^2
    
    semimajorAxis = [[0, a_float]; [10000000, a_float]];
    eccentricity = [[0, e_float]; [10000000, e_float]];
    inclination = [[0, i_float]; [10000000, i_float]];
    omega = [[0, omega_float]; [10000000, omega_float]];
    Omega = [[0, Omega_float]; [10000000, Omega_float]];
    trueAnomaly = [[0, nu_float]; [10000000, nu_float]];
    mu = [[0, mu_float]; [10000000, mu_float]];
    
    % Calculate orbital period
    T = 2*pi*sqrt((a_float)^3 / mu_float); % Orbital period in seconds
    
    % Calculate mean motion
    n_float = 2*pi / T; % Mean motion in rad/s
    mean_motion = [[0, n_float],
        [10000000, n_float]];
    
    load_system("aquaMasterModel")
    % open_system("eulerPropagate")
    
    simOut = sim(simIn);
    
    R = simOut.yout{1}.Values.Data;
    t = simOut.t;
    
    n = size(t,1);
    
    om_p = squeeze(simOut.om_p).';
    om_i = zeros(size(om_p.'));
    L_i = zeros(size(om_i));
    coords_p = zeros(size(R));
    coords_b = zeros(size(coords_p));
    
    for i=1:n
        om_i(:,i) = R(:,:,i).' * om_p(i,:).';
        L_p = Itotal_p * om_p(i,:).';
        L_i(:,i) = R(:,:,i).' * L_p;

        coords_p(:,:,i) = R(:,:,i).';
        coords_b(:,:,i) = coords_p(:,:,i) * A_ptob.';
    end

    % Orbital Frame Propagator 
    orbit_prop_time_series = simOut.t;
    run('numerical_orbit_propagation_from_main.m');

    eval([stateNames{Type}, '= squeeze(simOut.', stateNames{Type}, ');'])
    % Genrates time history of attitude parameters
    figure
    eval(['plot(t, ', stateNames{Type}, ', ''LineWidth'', 2)'])
    ax = gca();
    ax.FontSize = 14;
    xlabel('t [sec]')
    ylabel([stateNames{Type}, ' ', unitNames{Type}])
    legend(legendNames{Type})
    exportgraphics(gcf, ['../Images/time_history_', imageNames{Type}])
    
    % Generate herpolhode plot (ineretial frame polhode)
    figure
    plot3(om_i(1,:), om_i(2,:), om_i(3,:), 'LineWidth', 2)
    hold on
    L_scaled = (L_i(:,end)./norm(L_i(:,end))).*norm(om_i(:,end));
    quiver3(0,0,0,L_scaled(1), L_scaled(2), L_scaled(3))
    ax = gca();
    ax.FontSize = 14;
    axis equal
    xlabel('\omega_x')
    ylabel('\omega_y')
    zlabel('\omega_z')
    % hold off
    exportgraphics(gcf, ['../Images/herpolhode_', imageNames{Type}])
    viewVec1 = cross(om_i(:,end), L_scaled);
    view(viewVec1)
    exportgraphics(gcf, ['../Images/herpolhode_normal_', imageNames{Type}])

    % Generate angular momentum vector plot (inertial)
    figure
    plot3(L_i(1,:), L_i(2,:), L_i(3,:), 'LineWidth', 2)
    ax = gca();
    ax.FontSize = 14;
    xlabel('L_x')
    ylabel('L_y')
    zlabel('L_z')
    axis equal
    exportgraphics(gcf, ['../Images/angular_momentum_', imageNames{Type}])

    % figure
    % axis equal
    % ax = gca();
    % ax.FontSize = 14;
    % xlabel('L_x')
    % ylabel('L_y')
    % zlabel('L_z')
    L_mean = mean(L_i, 2);
    % quiver3(0,0,0, L_mean(1), L_mean(2), L_mean(3))
    % exportgraphics(gcf, ['../Images/angular_momentum_mean_', imageNames{Type}])

    % Generate reference frame plot in motion
    
    f1 = figure;
    ax1 = axes('parent', f1);
    axis equal
    xlim([-1.5 1.5])
    ylim([-1.5 1.5])
    zlim([-1.5 1.5])
    xlabel('x')
    ylabel('y')
    zlabel('z')
    ax1.FontSize = 14;
    view([1 1 1])
    hold on
    quiver3(0,0,0,1,0,0, 'Color', 'k', 'DisplayName', 'Inertial Frame')
    quiver3(0,0,0,0,1,0, 'Color', 'k', 'HandleVisibility', 'off')
    quiver3(0,0,0,0,0,1, 'Color', 'k', 'HandleVisibility', 'off')
    
    axNames_p = {'xp', 'yp', 'zp'};
    axNames_b = {'xb', 'yb', 'zb'};
    axNames_o = {'xo', 'yo', 'zo'};
    dataNames = {'UData', 'VData', 'WData'};
    for j=1:3
        eval([axNames_p{j}, ' = quiver3(0,0,0,coords_p(1,j,1), coords_p(2,j,1), coords_p(3,j,1), ''Color'', ''b'');'])
        eval([axNames_b{j}, ' = quiver3(0,0,0,coords_b(1,j,1), coords_b(2,j,1), coords_b(3,j,1), ''Color'', ''g'');'])
        eval([axNames_o{j}, ' = quiver3(0,0,0,coords_orbital(1,j,1), coords_orbital(2,j,1), coords_orbital(3,j,1), ''Color'', ''r'');'])
    end
    
    xp.DisplayName = 'Principal Frame';
    yp.HandleVisibility = 'off';
    zp.HandleVisibility = 'off';
    xb.DisplayName = 'Body Frame';
    yb.HandleVisibility = 'off';
    zb.HandleVisibility = 'off';
    xo.DisplayName = 'Orbital Frame';
    yo.HandleVisibility = 'off';
    zo.HandleVisibility = 'off';

    legend
    
    frameNumber = 1;
    ngif = n/2;
    frameFlags = floor(linspace(1, ngif, 4));
    exportgraphics(f1, ['../Images/reference_frame_gif_', gifNames{Type}])
    f2 = figure;
    for i=1:ngif
        f1;
        hold on
        for j=1:3
            for k=1:3
                eval([axNames_p{j}, '.', dataNames{k}, ' = coords_p(k,j,i);'])
                eval([axNames_b{j}, '.', dataNames{k}, ' = coords_b(k,j,i);'])
                eval([axNames_o{j}, '.', dataNames{k}, ' = coords_orbital(k,j,i);'])
            end
        end
        
        pause(0.001)
        
        if any(i == frameFlags)
            f2;
            axFrame = subplot(2,2,frameNumber, 'parent', f2);
            % ax2 = gca();
            % ax1Chil = ax1.Children;
            axcp = copyobj(ax1, f2);
            set(axcp,'Position',get(axFrame,'position'))
            % set(axcp,)
            delete(axFrame)
            subtitle = matlab.graphics.primitive.Text;
            subtitle.String = ['t = ', num2str(ceil(t(i))), ' s'];
            set(axcp,'Title', subtitle)

            if frameNumber == 4
                % Add legend outside of the plot area
                legend('Location', 'northoutside', 'Orientation', 'vertical');
            end

            frameNumber = frameNumber + 1;
        end
        if Type == 1
            exportgraphics(f1, ['../Images/reference_frame_gif_', gifNames{Type}], Append=true)
        end
        hold off
    end
    legend(axcp)
    % Set the units to inches
    set(f2, 'Units', 'inches');
    f2.Position(3) = 7; % Set width to 8 inches
    f2.Position(4) = 10; % Set height to 6 inches
    exportgraphics(f2, ['../Images/reference_frame_motion_', imageNames{Type}], 'Resolution', 300)

    % Generate reference frame plot in motion in RTN for 1 orbit (100 mins)
    
    % Orbital Frame Propagator 
    orbit_prop_time_series = simOut.t * 60;
    run('numerical_orbit_propagation_from_main.m');

    f1 = figure;
    ax1 = axes('parent', f1);
    axis equal
    xlim([-1.5 1.5])
    ylim([-1.5 1.5])
    zlim([-1.5 1.5])
    xlabel('x')
    ylabel('y')
    zlabel('z')
    ax1.FontSize = 14;
    view([1 1 1])
    hold on
    quiver3(0,0,0,1,0,0, 'Color', 'k', 'DisplayName', 'Inertial Frame')
    quiver3(0,0,0,0,1,0, 'Color', 'k', 'HandleVisibility', 'off')
    quiver3(0,0,0,0,0,1, 'Color', 'k', 'HandleVisibility', 'off')
    
    axNames_o = {'xo', 'yo', 'zo'};
    dataNames = {'UData', 'VData', 'WData'};
    for j=1:3
        eval([axNames_o{j}, ' = quiver3(0,0,0,coords_orbital(1,j,1), coords_orbital(2,j,1), coords_orbital(3,j,1), ''Color'', ''r'');'])
    end

    xo.DisplayName = 'Orbital Frame';
    yo.HandleVisibility = 'off';
    zo.HandleVisibility = 'off';

    legend
    
    frameNumber = 1;
    ngif = n/2;
    frameFlags = floor(linspace(1, ngif, 4));
    exportgraphics(f1, ['../Images/reference_frame_gif_orbital_', gifNames{Type}])
    f2 = figure;
    for i=1:ngif
        f1;
        hold on
        for j=1:3
            for k=1:3
                eval([axNames_o{j}, '.', dataNames{k}, ' = coords_orbital(k,j,i);'])
            end
        end
        
        pause(0.00001)
        
        if any(i == frameFlags)
            f2;
            axFrame = subplot(2,2,frameNumber, 'parent', f2);
            % ax2 = gca();
            % ax1Chil = ax1.Children;
            axcp = copyobj(ax1, f2);
            set(axcp,'Position',get(axFrame,'position'))
            % set(axcp,)
            delete(axFrame)
            subtitle = matlab.graphics.primitive.Text;
            subtitle.String = ['t = ', num2str(ceil(t(i))), ' s'];
            set(axcp,'Title', subtitle)

            if frameNumber == 4
                legend('Location', 'northoutside', 'Orientation', 'vertical');
            end

            frameNumber = frameNumber + 1;
        end
        if Type == 1
            exportgraphics(f1, ['../Images/reference_frame_gif_orbital_', gifNames{Type}], Append=true)
        end
        hold off
    end
    legend(axcp)
    % Set the units to inches
    set(f2, 'Units', 'inches');
    f2.Position(3) = 7; % Set width to 8 inches
    f2.Position(4) = 10; % Set height to 6 inches
    exportgraphics(f2, ['../Images/reference_frame_motion_orbital_', imageNames{Type}], 'Resolution', 300)
end
