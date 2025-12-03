clear; clc; close all;

%% 데이터 읽기
data_dir = 'C:\Users\user\Desktop\Figure\Sweep\mat 파일';
tubular_file = fullfile(data_dir, 'Tubular_Sweep_Crate_Rout.mat');
cylinder_file = fullfile(data_dir, 'Cylinder_Sweep_Crate_Rout.mat');

load(tubular_file);
tub = data;

load(cylinder_file);
cyl = data;

%% 변수 설정
C_tub = tub.C_rate;
D_tub = 2 * tub.R_out;

C_cyl = cyl.C_rate;
D_cyl = 2 * cyl.R_out;

%% 추가 변수 계산 (Tubular)
ismat_soc_tub = tub.SOC;
Elpcut = 0;
ismat_nlp_tub = double(tub.Elp_min > Elpcut);
T_allowed = 45;
ismat_Tmax_tub = double(tub.T_max < T_allowed);

%% 추가 변수 계산 (Cylinder)
ismat_soc_cyl = cyl.SOC;
ismat_nlp_cyl = double(cyl.Elp_min > Elpcut);
ismat_Tmax_cyl = double(cyl.T_max < T_allowed);

%% 등고선 좌표 추출 및 정렬 및 보간 (Tubular)
M_Elp_tub = contour(D_tub, C_tub, tub.Elp_min, [Elpcut, Elpcut]);

hold on
Elp_x_tub = M_Elp_tub(1, 2:end);
Elp_y_tub = M_Elp_tub(2, 2:end);

M_Tmax_tub = contour(D_tub, C_tub, tub.T_max, [T_allowed, T_allowed]);
hold off
close;
Tmax_x_tub = M_Tmax_tub(1, 2:end);
Tmax_y_tub = M_Tmax_tub(2, 2:end);

[Elp_x_tub, idx] = sort(Elp_x_tub);
Elp_y_tub = Elp_y_tub(idx);

[Tmax_x_tub, idx] = sort(Tmax_x_tub);
Tmax_y_tub = Tmax_y_tub(idx);

Elp_xq_tub = min(Elp_x_tub):1:max(Elp_x_tub);
Elp_yq_tub = interp1(Elp_x_tub, Elp_y_tub, Elp_xq_tub, 'linear');

Tmax_xq_tub = 30:1:max(Tmax_x_tub);
Tmax_yq_tub = interp1(Tmax_x_tub, Tmax_y_tub, Tmax_xq_tub, 'linear');

%% 등고선 좌표 추출 및 정렬 및 보간 (Cylinder)
M_Elp_cyl = contour(D_cyl, C_cyl, cyl.Elp_min, [Elpcut, Elpcut]);
hold on
Elp_x_cyl = M_Elp_cyl(1, 2:end);
Elp_y_cyl = M_Elp_cyl(2, 2:end);

M_Tmax_cyl = contour(D_cyl, C_cyl, cyl.T_max, [T_allowed, T_allowed]);
hold off
close;
Tmax_x_cyl = M_Tmax_cyl(1, 2:end);
Tmax_y_cyl = M_Tmax_cyl(2, 2:end);

[Elp_x_cyl, idx] = sort(Elp_x_cyl);
Elp_y_cyl = Elp_y_cyl(idx);

[Tmax_x_cyl, idx] = sort(Tmax_x_cyl);
Tmax_y_cyl = Tmax_y_cyl(idx);

Elp_xq_cyl = min(Elp_x_cyl):1:max(Elp_x_cyl);
Elp_yq_cyl = interp1(Elp_x_cyl, Elp_y_cyl, Elp_xq_cyl, 'linear');

Tmax_xq_cyl = 30:1:max(Tmax_x_cyl);
Tmax_yq_cyl = interp1(Tmax_x_cyl, Tmax_y_cyl, Tmax_xq_cyl, 'linear');

%% Merging coordinates and selecting the minimum y-value for each x-value (Tubular)
all_x_tub = unique([Elp_xq_tub, Tmax_xq_tub]);
min_y_tub = arrayfun(@(x) min([interp1(Elp_x_tub, Elp_y_tub, x, 'linear', inf), ...
    interp1(Tmax_x_tub, Tmax_y_tub, x, 'linear', inf)]), all_x_tub);
min_y_tub_coord = [all_x_tub; min_y_tub];

%% Merging coordinates and selecting the minimum y-value for each x-value (Cylinder)
all_x_cyl = unique([Elp_xq_cyl, Tmax_xq_cyl]);
min_y_cyl = arrayfun(@(x) min([interp1(Elp_x_cyl, Elp_y_cyl, x, 'linear', inf), ...
    interp1(Tmax_x_cyl, Tmax_y_cyl, x, 'linear', inf)]), all_x_cyl);
