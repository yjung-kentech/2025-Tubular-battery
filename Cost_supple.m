clear; clc; close all;
import com.comsol.model.*
import com.comsol.model.util.*
%% -------------------------------------------------------------
% 1. 기본 설정
% --------------------------------------------------------------
COM_filepath  = 'C:\Users\user\Desktop\Tubular battery 최종';
COM_tube    = 'JYR_cell_0522.mph';
% --- 수정된 부분: R_vec -> D_vec 으로 변경 및 값 수정 ---
D_out_vec = (5:1:40) * 2;   % [mm], D_out = 10:2:80
D_in_vec  = (0:0.5:10) * 2; % [mm], D_in  = 2:1:20
% 재료비 단가 정의
cost_unit.p_active   = 26.00; % [$/kg]
cost_unit.p_carbon   = 7.00;  % [$/kg]
cost_unit.p_binder   = 15.00; % [$/kg]
cost_unit.n_active   = 10.00; % [$/kg]
cost_unit.n_binder   = 10.00; % [$/kg]
cost_unit.al_foil    = 0.20;  % [$/m^2]
cost_unit.cu_foil    = 1.20;  % [$/m^2]
cost_unit.separator  = 0.90;  % [$/m^2]
cost_unit.electrolyte= 10.00; % [$/L]
% 에너지 비용 계산을 위한 상수 정의
C_const = 0.5; % [$], 기타 비용(조립, BOP 등)
Energy_density_volumetric = 813.1; % [kWh/m^3], 젤리롤 부피당 에너지 밀도
%% -------------------------------------------------------------
% 2. 필요한 파라미터 목록
% --------------------------------------------------------------
plist = { ...
    'n_epsilon','p_epsilon','s_epsilon', 'n_delta','p_delta','s_delta', ...
    'n_rho','p_rho','s_rho','e_rho', 'n_am1_rho','n_binder_rho', ...
    'p_am1_rho','p_ca_rho','p_pvdf_rho', 'n_am1_vf','n_binder_vf', ...
    'p_am1_vf','p_ca_vf','p_pvdf_vf', 'delta_cu', 'rho_cu', ...
    'delta_al', 'rho_al', 'h_jr'};
%% -------------------------------------------------------------
% 3. 튜블러 셀 모델 열기
% --------------------------------------------------------------
disp('Loading Tubular cell model...');
model_tube = mphload(fullfile(COM_filepath, COM_tube));
par = struct();
for k = 1:numel(plist)
    par.(plist{k}) = mphevaluate(model_tube, plist{k});
end
%% -------------------------------------------------------------
% 4. 2D 스윕 계산
% --------------------------------------------------------------
disp('Sweeping over D_out and D_in range...');
% --- 수정된 부분: R -> D로 변수명 변경 ---
num_D_out = length(D_out_vec); num_D_in  = length(D_in_vec);
prop_mass_kg = struct(); prop_area_m2 = struct(); cost = struct();
prop_volume_L.electrolyte_tubular = nan(num_D_out, num_D_in);
prop_volume_L.electrolyte_cylindrical = nan(num_D_out, num_D_in);
prop_volume_m3.V_jr = nan(num_D_out, num_D_in);
cost.cost_per_kWh_tubular = nan(num_D_out, num_D_in);
cost.cost_per_kWh_cylindrical = nan(num_D_out, num_D_in);
cost.total_cost_tubular = nan(num_D_out, num_D_in);
cost.total_cost_cylindrical = nan(num_D_out, num_D_in);

