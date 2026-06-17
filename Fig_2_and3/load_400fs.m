% load_400fs.m — parse 400fs_HBQ.csv into w1, w3, and data matrix
raw = readcell('400fs_HBQ.csv');

% w3: first row, columns 2 onward
w3 = cell2mat(raw(1, 2:end));   % 1 x N row vector

% w1: first column, rows 2 onward — cells are like "2→2592.63594"
w1_col = raw(2:end, 1);
w1 = zeros(length(w1_col), 1);
for i = 1:length(w1_col)
    s = char(string(w1_col{i}));
    % extract the last number after any non-numeric separator
    tok = regexp(s, '[\d.]+$', 'match');
    w1(i) = str2double(tok{1});
end
w1 = w1';   % 1 x M row vector

% data: rows 2 onward, columns 2 onward  (size: M x N)
% data(i,j) = value at w1(i), w3(j)
data = cell2mat(raw(2:end, 2:end));

fprintf('w1: %d points, %.2f to %.2f cm-1\n', numel(w1), min(w1), max(w1));
fprintf('w3: %d points, %.2f to %.2f cm-1\n', numel(w3), min(w3), max(w3));
fprintf('data size: %d x %d\n', size(data,1), size(data,2));

% Save to CSV
writematrix(w1(:),  'w1.csv');
writematrix(w3(:),  'w3.csv');
writematrix(data,   'data.csv');
fprintf('Saved: w1.csv, w3.csv, data.csv\n');