min_y_cyl_coord = [all_x_cyl; min_y_cyl];

%% Interpolating charging time using min_y values (Tubular)
chg_tub = arrayfun(@(x, y) interp2(D_tub, C_tub, tub.t95, x, y, 'linear', inf), all_x_tub, min_y_tub);
chg_tub_coord = [all_x_tub; chg_tub];

%% Interpolating charging time using min_y values (Cylinder)
chg_cyl = arrayfun(@(x, y) interp2(D_cyl, C_cyl, cyl.t95, x, y, 'linear', inf), all_x_cyl, min_y_cyl);
chg_cyl_coord = [all_x_cyl; chg_cyl];

%% Apparent energy density 추가
import com.comsol.model.*
import com.comsol.model.util.*

COM_filepath = 'C:\Users\user\Desktop\Tubular battery 최종';
COM_filename = 'JYR_cell_1223.mph';
COM_fullfile = fullfile(COM_filepath, COM_filename);

model = mphload(COM_fullfile);
ModelUtil.showProgress(true);

R_out_values = 5:1:40;

% Initialize a matrix to store results
rho_tub = zeros(1, length(R_out_values));
rho_cyl = zeros(1, length(R_out_values));

for i = 1:length(R_out_values)
    R_out = R_out_values(i);
    R_out_str = [num2str(R_out) '[mm]'];

    % Set the parameters in COMSOL
    model.param.set('R_out', R_out_str);

    % Get the value of cell2D_Q directly from the parameters
    rho_app = model.param.evaluate('rho_app*2.7778e-7');
    rho_app_cylin = model.param.evaluate('rho_app_cylin*2.7778e-7');

    % Store the result
    rho_tub(i) = rho_app;
    rho_cyl(i) = rho_app_cylin;
end

%% Define the number of desired markers
m_int = 15;  

% Interpolate for tubular and cylindrical data to get evenly spaced markers
x_tub = linspace(min(chg_tub_coord(1,:)), max(chg_tub_coord(1,:)), m_int);
y_tub = interp1(chg_tub_coord(1,:), chg_tub_coord(2,:), x_tub);

x_cyl = linspace(min(chg_cyl_coord(1,:)), max(chg_cyl_coord(1,:)), m_int);
y_cyl = interp1(chg_cyl_coord(1,:), chg_cyl_coord(2,:), x_cyl);

% Repeat for R_out_values (apparent energy density plots)
x_rho = linspace(min(R_out_values*2), max(R_out_values*2), m_int);
rho_tub_interp = interp1(R_out_values*2, rho_tub, x_rho);
rho_cyl_interp = interp1(R_out_values*2, rho_cyl, x_rho);

%% Plot with interpolated markers
figure;

fig = gcf;
set(fig, 'Position', [100, 100, 560, 420]);

lw = 1;
color1 = [0, 0.4510, 0.7608]; % Blue
color2 = [0.8039, 0.3255, 0.2980]; % Orange

% Charging Time Plot
yyaxis right;
h1 = plot(chg_tub_coord(1,:), chg_tub_coord(2,:), 'Color', color1, 'LineStyle', '-', 'LineWidth', lw);
hold on;
h2 = plot(chg_cyl_coord(1,:), chg_cyl_coord(2,:), 'Color', color2, 'LineStyle', '-', 'LineWidth', lw);

% Add interpolated markers
plot(x_tub, y_tub, 'o', 'Color', color1);
plot(x_cyl, y_cyl, 'o', 'Color', color2);

% 범례용 더미 플롯 생성 (선과 마커 포함)
h1_dummy = plot(NaN, NaN, 'Color', color1, 'LineStyle', '-', 'LineWidth', lw, 'Marker', 'o');
h2_dummy = plot(NaN, NaN, 'Color', color2, 'LineStyle', '-', 'LineWidth', lw, 'Marker', 'o');

xlabel('D_{out} [mm]', 'FontSize', 15);
xlim([10 80]);
ylabel('Charging time [min]', 'FontSize', 15);
ylim([0 35]);
grid off;
ax = gca;
ax.FontSize = 15;
ax.YColor = 'k';

% Apparent Energy Density Plot
yyaxis left;
h3 = plot(R_out_values*2, rho_tub, 'Color', color1, 'LineStyle', '-', 'LineWidth', lw);
hold on;
h4 = plot(R_out_values*2, rho_cyl, 'Color', color2, 'LineStyle', '-', 'LineWidth', lw);