% --- 수정된 부분: 루프 변수를 D로 변경 ---
for i = 1:num_D_out
    D_out = D_out_vec(i);
    for j = 1:num_D_in
        D_in = D_in_vec(j);
        
        % --- 수정된 부분: 지름 비교 조건 ---
        if D_in >= D_out, continue; end
        
        % --- 수정된 부분: 함수에 전달하기 위해 R값 계산 ---
        R_out = D_out / 2;
        R_in = D_in / 2;
        
        prop_tub = batteryPropertiesModel(R_out, R_in, par, 'tubular');
        prop_cyl = batteryPropertiesModel(R_out, R_in, par, 'cylindrical');
        
        prop_mass_kg.anode_active(i,j)   = prop_tub.mass_kg.anode_active;
        prop_mass_kg.anode_binder(i,j)   = prop_tub.mass_kg.anode_binder;
        prop_mass_kg.cathode_active(i,j) = prop_tub.mass_kg.cathode_active;
        prop_mass_kg.cathode_binder(i,j) = prop_tub.mass_kg.cathode_binder;
        prop_mass_kg.cathode_carbon(i,j) = prop_tub.mass_kg.cathode_carbon;
        prop_area_m2.components(i,j)     = prop_tub.area_m2;
        prop_volume_L.electrolyte_tubular(i,j) = prop_tub.volume_L.electrolyte;
        prop_volume_L.electrolyte_cylindrical(i,j) = prop_cyl.volume_L.electrolyte;
        prop_volume_m3.V_jr(i,j) = prop_tub.V_jr_m3;
        
        cost.anode_active(i,j)   = prop_tub.mass_kg.anode_active * cost_unit.n_active;
        cost.anode_binder(i,j)   = prop_tub.mass_kg.anode_binder * cost_unit.n_binder;
        cost.cathode_active(i,j) = prop_tub.mass_kg.cathode_active * cost_unit.p_active;
        cost.cathode_binder(i,j) = prop_tub.mass_kg.cathode_binder * cost_unit.p_binder;
        cost.cathode_carbon(i,j) = prop_tub.mass_kg.cathode_carbon * cost_unit.p_carbon;
        cost.separator(i,j)      = prop_tub.area_m2 * cost_unit.separator;
        cost.cu_foil(i,j)        = prop_tub.area_m2 * cost_unit.cu_foil;
        cost.al_foil(i,j)        = prop_tub.area_m2 * cost_unit.al_foil;
        cost.electrolyte_tubular(i,j) = prop_tub.volume_L.electrolyte * cost_unit.electrolyte;
        cost.electrolyte_cylindrical(i,j) = prop_cyl.volume_L.electrolyte * cost_unit.electrolyte;
        
        common_sum = cost.anode_active(i,j) + cost.anode_binder(i,j) + cost.cathode_active(i,j) + cost.cathode_binder(i,j) + cost.cathode_carbon(i,j) + cost.separator(i,j) + cost.cu_foil(i,j) + cost.al_foil(i,j);
                              
        cost.total_cost_tubular(i,j) = common_sum + cost.electrolyte_tubular(i,j);
        cost.total_cost_cylindrical(i,j) = common_sum + cost.electrolyte_cylindrical(i,j);
        
        V_jr_m3 = prop_volume_m3.V_jr(i,j);
        E_cell_kWh = Energy_density_volumetric * V_jr_m3;
        
        C_cell_tub_total = cost.total_cost_tubular(i,j) + C_const;
        cost.cost_per_kWh_tubular(i,j) = C_cell_tub_total / E_cell_kWh;
        
        C_cell_cyl_total = cost.total_cost_cylindrical(i,j) + C_const;
        cost.cost_per_kWh_cylindrical(i,j) = C_cell_cyl_total / E_cell_kWh;
        
    end
end
disp('Sweeping complete');
%% -------------------------------------------------------------
% 5. 결과 저장
% --------------------------------------------------------------
savename = sprintf('Cost_new.mat');
savepath = fullfile('C:\Users\user\Desktop\Figure\Cost Model\mat 파일', savename);
% --- 수정: prop_energy_kWh 제거 ---
save(savepath, 'D_out_vec', 'D_in_vec', 'prop_mass_kg', 'prop_area_m2', 'prop_volume_L', 'prop_volume_m3', 'cost', 'cost_unit', 'C_const');
fprintf('모든 분석 결과가 %s 에 저장되었습니다.\n', savepath);
%% -------------------------------------------------------------
% 6. 등고선 플롯
% --------------------------------------------------------------

% --- 스무딩 커널 크기 정의 ---
% 이 값을 조절하여 스무딩 강도를 변경할 수 있습니다. (예: [5 5])
smoothing_kernel = [3 3];

