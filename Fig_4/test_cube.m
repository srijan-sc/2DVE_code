N=40; nSlice=10; cubeW=0.85; cubeH=0.85; cubeD=0.85;
[X,Y]=meshgrid(linspace(0,1,N),linspace(0,1,N));
blob=@(cx,cy,sx,sy)exp(-((X-cx).^2/(2*sx^2)+(Y-cy).^2/(2*sy^2)));
base=0.9*blob(0.35,0.35,0.10,0.10)+0.7*blob(0.65,0.65,0.09,0.09)+ ...
     0.4*blob(0.35,0.65,0.07,0.11)+0.4*blob(0.65,0.35,0.08,0.10);
base=base/max(base(:));
t2_vals=linspace(0,500,nSlice); omega_beat=2*pi/350;
slices=zeros(N,N,nSlice);
for k=1:nSlice
    slices(:,:,k)=max(0,base*(1+0.35*cos(omega_beat*t2_vals(k))));
end
r=linspace(1,0.08,256)'; g=linspace(1,0.08,256)'; b=linspace(1,0.60,256)';
blueMap=[r g b];
zFinal=linspace(0,cubeD,nSlice);

fig=figure('Color','w','Position',[50 50 1100 520],'Visible','off','Renderer','zbuffer');

% LEFT: fanned slices
axL=axes(fig,'Position',[0.03 0.08 0.46 0.84]); hold(axL,'on'); axis(axL,'off');
fanSpreadX=0.20; fanSpreadY=0.12;
for k=1:nSlice
    xOff=(k-1)/nSlice*fanSpreadX; yOff=(k-1)/nSlice*fanSpreadY;
    surf(axL,X+xOff,Y+yOff,zeros(N,N)-k*0.002,slices(:,:,k),'EdgeColor','none','FaceAlpha',0.80);
end
colormap(axL,blueMap); caxis(axL,[0 1]);
xlim(axL,[-0.05 1.35]); ylim(axL,[-0.1 1.25]); zlim(axL,[-1 1]);
view(axL,-40,28);
text(axL,0.52,-0.13,-0.05,'\omega_1 (cm^{-1})','FontSize',13,'FontWeight','bold','HorizontalAlignment','center','Interpreter','tex');
text(axL,-0.14,0.5,-0.05,'\omega_3 (cm^{-1})','FontSize',13,'FontWeight','bold','Rotation',90,'HorizontalAlignment','center','Interpreter','tex');

% ARROW
annotation(fig,'arrow',[0.56 0.67],[0.50 0.50],'Color',[0.10 0.60 0.10],'LineWidth',5,'HeadWidth',20,'HeadLength',16);
annotation(fig,'textbox',[0.555 0.53 0.12 0.06],'String','FT','FontSize',11,'FontWeight','bold','Color',[0.10 0.60 0.10],'EdgeColor','none','HorizontalAlignment','center');

% RIGHT: cube
axR=axes(fig,'Position',[0.58 0.08 0.40 0.84]); hold(axR,'on'); axis(axR,'off');
for k=1:nSlice
    surf(axR,X*cubeW,Y*cubeH,zeros(N,N)+zFinal(k),slices(:,:,k),'EdgeColor','none','FaceAlpha',0.82);
end
c=[0.35 0.35 0.35]; lw=1.4;
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
xlim(axR,[-0.12 1.05]); ylim(axR,[-0.12 1.05]); zlim(axR,[-0.05 1.05]);
view(axR,-38,30);
text(axR,cubeW/2,-0.14,-0.02,'\omega_1 (cm^{-1})','FontSize',12,'FontWeight','bold','HorizontalAlignment','center','Interpreter','tex');
text(axR,-0.14,cubeH/2,cubeD/2,'\omega_3 (cm^{-1})','FontSize',12,'FontWeight','bold','Rotation',90,'HorizontalAlignment','center','Interpreter','tex');
text(axR,cubeW+0.06,cubeH/2,cubeD/4,'\omega_2 (cm^{-1})','FontSize',12,'FontWeight','bold','HorizontalAlignment','left','Interpreter','tex');

img=print(fig,'-RGBImage','-r96');
imwrite(img,'test_cube.png');
disp('done')
