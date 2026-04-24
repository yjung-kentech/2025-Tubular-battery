clear; clc; close all;

%% 파일 경로 및 기본 설정
img_dir = 'C:\Users\user\Desktop\새figure\png';
imageFiles = {'figure6a.png', 'figure6b.png', 'figure6c.png', ...
              'colorbar(25-45).png', 'figure6d.png', 'figure6e_new.png', 'figure6f.png'};
labels = {'a', 'b', 'c', 'd', 'e', 'f'};

% 윗줄(4개: a, b, c, colorbar), 아랫줄(3개: d, e, f)
numTop = 4;
numBottom = 3;

% 공통 높이 (축 비율)
commonHeight = 0.45;

% 좌우 상하 여백, 줄 간 간격 설정
leftMargin = 0.05;  
rightMargin = 0.07; 
topMargin = 0.05;   
bottomMargin = 0.05;

rowSpacing = -0.5;          % 두 줄 사이 간격
extraSpacingBottom = 0.03;  % 아랫줄 이미지 간 추가 간격
extraSpacingColorbar = 0.01; 
alignmentAdjustment = 0.04; % 아랫줄 왼쪽/오른쪽으로 조정

%% 이미지 불러오기
images = cell(1,7);
sizes = zeros(7,2);  % [height, width]
for i = 1:7
    fullImagePath = fullfile(img_dir, imageFiles{i});
    if exist(fullImagePath, 'file') ~= 2
        error('File not found: %s', fullImagePath);
    end
    images{i} = imread(fullImagePath);
    [sizes(i,1), sizes(i,2), ~] = size(images{i});
end

%% 비율 계산 및 스케일링
aspectRatios = sizes(:,2) ./ sizes(:,1);       % (width / height)
scaledWidths = aspectRatios * commonHeight;    % 높이를 commonHeight로 통일

% colorbar(4번째) 추가 간격
scaledWidths(4) = scaledWidths(4) + extraSpacingColorbar;

% 윗줄/아랫줄 가로 길이
totalTopWidth = sum(scaledWidths(1:4));
totalBottomWidth = sum(scaledWidths(5:7));

% 전체 가용 폭
availableWidth = 1 - leftMargin - rightMargin;

% 윗줄과 아랫줄 중 긴 쪽에 맞춰 scaleFactor
scaleFactor = availableWidth / max(totalTopWidth, totalBottomWidth);
scaledWidths = scaledWidths * scaleFactor;

%% 아래줄 개별 폭 조정 (d, e, f)
% - 먼저 평균값 계산
avgWidth = mean(scaledWidths(5:7));

% - d, e, f 각각 팩터 지정
dFactor = 0.95;  % d는 변경 없음
eFactor = 1.05;  % e는 5% 축소
fFactor = 0.95;  % f는 8% 확대 (원하는 만큼 조정)

scaledWidths(5) = avgWidth * dFactor; 
scaledWidths(6) = avgWidth * eFactor;
scaledWidths(7) = avgWidth * fFactor;

% 아랫줄 폭 재계산
totalBottomWidth = sum(scaledWidths(5:7));

%% Figure 생성
figure('Units', 'normalized', 'Position', [0.1, 0.1, 0.8, 0.8]);
set(gcf, 'Color', 'w');
fontsize = 25;

%% 윗줄 (a=1, b=2, c=3, colorbar=4)
% 각 이미지별 x 오프셋 설정
offsetA = 0.005;       % figure a 오른쪽 이동값
offsetB = 0.005;       % figure b 오른쪽 이동값
offsetC = 0.02;        % figure c 오른쪽 이동값
offsetColorbar = 0.01; % colorbar 오른쪽 이동값

y_top = 1 - topMargin - commonHeight;
x_start_top = leftMargin + (availableWidth - sum(scaledWidths(1:4))) / 2;

for i = 1:4
    % i 별로 다른 offset 적용
    if i == 1
        xPos = x_start_top + offsetA;      % a
    elseif i == 2
        xPos = x_start_top + offsetB;      % b
    elseif i == 3
        xPos = x_start_top + offsetC;      % c
    else
        xPos = x_start_top + offsetColorbar; % colorbar
    end
    
    ax = axes('Units','normalized',...
        'Position',[xPos, y_top, scaledWidths(i), commonHeight]);
    imshow(images{i});
    axis off;
    
    hold on;
    if i < 4  % a, b, c만 라벨
        text(ax, -0.035, 0.9, labels{i}, 'Units','normalized',...
            'FontWeight','bold','FontSize',fontsize,...
            'Color','black','BackgroundColor','white',...
            'Margin',1,'VerticalAlignment','top','HorizontalAlignment','left');
    end

    if i == 4
        cbLabel = 'Temperature [°C]';
        cbFont  = 20;
        set(ax, 'Clipping','off');

        text(ax, 0.9, 0.45, cbLabel, 'Units','normalized', ...
            'Rotation', 90, ...
            'FontSize', cbFont, ...
            'Color','black', ...
            'HorizontalAlignment','center', ...
            'VerticalAlignment','middle', ...
            'Clipping','off');
    end

    hold off;

    % colorbar(3→4)는 extraSpacingColorbar가 있으니 유지
    if i == 3
        x_start_top = x_start_top + scaledWidths(i) + extraSpacingColorbar;
    else
        x_start_top = x_start_top + scaledWidths(i);
    end
end


%% 아랫줄 (d, e, f)
x_start_bottom = leftMargin + (availableWidth - totalBottomWidth) / 2 - alignmentAdjustment;
y_bottom = bottomMargin;

% 라벨 위치(오프셋) 설정
d_label_x = -0.015; d_label_y = 1.095;
e_label_x = -0.025; e_label_y = 1.05;
f_label_x = -0.038; f_label_y = 1.08;

for i = 5:7
    % d/f 오프셋 등 (원하면 수정)
    if i == 5
        currentY = y_bottom - 0.01;  % d
    elseif i == 7
        currentY = y_bottom - 0.01;  % f ← 위로 올림!
    else
        currentY = y_bottom;        % e
    end

    ax = axes('Units', 'normalized', ...
        'Position', [x_start_bottom, currentY, scaledWidths(i), commonHeight]);
    imshow(images{i});
    axis off;

    hold on;
    switch i
        case 5  % d
            text(ax, d_label_x, d_label_y, labels{i-1}, 'Units', 'normalized',...
                'FontWeight', 'bold', 'FontSize', fontsize,...
                'Color', 'black', 'BackgroundColor', 'white',...
                'Margin', 1);
        case 6  % e
            text(ax, e_label_x, e_label_y, labels{i-1}, 'Units', 'normalized',...
                'FontWeight', 'bold', 'FontSize', fontsize,...
                'Color', 'black', 'BackgroundColor', 'white',...
                'Margin', 1);
        case 7  % f
            text(ax, f_label_x, f_label_y, labels{i-1}, 'Units', 'normalized',...
                'FontWeight', 'bold', 'FontSize', fontsize,...
                'Color', 'black', 'BackgroundColor', 'white',...
                'Margin', 1);
    end
    hold off;

    x_start_bottom = x_start_bottom + scaledWidths(i) + extraSpacingBottom;
end

%% 결과 저장
outputPath = fullfile(img_dir, 'figure6_소문자.png');
exportgraphics(gcf, outputPath, 'Resolution', 300);
