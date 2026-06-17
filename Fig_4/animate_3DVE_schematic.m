% animate_3DVE_schematic.m
%
% Story:
%   1. 2D spectra (ω₁ × ω₃) are collected at many t₂ waiting times
%      -> slices fan out, each labelled with a t₂ value
%   2. Fourier transform along t₂  ->  label morphs to ω₂
%   3. Slices compress into a 3D cube with axes ω₁, ω₂, ω₃
%   4. Cube gently rocks to reveal all three axes
%
% Output: animate_3DVE.gif  and  animate_3DVE.mp4

clear; close all; clc;

%% Parameters
N       = 40;    % grid points per 2D slice
nSlice  = 8;     % number of t₂ slices
fps     = 12;
gifFile = 'animate_3DVE.gif';
mp4File = 'animate_3DVE.mp4';

%% Synthetic 2D spectrum
[X, Y] = meshgrid(linspace(0,1,N), linspace(0,1,N));
blob = @(cx,cy,sx,sy) exp(-((X-cx).^2/(2*sx^2) + (Y-cy).^2/(2*sy^2)));
base = 0.9*blob(0.35,0.35,0.10,0.10) + 0.7*blob(0.65,0.65,0.09,0.09) + ...
       0.4*blob(0.35,0.65,0.07,0.11) + 0.4*blob(0.65,0.35,0.08,0.10);
base = base / max(base(:));

t2_vals     = linspace(0, 500, nSlice);
omega_beat  = 2*pi / 350;
slices      = zeros(N, N, nSlice);
for k = 1:nSlice
    slices(:,:,k) = max(0, base * (1 + 0.35*cos(omega_beat*t2_vals(k))));
end

%% Colormap: white -> deep blue
r = linspace(1, 0.08, 256)';
g = linspace(1, 0.08, 256)';
b = linspace(1, 0.60, 256)';
blueMap = [r g b];

%% Geometry
cubeW      = 0.85; cubeH = 0.85; cubeD = 0.85;
fanSpreadX = 0.38;
fanSpreadY = 0.22;
zFinal     = linspace(0, cubeD, nSlice);

%% Create ONE figure reused for all frames (much faster than close/reopen)
fig = figure('Color','w','Position',[50 50 1100 520], ...
             'Visible','off','Renderer','zbuffer');

%% Video writer
vw = VideoWriter(mp4File, 'MPEG-4');
vw.FrameRate = fps; vw.Quality = 95;
open(vw);
frameCount = 0;

%% =========================================================================
%  Shared draw helpers (inline for speed)
%% =========================================================================
function drawArrowAnnotation(fig, label, alpha_val)
    annotation(fig,'arrow',[0.56 0.67],[0.50 0.50], ...
        'Color',[0.10 0.60 0.10],'LineWidth',5, ...
        'HeadWidth',20,'HeadLength',16);
    if ~isempty(label) && alpha_val > 0.05
        c = [0.10 0.60 0.10]*alpha_val + [1 1 1]*(1-alpha_val);
        annotation(fig,'textbox',[0.555 0.53 0.13 0.06], ...
            'String',label,'FontSize',11,'FontWeight','bold', ...
            'Color',c,'EdgeColor','none', ...
            'HorizontalAlignment','center','Interpreter','none');
    end
end

function axL = buildLeftAx(fig, X, Y, slices, nVis, nSlice, ...
                             spreadX, spreadY, blueMap, t2_vals)
    axL = axes(fig,'Position',[0.03 0.08 0.46 0.84]);
    hold(axL,'on'); axis(axL,'off');
    dz = 0.18;   % z-gap between slices — this makes stacking clearly visible
    for k = 1:nVis
        xOff = (k-1)/nSlice * spreadX;
        yOff = (k-1)/nSlice * spreadY;
        zPos = (k-1) * dz;   % stack upward in z
        surf(axL, X+xOff, Y+yOff, zeros(size(X))+zPos, ...
            slices(:,:,k),'EdgeColor','none','FaceAlpha',0.80);
    end
    colormap(axL, blueMap); caxis(axL,[0 1]);
    xlim(axL,[-0.05 1.60]); ylim(axL,[-0.25 1.40]); zlim(axL,[-0.1 1.8]);
    view(axL,-42,18);
    text(axL,0.50,-0.22,-0.05,'\omega_1 (cm^{-1})', ...
        'FontSize',13,'FontWeight','bold','HorizontalAlignment','center','Interpreter','tex');
    text(axL,-0.14,0.5,0.0,'\omega_3 (cm^{-1})', ...
        'FontSize',13,'FontWeight','bold','Rotation',90,'HorizontalAlignment','center','Interpreter','tex');
    % label each visible slice on the right edge
    for k = 1:nVis
        xOff = (k-1)/nSlice * spreadX;
        yOff = (k-1)/nSlice * spreadY;
        zPos = (k-1) * dz;
        text(axL, 1.04+xOff, 0.5+yOff, zPos, ...
            sprintf('t_2 = %d fs', round(t2_vals(k))), ...
            'FontSize',9,'Color',[0.15 0.15 0.55],'Interpreter','tex', ...
            'FontWeight','bold');
    end
