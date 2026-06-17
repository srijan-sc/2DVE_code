cd(fileparts(mfilename('fullpath')));
files = {{'300fs_HBQ.csv','300 fs','plot_300fs_HBQ'}, {'400fs_HBQ.csv','400 fs','plot_400fs_HBQ'}, {'800fs_HBQ.csv','800 fs','plot_800fs_HBQ'}};
for ii = 1:numel(files)
    csv_file    = files{ii}{1};
    fig_label   = files{ii}{2};
    output_name = files{ii}{3};
    run_plot;
    close all;
    clearvars -except files ii;
end
