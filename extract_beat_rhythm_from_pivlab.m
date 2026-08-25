function [summary, beats, traceTable] = extract_beat_rhythm_from_pivlab(folder, fps, umPerPixel, varargin)
% EXTRACT_BEAT_RHYTHM_FROM_PIVLAB
% Derive a rhythm trace and beat timing from one PIVlab vector-field export
% per consecutive image pair.
%
% REQUIRED INPUTS
%   folder       Folder containing PIVlab exports (.csv, .txt, or .dat).
%                One file = one frame-pair vector field; files must have a
%                sortable frame number in the filename.
%   fps          Original video rate in frames/s.  For your recordings: 20.
%   umPerPixel   Spatial calibration. For the supplied movies, start with
%                1.22 (plastic) or 1.23 (scaffold), then replace with your
%                exact scale-bar calibration.
%
% NAME-VALUE OPTIONS
%   'Columns'       [x y u v] numeric-column indices in the export (default [1 2 3 4]).
%   'ROI'           [xmin xmax ymin ymax] in PIVlab x/y units (default []).
%   'Mode'          'center' (recommended), 'axis', or 'speed' (default 'center').
%   'AxisAngleDeg'  Tissue-axis angle for Mode='axis' (default 0).
%   'Center'        [x0 y0] for Mode='center' (default: ROI/vector-field centre).
%   'Polarity'      +1 or -1 for Mode='axis'; set so contraction is positive (default +1).
%   'MaxBPM'        Physiological upper bound used to prevent duplicate peaks (default 240).
%   'MinPromMAD'    Peak prominence in robust-noise units (default 3).
%   'SmoothSec'     Smoothing duration, seconds (default 0.10).
%   'SavePrefix'    Prefix for CSV/PNG outputs in folder (default 'piv_rhythm').
%
% OUTPUTS
%   summary      One-row table: beat count, median IBI, BPM, rhythm CV, etc.
%   beats        One row/detected beat.
%   traceTable   One row/PIV frame-pair with raw and smoothed waveform.
%
% INTERPRETATION
%   'center' calculates inward velocity toward a chosen centre. This is useful
%   for a compact/roughly symmetric contractile region. For aligned sheets, set
%   Mode='axis' and inspect vector overlays to choose the contraction polarity.
%   'speed' uses unsigned speed and may count contraction and relaxation as two
%   events per beat; use it only as a fallback.
%
% REQUIREMENT: Signal Processing Toolbox (findpeaks).

p = inputParser;
p.addParameter('Columns',[1 2 3 4],@(x)isnumeric(x)&&numel(x)==4);
p.addParameter('ROI',[],@(x)isnumeric(x)&&(isempty(x)||numel(x)==4));
p.addParameter('Mode','center',@(x)ischar(x)||isstring(x));
p.addParameter('AxisAngleDeg',0,@isnumeric);
p.addParameter('Center',[],@(x)isnumeric(x)&&(isempty(x)||numel(x)==2));
p.addParameter('Polarity',1,@(x)isnumeric(x)&&isscalar(x)&&any(x==[-1 1]));
p.addParameter('MaxBPM',240,@(x)isnumeric(x)&&isscalar(x)&&x>0);
p.addParameter('MinPromMAD',3,@(x)isnumeric(x)&&isscalar(x)&&x>0);
p.addParameter('SmoothSec',0.10,@(x)isnumeric(x)&&isscalar(x)&&x>=0);
p.addParameter('SavePrefix','piv_rhythm',@(x)ischar(x)||isstring(x));
p.parse(varargin{:});
o = p.Results;

% ----- 1. Read and naturally sort vector-field files -----
ext = {'*.csv','*.txt','*.dat'};
files = [];
for k = 1:numel(ext)
    files = [files; dir(fullfile(folder,ext{k}))]; %#ok<AGROW>
end
if isempty(files)
    error('No .csv, .txt, or .dat files found in %s', folder);
end
[~,ord] = natural_file_order({files.name});
files = files(ord);
if numel(files) < 8
    warning('Only %d PIV fields found. Rhythm estimates need a longer recording.',numel(files));
end

dt = 1/fps;
n = numel(files);
waveRaw = nan(n,1); motionSpeed = nan(n,1); nVec = zeros(n,1);

for i = 1:n
    A = readmatrix(fullfile(files(i).folder,files(i).name));
    A = A(:,o.Columns);
    A = A(all(isfinite(A),2),:);
    x=A(:,1); y=A(:,2); u=A(:,3); v=A(:,4);

    % Remove any user-defined region and zero-length/invalid vectors.
    keep = hypot(u,v) > 0;
    if ~isempty(o.ROI)
        keep = keep & x>=o.ROI(1) & x<=o.ROI(2) & y>=o.ROI(3) & y<=o.ROI(4);
    end
    x=x(keep); y=y(keep); u=u(keep); v=v(keep);
    nVec(i)=numel(u);
    if nVec(i)<10
        continue
    end

    % Reject the fastest 5% of retained vectors: commonly bad correlation vectors.
    magPix = hypot(u,v);
    cutoff = prctile(magPix,95);
    keep = magPix <= cutoff;
    x=x(keep); y=y(keep); u=u(keep); v=v(keep); magPix=magPix(keep);
    velUmS = magPix * umPerPixel / dt;
    motionSpeed(i) = median(velUmS,'omitnan');

    switch lower(string(o.Mode))
        case "center"
            if isempty(o.Center)
                c = [median(x,'omitnan') median(y,'omitnan')];
            else
                c = o.Center;
            end
            % Unit vectors point from each sample position toward the chosen centre.
            rx = c(1)-x; ry = c(2)-y; r = hypot(rx,ry);
            ok = r > max(1,0.02*max(range(x),range(y)));
            inwardPix = (u(ok).*rx(ok) + v(ok).*ry(ok))./r(ok);
            waveRaw(i) = median(inwardPix * umPerPixel / dt,'omitnan');
        case "axis"
            e = [cosd(o.AxisAngleDeg), sind(o.AxisAngleDeg)];
            signedPix = o.Polarity*(u*e(1) + v*e(2));
            waveRaw(i) = median(signedPix * umPerPixel / dt,'omitnan');
        case "speed"
            waveRaw(i) = motionSpeed(i);
        otherwise
            error('Mode must be center, axis, or speed.');
    end
