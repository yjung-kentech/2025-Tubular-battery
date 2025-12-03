clear; clc; close all;

% Load saved data
dataFile = 'C:\Users\user\Desktop\Figure\Figure 5\중간 데이터\figure5f.mat';
load(dataFile, 'data');

% Define velocity values (0.3 m/s intervals)
V_in_values = 0.1:0.3:4;

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

% Find marker positions exactly at 0.3 m/s intervals
MarkerIndices = arrayfun(@(x) find(abs(V_in_interp - x) == min(abs(V_in_interp - x)), 1), V_in_values);

% Colors
color1 = [0.8039, 0.3255, 0.2980]; % Orange (Temperature)
color2 = [0.0000, 0.4500, 0.7608]; % Blue (Pressure)

% Plot
figure;
lw = 1.5; % Line width

% Left Y-axis: Temperature
yyaxis left;
h1 = plot(V_in_interp, T_bottom_interp, '-o', 'Color', color1, ...
    'MarkerIndices', MarkerIndices, 'DisplayName', 'T_{out\_bottom}', 'LineWidth', lw);
hold on;
h2 = plot(V_in_interp, T_side_interp, '-x', 'Color', color1, ...
    'MarkerIndices', MarkerIndices, 'DisplayName', 'T_{out\_side}', 'LineWidth', lw);

ylabel('Temperature [°C]', 'FontSize', 18);
xlim([0.1, 4]);
ylim([25 30]);
set(gca, 'YColor', 'k');

% Right Y-axis: Pressure
yyaxis right;
h3 = plot(V_in_interp, Pin_top_interp, '-o', 'Color', color2, ...
    'MarkerIndices', MarkerIndices, 'DisplayName', 'P_{in\_top}', 'LineWidth', lw);
h4 = plot(V_in_interp, Pin_side_interp, '-x', 'Color', color2, ...
    'MarkerIndices', MarkerIndices, 'DisplayName', 'P_{in\_side}', 'LineWidth', lw);

ylabel('Pressure [Pa]', 'FontSize', 18);
xlim([0.1, 4]);
set(gca, 'YColor', 'k');
ax = gca;
ax.FontSize = 18;

xlabel('Velocity [m/s]', 'FontSize', 20);

% Combined Legend: Use line handles only
legend([h1, h2, h3, h4], {'T_{out\_bottom}', 'T_{out\_side}', 'P_{in\_top}', 'P_{in\_side}'}, ...
    'Location', 'northwest', 'NumColumns', 2, 'FontSize', 14);
grid off;
box on;
hold off;

% Save plot as PNG
fig = gcf;
set(fig, 'Position', [100, 100, 560*1.1, 420*1.1]);
exportgraphics(gcf, 'C:\Users\user\Desktop\Figure\Figure 5\png 파일\figure5e_new.png', 'Resolution', 300);