% 6.1 물리량(질량/면적/부피) 플롯
h_fig_phys = figure('Name', 'Physical Properties Breakdown', 'Position', [50, 50, 1000, 900]);
fields_physical = {'anode_active','anode_binder','cathode_active','cathode_binder', 'cathode_carbon','separator', 'cu_foil','al_foil', 'electrolyte_tubular', 'electrolyte_cylindrical'};
for k = 1:numel(fields_physical)
    field_name = fields_physical{k};
    subplot(4, 3, k);

    % --- [수정] 제목 생성 로직 변경 ---
    % 1. _tubular, _cylindrical을 먼저 괄호 형식으로 변경
    plot_title = strrep(field_name, '_tubular', ' (Tubular)');
    plot_title = strrep(plot_title, '_cylindrical', ' (Cylindrical)');
    % 2. 나머지 _ (예: anode_active)는 공백으로 변경
    plot_title = strrep(plot_title, '_', ' ');
    % 3. 첫 글자 대문자화
    plot_title(1) = upper(plot_title(1));
    % ---------------------------------

    switch field_name
        case {'separator', 'cu_foil', 'al_foil'}
            data_to_plot = prop_area_m2.components; unit_str = 'm^2';
        case {'electrolyte_tubular', 'electrolyte_cylindrical'}
            data_to_plot = prop_volume_L.(field_name); unit_str = 'L';
        otherwise
            data_to_plot = prop_mass_kg.(field_name) * 1000; unit_str = 'g';
    end
    
    % --- [수정] NaN 경계 스무딩 처리 ---
    % 'omitnan' 옵션으로 NaN 값은 제외하고 유효한 데이터만 스무딩합니다.
    data_to_plot_smooth = smoothdata(data_to_plot, 'gaussian', smoothing_kernel, 'omitnan');
    
    % --- 수정된 부분: 스무딩된 데이터로 플롯 ---
    contourf(D_in_vec, D_out_vec, data_to_plot_smooth, 20, 'LineStyle', 'none');
    
    % --- 수정된 부분: patch 좌표를 D_vec 기준으로 변경 ---
    x_patch = [max(D_in_vec), min(D_out_vec), max(D_in_vec)];
    y_patch = [min(D_out_vec), min(D_out_vec), max(D_in_vec)];
    patch(x_patch, y_patch, 'white', 'EdgeColor', 'none');
    set(gca, 'YDir', 'normal'); 
    % --- 수정된 부분: 축 라벨을 D로 변경 ---
    xlabel('D_{jr,in} [mm]', 'FontSize', 9); ylabel('D_{jr,out} [mm]', 'FontSize', 9);
    h = colorbar; ylabel(h, sprintf('%s [%s]', plot_title, unit_str), 'FontSize', 10);
    % --- 수정된 부분: 라벨 위치 조정 ---
    label_char = sprintf('%c', char(96 + k));
    text(-0.29, 1.09, label_char, 'Units', 'normalized', 'FontSize', 13, 'FontWeight', 'bold');
end

% 6.2 비용(Cost) 플롯
h_fig_cost = figure('Name', 'Cost Breakdown', 'Position', [100, 100, 1000, 900]);
fields_cost_plot = {'anode_active','anode_binder','cathode_active','cathode_binder',...
                    'cathode_carbon', 'separator','cu_foil','al_foil',...
                    'electrolyte_tubular','electrolyte_cylindrical'}; % removed total_cost

for k = 1:numel(fields_cost_plot)
    field_name = fields_cost_plot{k};
    subplot(4, 3, k);

    % --- [수정] 제목 생성 로직 변경 ---
    plot_title = strrep(field_name, '_tubular', ' (Tubular)');
    plot_title = strrep(plot_title, '_cylindrical', ' (Cylindrical)');
    plot_title = strrep(plot_title, '_', ' ');
    plot_title(1) = upper(plot_title(1));
    % ---------------------------------

    data_to_plot = cost.(field_name);
    
    % --- [수정] NaN 경계 스무딩 처리 ---
    data_to_plot_smooth = smoothdata(data_to_plot, 'gaussian', smoothing_kernel, 'omitnan');
    
    % --- 수정된 부분: 스무딩된 데이터로 플롯 ---
    contourf(D_in_vec, D_out_vec, data_to_plot_smooth, 20, 'LineStyle', 'none');
    
    % --- 수정된 부분: patch 좌표를 D_vec 기준으로 변경 ---
    x_patch = [max(D_in_vec), min(D_out_vec), max(D_in_vec)];
    y_patch = [min(D_out_vec), min(D_out_vec), max(D_in_vec)];
    patch(x_patch, y_patch, 'white', 'EdgeColor', 'none');
    set(gca, 'YDir', 'normal'); 
    % --- 수정된 부분: 축 라벨을 D로 변경 ---
    xlabel('D_{jr,in} [mm]', 'FontSize', 9); ylabel('D_{jr,out} [mm]', 'FontSize', 9);
    h = colorbar; ylabel(h, sprintf('%s [$]', plot_title), 'FontSize', 10);
    % --- 수정된 부분: 라벨 위치 조정 ---
    label_char = sprintf('%c', char(96 + k));
    text(-0.29, 1.09, label_char, 'Units', 'normalized', 'FontSize', 13, 'FontWeight', 'bold');
