function w1_projection_gui()
% w1_projection_gui  Interactive ω₁ projection explorer.
%   Left panel:
%     • ω₁ Min / Max  — type any wavenumber range directly
%     • SD Band       — dropdown to show/hide ±1 SD shading
%     • τ₂ points     — listbox, shift/ctrl-click, max 5; [Clear] button
%     • Plot / Export / Save CSV buttons
%   Right panel: projection traces + FTIR dual y-axis
%
%   Data cube is loaded once on launch.
cd(fileparts(mfilename('fullpath')));

% ── Paths ─────────────────────────────────────────────────────────────────
DATA_FILE = '/Users/srijan/Library/CloudStorage/OneDrive-UW/Lab_1/Analysis/HBQ_3D_analysis/data_cube_3DVE.mat';
FTIR_FILE = '../FTIR.csv';

% ── Fixed parameters ──────────────────────────────────────────────────────
PIX_RANGE    = [550 1000];
FZSIZE       = 4096;
TIME_AXIS    = 110:15:1015;
SMOOTH_SIGMA = 0.5;
SHADE_ALPHA  = 0.18;
FONT_SIZE    = 14;
LINE_WIDTH   = 2;
FTIR_COLOR   = [0.50 0.50 0.50];
COLORS = [
    0.22, 0.45, 0.69;
    0.80, 0.40, 0.00;
    0.17, 0.49, 0.36;
    0.58, 0.40, 0.74;
    0.84, 0.15, 0.16;
];

% ── Build ω₁ frequency axis from HeNe calibration ─────────────────────────
HeNeHalfCycle = 1.0554e-15;
SpeedOfLight  = 2.99792458e10;
freqRes  = (1 / HeNeHalfCycle) / SpeedOfLight / FZSIZE;
freqAxis = (0:FZSIZE-1) .* freqRes;

% ── Load data (once on launch) ────────────────────────────────────────────
fprintf('Loading data cube ... ');
tmp      = load(DATA_FILE);
dataCube = tmp.dataCube2;
fprintf('[%d × %d × %d]  (w3 × w1 × τ₂)\n', ...
    size(dataCube,1), size(dataCube,2), size(dataCube,3));

if size(dataCube,3) ~= numel(TIME_AXIS)
    error('TIME_AXIS has %d pts but cube dim 3 has %d.', numel(TIME_AXIS), size(dataCube,3));
end

ftir_raw  = readmatrix(FTIR_FILE);
ftir_freq = ftir_raw(:,1)';
ftir_int  = ftir_raw(:,2)';

% ── Figure layout ─────────────────────────────────────────────────────────
FIG_W = 1080;   FIG_H = 660;
CP_W  = 235;    % control panel pixel width
BG    = [0.93 0.93 0.93];

hf = figure('Name', 'ω₁ Projection Explorer', ...
            'Position', [80 80 FIG_W FIG_H], ...
            'Color', [1 1 1], ...
            'MenuBar', 'none', 'ToolBar', 'none', ...
            'NumberTitle', 'off', 'Resize', 'off');

annotation(hf, 'rectangle', [0 0 CP_W/FIG_W 1], ...
    'Color', 'none', 'FaceColor', BG);

% ── ω₁ range — two typed entry boxes ─────────────────────────────────────
HW = 93;    % width of each edit box
RX = 10 + HW + 23;   % x-start of right box  (= 126)

uicontrol(hf, 'Style', 'text', 'String', 'ω₁ Min (cm⁻¹)', ...
    'Position', [10 FIG_H-36 HW 18], ...
    'FontSize', 10, 'FontWeight', 'bold', 'BackgroundColor', BG, ...
    'HorizontalAlignment', 'left');
uicontrol(hf, 'Style', 'text', 'String', 'ω₁ Max (cm⁻¹)', ...
    'Position', [RX FIG_H-36 HW 18], ...
    'FontSize', 10, 'FontWeight', 'bold', 'BackgroundColor', BG, ...
    'HorizontalAlignment', 'left');

