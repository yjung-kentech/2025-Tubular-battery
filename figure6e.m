clear; clc; close all;

% Initiate COMSOL
import com.comsol.model.*;
import com.comsol.model.util.*;

COM_filepath = 'C:\Users\user\Desktop\Tubular battery 최종';
COM_filename = 'Tubular pack_4s2p_1105';
COM_fullfile = fullfile(COM_filepath, COM_filename);

model = mphload(COM_fullfile);
ModelUtil.showProgress(true);

% Define parameters
C_rate = 5.4;
R_out = 23;
R_in = 3;
T_initial = 25;

R_out_str = [num2str(R_out) '[mm]'];
R_in_str = [num2str(R_in) '[mm]'];
T_initial_str = [num2str(T_initial) '[degC]'];

% Adjust velocity values to 0.3 m/s intervals
V_in_values = 0.1:0.3:4;

% Initialize structures to store results
data.Tout_bottom = nan(1, length(V_in_values));
data.Tout_side = nan(1, length(V_in_values));
data.Pin_top = nan(1, length(V_in_values));
data.Pin_side = nan(1, length(V_in_values));

% Run simulations for each velocity
for i = 1:length(V_in_values)
    try
        V_in = V_in_values(i);
        V_in_str = [num2str(V_in) '[m/s]'];

        model.param.set('C_rate', C_rate);
        model.param.set('R_out', R_out_str);
        model.param.set('R_in', R_in_str);
        model.param.set('V_in', V_in_str);

        model.study('std1').run;

        % Store the maximum value for each parameter
        data.Tout_bottom(i) = max(mphglobal(model, 'Tout_bottom', 'unit', 'degC'));
        data.Tout_side(i) = max(mphglobal(model, 'Tout_side', 'unit', 'degC'));
        data.Pin_top(i) = max(mphglobal(model, 'Pin_top', 'unit', 'Pa'));
        data.Pin_side(i) = max(mphglobal(model, 'Pin_side', 'unit', 'Pa'));
    catch
        fprintf('Skipping V_in = %.2f m/s due to error.\n', V_in);
    end
end

% Remove NaN values before interpolation
valid_idx = ~isnan(data.Tout_bottom);
V_in_valid = V_in_values(valid_idx);
Tout_bottom_valid = fillmissing(data.Tout_bottom(valid_idx), 'linear');
Tout_side_valid = fillmissing(data.Tout_side(valid_idx), 'linear');
Pin_top_valid = fillmissing(data.Pin_top(valid_idx), 'linear');
Pin_side_valid = fillmissing(data.Pin_side(valid_idx), 'linear');

% Interpolation with pchip
V_in_interp = linspace(min(V_in_valid), max(V_in_valid), 100);
T_bottom_interp = interp1(V_in_valid, Tout_bottom_valid, V_in_interp, 'pchip');
T_side_interp = interp1(V_in_valid, Tout_side_valid, V_in_interp, 'pchip');
Pin_top_interp = interp1(V_in_valid, Pin_top_valid, V_in_interp, 'pchip');
Pin_side_interp = interp1(V_in_valid, Pin_side_valid, V_in_interp, 'pchip');

% Colors
color1 = [0.8039, 0.3255, 0.2980]; % Orange
color2 = [0.0000, 0.4500, 0.7608]; % Blue

% Plot
figure;
lw = 1;
MarkerIndices = find(ismember(V_in_interp, V_in_valid));

% Left Y-axis: Temperature
yyaxis left;
h1 = plot(V_in_interp, T_bottom_interp, '-o', 'Color', color1, ...
    'MarkerIndices', 1:10:length(V_in_interp), 'DisplayName', 'T_{out\_bottom}', 'LineWidth', lw);
hold on;
h2 = plot(V_in_interp, T_side_interp, '-x', 'Color', color1, ...
    'MarkerIndices', 1:10:length(V_in_interp), 'DisplayName', 'T_{out\_side}', 'LineWidth', lw);

ylabel('Temperature [°C]', 'FontSize', 10);
xlim([0.1, 4]);
ylim([min(T_side_interp), max(T_bottom_interp)]);
set(gca, 'YColor', 'k');

% Right Y-axis: Pressure
yyaxis right;
h3 = plot(V_in_interp, Pin_top_interp, '-o', 'Color', color2, ...
    'MarkerIndices', 1:10:length(V_in_interp), 'DisplayName', 'P_{in\_top}', 'LineWidth', lw);
h4 = plot(V_in_interp, Pin_side_interp, '-x', 'Color', color2, ...
    'MarkerIndices', 1:10:length(V_in_interp), 'DisplayName', 'P_{in\_side}', 'LineWidth', lw);

ylabel('Pressure [Pa]', 'FontSize', 10);
xlim([0.1, 4]);
ylim([min(Pin_side_interp), max(Pin_top_interp)]);
set(gca, 'YColor', 'k');

xlabel('Velocity [m/s]', 'FontSize', 10);

% Combined Legend: Use line handles only
legend([h1, h2, h3, h4], {'T_{out\_bottom}', 'T_{out\_side}', 'P_{in\_top}', 'P_{in\_side}'}, ...
    'Location', 'best');
grid on;
box on;
hold off;

% Save intermediate data
save('C:\Users\user\Desktop\새figure\mat 파일\figure6e.mat', 'data');

% Save plot as png
exportgraphics(gcf, 'C:\Users\user\Desktop\새figure\png\figure6e.png', 'Resolution', 300);
