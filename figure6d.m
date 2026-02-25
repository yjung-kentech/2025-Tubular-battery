clear; clc; close all;

%% ========================================================================
%  [1] COMSOL 모델 로드
% =========================================================================
import com.comsol.model.*;
import com.comsol.model.util.*;

COM_filepath = 'C:\Users\user\Desktop\Tubular battery 최종';
COM_filename = 'Tubular pack_4s2p_1105';
COM_fullfile = fullfile(COM_filepath, COM_filename);

model = mphload(COM_fullfile);
ModelUtil.showProgress(true);

%% ========================================================================
%  [2] 파라미터 설정
% =========================================================================
C_rate    = 5.4;
R_out     = 23;
R_in      = 3;
T_initial = 25;

R_out_str     = [num2str(R_out) '[mm]'];
R_in_str      = [num2str(R_in)  '[mm]'];
T_initial_str = [num2str(T_initial) '[degC]'];

% Velocity sweep
V_in_values = 0.1:0.3:4;   
nV = numel(V_in_values);

%% ========================================================================
%  [3] 셀 변수명 정의 (8셀)
% =========================================================================
cellTags = {'11','21','31','41','12','22','32','42'};
nCell = numel(cellTags);

Tavg_vars = cell(1,nCell);
Tmax_vars = cell(1,nCell);
for k = 1:nCell
    Tavg_vars{k} = ['Tavg_cell' cellTags{k}];
    Tmax_vars{k} = ['Tmax_cell' cellTags{k}];
end

%% ========================================================================
%  [4] 결과 저장 배열 (all_Tmax/all_Tavg = 8 x nV)
%      각 velocity에서 "시간 전체" 중 최대값(max over time)만 뽑아서 저장
% =========================================================================
all_Tmax = nan(nCell, nV);
all_Tavg = nan(nCell, nV);

%% ========================================================================
%  [5] Sweep 실행
% =========================================================================
for j = 1:nV
    V_in = V_in_values(j);
    V_in_str = [num2str(V_in) '[m/s]'];

    fprintf('[%d/%d] Running V_in=%.2f m/s ...\n', j, nV, V_in);

    try
        % 파라미터 세팅 (너 참고 코드 기준)
        model.param.set('C_rate', C_rate);
        model.param.set('R_out',  R_out_str);
        model.param.set('R_in',   R_in_str);
        model.param.set('T_initial', T_initial_str);
        model.param.set('V_in',   V_in_str);

        % 해석
        model.study('std1').run;

        % 각 셀별 Tmax/Tavg의 시간 이력 -> 최대값만 저장
        for k = 1:nCell
            Tmax_t = mphglobal(model, Tmax_vars{k}, 'unit', 'degC');
            Tavg_t = mphglobal(model, Tavg_vars{k}, 'unit', 'degC');

            all_Tmax(k,j) = max(Tmax_t(:));
            all_Tavg(k,j) = max(Tavg_t(:));
        end

    catch ME
        fprintf('  -> Skipping V_in=%.2f due to error: %s\n', V_in, ME.message);
        % NaN 그대로 유지
    end
end

%% ========================================================================
%  [6] MAT 저장 (중요: 플롯 코드가 요구하는 변수명 그대로 저장)
% =========================================================================
mat_save_path = 'C:\Users\user\Desktop\새figure\mat 파일\figure6d.mat';
save(mat_save_path, 'V_in_values', 'all_Tmax', 'all_Tavg', ...
    'C_rate', 'R_out', 'R_in', 'T_initial');
fprintf('\n✅ MAT 저장 완료: %s\n', mat_save_path);

%% ========================================================================
%  [7] 목표 그래프: Velocity vs Tmax/Tavg 밴드 + (선택)셀별 얇은 선
% =========================================================================
% 보간
V_interp = linspace(min(V_in_values), max(V_in_values), 200);

% interp1은 x가 단조여야 함 (현재는 단조 증가라 OK)
all_Tmax_interp = interp1(V_in_values, all_Tmax', V_interp, 'spline')';
all_Tavg_interp = interp1(V_in_values, all_Tavg', V_interp, 'spline')';

figure; hold on;

% 색상
cTmax = [0.8039, 0.3255, 0.2980];
cTavg = [0.0000, 0.4500, 0.7608];

% (선택) 셀별 얇은 선을 먼저 그림 (그림처럼 밴드가 두껍게 보이게 하려면 linewidth=1)
for k = 1:nCell
    plot(V_interp, all_Tmax_interp(k,:), '-', 'Color', cTmax, 'LineWidth', 1);
end

% Tmax 밴드
Tmax_max_curve = max(all_Tmax_interp, [], 1);
Tmax_min_curve = min(all_Tmax_interp, [], 1);
fill([V_interp, fliplr(V_interp)], [Tmax_max_curve, fliplr(Tmax_min_curve)], ...
     cTmax, 'FaceAlpha', 1, 'EdgeColor', 'none');

% 셀별 Tavg 얇은 선
for k = 1:nCell
    plot(V_interp, all_Tavg_interp(k,:), '-', 'Color', cTavg, 'LineWidth', 1);
end

% Tavg 밴드
Tavg_max_curve = max(all_Tavg_interp, [], 1);
Tavg_min_curve = min(all_Tavg_interp, [], 1);
fill([V_interp, fliplr(V_interp)], [Tavg_max_curve, fliplr(Tavg_min_curve)], ...
     cTavg, 'FaceAlpha', 1, 'EdgeColor', 'none');

% 라벨/스타일
xlabel('Velocity [m/s]', 'FontSize', 16);
ylabel('Temperature [°C]', 'FontSize', 16);
xlim([min(V_interp), max(V_interp)]);

% 너 첨부 그림 y축이 대략 35~50로 보이니 일단 이렇게 (원하면 수정)
ylim([25 50]);

% 범례용 더미 핸들
hTmax = plot(NaN, NaN, '-', 'Color', cTmax, 'LineWidth', 1.8);
hTavg = plot(NaN, NaN, '-', 'Color', cTavg, 'LineWidth', 1.8);
lgd = legend([hTmax, hTavg], {'T_{max}', 'T_{avg}'}, 'Location', 'northeast');
lgd.FontSize = 14;

ax = gca;
ax.FontSize = 16;
box on; grid off;
hold off;

% PNG 저장
png_save_path = 'C:\Users\user\Desktop\새figure\png\figure6d.png';
exportgraphics(gcf, png_save_path, 'Resolution', 300);
fprintf('✅ PNG 저장 완료: %s\n', png_save_path);