end

function axR = buildRightAx(fig, X, Y, slices, nSlice, zFinal, ...
                              cubeW, cubeH, cubeD, blueMap, az, omega2_alpha)
    axR = axes(fig,'Position',[0.58 0.08 0.38 0.84]);
    hold(axR,'on'); axis(axR,'off');
    for k = 1:nSlice
        surf(axR, X*cubeW, Y*cubeH, zeros(size(X))+zFinal(k), ...
            slices(:,:,k),'EdgeColor','none','FaceAlpha',0.82);
    end
    % wireframe
    c = [0.3 0.3 0.3]; lw = 1.4;
    plot3(axR,[0 cubeW],[0 0],[0 0],'Color',c,'LineWidth',lw);
    plot3(axR,[cubeW cubeW],[0 cubeH],[0 0],'Color',c,'LineWidth',lw);
    plot3(axR,[cubeW 0],[cubeH cubeH],[0 0],'Color',c,'LineWidth',lw);
    plot3(axR,[0 0],[cubeH 0],[0 0],'Color',c,'LineWidth',lw);
    plot3(axR,[0 cubeW],[0 0],[cubeD cubeD],'Color',c,'LineWidth',lw);
    plot3(axR,[cubeW cubeW],[0 cubeH],[cubeD cubeD],'Color',c,'LineWidth',lw);
    plot3(axR,[cubeW 0],[cubeH cubeH],[cubeD cubeD],'Color',c,'LineWidth',lw);
    plot3(axR,[0 0],[cubeH 0],[cubeD cubeD],'Color',c,'LineWidth',lw);
    plot3(axR,[0 0],[0 0],[0 cubeD],'Color',c,'LineWidth',lw);
    plot3(axR,[cubeW cubeW],[0 0],[0 cubeD],'Color',c,'LineWidth',lw);
    plot3(axR,[cubeW cubeW],[cubeH cubeH],[0 cubeD],'Color',c,'LineWidth',lw);
    plot3(axR,[0 0],[cubeH cubeH],[0 cubeD],'Color',c,'LineWidth',lw);
    colormap(axR, blueMap); caxis(axR,[0 1]);
    xlim(axR,[-0.12 1.10]); ylim(axR,[-0.12 1.20]); zlim(axR,[-0.05 1.05]);
    view(axR, az, 30);
    % axis labels
    text(axR, cubeW/2,-0.15,-0.02,'\omega_1 (cm^{-1})', ...
        'FontSize',12,'FontWeight','bold','HorizontalAlignment','center','Interpreter','tex');
    text(axR,-0.15,cubeH/2,cubeD/2,'\omega_3 (cm^{-1})', ...
        'FontSize',12,'FontWeight','bold','Rotation',90,'HorizontalAlignment','center','Interpreter','tex');
    t2_alpha = 1 - omega2_alpha;
    if t2_alpha > 0.05
        text(axR,cubeW/2,cubeH+0.12,cubeD/2,'t_2 (fs)', ...
            'FontSize',12,'FontWeight','bold','HorizontalAlignment','center','Interpreter','tex', ...
            'Color',[0.5 0.3 0.1]*t2_alpha+[1 1 1]*(1-t2_alpha));
    end
    if omega2_alpha > 0.05
        text(axR,cubeW/2,cubeH+0.12,cubeD/2,'\omega_2 (cm^{-1})', ...
            'FontSize',12,'FontWeight','bold','HorizontalAlignment','center','Interpreter','tex', ...
            'Color',[0 0 0]*omega2_alpha+[1 1 1]*(1-omega2_alpha));
    end
end

function captureFrame(fig, vw, gifFile, fps, frameCount)
    img = print(fig,'-RGBImage','-r72');
    writeVideo(vw, img);
    imgS = img(1:2:end,1:2:end,:);
    [idx,cmap] = rgb2ind(imgS,128);
    if frameCount == 1
        imwrite(idx,cmap,gifFile,'gif','LoopCount',Inf,'DelayTime',1/fps);
    else
        imwrite(idx,cmap,gifFile,'gif','WriteMode','append','DelayTime',1/fps);
    end
end

function y = smoothstep(x)
    x = max(0,min(1,x));
    y = 3*x.^2 - 2*x.^3;
end

%% =========================================================================
%  PHASE 1 (50 frames): slices appear one by one
%% =========================================================================
nP1 = 50;
for f = 1:nP1
    clf(fig);
    nVis = max(1, round((f/nP1)*nSlice));
    buildLeftAx(fig,X,Y,slices,nVis,nSlice,fanSpreadX,fanSpreadY,blueMap,t2_vals);
    drawArrowAnnotation(fig,'',0);
    frameCount = frameCount+1;
    captureFrame(fig,vw,gifFile,fps,frameCount);
end

%% =========================================================================
%  PHASE 2 (35 frames): FT label fades in on arrow
%% =========================================================================
nP2 = 35;
for f = 1:nP2
    clf(fig);
    buildLeftAx(fig,X,Y,slices,nSlice,nSlice,fanSpreadX,fanSpreadY,blueMap,t2_vals);
    drawArrowAnnotation(fig,'Fourier Transform', min(1,f/15));
    frameCount = frameCount+1;
    captureFrame(fig,vw,gifFile,fps,frameCount);
