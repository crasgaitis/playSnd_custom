function [wave,nSamps] = playSnd_load_next_stim(handles,idx)
% idx: indicates position of stimSeq
% wav: actual waveform in .waveform file
% nSamps: number of samples in waveform

%------ old version before 1/25/2016 ------------
% stimSeq = getappdata(handles.playSnd,'stimSeq');
% allStimWav = getappdata(handles.playSnd,'allStimWav');
% nSAMPS = getappdata(handles.playSnd,'nSamps');
% wave = allStimWav{stimSeq(idx,1)};
% nSamps = nSAMPS(stimSeq(idx,1));

%------- new verstion after 1/25/2016 ------------
skipStim = getappdata(handles.playSnd,'skipStim');
stimSeq = getappdata(handles.playSnd,'stimSeq');
fs = handles.settings.TDT.sampling_rate;
% nCmp = round(0.2*fs);  % test if stim is shorter than 200ms, which is chosen
nCmp = 0;
%to aid circuit status detection, then pad with zeros to increase length
tic
if ~skipStim(stimSeq(idx)) % if this stim is not skipped then it means after softGain it remains within TDT output range
    
    allStim = getappdata(handles.playSnd,'allStim');
    f = load(allStim{stimSeq(idx)});
    softGain = 10^(str2double(get(handles.softGain,'string'))/20);
    if isfield(f,'wave')
        wave = f.wave*handles.settings.TDT.range*softGain;
    end
    if isfield(f,'s') && isa(f.s,'Stim') % if a Stim object is stored instead
        if ~isnan(f.s.calibration_gain)
            fprintf('APPLY calibration gain: %f \n',f.s.calibration_gain);
            wave = f.s.calibration_gain * f.s.wave * handles.settings.TDT.range * softGain;
        else
            fprintf('NO calibration gain found\n')
            wave = f.s.wave * handles.settings.TDT.range * softGain;
        end
    end
    if length(wave) < nCmp
        wave = [wave zeros(1,nCmp - length(wave))];
    end
    nSamps = length(wave);
    
else
    wave = zeros(1,nCmp);
    nSamps = nCmp;
end
t = toc;
fprintf('new version! time to load data: %g sec\n',t);

return
