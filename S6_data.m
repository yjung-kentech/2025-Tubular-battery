clear; clc; close all;

%% 1. 경로 설정 ― 필요에 맞게 수정하세요
png_dir = 'C:/Users/user/Desktop/Figure/Supple Figure/png 파일';
data_dir = 'C:/Users/user/Desktop/Figure/Supple Figure/중간 데이터';
mat_file = fullfile(data_dir, 'S6.mat');

%% 2. 데이터 로드
load(mat_file, 'allResults');   % -> allResults(1:3).(필드)  구조체 배열

%% 3. 색상 및 레이블 세팅 (원본과 동일)
Tmax_color = [205,  83,  76] / 255;   % #CD534C
Tavg_color = [  0, 115, 194] / 255;   % #0073C2
I_color    = [239, 192,   0] / 255;   % #EFC000   (pack current → C-rate)
E_color    = [146,  94, 159] / 255;   % #925E9F   (pack voltage)
SOC_color  = [ 32, 133,  78] / 255;   % #20854E
labelT     = {'a','b','c'};

%% 4. Figure 생성
figure('Position', [100 100 1600 1200]);

for i = 1:numel(allResults)
    % ---- 4-1. 구조체에서 시계열 꺼내기 ----
    T_init_val = allResults(i).T_init;
    time_min   = allResults(i).time_min;
    Tmax       = allResults(i).Tmax;        % (Nt × nCells)
    Tavg       = allResults(i).Tavg;
    I_cell_C   = allResults(i).I_cell;      % 이미 C-rate 환산됨
    E_cell     = allResults(i).E_cell;      % Voltage [V]
    SOC        = allResults(i).SOC;
    nCells     = size(Tmax, 2);

    %% 4-2. Row 1 : 컨투어 이미지 + 컬러바 이미지 -----------------------------
    % (1) 원본 contour 이미지
    axPair = subplot(4,3,i);       % ① 원래 자리 하나 확보
    axPair.Units = 'normalized';
    pos = axPair.Position;         % [x y w h]
    delete(axPair)                 % ② 공간만 빌리고 바로 지움

    % ── ③ 이미지 크기 조정 (90% : 10%) → 기존보다 더 많이 차지하도록 확대
    w_img = pos(3) * 0.88;
    w_cb  = pos(3) * 0.12;

    % ── ④ 왼쪽 이미지 축 생성
    axImg = axes('Units','normalized','Position',[pos(1) - 0.01 pos(2)-0.06 w_img pos(4)* 1.6]);
    imshow(imread(fullfile(png_dir, sprintf('T_init=%d new.png',T_init_val))), ...
           'InitialMagnification', 200);  % 크기 확대
    axis off

    % ── ⑤ 오른쪽 컬러바 축 생성 (공간에 완전히 붙음)
    axCB = axes('Units','normalized', ...
                'Position', [pos(1) + w_img - 0.01 pos(2)-0.05 w_cb*1.6 pos(4)*1.5]);
    imshow(imread(fullfile(png_dir, 'colorbar3.png')), 'InitialMagnification', 200);
    axis off

    % ── ⑥ 열 구분 레이블 (a, b, c)
    annotation('textbox',[pos(1)-0.02, pos(2)+pos(4)-0.03, 0.05, 0.05], ...
               'String', labelT{i}, 'EdgeColor','none', 'FontSize', 20, ...
               'FontWeight','bold', 'Color','k');

    % ---- 4-3. Row 2 : Tmax & Tavg ----
    subplot(4, 3, 3+i);  hold on;
    % 음영: 셀 간 min-max 범위
    fill([time_min; flipud(time_min)], ...
         [min(Tmax,[],2); flipud(max(Tmax,[],2))], ...
         [1 0.8 0.8], 'FaceAlpha', 1, 'EdgeColor', 'none', 'HandleVisibility','off');
    fill([time_min; flipud(time_min)], ...
         [min(Tavg,[],2); flipud(max(Tavg,[],2))], ...
         [0.8 0.8 1], 'FaceAlpha', 1, 'EdgeColor', 'none', 'HandleVisibility','off');

    % 선: 첫 번째 셀만 범례에 표시
    hTmax = plot(time_min, Tmax(:,1), 'Color', Tmax_color, 'LineWidth', 1, 'DisplayName','T_{max}');
    for k = 2:nCells, plot(time_min, Tmax(:,k), 'Color', Tmax_color, 'LineWidth', 1, 'HandleVisibility','off'); end
    hTavg = plot(time_min, Tavg(:,1), 'Color', Tavg_color, 'LineWidth', 1, 'DisplayName','T_{avg}');
    for k = 2:nCells, plot(time_min, Tavg(:,k), 'Color', Tavg_color, 'LineWidth', 1, 'HandleVisibility','off'); end
    hold off;
    xlabel('Time [min]', 'FontSize', 13);
    ylabel('Temperature [°C]', 'FontSize', 13);
    set(gca, 'FontSize', 12);  xlim([0 max(time_min)]);
    legend([hTmax hTavg], {'T_{max}','T_{avg}'}, 'Location','southeast', ...
           'FontSize', 10);   box on; grid off;

    % ---- 4-4. Row 3 : C-rate & Voltage ----
    subplot(4, 3, 6+i);
    yyaxis right;  hold on;
    fill([time_min; flipud(time_min)], ...
         [min(I_cell_C,[],2); flipud(max(I_cell_C,[],2))], ...
         [0.8 1 0.8], 'FaceAlpha', 1, 'EdgeColor', 'none', 'HandleVisibility','off');
    hI = plot(time_min, I_cell_C(:,1), '-', 'Color', I_color, 'LineWidth', 1, 'DisplayName','I_{pack}');
    for k = 2:nCells, plot(time_min, I_cell_C(:,k), '-', 'Color', I_color, 'LineWidth', 1, 'HandleVisibility','off'); end
    ylabel('C-rate', 'FontSize', 13);
    ylim([0 12]);  set(gca, 'YColor','k', 'FontSize', 12);  hold off;

    yyaxis left; hold on;
    fill([time_min; flipud(time_min)], ...
         [min(E_cell,[],2); flipud(max(E_cell,[],2))], ...
         [0.8 0.8 1], 'FaceAlpha', 1, 'EdgeColor', 'none', 'HandleVisibility','off');
    hE = plot(time_min, E_cell(:,1), '-', 'Color', E_color, 'LineWidth', 1, 'DisplayName','V_{pack}');
    for k = 2:nCells, plot(time_min, E_cell(:,k), '-', 'Color', E_color, 'LineWidth', 1, 'HandleVisibility','off'); end
    ylabel('Voltage [V]', 'FontSize', 13);
    set(gca, 'YColor','k', 'FontSize', 12); hold off;

    xlabel('Time [min]', 'FontSize', 13);
    xlim([0 max(time_min)]);
    legend([hI hE], {'I_{pack}','V_{pack}'}, 'Location','southeast', 'FontSize', 10);
    box on; grid off;

    % ---- 4-5. Row 4 : SOC ----
    subplot(4, 3, 9+i);  hold on;
    fill([time_min; flipud(time_min)], ...
         [min(SOC,[],2); flipud(max(SOC,[],2))], ...
         [0.9 0.9 0.8], 'FaceAlpha', 1, 'EdgeColor', 'none', 'HandleVisibility','off');
    hSOC = plot(time_min, SOC(:,1), '-', 'Color', SOC_color, 'LineWidth', 1, 'DisplayName','SOC');
    for k = 2:nCells, plot(time_min, SOC(:,k), '-', 'Color', SOC_color, 'LineWidth', 1, 'HandleVisibility','off'); end
    hold off;
    xlabel('Time [min]', 'FontSize', 13);
    ylabel('SOC', 'FontSize', 13);
    set(gca, 'FontSize', 12);  xlim([0 max(time_min)]);
    legend(hSOC, {'SOC'}, 'Location','southeast', 'FontSize', 10);
    box on; grid off;
end

%% 5. Figure 저장
output_file = fullfile(png_dir, 'S6_new.png');
exportgraphics(gcf, output_file, 'Resolution', 300);
close(gcf);

disp(['완료: Figure가 "', output_file, '" 에 저장되었습니다.']);
