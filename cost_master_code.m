clear; clc; close all;
import com.comsol.model.*
import com.comsol.model.util.*

%% ========================================================================
%  [SECTION 1] 기본 설정 및 모델/데이터 로드
% =========================================================================
disp('Section 1: 기본 설정 및 모델/데이터 로드 시작...');

% --- 파일 경로 및 파라미터 벡터 정의 ---
COM_filepath = 'C:\Users\user\Desktop\Tubular battery 최종';
COM_model_file = 'JYR_cell_0522.mph'; % c_cell, rho_E 계산용 모델
Sweep_data_dir = 'C:\Users\user\Desktop\Figure\Sweep\mat 파일'; % t_chg 계산용 데이터

D_out_vec = (5:1:40) * 2;   % [mm], 10:2:80
D_in_vec  = (1:0.5:10) * 2; % [mm], 2:1:20
D_out_const_vec = [46, 60, 80]; % Figure e, f용 고정 D_out 값

% --- 비용 관련 상수 ---
cost_unit.p_active=26.00; cost_unit.p_carbon=7.00; cost_unit.p_binder=15.00;
cost_unit.n_active=10.00; cost_unit.n_binder=10.00; cost_unit.al_foil=0.20;
cost_unit.cu_foil=1.20; cost_unit.separator=0.90; cost_unit.electrolyte=10.00;
C_const = 0.5; Energy_density_volumetric = 813.1;

% --- COMSOL 모델 로드 및 파라미터 추출 ---
model = mphload(fullfile(COM_filepath, COM_model_file));
plist = {'n_epsilon','p_epsilon','s_epsilon','n_delta','p_delta','s_delta','n_rho','p_rho','s_rho','e_rho','n_am1_rho','n_binder_rho','p_am1_rho','p_ca_rho','p_pvdf_rho','n_am1_vf','n_binder_vf','p_am1_vf','p_ca_vf','p_pvdf_vf','delta_cu','rho_cu','delta_al','rho_al','h_jr'};
par = struct();
for k = 1:numel(plist), par.(plist{k}) = mphevaluate(model, plist{k}); end
disp('Section 1 완료.');

%% ========================================================================
%  [SECTION 2] t_chg(충전 시간) 계산 (D_out의 함수)
% =========================================================================
disp('Section 2: 충전 시간(t_chg) 계산 시작...');
load(fullfile(Sweep_data_dir, 'Tubular_Sweep_Crate_Rout.mat'));   tub_sweep = data;
load(fullfile(Sweep_data_dir, 'Cylinder_Sweep_Crate_Rout.mat'));  cyl_sweep = data;

Elpcut    = 0;
T_allowed = 45;