end

if any(nVec<10)
    warning('%d fields had <10 valid vectors and were retained as missing values.',sum(nVec<10));
end

t = ((1:n)'-0.5)*dt; % time at centre of the image pair
% Fill isolated missing fields before smoothing. Do not use a long gap as data.
waveFilled = fillmissing(waveRaw,'linear','EndValues','nearest');
span = max(3,2*floor((o.SmoothSec/dt)/2)+1); % odd number of samples
waveSmooth = smoothdata(waveFilled,'movmedian',span);
waveDetrended = waveSmooth - movmedian(waveSmooth,max(5,round(2/dt)),'Endpoints','shrink');

% Robust, data-specific prominence: estimate noise from first differences.
noise = mad(diff(waveDetrended),1)/sqrt(2);
if ~isfinite(noise) || noise==0
    noise = max(eps, mad(waveDetrended,1));
end
minProm = o.MinPromMAD*noise;
minDistance = max(1,round((60/o.MaxBPM)*fps));
[pk,loc,w,prom] = findpeaks(waveDetrended, ...
    'MinPeakProminence',minProm, 'MinPeakDistance',minDistance);

beatTime = t(loc);
ibi = [NaN; diff(beatTime)];
instBPM = 60./ibi;
if numel(beatTime)>=3
    medIBI = median(ibi(2:end),'omitnan');
    bpm = 60/medIBI;
    cvIBI = std(ibi(2:end),'omitnan')/mean(ibi(2:end),'omitnan');
else
    medIBI = NaN; bpm = NaN; cvIBI = NaN;
    warning('Fewer than 3 beats passed the fixed detection rule. Do not report BPM/CV; acquire a longer movie or inspect PIV settings.');
end

traceTable = table((1:n)',t,waveRaw,waveSmooth,waveDetrended,motionSpeed,nVec, ...
    'VariableNames',{'pair','time_s','contraction_raw_um_s','contraction_smooth_um_s','contraction_detrended_um_s','median_speed_um_s','n_vectors'});
beats = table((1:numel(loc))',loc,beatTime,pk,prom,w,ibi,instBPM, ...
    'VariableNames',{'beat_number','pair','time_s','peak_um_s','prominence_um_s','width_samples','IBI_s','instantaneous_BPM'});
summary = table(n,dt,o.Mode,sum(isfinite(waveRaw)),numel(loc),medIBI,bpm,cvIBI,minProm,minDistance, ...
    'VariableNames',{'n_pairs','pair_interval_s','mode','valid_fields','detected_beats','median_IBI_s','BPM','CV_IBI','min_peak_prominence_um_s','min_peak_distance_frames'});

% ----- 2. Save auditable tables and a visual QC plot -----
prefix = fullfile(folder,char(o.SavePrefix));
writetable(traceTable,[prefix '_trace.csv']);
writetable(beats,[prefix '_beats.csv']);
writetable(summary,[prefix '_summary.csv']);

fig = figure('Color','w','Position',[100 100 1100 650]);
tiledlayout(2,1,'TileSpacing','compact');
nexttile;
plot(t,motionSpeed,'Color',[.45 .45 .45],'LineWidth',1); grid on
xlabel('Time (s)'); ylabel('Median speed (µm/s)');
title('Unsigned apparent motion (QC only; may include relaxation)');
nexttile; hold on
plot(t,waveRaw,'Color',[.70 .80 .85],'LineWidth',1,'DisplayName','raw');
plot(t,waveSmooth,'Color',[0 .45 .55],'LineWidth',1.5,'DisplayName','smoothed');
plot(t,waveDetrended,'Color',[.10 .10 .10],'LineWidth',1,'DisplayName','detrended');
plot(beatTime,pk,'v','MarkerFaceColor',[.75 .20 .10],'MarkerEdgeColor','none','MarkerSize',7,'DisplayName','accepted peaks');
grid on; legend('Location','best'); xlabel('Time (s)'); ylabel('Contraction trace (µm/s)');
title(sprintf('Mode: %s | beats=%d | BPM=%s',string(o.Mode),numel(loc),num2str(bpm,'%.1f')));
exportgraphics(fig,[prefix '_QC.png'],'Resolution',200);

fprintf('\nSaved:\n  %s_trace.csv\n  %s_beats.csv\n  %s_summary.csv\n  %s_QC.png\n',prefix,prefix,prefix,prefix);
end

function [namesSorted, order] = natural_file_order(names)
% Sort filenames by their final numeric token, then alphabetically.
% Example: field_2.txt comes before field_10.txt.
n = numel(names); key = zeros(n,1);
for i=1:n
    token = regexp(names{i},'\d+(?!.*\d)','match','once');
    if isempty(token), key(i)=inf; else, key(i)=str2double(token); end
end
[~,order] = sortrows([key (1:n)'],[1 2]);
namesSorted = names(order);
end