w1_min_edit = uicontrol(hf, 'Style', 'edit', 'String', '2500', ...
    'Position', [10 FIG_H-64 HW 26], 'FontSize', 12, ...
    'HorizontalAlignment', 'center');

uicontrol(hf, 'Style', 'text', 'String', '–', ...
    'Position', [10+HW+3 FIG_H-60 16 18], 'FontSize', 13, ...
    'BackgroundColor', BG, 'HorizontalAlignment', 'center');

w1_max_edit = uicontrol(hf, 'Style', 'edit', 'String', '3000', ...
    'Position', [RX FIG_H-64 HW 26], 'FontSize', 12, ...
    'HorizontalAlignment', 'center');

% ── SD band dropdown ──────────────────────────────────────────────────────
uicontrol(hf, 'Style', 'text', 'String', 'SD Band', ...
    'Position', [10 FIG_H-96 CP_W-16 18], ...
    'FontSize', 10, 'FontWeight', 'bold', 'BackgroundColor', BG, ...
    'HorizontalAlignment', 'left');

sd_popup = uicontrol(hf, 'Style', 'popupmenu', ...
    'String', {'Off', '± 1 SD'}, ...
    'Value', 1, ...
    'Position', [10 FIG_H-122 CP_W-16 24], 'FontSize', 11);

% ── τ₂ listbox — label + Clear on same row ────────────────────────────────
uicontrol(hf, 'Style', 'text', 'String', 'τ₂ (fs)', ...
    'Position', [10 FIG_H-154 138 24], ...
    'FontSize', 11, 'FontWeight', 'bold', 'BackgroundColor', BG, ...
    'HorizontalAlignment', 'left');

uicontrol(hf, 'Style', 'pushbutton', 'String', 'Clear', ...
    'Position', [155 FIG_H-156 64 24], ...
    'FontSize', 10, 'Callback', @(~,~) doClear());

tau_labels = arrayfun(@(x) sprintf('%d fs', x), TIME_AXIS, 'UniformOutput', false);
def_idx    = find(ismember(TIME_AXIS, [200 500 605]));

tau2_lb = uicontrol(hf, 'Style', 'listbox', ...
    'String', tau_labels, 'Value', def_idx, ...
    'Min', 0, 'Max', 5, ...
    'Position', [10 218 CP_W-16 278], ...
    'FontSize', 11);

% ── Action buttons ────────────────────────────────────────────────────────
uicontrol(hf, 'Style', 'pushbutton', 'String', 'Plot', ...
    'Position', [10 176 CP_W-16 34], ...
    'FontSize', 13, 'FontWeight', 'bold', ...
    'Callback', @(~,~) doPlot());

uicontrol(hf, 'Style', 'pushbutton', 'String', 'Export  PNG / SVG', ...
    'Position', [10 134 CP_W-16 34], ...
    'FontSize', 11, 'Callback', @(~,~) doExport());

uicontrol(hf, 'Style', 'pushbutton', 'String', 'Save CSV', ...
    'Position', [10 92 CP_W-16 34], ...
    'FontSize', 11, 'Callback', @(~,~) doSaveCSV());

% ── Status ────────────────────────────────────────────────────────────────
h_status = uicontrol(hf, 'Style', 'text', 'String', 'Ready.', ...
    'Position', [10 8 CP_W-16 76], 'FontSize', 10, ...
    'BackgroundColor', BG, 'HorizontalAlignment', 'left');

% ── Plot axes ─────────────────────────────────────────────────────────────
ax_pos = [(CP_W+30)/FIG_W, 78/FIG_H, (FIG_W-CP_W-58)/FIG_W, (FIG_H-110)/FIG_H];

ax = axes('Parent', hf, 'Position', ax_pos, ...
          'Color', 'w', 'Box', 'on', ...
          'FontSize', FONT_SIZE, 'FontWeight', 'bold');
xlabel(ax, '\omega_1/2\pic (cm^{-1})', 'FontSize', FONT_SIZE, 'FontWeight', 'bold');
ylabel(ax, 'Intensity (a.u.)',          'FontSize', FONT_SIZE, 'FontWeight', 'bold');

