
function c = redblue_3(n)
% REDBLUE_3  Blue-white-red colormap (n colors, default 64)
    if nargin < 1, n = 64; end
    half = floor(n / 2);
    rem  = n - 2*half;                      % 0 or 1 for odd n

    % blue → white
    b2w = [linspace(0,1,half)', linspace(0,1,half)', ones(half,1)];
    % white → red
    w2r = [ones(half+rem,1), linspace(1,0,half+rem)', linspace(1,0,half+rem)'];

    c = [b2w; w2r];
end
