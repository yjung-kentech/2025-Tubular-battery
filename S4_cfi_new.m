clear; clc; close all

%% 1. 데이터 읽기 -----------------------------------------------------------
data_dir  = 'C:\Users\user\Desktop\MATLAB\Tubular_battery';
data_file = fullfile(data_dir, 'Tubular_Sweep_Crate_Rin_80.mat');
load(data_file);

% 컬러맵 읽기
color_data_file = fullfile(data_dir, 'slanCM_Data.mat');
load(color_data_file);

%% 2. 컬러맵 설정 ----------------------------------------------------------
color_type = 'SequentialP';
color_name = 'Greens';
type_idx = find(strcmp({slandarerCM.Type}, color_type));
name_idx = find(strcmp(slandarerCM(type_idx).Names, color_name));
color = slandarerCM(type_idx).Colors{name_idx};

%% 3. 축 데이터 -------------------------------------------------------------
C_rate_vec = data.C_rate;          % 원본 C-rate
D_in_vec   = 2*data.R_in;          % 원본 D_in

%% 4. ★ 고해상도 2-D 보간 ★ -----------------------------------------------
%   (→ 100 °C 경계가 부드럽게 표현)
N = 500;                                               % 해상도 (500×500)
D_in_hi   = linspace(min(D_in_vec),   max(D_in_vec),   N);
C_rate_hi = linspace(min(C_rate_vec), max(C_rate_vec), N);

[D_in_grid,   C_rate_grid]   = meshgrid(D_in_vec,   C_rate_vec);
[D_in_higrid, C_rate_higrid] = meshgrid(D_in_hi,    C_rate_hi);

% T_max 고해상도 보간
T_max_hi = interp2(D_in_grid, C_rate_grid, ...
                   data.T_max, D_in_higrid, C_rate_higrid, 'spline');

%% 5. 100 °C 초과 영역 마스킹 ----------------------------------------------
T_cut = 100;
over_100_mask = (T_max_hi > T_cut);   % 100도 초과 마스크

%% 6. 플로팅 ---------------------------------------------------------------
figure;
set(gcf, 'Position', [680, 558, 800, 620]);

cmin = min(data.t95(:));
cmax = max(data.t95(:));
numContours = 20;

% (1) t95 등고선 표현
contourf(D_in_vec, C_rate_vec, data.t95, ...
         linspace(cmin, cmax, numContours), 'LineColor', 'none');
clim([cmin cmax]);
colormap(color);
colorbar;
hold on;

% (2) 100 °C 초과 회색 영역 추가
[~, hOver100] = contourf(D_in_hi, C_rate_hi, double(over_100_mask), ...
                        [0.5 1.5], 'LineColor', 'none');
set(hOver100, 'FaceColor', [0.5 0.5 0.5], 'EdgeColor', 'none');

% (3) Tmax = 45 °C 경계선
T_allowed = 45;
[~, hTmax] = contour(D_in_vec, C_rate_vec, data.T_max, ...
                     [T_allowed, T_allowed], 'LineWidth', 2, 'LineColor', '#EE4C97');

% (4) Elp_min = 0 V 경계선
Elpcut = 0;
[~, hElp] = contour(D_in_vec, C_rate_vec, data.Elp_min, ...
                    [Elpcut, Elpcut], 'LineWidth', 2, 'LineColor', '#4DBBD5');

%% 7. 서식·레이블 -----------------------------------------------------------
xlabel('D_{in} [mm]', 'FontSize', 26);
ylabel('C-rate', 'FontSize', 26);

ax = gca;
ax.FontSize = 24;

pos = ax.Position;
pos(3) = pos(3) * 0.98;
ax.Position = pos;

h = colorbar;
ylabel(h, 't_{chg} [min]', 'FontSize', 26);

% 관심 지점 하이라이트
% x = 6;
% y = 6;
% xline(x, '--w', 'LineWidth', 1);
% yline(y, '--w', 'LineWidth', 1);
% plot(x, y, 'o', 'MarkerFaceColor', '#EFC000', 'MarkerEdgeColor', '#EFC000');

lgd = legend([hTmax, hElp], {'T_{max} = 45 ^oC', 'η_{n} = 0 V'}, ...
             'Location', 'northwest', 'FontSize', 25);
set(lgd, 'Color', [0.8, 0.8, 0.8]);
set(lgd, 'EdgeColor', 'black');

hold off;

%% 8. 이미지 저장 -----------------------------------------------------------
exportgraphics(gcf, 'C:\Users\user\Desktop\Figure\Supple Figure\png 파일\S4_i.png', 'Resolution', 300);