ax2 = [];

doPlot();   % auto-plot on launch

% ═════════════════════════════════════════════════════════════════════════
%  NESTED FUNCTIONS
% ═════════════════════════════════════════════════════════════════════════

    function doPlot(~, ~)

        % ── Read ω₁ range from edit boxes ─────────────────────────────────
        w1_lo = str2double(get(w1_min_edit, 'String'));
        w1_hi = str2double(get(w1_max_edit, 'String'));

        if isnan(w1_lo) || isnan(w1_hi) || w1_lo >= w1_hi
            set(h_status, 'String', 'Invalid ω₁ range — enter two numbers, min < max.');
            return;
        end

        w1_bins = round([w1_lo w1_hi] ./ freqRes);
        w1_axis = freqAxis(w1_bins(1):w1_bins(2));

        % ── Read τ₂ selection ─────────────────────────────────────────────
        sel = get(tau2_lb, 'Value');
        if isempty(sel)
            set(h_status, 'String', 'Select at least one τ₂ point.');
            return;
        end
        if numel(sel) > 5
            set(h_status, 'String', sprintf('Max 5 τ₂ points (%d selected).', numel(sel)));
            return;
        end

        % ── Build traces ──────────────────────────────────────────────────
        delete(ax.Children);
        hold(ax, 'on');
        h_lines = gobjects(numel(sel), 1);

        for ii = 1:numel(sel)
            t_idx    = sel(ii);
            actual_t = TIME_AXIS(t_idx);
            c        = COLORS(ii, :);

            slice   = dataCube(PIX_RANGE(1):PIX_RANGE(2), w1_bins(1):w1_bins(2), t_idx);
            abs_sl  = abs(slice);
            w3_mean = mean(abs_sl, 1);
            w3_std  = std(abs_sl,  0, 1);

            if SMOOTH_SIGMA > 0
                half = ceil(3 * SMOOTH_SIGMA);
                xk   = -half:half;
                kern = exp(-xk.^2 / (2*SMOOTH_SIGMA^2));
                kern = kern / sum(kern);
                w3_mean = conv(w3_mean, kern, 'same');
                w3_std  = conv(w3_std,  kern, 'same');
            end

            if get(sd_popup, 'Value') == 2
                xp = [w1_axis,          fliplr(w1_axis)];
                yp = [w3_mean + w3_std, fliplr(w3_mean - w3_std)];
                fill(ax, xp, yp, c, 'FaceAlpha', SHADE_ALPHA, ...
                     'EdgeColor', 'none', 'HandleVisibility', 'off');
            end

            h_lines(ii) = plot(ax, w1_axis, w3_mean, '-', ...
                'Color', c, 'LineWidth', LINE_WIDTH, ...
                'DisplayName', sprintf('%d fs', actual_t));
        end
        hold(ax, 'off');
        xlim(ax, [w1_lo w1_hi]);

        % ── FTIR dual y-axis ──────────────────────────────────────────────
        if ~isempty(ax2) && isgraphics(ax2)
            delete(ax2);
        end
        ax2 = axes('Parent', hf, 'Position', ax.Position, ...
                   'Color', 'none', 'YAxisLocation', 'right', ...
                   'XAxisLocation', 'top', 'XTick', []);
        hold(ax2, 'on');
        h_ftir = plot(ax2, ftir_freq, ftir_int, '-', ...
            'Color', FTIR_COLOR, 'LineWidth', 2.5, 'DisplayName', 'FTIR');
        hold(ax2, 'off');
        xlim(ax2, [w1_lo w1_hi]);
        ylabel(ax2, 'FTIR', 'FontSize', FONT_SIZE, 'FontWeight', 'bold', 'Color', FTIR_COLOR);
        set(ax2, 'FontSize', FONT_SIZE, 'FontWeight', 'bold', 'YColor', FTIR_COLOR);
        ax2.XAxis.Visible = 'off';

        legend(ax, [h_lines; h_ftir], 'Location', 'best', ...
               'FontSize', FONT_SIZE-2, 'Box', 'off');

        set(h_status, 'String', sprintf('Plotted %d trace(s)\nω₁: %d – %d cm⁻¹', ...
            numel(sel), round(w1_lo), round(w1_hi)));
    end

