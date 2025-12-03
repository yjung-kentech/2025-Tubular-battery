clear; clc; close all;

% 데이터 파일 경로 설정
data_save_path = 'C:\Users\user\Desktop\Figure\Figure 5\중간 데이터';
data_filename = 'figure5e.mat';
data_fullpath = fullfile(data_save_path, data_filename);

% 데이터 로드
load(data_fullpath, 'V_in_values', 'all_Tmax', 'all_Tavg');

% 보간 처리 (Interpolation)
V_interp = linspace(min(V_in_values), max(V_in_values), 100);
all_Tmax_interp = interp1(V_in_values, all_Tmax', V_interp, 'spline')';
all_Tavg_interp = interp1(V_in_values, all_Tavg', V_interp, 'spline')';

figure;
hold on;

% 각 셀별 Tmax 그래프 그리기 (빨간색)
num_cells = size(all_Tmax, 1);
for j = 1:num_cells
    plot(V_interp, all_Tmax_interp(j, :), '-', 'Color', [0.8039, 0.3255, 0.2980], 'LineWidth', 1);
end

% Tmax 음영 처리 (최대/최소 범위)
Tmax_max_curve = max(all_Tmax_interp, [], 1);
Tmax_min_curve = min(all_Tmax_interp, [], 1);
fill([V_interp, fliplr(V_interp)], [Tmax_max_curve, fliplr(Tmax_min_curve)], ...
     [0.8039, 0.3255, 0.2980], 'FaceAlpha', 1, 'EdgeColor', 'none');

% 각 셀별 Tavg 그래프 그리기 (파란색)
for j = 1:num_cells
    plot(V_interp, all_Tavg_interp(j, :), '-', 'Color', [0.0000, 0.4500, 0.7608], 'LineWidth', 1);
end

% Tavg 음영 처리 (최대/최소 범위)
Tavg_max_curve = max(all_Tavg_interp, [], 1);
Tavg_min_curve = min(all_Tavg_interp, [], 1);
fill([V_interp, fliplr(V_interp)], [Tavg_max_curve, fliplr(Tavg_min_curve)], ...
     [0.0000, 0.4500, 0.7608], 'FaceAlpha', 1, 'EdgeColor', 'none');

xlabel('Velocity [m/s]', 'FontSize', 16);
ylabel('Temperature [°C]', 'FontSize', 16);
xlim([min(V_interp), max(V_interp)]);
ylim([25 50]);
lgd = legend([plot(NaN, NaN, '-', 'Color', [0.8039, 0.3255, 0.2980], 'LineWidth', 1.5), ...
        plot(NaN, NaN, '-', 'Color', [0.0000, 0.4500, 0.7608], 'LineWidth', 1.5)], ...
        {'T_{max}', 'T_{avg}'}, 'Location', 'southeast');
lgd.FontSize = 12;

set(gca, 'YColor', 'k');
ax = gca;
ax.FontSize = 16;

grid off;
box on;
hold off;

% 플롯 저장
figure_save_path = 'C:\Users\user\Desktop\Figure\Figure 5\png 파일';
figure_filename = 'figure5d_new.png';
figure_fullpath = fullfile(figure_save_path, figure_filename);
exportgraphics(gcf, figure_fullpath, 'Resolution', 300);

fprintf('그래프가 성공적으로 저장되었습니다: %s\n', figure_fullpath);
