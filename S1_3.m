clear; clc; close all;

%% --- [1] 경로 및 기본 설정 ---
COM_filepath = 'C:/Users/user/Desktop/Tubular battery 최종';
COM_filename1 = 'JYR_cell_0213.mph';         % Tube 모델
COM_filename2 = 'JYR_cylinder_cell_0213.mph';  % Cylinder 모델
COM_fullfile1 = fullfile(COM_filepath, COM_filename1);
COM_fullfile2 = fullfile(COM_filepath, COM_filename2);

png_dir = 'C:/Users/user/Desktop/Figure/Supple Figure/png 파일';

% D_out별로 다른 C-rate
R_out_list = [10.5, 23, 35];  % (D_out=21, 46, 70)
C_rate_set_1 = [2, 6, 10];      % (D_out=21,46)
C_rate_set_2 = [2, 4, 6];       % (D_out=70)

labelABC = {'a','b','c'};
colors   = {'#CD534C','#0073C2','#EFC000','#925E9F','#20854E','#4DBBD5'};

%% --- [2] subplot 위치/크기 설정 ---
figureWidth  = 1600;
figureHeight = 900;

% 첫 행 (Contour) 및 2~4행 subplot 기본 비율
width  = 0.25;
height = 0.17;

% 열 간 간격 등
hspace  = 0.02;
left0   = 0.07;

% (여기) 첫 번째 행(Contour 그림) 위치/크기
bottomRow1 = 0.74;  % 첫 행 y 위치 (원하는 대로 미세조정 가능)

% 2~4행의 subplot 위치 (temperature, voltage & current, SOC & E_lp)
bottomRow2 = 0.56;
bottomRow3 = 0.34;
bottomRow4 = 0.12;

% 2~4행 그래프는 1행 대비 크기 축소 (예: 0.77, 0.82)
width2  = width  * 0.77;
height2 = height * 0.82;