end

%% -------------------------------------------------------------
% 6.3. 종합 비용 및 에너지 플롯 (2x2)
% --------------------------------------------------------------
% --- 수정: Figure 이름, Position 변경 ---
h_fig_combined_2x2 = figure('Name', 'Combined Cost and Energy Analysis', 'Position', [100, 100, 1000, 700]);
num_levels = 400; % 등고선 레벨 수는 유지합니다.
% --- Color definitions ---
color_tubular_line = '#0073C2'; % Blue
color_cylindrical_line = '#CD534C'; % Red
color_46_line = '#EFC000'; % Yellow
color_60_line = '#925E9F'; % Purple
color_80_line = '#20854E'; % Green

% --- [신규] c, d 플롯을 위한 작은 스무딩 커널 정의 ---
% 아주 작은 커널 ([1 1])을 사용하여 데이터는 최소한으로만 스무딩하고
% 경계선은 patch로 덮는 방식을 시도합니다.
smoothing_kernel_small = [1 1]; 

% --- patch를 그리기 위한 좌표 (D_in >= D_out 영역) ---
x_patch = [max(D_in_vec), min(D_out_vec), max(D_in_vec)];
y_patch = [min(D_out_vec), min(D_out_vec), max(D_in_vec)];

% --- (a) Total Cost Cylindrical (Subplot 2, 2, 1) ---
axes('Position', [0.11, 0.59, 0.34, 0.33]);
data_to_plot_a = cost.total_cost_cylindrical;

% --- smoothdata 적용 ---
data_to_plot_a_smooth = smoothdata(data_to_plot_a, 'gaussian', smoothing_kernel, 'omitnan'); % 기존 smoothing_kernel 사용
contourf(D_in_vec, D_out_vec, data_to_plot_a_smooth, 20, 'LineStyle', 'none');

patch(x_patch, y_patch, 'white', 'EdgeColor', 'none');
set(gca, 'YDir', 'normal'); 
xlabel('D_{jr,in} [mm]', 'FontSize', 14); ylabel('D_{jr,out} [mm]', 'FontSize', 13);
h = colorbar; ylabel(h, 'Cell cost (Cylindrical) [$]', 'FontSize', 14);
h.FontSize = 12;
text(-0.2, 1.1, 'a', 'Units', 'normalized', 'FontSize', 16, 'FontWeight', 'bold');
set(gca, 'FontSize', 12);
xlim([0, 20]); ylim([10, 80]);

% --- (b) Total Cost Tubular (Subplot 2, 2, 2) ---
axes('Position', [0.57, 0.59, 0.34, 0.33]); 
data_to_plot_b = cost.total_cost_tubular;

% --- smoothdata 적용 ---
data_to_plot_b_smooth = smoothdata(data_to_plot_b, 'gaussian', smoothing_kernel, 'omitnan'); % 기존 smoothing_kernel 사용
contourf(D_in_vec, D_out_vec, data_to_plot_b_smooth, 20, 'LineStyle', 'none');

patch(x_patch, y_patch, 'white', 'EdgeColor', 'none');
set(gca, 'YDir', 'normal'); 
xlabel('D_{jr,in} [mm]', 'FontSize', 14); ylabel('D_{jr,out} [mm]', 'FontSize', 13);
h = colorbar; ylabel(h, 'Cell cost (Tubular) [$]', 'FontSize', 14);
h.FontSize = 12;
text(-0.2, 1.1, 'b', 'Units', 'normalized', 'FontSize', 16, 'FontWeight', 'bold');
set(gca, 'FontSize', 12);
xlim([0, 20]); ylim([10, 80]);

% --- (c) Cylindrical Cell Cost [$/kWh] ---
axes('Position', [0.11, 0.12, 0.34, 0.33]); 