end

%% =========================================================================
%  PHASE 3 (70 frames): slices fly into cube; t₂ -> ω₂
%% =========================================================================
nP3 = 70;
for f = 1:nP3
    clf(fig);
    ease = smoothstep(f/nP3);

    buildLeftAx(fig,X,Y,slices,nSlice,nSlice,fanSpreadX,fanSpreadY,blueMap,t2_vals);
    drawArrowAnnotation(fig,'Fourier Transform',1.0);

    % Right: slices transition from fanned -> cube positions
    axR = axes(fig,'Position',[0.58 0.08 0.38 0.84]);
    hold(axR,'on'); axis(axR,'off');
    dz_fan = 0.18;
    for k = 1:nSlice
        xOff = (k-1)/nSlice*fanSpreadX*(1-ease);
        yOff = (k-1)/nSlice*fanSpreadY*(1-ease);
        zStart = (k-1)*dz_fan;
        zPos = zStart*(1-ease) + zFinal(k)*ease;
        surf(axR,X*cubeW+xOff,Y*cubeH+yOff,zeros(size(X))+zPos, ...
            slices(:,:,k),'EdgeColor','none','FaceAlpha',0.82);
    end
    c=[0.3 0.3 0.3]; lw=1.4;
    plot3(axR,[0 cubeW],[0 0],[0 0],'Color',c,'LineWidth',lw);
    plot3(axR,[cubeW cubeW],[0 cubeH],[0 0],'Color',c,'LineWidth',lw);
    plot3(axR,[cubeW 0],[cubeH cubeH],[0 0],'Color',c,'LineWidth',lw);
    plot3(axR,[0 0],[cubeH 0],[0 0],'Color',c,'LineWidth',lw);
    plot3(axR,[0 cubeW],[0 0],[cubeD cubeD],'Color',c,'LineWidth',lw);
    plot3(axR,[cubeW cubeW],[0 cubeH],[cubeD cubeD],'Color',c,'LineWidth',lw);
    plot3(axR,[cubeW 0],[cubeH cubeH],[cubeD cubeD],'Color',c,'LineWidth',lw);
    plot3(axR,[0 0],[cubeH 0],[cubeD cubeD],'Color',c,'LineWidth',lw);
    plot3(axR,[0 0],[0 0],[0 cubeD],'Color',c,'LineWidth',lw);
    plot3(axR,[cubeW cubeW],[0 0],[0 cubeD],'Color',c,'LineWidth',lw);
    plot3(axR,[cubeW cubeW],[cubeH cubeH],[0 cubeD],'Color',c,'LineWidth',lw);
    plot3(axR,[0 0],[cubeH cubeH],[0 cubeD],'Color',c,'LineWidth',lw);
    colormap(axR,blueMap); caxis(axR,[0 1]);
    xlim(axR,[-0.12 1.10]); ylim(axR,[-0.12 1.20]); zlim(axR,[-0.05 1.05]);
    view(axR,-38,30);
    text(axR,cubeW/2,-0.15,-0.02,'\omega_1 (cm^{-1})','FontSize',12,'FontWeight','bold','HorizontalAlignment','center','Interpreter','tex');
    text(axR,-0.15,cubeH/2,cubeD/2,'\omega_3 (cm^{-1})','FontSize',12,'FontWeight','bold','Rotation',90,'HorizontalAlignment','center','Interpreter','tex');
    t2a = 1-ease; w2a = ease;
    if t2a>0.05, text(axR,cubeW/2,cubeH+0.12,cubeD/2,'t_2 (fs)','FontSize',12,'FontWeight','bold','HorizontalAlignment','center','Interpreter','tex','Color',[0.5 0.3 0.1]*t2a+[1 1 1]*(1-t2a)); end
    if w2a>0.05, text(axR,cubeW/2,cubeH+0.12,cubeD/2,'\omega_2 (cm^{-1})','FontSize',12,'FontWeight','bold','HorizontalAlignment','center','Interpreter','tex','Color',[0 0 0]*w2a+[1 1 1]*(1-w2a)); end

    frameCount = frameCount+1;
    captureFrame(fig,vw,gifFile,fps,frameCount);
end

%% =========================================================================
%  PHASE 4 (55 frames): final cube rocks gently
%% =========================================================================
nP4 = 55;
for f = 1:nP4
    clf(fig);
    buildLeftAx(fig,X,Y,slices,nSlice,nSlice,fanSpreadX,fanSpreadY,blueMap,t2_vals);
    drawArrowAnnotation(fig,'Fourier Transform',1.0);
    az = -38 + 22*sin(2*pi*f/nP4);
    buildRightAx(fig,X,Y,slices,nSlice,zFinal,cubeW,cubeH,cubeD,blueMap,az,1.0);
    frameCount = frameCount+1;
    captureFrame(fig,vw,gifFile,fps,frameCount);
end

close(vw);
fprintf('\nDone! Frames: %d  ->  %s  and  %s\n', frameCount, gifFile, mp4File);
