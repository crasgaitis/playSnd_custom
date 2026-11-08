function playSnd_timer_stopfcn(obj,event,handles)

RX6 = getappdata(handles.playSnd,'RX6');
RX6.Halt;
playSnd_reset_atten(handles);
hMat = getappdata(handles.playSnd,'hMat');
nStimPlayed = getappdata(handles.playSnd,'nStimPlayed');
if nStimPlayed == 0
    delete(fullfile(getappdata(handles.playSnd,'stimfile_dir'),...
        getappdata(handles.playSnd,'stimfile_name')));
    return
end

stimPlayedID = zeros(nStimPlayed,1);
stimPlayedAtten = zeros(nStimPlayed,1);

i = 1;
name = sprintf('stimPlayedID%d',i);
if isappdata(handles.playSnd,name)
    stimPlayedID(i) = getappdata(handles.playSnd,name);
    rmappdata(handles.playSnd,name);  % remove appdata
end
name = sprintf('stimPlayedAtten%d',i);
if isappdata(handles.playSnd,name)
    stimPlayedAtten(i) = getappdata(handles.playSnd,name);
    rmappdata(handles.playSnd,name);  % remove appdata
end
cheetahMode = getappdata(handles.playSnd,'cheetahMode');
if cheetahMode
    name = sprintf('stimPlayedEvent%d',i);
    if isappdata(handles.playSnd,name)
        stimPlayedEvent = getappdata(handles.playSnd,name);
        rmappdata(handles.playSnd,name);  % remove appdata
        % preallocate memory for stimPlayedEvent
        stimPlayedEvent = repmat(stimPlayedEvent,nStimPlayed,1);
    end
end

for i = 2:nStimPlayed
    name = sprintf('stimPlayedID%d',i);
    if isappdata(handles.playSnd,name)
        stimPlayedID(i) = getappdata(handles.playSnd,name);
        rmappdata(handles.playSnd,name);  % remove appdata
    end
    name = sprintf('stimPlayedAtten%d',i);
    if isappdata(handles.playSnd,name)
        stimPlayedAtten(i) = getappdata(handles.playSnd,name);
        rmappdata(handles.playSnd,name);  % remove appdata
    end
    
    if cheetahMode
        name = sprintf('stimPlayedEvent%d',i);
        if isappdata(handles.playSnd,name)
            stimPlayedEvent(i) = getappdata(handles.playSnd,name);
            rmappdata(handles.playSnd,name);  % remove appdata
        end
    end
end
% hMat.nCycle = getappdata(handles.playSnd,'nCycle');
hMat.skipStim = getappdata(handles.playSnd,'skipStim');
hMat.softGain = str2double(get(handles.softGain,'string'));
hMat.nStimPlayed = nStimPlayed;
hMat.stimPlayedID = stimPlayedID;
hMat.stimPlayedAtten = stimPlayedAtten;
hMat.nRep = getappdata(handles.playSnd,'nRepeat');
hMat.fs = getappdata(handles.playSnd,'curr_fs');
hMat.randomized = 1; % playSnd GUI always randonmize stim presentation


if cheetahMode
    hMat.stimPlayedEvent = stimPlayedEvent;
end
sel = get(handles.trgSrc,'value');
str = get(handles.trgSrc,'string');
trgSrc = str{sel};
if strncmp(trgSrc, 'User P(0.0)', length('User P(0.0)'))
    useFrameClk = 0;
end
if strncmp(trgSrc, 'Frame Clk', length('Frame Clk'))
    useFrameClk = 1;
end
if get(handles.imagingMode,'value')
    if useFrameClk
        hMat.nBaseFrame = str2double(get(handles.nBaseFrame,'string'));
        hMat.framesPerStim = nan;
        hMat.stimOnFrame = getappdata(handles.playSnd,'stimOnFrame');
        
    end
end

hMat.stim_root_path = getappdata(handles.playSnd,'stim_root_path');
hMat.stimFolderID = getappdata(handles.playSnd,'stimFolderID'); %stimFolderID stores which folder each stim belongs to
hMat.stimFolder = getappdata(handles.playSnd,'stimFolder'); % stimFolder stores the folders from where we load the stimuli
hMat.atten = getappdata(handles.playSnd,'atten'); % note atten is a cell array

% new functionality added 7/25/2016, save the parameters string in the gui
% in case we want to do the experiment the exact same way
hMat.trgSrcVal = get(handles.trgSrc,'Value'); % trigger source
hMat.nRepeatString = get(handles.nRepeat,'String');
hMat.attenString = get(handles.atten,'String');
hMat.softGainString = get(handles.softGain,'String');
hMat.tdtFsVal = get(handles.tdt_fs,'Value');
hMat.chanSelVal = get(handles.channel_sel,'Value');
hMat.nBaseFrameString = get(handles.nBaseFrame,'String');
hMat.nFramesPlayoutString = get(handles.nFramesPlayout,'String');
hMat.nFramesBetweenString = get(handles.nFramesBetween,'String');
hMat.preset_stim_seq = getappdata(handles.playSnd,'preset_stim_seq'); % save preset stimuli sequence, regardless of using it or not
hMat.preset_stim_seq_filename = getappdata(handles.playSnd,'preset_stim_seq_filename');
fprintf('done saving sound file data to: \n%s\n',hMat.Properties.Source);
% [~,fn,ext] = fileparts(hMat.Properties.Source);
% copyfile(hMat.Properties.Source,fullfile('Z:\Current\JiLiu\sound_files',[fn,ext]));
return