data_to_plot_c = cost.cost_per_kWh_cylindrical;
% --- [수정] 작은 스무딩 커널 적용 ---
data_to_plot_c_smooth = smoothdata(data_to_plot_c, 'gaussian', smoothing_kernel_small, 'omitnan');
contourf(D_in_vec, D_out_vec, data_to_plot_c_smooth, num_levels, 'LineStyle', 'none');

patch(x_patch, y_patch, 'white', 'EdgeColor', 'none');
set(gca, 'YDir', 'normal');
xlabel('D_{jr,in} [mm]', 'FontSize', 14); ylabel('D_{jr,out} [mm]', 'FontSize', 13);
h = colorbar; ylabel(h, 'Cost per kWh (Cylindrical) [$/kWh]', 'FontSize', 14);
h.FontSize = 12;
caxis([70 200]);
text(-0.2, 1.1, 'c', 'Units', 'normalized', 'FontSize', 16, 'FontWeight', 'bold');
set(gca, 'FontSize', 12);
hold on;
% --- Design Lines for Cylindrical ---
Dout_line = linspace(min(D_out_vec), max(D_out_vec), 400);
Din_line_cyl = zeros(size(Dout_line));
for k = 1:length(Dout_line)
    if Dout_line(k) <= 18
        Din_line_cyl(k) = 2;
    elseif Dout_line(k) < 46
        Din_line_cyl(k) = 2 + (Dout_line(k)-18)*(4-2)/(46-18);
    else
        Din_line_cyl(k) = 4;
    end
end
plot(Din_line_cyl, Dout_line, '-', 'Color', color_cylindrical_line, 'LineWidth', 2);
highlight_points = [46, 60, 80];
highlight_colors = {color_46_line, color_60_line, color_80_line}; % Yellow, Purple, Green
for i = 1:length(highlight_points)
    val = highlight_points(i);
    Din_val = interp1(Dout_line, Din_line_cyl, val);
    plot(Din_val, val, 's', 'MarkerEdgeColor', highlight_colors{i}, ...
         'MarkerFaceColor', highlight_colors{i}, 'MarkerSize', 7);
end
xlim([0, 20]); ylim([10, 80]);
hold off;

% --- (d) Tubular Cell Cost [$/kWh] (Subplot 2, 2, 4) ---
axes('Position', [0.57, 0.12, 0.34, 0.33]);

data_to_plot_d = cost.cost_per_kWh_tubular;
% --- [수정] 작은 스무딩 커널 적용 ---
data_to_plot_d_smooth = smoothdata(data_to_plot_d, 'gaussian', smoothing_kernel_small, 'omitnan');
contourf(D_in_vec, D_out_vec, data_to_plot_d_smooth, num_levels, 'LineStyle', 'none');

patch(x_patch, y_patch, 'white', 'EdgeColor', 'none');
set(gca, 'YDir', 'normal');
xlabel('D_{jr,in} [mm]', 'FontSize', 14); ylabel('D_{jr,out} [mm]', 'FontSize', 13);
h = colorbar; ylabel(h, 'Cost per kWh (Tubular) [$/kWh]', 'FontSize', 14);
h.FontSize = 12;
caxis([70 200]);
text(-0.2, 1.1, 'd', 'Units', 'normalized', 'FontSize', 16, 'FontWeight', 'bold');
set(gca, 'FontSize', 12);
hold on;
% --- Design Lines for Tubular ---
Dout_line = linspace(min(D_out_vec), max(D_out_vec), 200);
Din_line_tub = ones(size(Dout_line)) * 6; % constant 6 mm
plot(Din_line_tub, Dout_line, '-', 'Color', color_tubular_line, 'LineWidth', 2);
Dout_lines_tub = [46, 60, 80];
line_colors = {color_46_line, color_60_line, color_80_line}; % Yellow, Purple, Green
marker_interval = 2; % 2mm 간격
for i = 1:length(Dout_lines_tub)
    y = Dout_lines_tub(i);
    x_start = 4;
    x_end = max(D_in_vec); 
    plot([x_start, x_end], [y y], '-', 'Color', line_colors{i}, 'LineWidth', 2);
    marker_x = x_start:marker_interval:x_end;
    marker_y = ones(size(marker_x)) * y;
    plot(marker_x, marker_y, 's', 'MarkerEdgeColor', line_colors{i}, ...
         'MarkerFaceColor', 'none', 'MarkerSize', 7, 'LineWidth', 1.5);
