clear; clc; close all;

%% ────────────────────── 1. COMSOL 결과 읽기 ────────────────────────────
import com.comsol.model.*
import com.comsol.model.util.*

COM_path   = 'C:\Users\user\Desktop\Tubular battery 최종';
file_tube  = 'JYR_cell_0202.mph';
file_cyl   = 'JYR_cylinder_cell_0202.mph';

C_rate = 6;
R_out  = 23;               
R_out_str = [num2str(R_out) '[mm]'];

% ─ Tube
m1 = mphload(fullfile(COM_path,file_tube));
ModelUtil.showProgress(true);
m1.param.set('C_rate',C_rate);  m1.param.set('R_out',R_out_str);
m1.study('std1').run;
time1  = mphglobal(m1,'t','unit','min');
T_max1 = mphglobal(m1,'T_max','unit','degC');
T_avg1 = mphglobal(m1,'T_avg','unit','degC');
ModelUtil.remove('model1');

% ─ Cyl
m2 = mphload(fullfile(COM_path,file_cyl));
m2.param.set('C_rate',C_rate);  
m2.param.set('R_out',R_out_str);
m2.param.set('L', num2str(R_out));
m2.study('std1').run;
time2  = mphglobal(m2,'t','unit','min');
T_max2 = mphglobal(m2,'T_max','unit','degC');
T_avg2 = mphglobal(m2,'T_avg','unit','degC');
ModelUtil.remove('model2');

%% ────────────────────── 2. 영상 저장 설정 ──────────────────────────────
video_dir = 'C:\Users\user\Desktop\Figure\Figure 1\video 파일';
if ~exist(video_dir,'dir'), mkdir(video_dir); end
vobj = VideoWriter(fullfile(video_dir,'figure1_temp.mp4'),'MPEG-4');
vobj.FrameRate = 10;   open(vobj);

%% ────────────────────── 3. 그래프 초기 세팅 ────────────────
lw = 1;
col1 = [0.8039,0.3255,0.2980];   % 빨강
col2 = [0.0000,0.4500,0.7608];   % 파랑

figure;  
hold on;
box on;

% 초기 plot (빈 데이터)
h_tube_max = plot(NaN,NaN,'-o','Color',col1,'LineWidth',lw,...
                  'MarkerIndices',[],'DisplayName','tube.T_{max}');
h_tube_avg = plot(NaN,NaN,'-o','Color',col2,'LineWidth',lw,...
                  'MarkerIndices',[],'DisplayName','tube.T_{avg}');
h_cyl_max  = plot(NaN,NaN,'-x','Color',col1,'LineWidth',lw,...
                  'MarkerIndices',[],'DisplayName','cyl.T_{max}');
h_cyl_avg  = plot(NaN,NaN,'-x','Color',col2,'LineWidth',lw,...
                  'MarkerIndices',[],'DisplayName','cyl.T_{avg}');

xlabel('Time [min]','FontSize',15);
ylabel('Temperature [^oC]','FontSize',15);
set(gca,'FontSize',15);
xlim([0, min(max(time1), max(time2))]);
ylim([25 60]);
% ylim([ min([T_avg1(:);T_avg2(:);T_max1(:);T_max2(:)]) - 1 , max([T_avg1(:);T_avg2(:);T_max1(:);T_max2(:)]) + 1 ]);
lgd = legend('Location','southeast','NumColumns',2);  
lgd.FontSize = 13;

set(gca, 'Position', [0.13, 0.18, 0.8, 0.72]);

%% ────────────────────── 4. 프레임 루프 (exportgraphics + resize) ────────────────────────────────
N = max([length(time1) length(time2)]);

% 임시 파일 경로 생성
tempfile = [tempname, '.png'];

% VideoWriter가 요구하는 프레임 크기 설정
target_width  = 1544;
target_height = 1218;

for i = 1:N
    % ─ 데이터 누적 및 갱신
    if i <= length(time1)
        h_tube_max.XData = time1(1:i);  h_tube_max.YData = T_max1(1:i);
        h_tube_avg.XData = time1(1:i);  h_tube_avg.YData = T_avg1(1:i);
        idx1 = find(mod(time1(1:i),2)==0);
        h_tube_max.MarkerIndices = idx1;
        h_tube_avg.MarkerIndices = idx1;
    end
    if i <= length(time2)
        h_cyl_max.XData = time2(1:i);   h_cyl_max.YData = T_max2(1:i);
        h_cyl_avg.XData = time2(1:i);   h_cyl_avg.YData = T_avg2(1:i);
        idx2 = find(mod(time2(1:i),2)==0);
        h_cyl_max.MarkerIndices = idx2;
        h_cyl_avg.MarkerIndices = idx2;
    end

    drawnow;

    % 고해상도 PNG로 임시 저장 후 읽기
    % --- 고해상도 PNG로 임시 저장 (여백 유지)
    print(gcf, '-dpng', '-r300', '-loose', tempfile);

    img = imread(tempfile);

    % 영상 프레임 크기에 맞춰 resize
    img = imresize(img, [target_height, target_width]);
    writeVideo(vobj, img);
end

close(vobj);

delete(tempfile);

disp('동영상 저장 완료');
