clear; clc; close all;

%% 1. 경로 및 파일 설정
in_dir  = 'C:\Users\user\Desktop\Figure\Sweep\mat 파일';
out_dir = fullfile(in_dir, 'Processed');
if ~exist(out_dir, 'dir'), mkdir(out_dir), end

% 입/출력 파일 목록 정의
in_files  = {'Cylinder_Sweep_Crate_Rout.mat', 'Tubular_Sweep_Crate_Rout.mat'};
out_files = {'contour_cyl.mat', 'contour_tube.mat'};

%% 2. 데이터 처리 및 저장 루프
disp('데이터 처리 및 저장을 시작합니다.');
for k = 1:length(in_files)
    
    in_file = in_files{k};
    fprintf('처리 중: %s\n', in_file);
    
    % 원본 데이터 로드
    load(fullfile(in_dir, in_file));
    
    % --- 데이터 준비 ---
    c_rate = data.C_rate;
    d_out  = 2 * data.R_out;
    
    % 고해상도 그리드 및 데이터 보간
    d_out_hr  = linspace(min(d_out), max(d_out), 500);
    c_rate_hr = linspace(min(c_rate), max(c_rate), 500);
    [d_out_grid, c_rate_grid]     = meshgrid(d_out, c_rate);
    [d_out_hr_grid, c_rate_hr_grid] = meshgrid(d_out_hr, c_rate_hr);
    
    T_smooth   = interp2(d_out_grid, c_rate_grid, data.T_max, d_out_hr_grid, c_rate_hr_grid, 'spline');
    Elp_smooth = interp2(d_out_grid, c_rate_grid, data.Elp_min, d_out_hr_grid, c_rate_hr_grid, 'spline');
    t95_smooth = interp2(d_out_grid, c_rate_grid, data.t95, d_out_hr_grid, c_rate_hr_grid, 'spline');
    
    % 온도 제한 초과 영역을 NaN으로 처리
    max_temp = 100;
    is_over_temp = T_smooth > max_temp;
    T_smooth(is_over_temp)   = NaN;
    Elp_smooth(is_over_temp) = NaN;
    t95_smooth(is_over_temp) = NaN;
    
    % 원본 해상도 데이터 추출
    elp_orig = data.Elp_min;

    % --- 중간 데이터 파일로 저장 ---
    save_path = fullfile(out_dir, out_files{k});
    save(save_path, ...
         'd_out_hr', 'c_rate_hr', ...
         'T_smooth', 'Elp_smooth', 't95_smooth', ...
         'd_out', 'c_rate', 'elp_orig');
         
    fprintf('  > 저장 완료: %s\n', save_path);
end
disp('모든 데이터 처리를 완료했습니다.');