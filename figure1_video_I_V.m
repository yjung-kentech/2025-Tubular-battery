clear; clc; close all;

%% ────────────────────── 1. COMSOL 결과 읽기 ───────────────────────────
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
m1.param.set('C_rate',C_rate);  
m1.param.set('R_out',R_out_str);
m1.study('std1').run;

time1      = mphglobal(m1,'t','unit','min');
E_cell1    = mphglobal(m1,'E_cell','unit','V');        % << 전압
I_cell1    = mphglobal(m1,'I_cell','unit','A');        % << 시간축 전류
I1C_tube   = mphglobal(m1,'I_1C_2D','unit','A');       % << 1C 전류 (스칼라)
ModelUtil.remove('model1');

% ─ Cyl
m2 = mphload(fullfile(COM_path,file_cyl));
m2.param.set('C_rate',C_rate);  
m2.param.set('R_out',R_out_str);
m2.param.set('L', num2str(R_out));
m2.study('std1').run;

time2      = mphglobal(m2,'t','unit','min');
E_cell2    = mphglobal(m2,'E_cell','unit','V');
I_cell2    = mphglobal(m2,'I_cell','unit','A');
I1C_cyl    = mphglobal(m2,'I_1C_2D','unit','A');
ModelUtil.remove('model2');

%% ────────────────────── 2. C-rate 계산 & 0구간 필터 ────────────────────
cRate1 = -I_cell1./I1C_tube;    % 방전-전류를 양수로
cRate2 = -I_cell2./I1C_cyl;

nz1 = cRate1~=0;                % 0 → NaN 처리(안 보이게)
nz2 = cRate2~=0;
cRate1(~nz1)=NaN; cRate2(~nz2)=NaN;

%% ────────────────────── 3. 영상 저장 설정 ──────────────────────────────
video_dir = 'C:\Users\user\Desktop\Figure\Figure 1\video 파일';
if ~exist(video_dir,'dir'), mkdir(video_dir); end
vobj = VideoWriter(fullfile(video_dir,'figure1_V,I.mp4'),'MPEG-4');
vobj.FrameRate = 10;   open(vobj);

%% ────────────────────── 4. 그래프 초기 세팅 ────────────────────────────
lw = 1;
colors = {'#925E9F', '#EFC000'}; 

figure; hold on; box on;

% ── Voltage (좌측 y축)
yyaxis left
hV_tube = plot(NaN,NaN,'o-','Color',colors{1},'LineWidth',lw,...
               'MarkerIndices',[],'DisplayName','tube.V');
hV_cyl  = plot(NaN,NaN,'x-','Color',colors{1},'LineWidth',lw,...
               'MarkerIndices',[],'DisplayName','cyl.V');
ylabel('Voltage [V]','FontSize',15,'Color','k');
set(gca,'YColor','k');

ylim([ min([E_cell1(:); E_cell2(:)]) - 0.1 , ...
      max([E_cell1(:); E_cell2(:)]) + 0.1 ]);

% ── C-rate (우측 y축)
yyaxis right
hI_tube = plot(NaN,NaN,'o-','Color',colors{2},'LineWidth',lw,...
               'MarkerIndices',[],'DisplayName','tube.I');
hI_cyl  = plot(NaN,NaN,'x-','Color',colors{2},'LineWidth',lw,...
               'MarkerIndices',[],'DisplayName','cyl.I');
ylabel('C-rate','FontSize',15,'Color','k');
ylim([0 12]);
set(gca,'YColor','k');

% ── 공통 축 설정
xlabel('Time [min]','FontSize',15);
set(gca,'FontSize',15);
xlim([0, min(max(time1), max(time2))]);
lgd = legend('Location','northwest','NumColumns',2,'Orientation','horizontal');
lgd.FontSize = 12;

% ── 여백 미세 조정
set(gca,'Position',[0.13 0.18 0.76 0.72]);

%% ────────────────────── 5. 프레임 루프 ────────────────────────────────
N = max([numel(time1) numel(time2)]);
tempfile = [tempname,'.png'];
target_width  = 1544;
target_height = 1218;

for i = 1:N
    % Voltage 업데이트
    if i<=numel(time1)
        hV_tube.XData = time1(1:i);
        hV_tube.YData = E_cell1(1:i);
        hV_tube.MarkerIndices = find(mod(1:i,  round(numel(time1)/10))==0);
    end
    if i<=numel(time2)
        hV_cyl.XData  = time2(1:i);
        hV_cyl.YData  = E_cell2(1:i);
        hV_cyl.MarkerIndices = find(mod(1:i,  round(numel(time2)/10))==0);
    end

    % C-rate 업데이트
    if i<=numel(time1)
        hI_tube.XData = time1(1:i);
        hI_tube.YData = cRate1(1:i);
        hI_tube.MarkerIndices = find(mod(1:i,  round(numel(time1)/10))==0);
    end
    if i<=numel(time2)
        hI_cyl.XData  = time2(1:i);
        hI_cyl.YData  = cRate2(1:i);
        hI_cyl.MarkerIndices = find(mod(1:i,  round(numel(time2)/10))==0);
    end

    drawnow;

    % 프레임 저장
    print(gcf,'-dpng','-r300','-loose',tempfile);
    img = imread(tempfile);
    img = imresize(img,[target_height target_width]);
    writeVideo(vobj,img);
end

close(vobj); delete(tempfile);
disp('동영상 저장 완료');
