clear; clc; close all;
import com.comsol.model.*
import com.comsol.model.util.*

%% 1. 파일 및 저장 경로 설정
COM_filepath = 'C:\Users\user\Desktop\Aging model';
COM_filename = 'JYR_3segment_agingcycle (2C)_1121.mph';
COM_fullfile = fullfile(COM_filepath, COM_filename);

out_dir = 'C:\Users\user\Desktop\Figure\Supple Figure\png 파일';
if ~exist(out_dir, 'dir'), mkdir(out_dir); end
out_name = '2C 튜블러_충전.png';
out_fullfile = fullfile(out_dir, out_name);

%% 2. 데이터셋 및 색상
all_datasets = {'dset44','dset19','dset24','dset29','dset34','dset39'};
all_labels   = {'1st cycle','100th cycle','200th cycle','300th cycle','400th cycle','500th cycle'};
n_dset = numel(all_datasets);
colors = get_nebula_colors(n_dset);

%% 3. 모델 로드
if ~exist('model','var')
    fprintf('모델 로드 중: %s\n', COM_fullfile);
    model = mphload(COM_fullfile);
    fprintf('모델 로드 완료.\n');
end

%% 4. Figure 설정
f = figure('Color','w','Units','pixels', 'Position',[150 50 580 1300]);

% [핵심 변경] Padding을 'loose'로 설정하여 바깥 여백을 넉넉하게 확보
tlo = tiledlayout(f, 4, 1, 'TileSpacing','loose', 'Padding','loose');

% 폰트 및 라인 설정 공통 변수
yLabelFontSize = 16;
xLabelFontSize = 15;
axisFontSize   = 13;
labelFontSize  = 18; % a, b, c, d 라벨 크기
labelXPos      = -0.16; % 라벨 좌우 위치 (더 왼쪽으로 보내려면 값을 줄이세요 예: -0.2)
labelYPos      = 1.05;  % 라벨 상하 위치

% --- (1) 전압 (Voltage) ---
ax1 = nexttile(1);
hold(ax1, 'on'); grid(ax1, 'off'); box(ax1, 'on');
ylabel(ax1, 'Voltage [V]', 'FontSize', yLabelFontSize);
xlabel(ax1, 'Charging capacity [Ah]', 'FontSize', xLabelFontSize);
set(ax1, 'FontSize', axisFontSize, 'LineWidth', 1);
% 라벨 (a)
text(ax1, labelXPos, labelYPos, 'a', 'Units', 'normalized', ...
    'FontSize', labelFontSize, 'FontWeight', 'bold');

% --- (2) 전류 (Current) ---
ax2 = nexttile(2);
hold(ax2, 'on'); grid(ax2, 'off'); box(ax2, 'on');
ylabel(ax2, 'C-rate', 'FontSize', yLabelFontSize);
xlabel(ax2, 'Charging capacity [Ah]', 'FontSize', xLabelFontSize);
set(ax2, 'FontSize', axisFontSize, 'LineWidth', 1);
% 라벨 (c)
text(ax2, labelXPos, labelYPos, 'c', 'Units', 'normalized', ...
    'FontSize', labelFontSize, 'FontWeight', 'bold');

% --- (3) 최고 온도 (Max Temp) ---
ax3 = nexttile(3);
hold(ax3, 'on'); grid(ax3, 'off'); box(ax3, 'on');
ylabel(ax3, 'T_{max} [°C]', 'FontSize', yLabelFontSize);
xlabel(ax3, 'Charging capacity [Ah]', 'FontSize', xLabelFontSize);
set(ax3, 'FontSize', axisFontSize, 'LineWidth', 1);
% 라벨 (e)
text(ax3, labelXPos, labelYPos, 'e', 'Units', 'normalized', ...
    'FontSize', labelFontSize, 'FontWeight', 'bold');

% --- (4) 평균 온도 (Avg Temp) ---
ax4 = nexttile(4);
hold(ax4, 'on'); grid(ax4, 'off'); box(ax4, 'on');
ylabel(ax4, 'T_{avg} [°C]', 'FontSize', yLabelFontSize);
xlabel(ax4, 'Charging capacity [Ah]', 'FontSize', xLabelFontSize);
set(ax4, 'FontSize', axisFontSize, 'LineWidth', 1);
% 라벨 (g)
text(ax4, labelXPos, labelYPos, 'g', 'Units', 'normalized', ...
    'FontSize', labelFontSize, 'FontWeight', 'bold');

%% 5. 데이터 추출 및 플롯
fprintf('데이터 추출 및 플롯 시작...\n');

