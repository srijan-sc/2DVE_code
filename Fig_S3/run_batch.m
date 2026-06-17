cd(fileparts(mfilename('fullpath')));

delays = {'200fs', '300fs', '500fs', '800fs'};
labels = {'200 fs', '300 fs', '500 fs', '800 fs'};

for k = 1:4
    raw         = readcell(['dmso_' delays{k} '.csv']);
    fig_label   = labels{k};
    output_name = ['plot_' delays{k} '_dmso'];
    run_plot;
    close(fig);
end