% ─────────────────────────────────────────────────────────────────────────

    function doClear(~, ~)
        set(tau2_lb, 'Value', 1);
        set(tau2_lb, 'Value', []);
        drawnow;
        delete(ax.Children);
        legend(ax, 'off');
        if ~isempty(ax2) && isgraphics(ax2)
            delete(ax2);
            ax2 = [];
        end
        set(h_status, 'String', 'Selection and plot cleared.');
    end

% ─────────────────────────────────────────────────────────────────────────

    function doExport(~, ~)
        if isempty(ax2) || ~isgraphics(ax2)
            set(h_status, 'String', 'Nothing to export — click Plot first.');
            return;
        end

        w1_lo = str2double(get(w1_min_edit, 'String'));
        w1_hi = str2double(get(w1_max_edit, 'String'));
        out   = sprintf('w1_projection_%d_%d', round(w1_lo), round(w1_hi));

        fig_ex = figure('Visible', 'off', 'Color', 'w', ...
            'Units', 'centimeters', 'Position', [0 0 14 9], ...
            'PaperUnits', 'centimeters', 'PaperSize', [14 9]);

        copyobj(ax,  fig_ex);
        copyobj(ax2, fig_ex);

        exportgraphics(fig_ex, [out '.svg'], 'ContentType', 'vector', 'BackgroundColor', 'white');
        exportgraphics(fig_ex, [out '.png'], 'Resolution', 300, 'BackgroundColor', 'white');
        close(fig_ex);

        fprintf('Exported: %s.svg / .png\n', out);
        set(h_status, 'String', sprintf('Saved:\n%s.svg\n%s.png', out, out));
    end

% ─────────────────────────────────────────────────────────────────────────

    function doSaveCSV(~, ~)

        w1_lo = str2double(get(w1_min_edit, 'String'));
        w1_hi = str2double(get(w1_max_edit, 'String'));

        if isnan(w1_lo) || isnan(w1_hi) || w1_lo >= w1_hi
            set(h_status, 'String', 'Invalid ω₁ range — fix before saving.');
            return;
        end

        sel = get(tau2_lb, 'Value');
        if isempty(sel)
            set(h_status, 'String', 'Select at least one τ₂ point.');
            return;
        end

        w1_bins = round([w1_lo w1_hi] ./ freqRes);
        w1_axis = freqAxis(w1_bins(1):w1_bins(2))';   % [Nw1 × 1]

        outdir = fullfile('..', 'tau2_data');
        if ~exist(outdir, 'dir'),  mkdir(outdir);  end

        saved = {};
        for ii = 1:numel(sel)
            t_idx    = sel(ii);
            actual_t = TIME_AXIS(t_idx);

            slice   = dataCube(PIX_RANGE(1):PIX_RANGE(2), w1_bins(1):w1_bins(2), t_idx);
            abs_sl  = abs(slice);
            w3_mean = mean(abs_sl, 1)';   % [Nw1 × 1]
            w3_std  = std(abs_sl,  0, 1)';

            if SMOOTH_SIGMA > 0
                half = ceil(3 * SMOOTH_SIGMA);
                xk   = -half:half;
                kern = exp(-xk.^2 / (2*SMOOTH_SIGMA^2));
                kern = (kern / sum(kern))';
                w3_mean = conv(w3_mean, kern, 'same');
                w3_std  = conv(w3_std,  kern, 'same');
            end

            T = table(w1_axis, w3_mean, w3_std, ...
                'VariableNames', {'w1_cm', 'intensity', 'sd'});

            fname = fullfile(outdir, sprintf('%dfs_HBQ.csv', actual_t));
            writetable(T, fname);
            saved{end+1} = sprintf('%d fs', actual_t); %#ok<AGROW>
            fprintf('Saved: %s\n', fname);
        end

        set(h_status, 'String', sprintf('CSV saved:\n%s', strjoin(saved, ', ')));
    end

end