%% --- [3] S1~S3 생성 ---
for i = 1:3
    R_out_val = R_out_list(i);
    D_out_val = 2 * R_out_val;  % (21,46,70)

    if abs(R_out_val - 35) < 1e-9
        C_rate_set = C_rate_set_2;   % [2,4,6]
    else
        C_rate_set = C_rate_set_1;   % [2,6,10]
    end

    figure('Position',[100 100 figureWidth figureHeight]);

    for j = 1:length(C_rate_set)
        cRateVal = C_rate_set(j);
        R_out_str = sprintf('%g[mm]', R_out_val);

        % --- Tube 모델 로드 및 계산 ---
        model1 = mphload(COM_fullfile1);
        model1.param.set('C_rate', cRateVal);
        model1.param.set('R_out', R_out_str);
        model1.study('std1').run;

        time_min1 = mphglobal(model1, 't', 'unit', 'min');
        T_max1    = mphglobal(model1, 'T_max', 'unit', 'degC');
        T_avg1    = mphglobal(model1, 'T_avg', 'unit', 'degC');
        I_cell1   = mphglobal(model1, 'comp1.I_cell', 'unit', 'A');
        E_cell1   = mphglobal(model1, 'comp1.E_cell', 'unit', 'V');
        SOC1      = mphglobal(model1, 'comp1.SOC');
        E_lp1     = mphglobal(model1, 'comp1.E_lp', 'unit', 'V');
        I_tube = mphglobal(model1, 'I_1C_2D', 'unit', 'A');

        % --- Cylinder 모델 로드 및 계산 ---
        model2 = mphload(COM_fullfile2);
        model2.param.set('C_rate', cRateVal);
        model2.param.set('R_out', R_out_str);
        model2.param.set('L', num2str(R_out_val));
        model2.study('std1').run;

        time_min2 = mphglobal(model2, 't', 'unit', 'min');
        T_max2    = mphglobal(model2, 'T_max', 'unit', 'degC');
        T_avg2    = mphglobal(model2, 'T_avg', 'unit', 'degC');
        I_cell2   = mphglobal(model2, 'comp1.I_cell', 'unit', 'A');
        E_cell2   = mphglobal(model2, 'comp1.E_cell', 'unit', 'V');
        SOC2      = mphglobal(model2, 'comp1.SOC');
        E_lp2     = mphglobal(model2, 'comp1.E_lp', 'unit', 'V');
        I_cyl = mphglobal(model2, 'I_1C_2D', 'unit', 'A');

        marker_idx1 = 1 : max(1, round(length(time_min1)/6)) : length(time_min1);
        marker_idx2 = 1 : max(1, round(length(time_min2)/6)) : length(time_min2);

        t_max = max([time_min1; time_min2]);

        %% ---------------------------
        %% (1) 첫 행: Temperature Contour
        %% ---------------------------
        ax_top = subplot(4, 3, j);

        % --- 1. 이미지 파일 로딩 ---
        f_cyl = fullfile(png_dir, sprintf('Cylinder, C-rate=%d, D_out=%d.png', cRateVal, D_out_val));
        f_tub = fullfile(png_dir, sprintf('Tubular, C-rate=%d, D_out=%d.png', cRateVal, D_out_val));
        f_cb  = fullfile(png_dir, 'colorbar 25-100.png');

        cyl_img = imread(f_cyl);
        tub_img = imread(f_tub);
        cb_img  = imread(f_cb);

        % --- 2. 이미지 확대 ---
        cell_img_scale = 3;  % << 조정 가능: 셀 이미지 확대 배율
        cyl_img = imresize(cyl_img, cell_img_scale);
        tub_img = imresize(tub_img, cell_img_scale);

        cb_scaleH = 1*4;    % << 조정 가능: 컬러바 세로 배율
        cb_scaleW = 1*1.4;    % << 조정 가능: 컬러바 가로 배율
        cb_img = imresize(cb_img, cb_scaleH);  
        cb_img = imresize(cb_img, [size(cb_img,1), round(size(cb_img,2)*cb_scaleW)]);

        % --- 2.5. 컬러바 살짝 위로 올리기 (아래에 흰색 padding 추가)
        cb_shift_pixels = 20;  % <<< 이 값 조절 가능 (10~20 권장)
        cb_img = padarray(cb_img, [cb_shift_pixels, 0], 255, 'post');

        % --- 3. 이미지 높이 맞추기 ---
        desired_height = max([size(cyl_img,1), size(tub_img,1), size(cb_img,1)]);
        cyl_img = padImage(cyl_img, desired_height);
        tub_img = padImage(tub_img, desired_height);
        cb_img  = padImage(cb_img, desired_height);

        % --- 4. 이미지 결합 + 전체 확대 ---
        spaceWidth = 100;  % << 조정 가능: 실린더-튜브 사이 공백
        space = 255 * ones(desired_height, spaceWidth, 3, 'uint8');

        % [실린더, 공백, 튜브, 컬러바] 순서로 붙임
        combined_img = [cyl_img, space, tub_img, cb_img];

        final_resize_factor = 3.3;  % << 조정 가능: 최종 확대 배율
        combined_img = imresize(combined_img, final_resize_factor);

        % --- 5. subplot에 이미지 표시 ---
        imshow(combined_img, 'Parent', ax_top, 'InitialMagnification', 100);
        axis(ax_top, 'off');

        % (h) 서브플롯 라벨
        text(ax_top, -0.21, 1.1, labelABC{j}, 'Units','normalized','FontSize',20,...
            'FontWeight','bold','HorizontalAlignment','left','VerticalAlignment','top');

        % (i) 1행의 subplot 위치 지정 (j=1,2,3 각각 가로로 나란히)
        leftPos_top = left0 + (j-1)*(width + hspace) - 0.07;
        width_top  = width  * 1.4;   % 혹은 직접 0.28, 0.3 등 원하는 값
        height_top = height * 1.4;
        set(ax_top, 'Position', [leftPos_top bottomRow1 width_top height_top]);

        %% ---------------------------
        %% (2) 두 번째 행: Temperature Plot
        %% ---------------------------
        ax_temp = subplot(4, 3, 3 + j);
        plot(time_min1, T_max1, 'o-', 'Color', colors{1}, ...
            'DisplayName','tube.T_{max}', 'MarkerIndices', marker_idx1);
        hold on;
        plot(time_min1, T_avg1, 'o-', 'Color', colors{2}, ...
            'DisplayName','tube.T_{avg}', 'MarkerIndices', marker_idx1);
        plot(time_min2, T_max2, 'x-', 'Color', colors{1}, ...
            'DisplayName','cyl.T_{max}', 'MarkerIndices', marker_idx2);
        plot(time_min2, T_avg2, 'x-', 'Color', colors{2}, ...
            'DisplayName','cyl.T_{avg}', 'MarkerIndices', marker_idx2);
        hold off;
        grid off;
        xlim([0 t_max]);
        ylim([20 100]);
        xlabel('Time [min]', 'FontSize',13);
        ylabel('Temperature [^oC]', 'FontSize',13, 'Color','k');
        set(gca, 'FontSize',12, 'YColor','k');
        legend('Location','northwest','FontSize',9,'NumColumns',2,'Orientation','horizontal');
        leftPos = left0 + (j-1)*(width + hspace);
        set(ax_temp, 'Position', [leftPos bottomRow2 width2 height2]);

        %% ---------------------------
        %% (3) 세 번째 행: Voltage & Current
        %% ---------------------------
        ax_cv = subplot(4, 3, 6 + j);
        
        % Voltage: 좌측 y축 (필터 없이 그리기)
        yyaxis left;
        hV1 = plot(time_min1, E_cell1, 'o-', 'Color', colors{4}, 'DisplayName','tube.V', ...
            'MarkerIndices', marker_idx1);
        hold on;
        hV2 = plot(time_min2, E_cell2, 'x-', 'Color', colors{4}, 'DisplayName','cyl.V', ...
            'MarkerIndices', marker_idx2);
        ylabel('Voltage [V]', 'FontSize',13, 'Color','k');
        set(gca, 'YColor','k');

        % C-rate: 우측 y축, 0인 구간 필터링
        yyaxis right;
        % C-rate 계산
        cRate1 = -I_cell1 / I_tube;
        cRate2 = -I_cell2 / I_cyl;
        
        % 0이 아닌 인덱스만 필터링 (원하는 경우, 0과 아주 작은 값들도 제거하려면 조건을 조정하세요)
        idx1 = cRate1 ~= 0;
        idx2 = cRate2 ~= 0;
        
        % 필터링된 시간과 C-rate 값
        timeFiltered1 = time_min1(idx1);
        timeFiltered2 = time_min2(idx2);
        cRateFiltered1 = cRate1(idx1);
        cRateFiltered2 = cRate2(idx2);
        
        % 필요한 경우, 마커 인덱스 재계산 (여기서는 필터링된 데이터의 길이에 따라)
        markerFiltered1 = 1 : max(1, round(numel(timeFiltered1)/6)) : numel(timeFiltered1);
        markerFiltered2 = 1 : max(1, round(numel(timeFiltered2)/6)) : numel(timeFiltered2);
        
        hI1 = plot(timeFiltered1, cRateFiltered1, 'o-', 'Color', colors{3}, ...
            'MarkerIndices', markerFiltered1, 'DisplayName','tube.I');
        hI2 = plot(timeFiltered2, cRateFiltered2, 'x-', 'Color', colors{3}, ...
            'MarkerIndices', markerFiltered2, 'DisplayName','cyl.I');
        ylabel('C-rate', 'FontSize', 13, 'Color','k');
        ylim([0 12]);
        set(gca, 'YColor','k','FontSize',12);
        xlabel('Time [min]', 'FontSize',13);
        xlim([0 t_max]);
        
        % legend: 좌측의 Voltage와 우측의 C-rate 객체 모두
        legHandles = [hV1(:).', hV2(:).', hI1(:).', hI2(:).'];
        legend(legHandles, {'tube.V','cyl.V','tube.I','cyl.I'}, ...
            'Location','northwest','FontSize',9,'NumColumns',2,'Orientation','horizontal');
        
        grid off;
        hold off;
        leftPos = left0 + (j-1)*(width + hspace);
        set(ax_cv, 'Position', [leftPos bottomRow3 width2 height2]);

        %% ---------------------------
        %% (4) 네 번째 행: SOC & E_lp
        %% ---------------------------
        ax_soc = subplot(4, 3, 9 + j);
        yyaxis left;
        plot(time_min1, E_lp1, 'o-', 'Color', colors{5}, 'DisplayName','tube.η_{n}', ...
            'MarkerIndices', marker_idx1);
        hold on;
        plot(time_min2, E_lp2, 'x-', 'Color', colors{5}, 'DisplayName','cyl.η_{n}', ...
            'MarkerIndices', marker_idx2);
        ylabel('Anode potential [V]', 'FontSize',13, 'Color','k');
        ylim([-0.05 0.25]);
        set(gca, 'YColor','k');

        yyaxis right;
        plot(time_min1, SOC1, 'o-', 'Color', colors{6}, 'DisplayName','tube.SOC', ...
            'MarkerIndices', marker_idx1);
        plot(time_min2, SOC2, 'x-', 'Color', colors{6}, 'DisplayName','cyl.SOC', ...
            'MarkerIndices', marker_idx2);
        ylabel('SOC', 'FontSize',13, 'Color','k');
        set(gca, 'YColor','k','FontSize',12);
        xlabel('Time [min]', 'FontSize',13);
        xlim([0 t_max]);
        legend('Location','northwest','FontSize',9,'NumColumns',2,'Orientation','horizontal');
        grid off;
        hold off;
        leftPos = left0 + (j-1)*(width + hspace);
        set(ax_soc, 'Position', [leftPos bottomRow4 width2 height2]);
    end

    outname = sprintf('S%d.png', i);
    filename = fullfile(png_dir, outname);
    exportgraphics(gcf, filename, 'Resolution', 300);
    close(gcf);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 로컬 함수: padImage (이미지가 desired_height보다 작을 경우에만 pad, 크면 그대로 유지)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function outImg = padImage(inImg, desired_height)
    h_in = size(inImg,1);
    if h_in < desired_height
        pad_total = desired_height - h_in;
        pad_top   = floor(pad_total/2);
        pad_bottom= pad_total - pad_top;
        outImg = padarray(inImg, [pad_top, 0], 255, 'pre');
        outImg = padarray(outImg, [pad_bottom, 0], 255, 'post');
    else
        % 이미지 크기가 desired_height 이상이면 축소하지 않고 그대로 반환
        outImg = inImg;
    end
end
