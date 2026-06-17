% Extract frames 40, 80, 130, 180 from the GIF to check each phase
gifFile = 'animate_3DVE.gif';
checkFrames = [40, 80, 130, 180];
for i = 1:length(checkFrames)
    f = checkFrames(i);
    [img, cmap] = imread(gifFile, f);
    rgb = ind2rgb(img, cmap);
    imwrite(rgb, sprintf('check_frame_%03d.png', f));
end
disp('done')
