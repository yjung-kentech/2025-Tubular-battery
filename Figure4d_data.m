%% 중간 데이터 로드
save_dir = 'C:\Users\user\Desktop\Figure\Figure 4\중간 데이터';
load(fullfile(save_dir, 'fig4d_inter.mat')); % 저장된 데이터 불러오기

%% D_out = 46 mm에서 D_in = 4~10 mm일 때 Charging Time & Energy Density 계산

D_out_target = 46;  % 외경 D_out = 46 mm
D_in_targets = [4, 5, 6, 7, 8, 9, 10]; % 원하는 내부 지름 D_in 값 (mm)

% -------------------------------
% Charging Time (Tubular)
% -------------------------------
charging_time_data = inter_data.tubular.charging_time_coordinates{1}; % D_out = 46mm

% D_in 값과 Charging Time 보간
charging_time_results = interp1(charging_time_data(1, :), charging_time_data(2, :), ...
                                D_in_targets, 'linear', 'extrap');

% -------------------------------
% Energy Density (Tubular)
% -------------------------------
D_in_vec_all = inter_data.comsol.R_in_values * 2; % 내부 지름(mm)
[~, idx_Rout46] = min(abs(inter_data.comsol.R_out_values*2 - D_out_target)); % D_out=46mm 위치 찾기

rhoE_vec = inter_data.comsol.rho_app_results(:, idx_Rout46); % 46mm용 rho_E 데이터

% D_in 값과 Energy Density 보간
rhoE_results = interp1(D_in_vec_all, rhoE_vec, D_in_targets, 'linear', 'extrap');

% -------------------------------
% 결과 출력
% -------------------------------
fprintf('\nD_out = %d mm에서 D_in별 Charging Time & Energy Density:\n', D_out_target);
for i = 1:length(D_in_targets)
    fprintf('  D_in = %d mm: Charging Time = %.3f min | Energy Density = %.3f kWh/m^3\n', ...
            D_in_targets(i), charging_time_results(i), rhoE_results(i));
end