for k = 1:n_dset
    dset = all_datasets{k};
    
    % (1) 시간 및 기준점
    t = mphglobal(model, 't', 'dataset', dset, 'outersolnum','all', 'unit','s');
    t = t(:);
    if isempty(t), continue; end
    t0 = t(1);

    % (2) 표현식 정의
    expr_Q = sprintf(['((comp1.deltaQ - at(%g, comp1.deltaQ)) + ' ...
                      '(comp2.deltaQ - at(%g, comp2.deltaQ)) + ' ...
                      '(comp3.deltaQ - at(%g, comp3.deltaQ)))/3'], t0,t0,t0);
    
    expr_V = '(comp1.E_cell + comp2.E_cell + comp3.E_cell)/3';
    
    expr_C = ['(if(comp1.I_cell<0, -comp1.I_cell/I_1C_2D, NaN) + ' ...
               'if(comp2.I_cell<0, -comp2.I_cell/I_1C_2D, NaN) + ' ...
               'if(comp3.I_cell<0, -comp3.I_cell/I_1C_2D, NaN))/3'];
           
    expr_Tmax = 'max(max(comp1.T_max, comp2.T_max), comp3.T_max) - 273.15';
    expr_Tavg = '((comp1.T_avg + comp2.T_avg + comp3.T_avg)/3) - 273.15';

    % (3) 데이터 가져오기
    Q_raw  = mphglobal(model, expr_Q, 'dataset', dset, 'outersolnum','all', 'unit','Ah');
    V_raw  = mphglobal(model, expr_V, 'dataset', dset, 'outersolnum','all', 'unit','V');
    C_raw  = mphglobal(model, expr_C, 'dataset', dset, 'outersolnum','all'); 
    Tm_raw = mphglobal(model, expr_Tmax, 'dataset', dset, 'outersolnum','all');
    Ta_raw = mphglobal(model, expr_Tavg, 'dataset', dset, 'outersolnum','all');
    
    % 길이 동기화
    n = min([numel(Q_raw), numel(V_raw), numel(C_raw), numel(Tm_raw), numel(Ta_raw)]);
    Q_raw = Q_raw(1:n); V_raw = V_raw(1:n); C_raw = C_raw(1:n); 
    Tm_raw = Tm_raw(1:n); Ta_raw = Ta_raw(1:n);

    % (4) 충전 구간 추출
    idx_chg = longest_segment_by_monotonicity(V_raw, +1);

    if ~isempty(idx_chg)
        Q_seg  = Q_raw(idx_chg);
        V_seg  = V_raw(idx_chg);
        C_seg  = C_raw(idx_chg);
        Tm_seg = Tm_raw(idx_chg);
        Ta_seg = Ta_raw(idx_chg);
        
        % X축 보정
        Q_plot = Q_seg - Q_seg(1);
        
        % [데이터 전처리] 시작점 강제 추가 (수직선 구현)
        Q_final = [0; Q_plot]; 
        
        V_final  = [3.0; V_seg];        
        C_final  = [0; C_seg];          
        Tm_final = [Tm_seg(1); Tm_seg]; 
        Ta_final = [Ta_seg(1); Ta_seg]; 

        % [Plotting]
        lw = 1.0;
        col = colors(k,:);
        
        plot(ax1, Q_final, V_final,  '-', 'Color', col, 'LineWidth', lw);
        plot(ax2, Q_final, C_final,  '-', 'Color', col, 'LineWidth', lw);
        plot(ax3, Q_final, Tm_final, '-', 'Color', col, 'LineWidth', lw);
        plot(ax4, Q_final, Ta_final, '-', 'Color', col, 'LineWidth', lw);
    end
end

% 범례 (맨 위 그래프에만 표시)
lgd = legend(ax1, all_labels, 'Location','southeast', 'FontSize', 12);

% 축 동기화 및 범위 설정
linkaxes([ax1, ax2, ax3, ax4], 'x');
xlim(ax1, [0 inf]);

ylim(ax1, [3.0 4.2]);
ylim(ax3, [25 34]);
ylim(ax4, [25 31]);

%% 6. 이미지 저장
fprintf('이미지 저장 중: %s\n', out_fullfile);
exportgraphics(f, out_fullfile, 'Resolution', 600);
fprintf('저장 완료.\n');

%% =================================================================
%  Local Functions
% =================================================================

function colors = get_nebula_colors(n)
    stops = [0.0,  0.00, 0.20, 0.60;
             0.5,  0.50, 0.10, 0.70;
             1.0,  0.90, 0.40, 0.60];
    x = linspace(0, 1, n)';
    r = interp1(stops(:,1), stops(:,2), x, 'pchip');
    g = interp1(stops(:,1), stops(:,3), x, 'pchip');
    b = interp1(stops(:,1), stops(:,4), x, 'pchip');
    colors = max(0, min(1, [r, g, b]));
end

function idx = longest_segment_by_monotonicity(x, modeSign)
    x = x(:);
    dx = [0; diff(x)];
    epsVal = 1e-4; 

    if modeSign > 0
        mask = dx > -epsVal; 
    else
        mask = dx <  epsVal; 
    end
    
    win = max(1, min(11, floor(numel(mask)/100)));
    if win > 1
        mask = movmean(double(mask), win) > 0.5;
    end

    d = diff([false; mask; false]);
    s = find(d==1);
    e = find(d==-1) - 1;

    if isempty(s)
        idx = [];
    else
        [~, im] = max(e - s + 1);
        idx = s(im):e(im);
    end
end