end
xlim([0, 20]); ylim([10, 80]);
hold off;

%% -------------------------------------------------------------
% 7. 결과 그림 파일로 저장
% --------------------------------------------------------------
% ... (이후 코드는 동일) ...
% --------------------------------------------------------------
disp('Saving figures as PNG files...');
save_dir_png = 'C:\Users\user\Desktop\Figure\Cost Model\png 파일';
if ~exist(save_dir_png, 'dir')
   mkdir(save_dir_png);
   fprintf('PNG 저장 폴더를 생성했습니다: %s\n', save_dir_png);
end
filename_phys = '부품별_물리량_분포.png';
savepath_phys = fullfile(save_dir_png, filename_phys);
exportgraphics(h_fig_phys, savepath_phys, 'Resolution', 300);
fprintf('물리량 분포 그림이 %s 에 저장되었습니다.\n', savepath_phys);
filename_cost = '부품별_비용_분포.png';
savepath_cost = fullfile(save_dir_png, filename_cost);
exportgraphics(h_fig_cost, savepath_cost, 'Resolution', 300);
fprintf('비용 분포 그림이 %s 에 저장되었습니다.\n', savepath_cost);
% --- 수정: 3x2 -> 2x2로 파일 이름 및 변수명 변경 ---
filename_combined_2x2 = '종합_비용_및_에너지_분석_2x2.png';
savepath_combined_2x2 = fullfile(save_dir_png, filename_combined_2x2);
exportgraphics(h_fig_combined_2x2, savepath_combined_2x2, 'Resolution', 300);
fprintf('종합 분석(2x2) 그림이 %s 에 저장되었습니다.\n', savepath_combined_2x2);
disp('All figures have been saved successfully.');

% --- (Local Function은 이전과 동일) ---
%% =============================================================
%      batteryPropertiesModel  (local function)
% =================================A============================
function prop = batteryPropertiesModel(R_out_mm, R_in_mm, par, cellType)
    R_out_m=R_out_mm*1e-3; R_in_m=R_in_mm*1e-3;
    delta_tl=par.n_delta+par.s_delta+par.p_delta+0.5*par.delta_cu+0.5*par.delta_al;
    L_jr=pi*(R_out_m^2-R_in_m^2)/delta_tl;
    H_jr=(15/14*R_out_mm+55.5-2*par.h_jr)*1e-3;
    A_jr=L_jr*H_jr;
    
    prop.V_jr_m3 = pi * (R_out_m^2 - R_in_m^2) * H_jr;
    
    prop.area_m2 = A_jr;
    prop.mass_kg.anode_active = (1-par.n_epsilon)*par.n_delta*par.n_am1_rho*par.n_am1_vf * A_jr;
    prop.mass_kg.anode_binder = (1-par.n_epsilon)*par.n_delta*par.n_binder_rho*par.n_binder_vf * A_jr;
    prop.mass_kg.cathode_active = (1-par.p_epsilon)*par.p_delta*par.p_am1_rho*par.p_am1_vf * A_jr;
    prop.mass_kg.cathode_carbon = (1-par.p_epsilon)*par.p_delta*par.p_ca_rho*par.p_ca_vf * A_jr;
    prop.mass_kg.cathode_binder = (1-par.p_epsilon)*par.p_delta*par.p_pvdf_rho*par.p_pvdf_vf * A_jr;
    
    vol_core_m3 = (par.s_epsilon*par.s_delta + par.n_epsilon*par.n_delta + par.p_epsilon*par.p_delta) * A_jr;
    
    total_vol_m3 = 0;
    switch lower(cellType)
        case 'tubular'
            vol_cap_m3  = pi * (R_out_m^2 - R_in_m^2) * (2 * par.h_jr * 1e-3);
            total_vol_m3 = vol_core_m3 + vol_cap_m3;
        case 'cylindrical'
            vol_cap_m3 = pi * (R_out_m^2) * (2 * par.h_jr * 1e-3);
            vol_center_m3 = pi * (R_in_m^2) * H_jr;
            total_vol_m3 = vol_core_m3 + vol_cap_m3 + vol_center_m3;
    end
    prop.volume_L.electrolyte = total_vol_m3 * 1000;
end