% Add interpolated markers
plot(x_rho, rho_tub_interp, '^', 'Color', color1);
plot(x_rho, rho_cyl_interp, '^', 'Color', color2);

% 범례용 더미 플롯 생성 (선과 마커 포함)
h3_dummy = plot(NaN, NaN, 'Color', color1, 'LineStyle', '-', 'LineWidth', lw, 'Marker', '^');
h4_dummy = plot(NaN, NaN, 'Color', color2, 'LineStyle', '-', 'LineWidth', lw, 'Marker', '^');

ylabel('\rho_{E} [kWh/m^3]', 'FontSize', 17);
ylim([390 800]);
ax.YColor = 'k';
box on;

lgd = legend([h1_dummy, h2_dummy, h3_dummy, h4_dummy], {'tube.t_{chg}', 'cyl.t_{chg}', 'tube.\rho_{E}', 'cyl.\rho_{E}'}, 'Location', 'southeast', 'NumColumns', 2, 'FontSize', 13);
% lgd.FontSize = 11;
legend boxon;

%% 그림 저장

figure_save_dir = 'C:\Users\user\Desktop\Figure\Figure 4\png 파일';
figure_save_path = fullfile(figure_save_dir, 'figure4a_new.png');
exportgraphics(gcf, figure_save_path, 'Resolution', 600);

%% D_out 46mm, 60mm, 80mm 일 때 energy density, charging time 계산

D_out_targets = [46, 60, 80];

% Calculate the energy density for tubular and cylindrical cells at specified D_out values
rho_energy_tub = interp1(R_out_values * 2, rho_tub, D_out_targets, 'linear', 'extrap');
rho_energy_cyl = interp1(R_out_values * 2, rho_cyl, D_out_targets, 'linear', 'extrap');

% Calculate the charging time for tubular and cylindrical cells at specified D_out values
chg_tub_target = interp1(chg_tub_coord(1, :), chg_tub_coord(2, :), D_out_targets, 'linear', 'extrap');
chg_cyl_target = interp1(chg_cyl_coord(1, :), chg_cyl_coord(2, :), D_out_targets, 'linear', 'extrap');

% Display the results
for i = 1:length(D_out_targets)
    fprintf('D_out = %d mm\n', D_out_targets(i));
    fprintf('  Tubular - Energy Density: %.3f kWh/m^3, Charging Time: %.3f min\n', rho_energy_tub(i), chg_tub_target(i));
    fprintf('  Cylinder - Energy Density: %.3f kWh/m^3, Charging Time: %.3f min\n', rho_energy_cyl(i), chg_cyl_target(i));
end

%% 중간 데이터 저장을 위한 디렉토리 설정
save_dir = 'C:\Users\user\Desktop\Figure\Figure 4\중간 데이터';
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

%% 중간 데이터 그룹화
% 1. Original Data
OrigData.tub = tub;
OrigData.cyl = cyl;

% 2. Rate and D_out Vectors
RateDout.C_tub = C_tub;
RateDout.D_tub = D_tub;
RateDout.C_cyl = C_cyl;
RateDout.D_cyl = D_cyl;

% 3. Merged Coordinates
MergeCoord.min_y_tub = min_y_tub_coord;
MergeCoord.min_y_cyl = min_y_cyl_coord;

% 4. Charging Time
ChgTime.chg_tub = chg_tub_coord;
ChgTime.chg_cyl = chg_cyl_coord;

% 5. Apparent Energy Density
AEnergy.rho_tub = rho_tub;
AEnergy.rho_cyl = rho_cyl;

% 6. Interpolated Markers
Markers.m_int = m_int;
Markers.x_tub = x_tub;
Markers.y_tub = y_tub;
Markers.x_cyl = x_cyl;
Markers.y_cyl = y_cyl;
Markers.x_rho = x_rho;
Markers.rho_tub_interp = rho_tub_interp;
Markers.rho_cyl_interp = rho_cyl_interp;

%% 전체 중간 데이터 저장 (구조체로 그룹화)
IntermediateData = struct(...
    'OrigData', OrigData, ...
    'RateDout', RateDout, ...
    'MergeCoord', MergeCoord, ...
    'ChgTime', ChgTime, ...
    'AEnergy', AEnergy, ...
    'Markers', Markers ...
);

save(fullfile(save_dir, 'fig4a_inter.mat'), 'IntermediateData');

load(fullfile(save_dir, 'fig4a_inter.mat'));
