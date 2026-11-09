Bench test of the 2-speaker circuit, without playSnd GUI.
%   1. connects to RX6 + PA5s and loads the circuit
%   2. lists the circuit's tags (check data, data2, bufSzCmp, nPlayedRX6, ...)
%   3. plays audible tones: LEFT only, RIGHT only, BOTH

clear; close all;

%% settings
circuit  = 'Y:\TDT_Code_JL\PlaySnd_GUI\Code\StimPresentation\RX6_circuit\otherStim_frameClk_dualspeaker_catherine.rcx';
n_fs     = 5;      % LoadCOFsf rate index (5 -> 195312.5 Hz); [] = circuit default
amp      = 0.5;    % V peak at the DAC (EC1/ED1: keep <= 4 V)
atten_dB = 30;     % PA5 attenuation, same on both ears. 
nPA5     = 2;      % set to 1 if only one PA5 is connected
dur      = 0.5;    % s per tone
fL = 5000;  fR = 8000;   % Hz, audible and inside the EC1 range (4-110 kHz)

%% connect + load circuit
fig = figure('Visible','off');
RX6 = actxcontrol('RPco.x',[5 5 0 0],fig);
if ~RX6.ConnectRX6('GB',1) && ~RX6.ConnectRX6('USB',1)
    error('Could not connect to RX6 (GB or USB).');
end
RX6.Halt; RX6.ClearCOF;
if isempty(n_fs), ok = RX6.LoadCOF(circuit); else, ok = RX6.LoadCOFsf(circuit,n_fs); end
if ~ok, error('Failed to load circuit:\n%s', circuit); end
fs = RX6.GetSFreq;
fprintf('Loaded circuit, fs = %.2f Hz\n', fs);

for i = 1:nPA5
    PA5(i) = actxcontrol('PA5.x',[5 5 0 0],fig); %#ok<SAGROW>
    if ~PA5(i).ConnectPA5('GB',i) && ~PA5(i).ConnectPA5('USB',i)
        error('Could not connect to PA5 %d.', i);
    end
    PA5(i).SetAtten(atten_dB);
    fprintf('PA5 %d set to %g dB\n', i, atten_dB);
end

%% list tags
fprintf('\nCircuit tags:\n');
n = RX6.GetNumOf('ParTag');
for i = 1:n
    nm = RX6.GetNameOf('ParTag', i);
    fprintf('  %-15s size %d\n', nm, RX6.GetTagSize(nm));
end
need = {'data','data2','bufSzCmp','nPlayedRX6','playing','trg_sel','frame2cnt'};
tags = arrayfun(@(i) RX6.GetNameOf('ParTag',i), 1:n, 'UniformOutput', false);
missing = setdiff(need, tags);
if ~isempty(missing)
    fprintf('\n*** Missing tags: %s ***\n', strjoin(missing, ', '));
end

%% start circuit (same sequence as playSnd)
RX6.Run;
RX6.SoftTrg(1);   % start
RX6.SoftTrg(2);   % reset counters / buffer position
pause(0.2);

%% stimuli
t    = (0:round(dur*fs)-1)'/fs;
ramp = min(1, min(t, flipud(t))/0.01);  % 10 ms on/off ramps
toneL = amp * sin(2*pi*fL*t) .* ramp;
toneR = amp * sin(2*pi*fR*t) .* ramp;
z     = zeros(size(t));

tests = { 'LEFT only  (5 kHz)', toneL, z;
          'RIGHT only (8 kHz)', z,     toneR;
          'BOTH (5 + 8 kHz)',   toneL, toneR };

for k = 1:size(tests,1)
    input(sprintf('\nPress Enter to play: %s ', tests{k,1}), 's');
    play_once(RX6, tests{k,2}, tests{k,3}, fs);
end

%% clean up
RX6.Halt;
for i = 1:nPA5, PA5(i).SetAtten(120); end
fprintf('\nDone. RX6 halted, PA5s set to 120 dB.\n');

%% ---------------- local function ----------------
function play_once(RX6, L, R, fs)
    N = numel(L);
    if ~RX6.SetTagVal('bufSzCmp', N-1), warning('bufSzCmp not set'); end
    okL = RX6.WriteTagV('data',  0, L(:)');
    okR = RX6.WriteTagV('data2', 0, R(:)');
    fprintf('  wrote data (%d) / data2 (%d), %d samples\n', okL, okR, N);

    RX6.SetTagVal('trg_sel', 2);    % 2 = Soft3 software trigger ("sound only")
    RX6.SetTagVal('frame2cnt', 1);  % play on the 1st trigger (frameClk circuit)
    n0 = RX6.GetTagVal('nPlayedRX6');

    % send software triggers until the stimulus has played (max 5 tries)
    for tries = 1:5
        RX6.SoftTrg(3);
        t0 = tic;
        while toc(t0) < N/fs + 0.5
            if RX6.GetTagVal('nPlayedRX6') > n0, break; end
            pause(0.01);
        end
        if RX6.GetTagVal('nPlayedRX6') > n0, break; end
    end
    n1 = RX6.GetTagVal('nPlayedRX6');
    fprintf('  nPlayedRX6: %d -> %d after %d trigger(s)%s\n', n0, n1, tries, ...
        ternary(n1 > n0, '', '   <-- did NOT register as played'));
    RX6.SoftTrg(2);                 % reset buffer position for the next one
    pause(0.3);
end

function out = ternary(c,a,b)
    if c, out = a; else, out = b; end
end