% --- (2.1) Tubular t95 추출 ---
% --- 수정: 데이터 행렬의 전치(') 제거 ---
M_Elp_tub = contourc(2*tub_sweep.R_out, tub_sweep.C_rate, tub_sweep.Elp_min, [Elpcut, Elpcut]);
M_Tmax_tub = contourc(2*tub_sweep.R_out, tub_sweep.C_rate, tub_sweep.T_max, [T_allowed, T_allowed]);
all_x_tub = unique([M_Elp_tub(1,2:end), M_Tmax_tub(1,2:end)]);
min_y_tub = arrayfun(@(x) min([interp1(M_Elp_tub(1,2:end), M_Elp_tub(2,2:end), x, 'linear', inf), ...
                               interp1(M_Tmax_tub(1,2:end), M_Tmax_tub(2,2:end), x, 'linear', inf)]), all_x_tub);
charging_time_tub = interp2(2*tub_sweep.R_out, tub_sweep.C_rate, tub_sweep.t95, all_x_tub, min_y_tub, 'linear');
charging_time_coordinates.tub = [all_x_tub; charging_time_tub];

% --- (2.2) Cylinder t95 추출 ---
% --- 수정: 데이터 행렬의 전치(') 제거 ---
M_Elp_cyl = contourc(2*cyl_sweep.R_out, cyl_sweep.C_rate, cyl_sweep.Elp_min, [Elpcut, Elpcut]);
M_Tmax_cyl = contourc(2*cyl_sweep.R_out, cyl_sweep.C_rate, cyl_sweep.T_max, [Elpcut, T_allowed]);
all_x_cyl = unique([M_Elp_cyl(1,2:end), M_Tmax_cyl(1,2:end)]);
min_y_cyl = arrayfun(@(x) min([interp1(M_Elp_cyl(1,2:end), M_Elp_cyl(2,2:end), x, 'linear', inf), ...
                               interp1(M_Tmax_cyl(1,2:end), M_Tmax_cyl(2,2:end), x, 'linear', inf)]), all_x_cyl);
charging_time_cyl = interp2(2*cyl_sweep.R_out, cyl_sweep.C_rate, cyl_sweep.t95, all_x_cyl, min_y_cyl, 'linear');
charging_time_coordinates.cyl = [all_x_cyl; charging_time_cyl];

% --- D_out_vec에 맞게 보간하여 1D 벡터 생성 ---
t_chg_tub_vec = interp1(all_x_tub, charging_time_tub, D_out_vec, 'linear', 'extrap');
t_chg_cyl_vec = interp1(all_x_cyl, charging_time_cyl, D_out_vec, 'linear', 'extrap');
disp('Section 2 완료.');

%% ========================================================================
%  [SECTION 3] 2D 전체 계산 (c_cell, rho_E)
% =========================================================================
disp('Section 3: c_cell 및 rho_E 2D 매트릭스 계산 시작 (시간이 걸릴 수 있습니다)...');
num_D_out = length(D_out_vec); num_D_in = length(D_in_vec);
% 결과를 저장할 2차원 행렬 초기화
c_cell_tub_matrix = nan(num_D_out, num_D_in);
c_cell_cyl_matrix = nan(num_D_out, num_D_in);
rho_E_tub_matrix  = nan(num_D_out, num_D_in);
rho_E_cyl_matrix  = nan(num_D_out, num_D_in);

for i = 1:num_D_out
    for j = 1:num_D_in
        D_out = D_out_vec(i); D_in = D_in_vec(j);
        if D_in >= D_out, continue; end
        R_out = D_out / 2; R_in = D_in / 2;
        
        % --- c_cell 계산 ---
        prop_tub = batteryPropertiesModel(R_out, R_in, par, 'tubular');
        prop_cyl = batteryPropertiesModel(R_out, R_in, par, 'cylindrical');
        common_sum = (prop_tub.mass_kg.anode_active*cost_unit.n_active) + (prop_tub.mass_kg.anode_binder*cost_unit.n_binder) + (prop_tub.mass_kg.cathode_active*cost_unit.p_active) + (prop_tub.mass_kg.cathode_binder*cost_unit.p_binder) + (prop_tub.mass_kg.cathode_carbon*cost_unit.p_carbon) + (prop_tub.area_m2*cost_unit.separator) + (prop_tub.area_m2*cost_unit.cu_foil) + (prop_tub.area_m2*cost_unit.al_foil);
        total_cost_tub = common_sum + (prop_tub.volume_L.electrolyte * cost_unit.electrolyte);
        total_cost_cyl = common_sum + (prop_cyl.volume_L.electrolyte * cost_unit.electrolyte);
        E_cell_kWh_tub = Energy_density_volumetric * prop_tub.V_jr_m3;
        E_cell_kWh_cyl = Energy_density_volumetric * prop_cyl.V_jr_m3;
        c_cell_tub_matrix(i, j) = (total_cost_tub + C_const) / E_cell_kWh_tub;
        c_cell_cyl_matrix(i, j) = (total_cost_cyl + C_const) / E_cell_kWh_cyl;
        
        % --- rho_E 계산 (COMSOL 연동) ---
        % rho_E는 D_in의 영향이 미미하지만, 정확도를 위해 두 파라미터 모두 설정
        model.param.set('R_out', [num2str(R_out) '[mm]']);
        model.param.set('R_in', [num2str(R_in) '[mm]']); % D_in 영향도 반영
        rho_E_tub_matrix(i, j) = model.param.evaluate('rho_app*2.7778e-7');
        rho_E_cyl_matrix(i, j) = model.param.evaluate('rho_app_cylin*2.7778e-7');
    end
    fprintf('2D 계산 진행 중: D_out = %d mm (%.1f%%)\n', D_out_vec(i), i/num_D_out*100);
end
disp('Section 3 완료.');

%% ========================================================================
%  [SECTION 4] 각 Figure에 필요한 데이터 추출 및 구조화 (수정된 버전)
% =========================================================================
disp('Section 4: 각 Figure용 데이터 추출 및 구조화 시작...');
MasterData = struct();

% --- Figure (b)와 (c)는 동일한 조건의 데이터를 사용하므로 함께 추출 ---
idx_Din_tub_6mm = find(D_in_vec == 6);
c_cell_tub_for_figs = c_cell_tub_matrix(:, idx_Din_tub_6mm);
rho_E_tub_for_figs = rho_E_tub_matrix(:, idx_Din_tub_6mm);

c_cell_cyl_for_figs = zeros(num_D_out, 1);
rho_E_cyl_for_figs = zeros(num_D_out, 1);
for i = 1:num_D_out
    R_out_mm = D_out_vec(i) / 2;
    if R_out_mm <= 9, R_in_cyl_mm = 1; elseif R_out_mm <= 23, R_in_cyl_mm = 1+(R_out_mm-9)/14; else, R_in_cyl_mm = 2; end
    [~, idx_Din_cyl] = min(abs(D_in_vec - (R_in_cyl_mm * 2)));
    c_cell_cyl_for_figs(i) = c_cell_cyl_matrix(i, idx_Din_cyl);
    rho_E_cyl_for_figs(i) = rho_E_cyl_matrix(i, idx_Din_cyl);
end

% --- Figure (b)용 데이터 저장 ---
MasterData.fig_b.D_out_vec = D_out_vec;
MasterData.fig_b.c_cell_tub = c_cell_tub_for_figs;
MasterData.fig_b.c_cell_cyl = c_cell_cyl_for_figs;

% --- Figure (c)용 데이터 저장 (c_cell 데이터 추가) ---
MasterData.fig_c.D_out_vec = D_out_vec;
MasterData.fig_c.t_chg_tub = t_chg_tub_vec;
MasterData.fig_c.t_chg_cyl = t_chg_cyl_vec;
MasterData.fig_c.rho_E_tub = rho_E_tub_for_figs;
MasterData.fig_c.rho_E_cyl = rho_E_cyl_for_figs;
MasterData.fig_c.c_cell_tub = c_cell_tub_for_figs; % <-- 이 라인이 추가되었습니다.
MasterData.fig_c.c_cell_cyl = c_cell_cyl_for_figs; % <-- 이 라인이 추가되었습니다.

% --- Figure (e), (f)용 데이터 (기존과 동일) ---
MasterData.fig_e.D_in_vec = D_in_vec;
for d_val = D_out_const_vec
    [~, idx] = min(abs(D_out_vec - d_val));
    MasterData.fig_e.(['c_cell_tub_' num2str(d_val) 'mm']) = c_cell_tub_matrix(idx, :);
    MasterData.fig_e.(['c_cell_cyl_' num2str(d_val) 'mm']) = c_cell_cyl_matrix(idx, :);
    MasterData.fig_f.(['rho_E_tub_' num2str(d_val) 'mm']) = rho_E_tub_matrix(idx, :);
    MasterData.fig_f.(['rho_E_cyl_' num2str(d_val) 'mm']) = rho_E_cyl_matrix(idx, :);
    MasterData.fig_f.(['t_chg_tub_' num2str(d_val) 'mm']) = t_chg_tub_vec(idx);
    MasterData.fig_f.(['t_chg_cyl_' num2str(d_val) 'mm']) = t_chg_cyl_vec(idx);
end
disp('Section 4 완료.');

%% ========================================================================
%  [SECTION 5] 최종 마스터 데이터 파일 저장
% =========================================================================
save_dir = 'C:\Users\user\Desktop\Figure\Cost Model\mat 파일';
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
save(fullfile(save_dir, 'Cost_Master.mat'), 'MasterData');
disp(['마스터 데이터 파일 저장 완료: ' fullfile(save_dir, 'Cost_Master.mat')]);

%% ========================================================================
%  Local Function: batteryPropertiesModel (기존과 동일)
% =========================================================================
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