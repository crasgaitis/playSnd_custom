
function varargout = playSnd(varargin)
% PLAYSND MATLAB code for playSnd.fig
%      PLAYSND, by itself, creates a new PLAYSND or raises the existing
%      singleton*.
%
%      H = PLAYSND returns the handle to a new PLAYSND or the handle to
%      the existing singleton*.
%
%      PLAYSND('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PLAYSND.M with the given input arguments.
%
%      PLAYSND('Property','Value',...) creates a new PLAYSND or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before playSnd_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to playSnd_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help playSnd

% Last Modified by GUIDE v2.5 02-Nov-2021 13:32:20

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @playSnd_OpeningFcn, ...
    'gui_OutputFcn',  @playSnd_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end

% End initialization code - DO NOT EDIT

function settings = do_init_param(handles,whichrig)
% switch whichrig
%     case 'Cheetah'
%         ROOT = 'D:\Ji\GoogleDrive\';
%     case 'Prairie'
%         ROOT = 'D:\Ji\GoogleDrive\';
%     case 'BScope'
%         ROOT = 'C:\Ji\TDT\';
%     case 'Imaging'
% end
ROOT = getappdata(handles.playSnd,'root_path');
settings.stim_path = fullfile(ROOT,'Stim');
% switch whichrig
%     case 'Cheetah'
%         settings.stim_path = fullfile(ROOT,'Stim');
%     case 'Prairie'
%         settings.stim_path = fullfile(ROOT,'Stim');
%     case 'BScope'
%         settings.stim_path = fullfile(ROOT,'Stim');
% end

% settings.nCycle = 1; % cycle of continuous repeats
settings.nRepeat = 1; % repreat each stimulus for how many times
circuit_root = fullfile(ROOT,'Code\StimPresentation\RX6_circuit');
settings.TDT.circuit_fpath_otherStim_UserP = fullfile(circuit_root,...
    'otherStim_UserP(0.0)_test1.1.rcx');
settings.TDT.circuit_fpath_otherStim_frameClk = fullfile(circuit_root,...
    'otherStim_frameClk_softTrg_nonUniformItv_v1.0.rcx');
settings.TDT.circuit_fpath_longStim_UserP = fullfile(circuit_root,...
    'ripple_Escabi_UserP(0.0)_test1.5.rcx');
settings.TDT.circuit_fpath_longStim_frameClk = fullfile(circuit_root,...
    'ripple_Escabi_frameClk_test1.3.rcx');
settings.TDT.circuit_fpath_otherStimWithITD_UserP = fullfile(circuit_root,...
    'otherStim_UserP(0.0)_ITD_v2.0.rcx');
% specify the stimfolder(sound file path)
cheetahMode = get(handles.cheetahMode,'Value');
if cheetahMode
    %hCheetah = findall(0,'type','figure','tag','cheetah_helper'); % find handle of cheetah_helper
%     hCheetah = findobj('Tag','cheetah_helper');
%     if isempty(hCheetah)
%         error('cheetah_helper is not running!');
%     end
%     stimfile_dir = getappdata(hCheetah,'cheetah_dir');
    stimfile_dir = fullfile(ROOT,'sound_files');
    if ~isdir(stimfile_dir)
        mkdir(stimfile_dir);
    end
    GetCheetahEvent; % flush all previous events
    fprintf('Cheetah helper found!');
    setappdata(handles.playSnd,'cheetahMode',1);
else
    setappdata(handles.playSnd,'cheetahMode',0);
    stimfile_dir = fullfile(ROOT,'sound_files');
    if ~isdir(stimfile_dir)
        mkdir(stimfile_dir);
    end
end
setappdata(handles.playSnd,'stimfile_dir',stimfile_dir);
% specify mapping from channels to TDT circuit buffers
% settings.TDT.CHANNELS = {'play_1' 'play_2'};
% switch whichrig
%     case 'Cheetah'
%         settings.TDT.nPA5 = 2; % we have
%     case 'Prairie'
%         settings.TDT.nPA5 = 1; % we have
%     case 'BScope'T
%         settings.TDT.nPA5 = 1; % we have
% end
settings.TDT.nPA5 = 1; % we have
settings.TDT.range = 9.9999; % +- 10V, but prevent clipping
settings.TDT.callback_period = 0.050; % in seconds, period for the buffer update timer
% specify mapping from trigger type to TDT mux select
%settings.stim_triggers = strvcat('User (P0.0)','Frame Clk','Line Clk');
% settings.TDT.TRIGGER_MUX_SELECT = [0 1 1];
% buffer size in circuit MUST be divisible by number of chunks.
% must have at least two chunks.
% settings.TDT.NCHUNKS = 4;
settings.TDT.sampling_rate = 195312.50;
settings.TDT.fs_n = 5; % second argument for RX6.LoadCOFsf, the first being the circuit file path, 5->200kHz, w/ realizable rate 195312.50Hz
settings.TDT.maxSPL = 80; % maximum sound level speaker is calibrated to
settings.TDT.atten = 0;  % default attenuation
settings.TDT.timer_name = 'playSndTimer';

return

function do_init_gui(handles)

set(handles.stim_path,'string',handles.settings.stim_path);
% set(handles.atten,'string',num2str(handles.settings.TDT.atten));
% set(handles.nRepeat,'string',num2str(handles.settings.nRepeat));
findStim(handles);
setappdata(handles.stim_uselist,'n_stim_use',0); % when initialize, no TORC selected
setappdata(handles.playSnd,'armed',0);
return

function findStim(handles)
folder = get(handles.stim_path,'string');
files = dir(folder);
stim = cellstr('N/A'); idx = 0;
for i = 1:length(files)
    identifier = 'stim';
    if files(i).isdir && strncmp(identifier,files(i).name,length(identifier))
        idx = idx + 1;
        stim{idx} = files(i).name;
    end
end

if idx == 0
    % no stim folder is found
    set(handles.stim_idlelist,'string',stim);
    set(handles.stim_idlelist,'enable','off');
else
    set(handles.stim_idlelist,'value',1);
    set(handles.stim_idlelist,'enable','on');
    set(handles.stim_idlelist,'string',stim);
    setappdata(handles.stim_idlelist,'n_stim_idle',idx);
    set(handles.stim_uselist,'value',1);
    set(handles.stim_uselist,'string',cellstr('stim to use'));
    setappdata(handles.stim_idlelist,'n_stim_use',0);
end

return

function findWaveform(handles,subfolder,hObject)
% this function finds all the .waveform files under subfolder
allStim = getappdata(handles.playSnd,'allStim');
nStim = getappdata(handles.playSnd,'nStim');
folder = get(handles.stim_path,'string');
path = fullfile(folder,subfolder);
files = dir(path);
for i = 1:length(files)
    [~,~,ext] = fileparts(files(i).name);
    if strcmp('.waveform',ext)
        nStim = nStim + 1;
        allStim{nStim} = fullfile(path,...
            files(i).name);
    end
end
setappdata(handles.playSnd,'allStim',allStim);
setappdata(handles.playSnd,'nStim',nStim);
return

function nStimFound = findWaveform_mat(handles,subfolder)
nStimFound = 0;
% this function finds all the .mat files under subfolder
allStim = getappdata(handles.playSnd,'allStim');
nStim = getappdata(handles.playSnd,'nStim');
folder = get(handles.stim_path,'string');
path = fullfile(folder,subfolder);

% if play long continuous stim
if get(handles.sel_long_stim,'value') == 1
    setappdata(handles.playSnd,'root',folder);
    setappdata(handles.playSnd,'folder_name',subfolder)
    param_fpath = fullfile(path,sprintf('%s_param.mat',subfolder));
    hMat_param = matfile(param_fpath,'writable',true);
    setappdata(handles.playSnd,'hMat_param',hMat_param);    
    nStim = 1;
    allStim = cellstr(param_fpath);
    hMat = [];
    nStimFound = 1;
end
% if play short stim
if get(handles.sel_other,'value') == 1
    files = what(path);
    allStim_tmp = cell(length(files.mat),1);
    for i = 1:length(files.mat)
        fullname = fullfile(path,files.mat{i});
        h = matfile(fullname);
        if ~isempty(whos(h,'wave'))
%             nStim = nStim + 1;
%             allStim{nStim} = fullname;
            nStimFound = nStimFound + 1;    
            allStim_tmp{nStimFound} = fullname;
            disp(fullname);
            continue;
        end
        if ~isempty(whos(h,'s')) 
            %             nStim = nStim + 1;
            %             allStim{nStim} = fullname;
            nStimFound = nStimFound + 1;
            allStim_tmp{nStimFound} = fullname;
            disp(fullname);
            continue;
        end

    end
end

allStim = [allStim ; allStim_tmp(1:nStimFound)];
nStim = nStim + nStimFound;
setappdata(handles.playSnd,'allStim',allStim);
setappdata(handles.playSnd,'nStim',nStim);
setappdata(handles.playSnd,'hMat_stim',[]);
return

% --- Executes just before playSnd is made visible.
function playSnd_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to playSnd (see VARARGIN)

% Choose default command line output for playSnd
handles.output = hObject;
movegui(handles.playSnd,'center');
if isempty(varargin)
    fprintf('not enough input arguments')
else
    whichrig = varargin{1};
    root_path = varargin{2};
    handles.whichrig = whichrig;
    setappdata(handles.playSnd,'whichrig',whichrig);
    setappdata(handles.playSnd,'root_path',root_path);
    % Update handles structure
    switch whichrig
        case 'Cheetah'
            set(handles.channel_sel,'value',2);
            set(handles.cheetahMode,'value',1);
            set(handles.trgSrc,'value',1);
        case 'Prairie'
            set(handles.channel_sel,'value',2);
            set(handles.imagingMode,'value',1);
            set(handles.trgSrc,'value',1); 
        case 'Bruker'
            set(handles.channel_sel,'value',2);
            set(handles.imagingMode,'value',1);
            set(handles.trgSrc,'value',1); 
        case 'BScope'
            set(handles.channel_sel,'value',2);
            set(handles.imagingMode,'value',1);
            set(handles.trgSrc,'value',1);
        case 'Dual_WF'
            set(handles.channel_sel,'value',1);
            set(handles.imagingMode,'value',1);
            set(handles.trgSrc,'value',2); 
    end
    handles.settings = do_init_param(handles,whichrig);
    do_init_gui(handles); % putting setting values into gui interface
    do_init_TDT(handles);
end
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes playSnd wait for user response (see UIRESUME)
% uiwait(handles.playSnd);

% --- Outputs from this function are returned to the command line.
function varargout = playSnd_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function stim_path_Callback(hObject, eventdata, handles)
% hObject    handle to stim_path (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of stim_path as text
%        str2double(get(hObject,'String')) returns contents of stim_path as a double

% --- Executes during object creation, after setting all properties.
function stim_path_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stim_path (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in loadStimPath.
function loadStimPath_Callback(hObject, eventdata, handles)
% hObject    handle to loadStimPath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% switch handles.whichrig
%     case 'Ji_desktop'
%         start_path = 'C:\Users\Ji Liu\Dropbox\RippleStim';
%     case 'Ji_laptop'
%         start_path = 'C:\Users\Ji Liu\Dropbox\RippleStim';
%     case 'Cheetah'
%         start_path = handles.settings.stim_path;
%     case 'Prairie'
%         start_path = handles.settings.stim_path;
%     case 'BScope'
%         start_path = handles.settings.stim_path;
% end
start_path = handles.settings.stim_path;
stim_path = uigetdir(start_path,...
    'Please Select a Stim Path');
if stim_path
    set(handles.stim_path,'string',stim_path);
    findStim(handles);
    guidata(hObject,handles);
end

% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes on selection change in stim_uselist.
function stim_uselist_Callback(hObject, eventdata, handles)
% hObject    handle to stim_uselist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns stim_uselist contents as cell array
%        contents{get(hObject,'Value')} returns selected item from stim_uselist

% --- Executes during object creation, after setting all properties.
function stim_uselist_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stim_uselist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on key press with focus on stim_idlelist and none of its controls.
function stim_idlelist_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to stim_idlelist (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if strcmp(eventdata.Key, 'm')
    if getappdata(handles.stim_idlelist,'n_stim_idle')>=1
        idx = get(handles.stim_idlelist,'value');
        subfolder = get(handles.stim_idlelist,'string');
        if ~iscell(subfolder)
            subfolder = cellstr(subfolder);
        end
        putStimtoUse(handles,subfolder{idx});
        %         removeStimfromIdle(handles,subfolder,idx);
    else
        % do nothing?
    end
end

function putStimtoUse(handles,subfolder)
uselist = get(handles.stim_uselist,'string');
n = getappdata(handles.stim_uselist,'n_stim_use');
if ~iscell(uselist)
    uselist = cellstr(uselist);
end
uselist{n+1} = subfolder;
set(handles.stim_uselist,'string',uselist);
setappdata(handles.stim_uselist,'n_stim_use',n+1);
return

function removeStimfromIdle(handles,subfolder,idx)
n = getappdata(handles.stim_idlelist,'n_stim_idle');
setappdata(handles.stim_idlelist,'n_stim_idle',n-1);
subfolder(idx) = [];
tmp = min(idx,size(subfolder,1));
set(handles.stim_idlelist,'value',tmp);
set(handles.stim_idlelist,'string',subfolder);
return

% --- Executes on button press in arm_disarm.
function arm_disarm_Callback(hObject, eventdata, handles)
% hObject    handle to arm_disarm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~getappdata(handles.playSnd,'armed')
    succeeded = do_arm(handles,hObject);
    if succeeded
        setappdata(handles.playSnd,'armed',1);
        update_arm_disarm_toggle(handles);
    else
        
    end
else
    succeeded = do_disarm(handles,hObject);
    if succeeded
        setappdata(handles.playSnd,'armed',0);
        update_arm_disarm_toggle(handles);
        report_status(handles,'Disarmed!');
    end
end

function [succeeded,nSamps] = loadWaveform_other(handles)
allStim = getappdata(handles.playSnd,'allStim');
nStim = getappdata(handles.playSnd,'nStim');
nSamps = zeros(nStim,1); % nSamps saves how long each stim is in # of samples
allStimWav = cell(nStim,1);
nErr=0;
softGain = 10^(str2double(get(handles.softGain,'string'))/20);


skipStim = zeros(nStim,1);
% for i = 1:nStim
%     f = load(allStim{i});
%     wave = [];
%     if isfield(f,'wave')
%        wave = f.wave;
%     end
%     
%     if isempty(wave)
%         nErr = nErr+1;
%         fprintf('\nfile format error:\n%s',allStim{i});
%         allStim(i) = [];
%         continue
%     end
%     
%     %wave = wave*handles.settings.TDT.range; % normalize waveform to span RX6 output range, which is 10volts
%     
%     if max(abs(wave))*softGain > 1 % handles.settings.TDT.range
%         report_status(handles,'software gain causing signal amplitude over RX6 input range!')
%         skipStim(i) = 1;
%     end
%     
%     allStimWav{i,1} = 0; % changed 1/25/2016 by JL, we load each stim during stim presentation, not now
%     nSamps(i) = length(wave);
%     
%     
% end
if nErr>=nStim
    succeeded = 0;
else
    setappdata(handles.playSnd,'allStimWav',allStimWav);
    setappdata(handles.playSnd,'skipStim',skipStim);
    setappdata(handles.playSnd,'nSamps',nSamps);
    setappdata(handles.playSnd,'nStim',nStim-nErr);
    setappdata(handles.playSnd,'allStim',allStim);
%     setappdata(handles.playSnd,'param',param);
    succeeded = 1;
end

return

function succeeded = loadWaveform_DRC(handles)
allStim = getappdata(handles.playSnd,'allStim');
nStim = getappdata(handles.playSnd,'nStim');
allStimWav = cell(nStim,1);nSamps = zeros(nStim,1);
nErr=0;
softGain = 10^(str2double(get(handles.softGain,'string'))/20);
fs = handles.settings.TDT.sampling_rate;

for i = 1:nStim
    f = load(allStim{i});
    try
        wave = f.wave;
        wave = wave*handles.settings.TDT.range; % normalize waveform to span RX6 output range, which is 10volts
        
        if max(abs(wave))*softGain > handles.settings.TDT.range
            report_status(handles,'software gain causing signal amplitude over RX6 input range!')
        else
            wave = wave*softGain;
        end

        allStimWav{i,1} = wave;
        nSamps(i) = length(wave);
        if i == 1
            param = f.param;
        else
            param(i) = f.param;
        end
    catch
        nErr = nErr+1;
        fprintf('\nfile format error:\n%s',allStim{i});
        allStim(i) = [];
        continue
    end
end
if nErr>=nStim
    succeeded = 0;
else
    setappdata(handles.playSnd,'allStimWav',allStimWav);
    setappdata(handles.playSnd,'nSamps',nSamps);
    setappdata(handles.playSnd,'nStim',nStim-nErr);
    setappdata(handles.playSnd,'allStim',allStim);
    setappdata(handles.playSnd,'param',param);
    succeeded = 1;
end

return

function succeeded = loadWaveform_long(handles)
allStim = getappdata(handles.playSnd,'allStim');
nStim = getappdata(handles.playSnd,'nStim');
allStimWav = cell(nStim,1);nSamps = zeros(nStim,1);
nSeg = zeros(nStim,1); nSamps_seg = zeros(nStim,1);
nErr=0;
softGain = 10^(str2double(get(handles.softGain,'string'))/20);
for i = 1:nStim
    f = matfile(allStim{i});
    try

        if abs(f.wav_min) * softGain  > 1 || abs(f.wav_max) * softGain  > 1
            report_status(handles,'software gain causing signal amplitude over RX6 input range!')
            succeeded = 0;
            return
        else
            allStimWav = 0;
            nSeg(i) = f.nSeg;
            nSamps_seg(i) = f.nSamps_seg;
        end

    catch
        nErr = nErr+1;
        fprintf('\nfile format error:\n%s',allStim{i});
        allStim(i) = [];
        continue
    end
end
if nErr>=nStim
    succeeded = 0;
else
    setappdata(handles.playSnd,'allStimWav',allStimWav);
    if get(handles.sel_other,'value')
        setappdata(handles.playSnd,'nSamps',nSamps);
    else
        setappdata(handles.playSnd,'nSamps_seg',nSamps_seg);
        setappdata(handles.playSnd,'nSeg',nSeg);
    end
    setappdata(handles.playSnd,'nStim',nStim-nErr);
    setappdata(handles.playSnd,'allStim',allStim);
    succeeded = 1;
end

return


function succeeded = do_arm(handles,hObject)
if get(handles.sel_other,'value')  % if want to play other stim than Escabi's DMR, which is hugely long
    %% find waveform files
    % each entry in the uselist is a folder, so containing possibly multiple
    % stimuli
    nFolder = getappdata(handles.stim_uselist,'n_stim_use');
    tic
    if nFolder>=1
        subfolder = get(handles.stim_uselist,'string');
        if ~iscell(subfolder)
            subfolder = cellstr(subfolder);
        end
        setappdata(handles.playSnd,'allStim',cell(0)); % empty cell array
        setappdata(handles.playSnd,'nStim',0);
        stimFolderID = [];
        for i = 1:nFolder % find all .waveform files in the folder
            nStimFound = findWaveform_mat(handles,subfolder{i}); % findWaveform will put all waveform files
            stimFolderID = [stimFolderID ; i*ones(nStimFound,1)]; % stimFolderID indicates which folder each stim comes from
        end
        
    else
        report_status(handles,'No stim selected!');
        succeeded = 0;
        return
    end
    toc
    if getappdata(handles.playSnd,'nStim')<=0
        report_status(handles,'No waveform files found!');
        succeeded = 0;
        return
    else
        report_status(handles,'waveform files found!')
        
    end
    tic
    [succeeded,nSamps] = loadWaveform_other(handles);
    if ~succeeded
        report_status(handles,'loading waveform failure!');
        return
    else
        report_status(handles,'succeeded loading waveform!');
        
    end
    toc
    %% randomize sequence of repetitins of all stimuli
    atten = eval(get(handles.atten,'string')); % atten should be a cell array the same length as nFolder
    assert(length(atten)==nFolder,'check attenuation cell string length!');
    nAtten = zeros(nFolder,1);
    for i = 1:nFolder
        if ~isempty(find(atten{i}<0))
            report_status(handles,'Negative attenuation not allowed!');
            succeeded = 0;
            return
        end
        nAtten(i) = length(atten{i});
    end
    nStim = getappdata(handles.playSnd,'nStim');
    nRep = eval(get(handles.nRepeat,'string')); % atten should be an array the same length as nFolder
    if length(nRep) ~= nFolder
        error('check rep, should be vector of length %d\n',nFolder);
    end
    
    % ask user if use preset stim sequence
    choice = questdlg('Use preset stim sequence?', ...
        ' ', ...
        'Yes','No','No');
    % Handle response
    switch choice
        case 'Yes'
            use_preset = 1;
        case 'No'
            use_preset = 0;
            
    end
    if ~use_preset
        stimSeqAll = [];
        for iFolder = 1:nFolder
            atten_tmp = atten{iFolder};
            ind = find(stimFolderID==iFolder);
            nStimThisFolder = length(ind);
            stimSeq = zeros(nStimThisFolder*nAtten(iFolder)*nRep(iFolder),2);
            k=1;
            for i = 1:nStimThisFolder
                for j = 1:nAtten(iFolder)
                    stimSeq(k:k+nRep(iFolder)-1,:) = repmat([ind(i),atten_tmp(j)],nRep(iFolder),1);
                    k=k+nRep(iFolder);
                end
            end
            stimSeqAll = [stimSeqAll ; stimSeq];
        end
        rndIdx = randperm(size(stimSeqAll,1));
        stimSeq = stimSeqAll(rndIdx,:); % randomize stim presentation
        nTotalStim = size(stimSeq,1);
        % if Frame_Clk is selected as trigger mode, then need to generate
        % sequence indicating at which frame each frame starts
        
        trgSrcStr = get(handles.trgSrc,'String');
        sel = get(handles.trgSrc,'value');
        if ~iscell(trgSrcStr)
            trgSrcStr = cellstr(trgSrcStr);
        end
        trgSrc = trgSrcStr{sel};
        stimOnFrame = nan; % if it is cheetah mode then we won't use frame clk
        if strncmp(trgSrc, 'Frame Clk',length('Frame Clk'))
            % how many frames allowed for each stim to be played, fixed for a
            % particular folder
            nFramesPlayout = eval(get(handles.nFramesPlayout,'String'));
            if length(nFramesPlayout)~=nFolder
                error('check # of frames for playout, should be a vector of length %d\n',nFolder);
            end
            % how many frames after a stim is finished and next starts,
            % randomized
            nFramesBetween = eval(get(handles.nFramesBetween,'String'));
            if size(nFramesBetween,1)~=nFolder && size(nFramesBetween,2)~=2
                error('check # of frames between stim, should be a matrix of length %d by 2\n',nFolder);
            end
            stimOnFrame = zeros(nTotalStim,1);
            nBaseFrame = eval(get(handles.nBaseFrame,'String'));
            stimOnFrame(1) = nBaseFrame + 1;
            for iStim = 2:nTotalStim
                stimIDpre = stimSeq(iStim-1,1);  % find out what is the last stim
                folderIDpre = stimFolderID(stimIDpre); % folderID determines how many frames to allow stim playout
                % and how many frames to wait before next stim is played
                stimIDcurr = stimSeq(iStim,1);   % find out what is the current stim
                folderIDcurr = stimFolderID(stimIDcurr);
                stimOnFrame(iStim) = stimOnFrame(iStim-1) + nFramesPlayout(folderIDpre) + randi(nFramesBetween(folderIDcurr,:));
                % when the next stim will be played is determined by add on
                % top of when previous stim starts, the frames needed to
                % play the last one and the frames needed to load the
                % current stim
            end
            report_status(handles,sprintf('# of frames to reach the last stim: %d',stimOnFrame(end)));
        end
    else % use preset 
        preset_stim_seq = getappdata(handles.playSnd,'preset_stim_seq');

        % check if folders match up
        preset_subfolder = preset_stim_seq.subfolder;
        for k = 1:length(preset_subfolder)
            if ~strcmp(preset_subfolder{k},subfolder{k})
                error('stim folder does not match up with preset stim folder!\npreset: %s\ncurrent: %s',preset_subfolder{k},subfolder{k});
            end
        end
        % if pass checking
        stimOnFrame = preset_stim_seq.stimOnFrame;
        stimSeq = preset_stim_seq.stimSeq;
        nTotalStim = size(stimSeq,1);
        
        report_status(handles,sprintf('# of frames to reach the last stim: %d',stimOnFrame(end)));
    end
    
    stim_root_path = get(handles.stim_path,'string'); % the path where all folders containing stim files are kept
    setappdata(handles.playSnd,'stim_root_path',stim_root_path);
    setappdata(handles.playSnd,'stimFolderID',stimFolderID);
    setappdata(handles.playSnd,'stimFolder',subfolder);
    setappdata(handles.playSnd,'atten',atten);
    
    setappdata(handles.playSnd,'stimSeq',stimSeq);
    setappdata(handles.playSnd,'stimOnFrame',stimOnFrame);
    setappdata(handles.playSnd,'nRepeat',nRep);
    setappdata(handles.playSnd,'nPresent',nTotalStim); % save number of all presentations of stimuli
    setappdata(handles.playSnd,'testMode',get(handles.testMode,'value'));
    setappdata(handles.playSnd,'cheetahMode',get(handles.cheetahMode,'value'));
    %% initialize TDT circuit
    report_status(handles,'Arming...');
    succeeded = do_start_TDT_hardware_otherStims(handles);
    if ~succeeded
        return
    end
    
    %% start timer
    % use a matlab timer instead of polling on the buffer pointer.
    % this allows use of the matlab console while the playback is occurring,
    % and also frees up some cycles on the CPU. the period must be low enough,
    % however, so that the buffer does not overrun. the TDT circuit contains a
    % hardware flag for buffer overrun, which results in a fatal error.
    % remove any previous timers created here and create a new one.
    
    t = timerfindall('Tag',handles.settings.TDT.timer_name);
    if ~isempty(t), stop(t); delete(t); end
    
    TDT_TIMER = timer('Period',handles.settings.TDT.callback_period,...
        'TasksToExecute',inf,...
        'TimerFcn',{@playSnd_timer_callback_workForAll,handles},...
        'StartFcn',{@playSnd_timer_startfcn,handles},...
        'StopFcn',{@playSnd_timer_stopfcn,handles},...
        'ExecutionMode','fixedRate',...
        'BusyMode','drop',...
        'Tag',handles.settings.TDT.timer_name);
    setappdata(handles.playSnd,'TDT_TIMER',TDT_TIMER);
    start(TDT_TIMER);
    %% now wait for ephus trigger
    
    %%
    
end
if get(handles.sel_long_stim,'value') %  if want to play long continuous stim
    nFolder = getappdata(handles.stim_uselist,'n_stim_use');
    if nFolder==1
        subfolder = get(handles.stim_uselist,'string');
        if ~iscell(subfolder)
            subfolder = cellstr(subfolder);
        end
        setappdata(handles.playSnd,'allStim',cell(0));
        setappdata(handles.playSnd,'nStim',0);
        findWaveform_mat(handles,subfolder{1}); % findWaveform will put all waveform files
        
    else
        report_status(handles,'No stim selected! Or one stim at a time!');
        succeeded = 0;
        return
    end
    if getappdata(handles.playSnd,'nStim')<=0
        report_status(handles,'No waveform files found!');
        succeeded = 0;
        return
    else
        report_status(handles,'Waveforms found!')
    end
    succeeded = loadWaveform_long(handles);
    if ~succeeded
        report_status(handles,'loading waveform failure!');
        return
    else
        report_status(handles,'succeeded loading waveform!');
        
    end
    % no need to randomize presentation of stimuli, usually only one DMR
    % should be selected, so what's left is to start TDT system, w/o the
    % timer this time. Stim play out can be monitored through while loop
    % this time!!!
    atten = eval(get(handles.atten,'string'));
    if ~isempty(find(atten<0))
        report_status(handles,'Negative attenuation not allowed!');
        succeeded = 0;
        return
    end
    nStim = getappdata(handles.playSnd,'nStim');
    nAtten = length(atten);
    nRep = str2double(get(handles.nRepeat,'string'));
    stimSeq = zeros(nStim*nAtten*nRep,2);
    k=1;
    for i = 1:nStim
        for j = 1:nAtten
            stimSeq(k:k+nRep-1,:) = repmat([i,atten(j)],nRep,1);
            k=k+nRep;
        end
    end
    rndIdx = randperm(nStim*nAtten*nRep);
    stimSeq = stimSeq(rndIdx,:); % randomize stim presentation
    setappdata(handles.playSnd,'stimSeq',stimSeq);
    setappdata(handles.playSnd,'nRepeat',nRep);
    setappdata(handles.playSnd,'nPresent',size(stimSeq,1)); % save number of all presentations of stimuli
    setappdata(handles.playSnd,'testMode',get(handles.testMode,'value'));
    setappdata(handles.playSnd,'cheetahMode',get(handles.cheetahMode,'value'));
    
    %% initialize TDT circuit
    report_status(handles,'Arming...');
    if get(handles.sel_long_stim,'value')
        succeeded = do_start_TDT_hardware_rippleEscabi(handles);
    end

    if ~succeeded
        return
    end
    
    
    t = timerfindall('Tag',handles.settings.TDT.timer_name);
    if ~isempty(t), stop(t); delete(t); end
    
    
    if get(handles.sel_long_stim,'value')
        TDT_TIMER = timer('Period',handles.settings.TDT.callback_period,...
            'TasksToExecute',inf,...
            'TimerFcn',{@playSnd_timer_callback_workForAll,handles},...
            'StartFcn',{@playSnd_timer_startfcn,handles},...
            'StopFcn',{@playSnd_timer_stopfcn,handles},...
            'ExecutionMode','fixedRate',...
            'BusyMode','drop',...
            'Tag',handles.settings.TDT.timer_name);
    end
    setappdata(handles.playSnd,'TDT_TIMER',TDT_TIMER);
    start(TDT_TIMER);
end



return

function succeeded = do_disarm(handles,hObject)
succeeded = 1;
TDT_TIMER = getappdata(handles.playSnd,'TDT_TIMER');
if isvalid(TDT_TIMER)
    stop(TDT_TIMER);delete(TDT_TIMER);
end
setappdata(handles.playSnd,'armed',0);
return

function update_arm_disarm_toggle(handles)

if getappdata(handles.playSnd,'armed')
    set(handles.arm_disarm,'String','Disarm');
    set(handles.arm_disarm,'backgroundColor',[0 70/256 112/256]);
    %   set(handles.arm_disarm,'Value',1);
    set(handles.arm_disarm,'FontAngle','Normal');
    set(handles.arm_disarm,'FontName','Times New Roman');
    set(handles.arm_disarm,'foregroundColor',[1 1 1]);
    
else
    set(handles.arm_disarm,'String','Arm');
    set(handles.arm_disarm,'FontAngle','italic');
    set(handles.arm_disarm,'backgroundColor',[0 114/256 189/256]);
    set(handles.arm_disarm,'foregroundColor',[1 1 1]);
    set(handles.arm_disarm,'FontName','MS Sans Serif');
    %   set(handles.arm_disarm,'Value',0);
end

function succeeded = do_start_TDT_hardware_rippleEscabi(handles)
RX6 = getappdata(handles.playSnd,'RX6');
RX6.Halt;
RX6.ClearCOF;
trgSrcStr = get(handles.trgSrc,'String');
sel = get(handles.trgSrc,'value');
if ~iscell(trgSrcStr)
    trgSrcStr = cellstr(trgSrcStr);
end
trgSrc = trgSrcStr{sel};

if strncmp(trgSrc, 'User P(0.0)', length('User P(0.0)'))
    COF_path = handles.settings.TDT.circuit_fpath_longStim_UserP;
    useFrameClk = 0;
end
if strncmp(trgSrc, 'Frame Clk', length('Frame Clk'));
    COF_path = handles.settings.TDT.circuit_fpath_longStim_frameClk;
    useFrameClk = 1;
    nFrame = str2double(get(handles.cntFrames,'string'));
    setappdata(handles.playSnd,'nFrame',nFrame);
    setappdata(handles.playSnd,'nBaseFrame',nFrame);
end
setappdata(handles.playSnd,'useFrameClk',useFrameClk);
if ~exist(COF_path,'file')
    handles.errorMSG = 'TDT circuit file does not exist!';
    report_status(handles,handles.errorMSG);
    succeeded = 0;
    return
end
% RX6.LoadCOFsf(COF_path,handles.settings.TDT.fs_n);
switch handles.tdt_fs.Value
    case 1  % 100kHz fs
        n_fs = 4;
    case 2  % 200kHz fs
        n_fs = 5;
end
RX6.LoadCOFsf(COF_path,n_fs);
fprintf('circuit path: %s\n',COF_path);
% second argument in the above line(5, in this case) specifies sampling
% rate of RX6(see RX6 manual). Actual rate realizable by RX6 corrosponding
% to 200kHz is 195312.50Hz

%% load first stim waveform into MATLAB memory

succeeded = playRipple_set_TDT_tags_rippleEscabi(handles,useFrameClk); % 0: source0; 1 source1; set tags specific to each source
if ~succeeded
    return
end

% succeeded = playRipple_set_TDT_other_tags(handles);% set other tags that are same for both source
% if ~succeeded
%     return
% end
%% set attenuation for the first stimulus
succeeded = playSnd_set_atten(handles,1);
if ~succeeded
    return
end
RX6.Run;

return
%%
function succeeded = do_start_TDT_hardware_otherStims(handles)
RX6 = getappdata(handles.playSnd,'RX6');
RX6.Halt;
RX6.ClearCOF;
trgSrcStr = get(handles.trgSrc,'String');
sel = get(handles.trgSrc,'value');
if ~iscell(trgSrcStr)
    trgSrcStr = cellstr(trgSrcStr);
end
trgSrc = trgSrcStr{sel};

% select different circuit according to trigger source
if strncmp(trgSrc, 'User P(0.0)', length('User P(0.0)'))
    COF_path = handles.settings.TDT.circuit_fpath_otherStim_UserP;
    useFrameClk = 0;
end

if strncmp(trgSrc, 'Frame Clk', length('Frame Clk'))
    COF_path = handles.settings.TDT.circuit_fpath_otherStim_frameClk;
    useFrameClk = 1;
end
setappdata(handles.playSnd,'useFrameClk',useFrameClk);
% load circuit 
if ~exist(COF_path,'file')
    handles.errorMSG = 'TDT circuit file does not exist!';
    report_status(handles,handles.errorMSG);
    succeeded = 0;
    return
end
% print circuit and load circuit into RX6
fprintf('circuit file: %s\n',COF_path);
switch handles.tdt_fs.Value
    case 1  % 100kHz fs
        n_fs = 4;
    case 2  % 200kHz fs
        n_fs = 5;
    case 3 % use circuit default setting
        n_fs = nan;
end
if ~isnan(n_fs)
    RX6.LoadCOFsf(COF_path,n_fs);
    if RX6.LoadCOFsf(COF_path,n_fs)
        fprintf('\nPASSED loading circuit\n');
    else
        fprintf('\nFAILED loading circuit\n');
    end
else
    if RX6.LoadCOF(COF_path);
        fprintf('\nPASSED loading circuit\n');
    else
        fprintf('\nFAILED loading circuit\n');
    end
end
fs = RX6.GetSFreq;
fprintf('current fs: %fHz\n',fs);
setappdata(handles.playSnd,'curr_fs',fs);

% second argument in the above line(5, in this case) specifies sampling
% rate of RX6(see RX6 manual). Actual rate realizable by RX6 corrosponding
% to 200kHz is 195312.50Hz

%% load first stim waveform into MATLAB memory
[wav,nSamps] = playSnd_load_next_stim(handles,1);
%% set TDT circuit tags for next stimulus
succeeded = playSnd_set_TDT_tags(handles,wav,nSamps,useFrameClk); % 0: source0; 1 source1; set tags specific to each source

if ~succeeded
    return
end

%% set attenuation for the first stimulus
succeeded = playSnd_set_atten(handles,1);
if ~succeeded
    return
end
RX6.Run;
return

function succeeded = do_start_TDT_hardware_DRC(handles,hObject)
RX6 = getappdata(handles.playSnd,'RX6');
RX6.Halt;
RX6.ClearCOF;
trgSrcStr = get(handles.trgSrc,'String');
sel = get(handles.trgSrc,'value');
if ~iscell(trgSrcStr)
    trgSrcStr = cellstr(trgSrcStr);
end
trgSrc = trgSrcStr{sel};
if strncmp(trgSrc, 'UserP(0.0)', length('UserP(0.0)'))
    
    COF_path = handles.settings.TDT.circuit_fpath_DRC_UserP;
    useFrameClk = 0;
end
if strncmp(trgSrc, 'Frame Clk', length('Frame Clk'))
    
    COF_path = handles.settings.TDT.circuit_fpath_DRC_frameClk;
    useFrameClk = 1;

end
setappdata(handles.playSnd,'useFrameClk',useFrameClk);
if ~exist(COF_path,'file')
    handles.errorMSG = 'TDT circuit file does not exist!';
    report_status(handles,handles.errorMSG);
    succeeded = 0;
    return
end
fprintf('circuit file: %s\n',COF_path);
if RX6.LoadCOFsf(COF_path,handles.settings.TDT.fs_n)
    fprintf('\nPASSED loading circuit\n');
else
    fprintf('\nFAILED loading circuit\n');
end
% second argument in the above line(5, in this case) specifies sampling
% rate of RX6(see RX6 manual). Actual rate realizable by RX6 corrosponding
% to 200kHz is 195312.50Hz

%% load first stim waveform into MATLAB memory
%% set TDT circuit tags for next stimulus
succeeded = playRipple_set_TDT_tags_DRC(handles); % 0: source0; 1 source1; set tags specific to each source
if ~succeeded
    return
end
% succeeded = playRipple_set_TDT_other_tags(handles);% set other tags that are same for both source
% if ~succeeded
%     return
% end
%% set attenuation for the first stimulus
succeeded = playRipple_set_atten(handles,1);
if ~succeeded
    return
end
RX6.Run;
return

%% ADAPTED FROM PAUL WATKIN, auditoryStim GUI
function succeeded = do_init_TDT(handles)
succeeded = 1;
% iniate communication with RX6.
report_status(handles,'Connecting to RX6');

% Create an Active X control that can talk to a RX6
TDTRX6 = actxcontrol('RPco.x', [5 5 0 0], handles.playSnd);

% Tell the Active X control to establish comm. link with the RX6
%if ~TDTRX6.ConnectRX6('USB', 1) % xxx - make parameter in handles.TDT

if ~TDTRX6.ConnectRX6('GB', 1)
    handles.errorMSG = 'FAILED connecting to RX6 through GB!';
    report_status(handles,handles.errorMSG);
    if ~TDTRX6.ConnectRX6('USB', 1)
        handles.errorMSG = 'FAILED connecting to RX6 through USB!';
        report_status(handles,handles.errorMSG);
        succeeded = 0;return
    else
        report_status(handles,'PASSED connecting to RX6 through USB!');
    end
else
    report_status(handles,'PASSED connecting to RX6 through GB!');
end

% handles.TDT.RX6 = TDTRX6;
setappdata(handles.playSnd,'RX6',TDTRX6);
% initialize the attenuators.
report_status(handles,'Connecting to PA5');

% Create Active X controls to talk to PA5s
%TDTPA5 = zeros(1,handles.TDT.NUMPA5);

clear TDTPA5
for i=1:handles.settings.TDT.nPA5
    TDTPA5(i) = actxcontrol('PA5.x',[5 5 0 0], handles.playSnd);
    
    % Tell the Active X control to establish comm. link with the PA5s
    %if ~TDTPA5(i).ConnectPA5('USB',i) % xxx - make parameter in handles.TDT
    if ~TDTPA5(i).ConnectPA5('GB',i)
        
        report_status(handles,sprintf('FAILED connecting to PA5 %d/%d through GB!',...
            i,handles.settings.TDT.nPA5));
        if ~TDTPA5(i).ConnectPA5('USB',i)
            handles.errorMSG = sprintf('FAILED connecting to PA5 %d/%d through USB!',...
                i,handles.settings.TDT.nPA5);
            report_status(handles,handles.errorMSG);
            
            succeeded = 0; return
        else
            report_status(handles,sprintf('PASSED connecting to PA5 %d/%d through USB!',...
                i,handles.settings.TDT.nPA5));
        end
        %     succeeded = 0; return
    else
        report_status(handles,sprintf('PASSED connecting to PA5 %d/%d through GB!',...
            i,handles.settings.TDT.nPA5));
    end
end

% handles.TDT.PA5 = TDTPA5;
setappdata(handles.playSnd,'PA5',TDTPA5);

% update hw information application data for callbacks
% setappdata(handles.playSnd,'TDT',handles.TDT);
report_status(handles,'TDT initiation complete!');


function report_status(handles,message)
set(handles.status_str,'string',message,'visible','on');
display(sprintf('\n%s\n',message));
drawnow;




% --- Executes when selected object is changed in uibuttongroup1.
function uibuttongroup1_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uibuttongroup1
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
if get(handles.TORC1,'value')
    set(handles.stim_idlelist,'enable','on');
    set(handles.stim_uselist,'enable','on');
    set(handles.TORC2_list,'enable','off');
    set(handles.TORC2_uselist,'enable','off');
else
    set(handles.TORC2_list,'enable','on');
    set(handles.TORC2_uselist,'enable','on');
    set(handles.stim_idlelist,'enable','off');
    set(handles.stim_uselist,'enable','off');
end


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over stim_uselist.
function stim_uselist_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to stim_uselist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


function putStimtoIdle(handles,subfolder)
idleList = get(handles.stim_idlelist,'string');
n = getappdata(handles.stim_idlelist,'n_stim_idle');
if ~iscell(idleList)
    idleList = cellstr(idleList);
end
idleList{n+1} = subfolder;
set(handles.stim_idlelist,'string',idleList);
setappdata(handles.stim_idlelist,'n_stim_idle',n+1);


return

function removeStimfromUse(handles,subfolder,idx)
n = getappdata(handles.stim_uselist,'n_stim_use');
setappdata(handles.stim_uselist,'n_stim_use',n-1);
subfolder(idx) = [];
tmp = min(idx,size(subfolder,1));
set(handles.stim_uselist,'value',tmp);
set(handles.stim_uselist,'string',subfolder);
return


% --- Executes on key press with focus on stim_uselist and none of its controls.
function stim_uselist_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to stim_uselist (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
% if strcmp(eventdata.Key, 'n')
%     if getappdata(handles.stim_uselist,'n_stim_use')>=1
%         idx = get(handles.stim_uselist,'value');
%         subfolder = get(handles.stim_uselist,'string');
%         if ~iscell(subfolder)
%             subfolder = cellstr(subfolder);
%         end
%         putStimtoIdle(handles,subfolder{idx});
%         removeStimfromUse(handles,subfolder,idx);
%     else
%         % do nothing?
%     end
% end









function nCycle_Callback(hObject, eventdata, handles)
% hObject    handle to nCycle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of nCycle as text
%        str2double(get(hObject,'String')) returns contents of nCycle as a double


% --- Executes during object creation, after setting all properties.
function nCycle_CreateFcn(hObject, eventdata, handles)
% hObject    handle to nCycle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function nRepeat_Callback(hObject, eventdata, handles)
% hObject    handle to nRepeat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of nRepeat as text
%        str2double(get(hObject,'String')) returns contents of nRepeat as a double


% --- Executes during object creation, after setting all properties.
function nRepeat_CreateFcn(hObject, eventdata, handles)
% hObject    handle to nRepeat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function atten_Callback(hObject, eventdata, handles)
% hObject    handle to atten (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of atten as text
%        str2double(get(hObject,'String')) returns contents of atten as a double


% --- Executes during object creation, after setting all properties.
function atten_CreateFcn(hObject, eventdata, handles)
% hObject    handle to atten (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in stim_idlelist.
function stim_idlelist_Callback(hObject, eventdata, handles)
% hObject    handle to stim_idlelist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns stim_idlelist contents as cell array
%        contents{get(hObject,'Value')} returns selected item from stim_idlelist


% --- Executes during object creation, after setting all properties.
function stim_idlelist_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stim_idlelist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object deletion, before destroying properties.
function stim_idlelist_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to stim_idlelist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes when selected object is changed in modeChange.
function modeChange_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in modeChange
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(handles.testMode,'value')
    looptest(handles.playSnd);
    
end
if get(handles.cheetahMode,'value')
end


% --- Executes on key press with focus on arm_disarm and none of its controls.
function arm_disarm_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to arm_disarm (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in toggle_arm_disarm.
function toggle_arm_disarm_Callback(hObject, eventdata, handles)
% hObject    handle to toggle_arm_disarm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~getappdata(handles.playSnd,'armed')
    succeeded = do_arm(handles,hObject);
    if succeeded
        setappdata(handles.playSnd,'armed',1);
        %         update_arm_disarm_toggle(handles);
        set(handles.toggle_arm_disarm,'String','Disarm');
    else
        set(handles.toggle_arm_disarm,'value',0);
    end
else
    succeeded = do_disarm(handles,hObject);
    if succeeded
        setappdata(handles.playSnd,'armed',0);
        %         update_arm_disarm_toggle(handles);
        report_status(handles,'Disarmed!');
        set(handles.toggle_arm_disarm,'String','Arm');
    else
        set(handles.toggle_arm_disarm,'value',1);
        
    end
end
% Hint: get(hObject,'Value') returns toggle state of toggle_arm_disarm


% --- Executes on button press in SoftTrg_1.
function SoftTrg_1_Callback(hObject, eventdata, handles)
% hObject    handle to SoftTrg_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

RX6 = getappdata(handles.playSnd,'RX6');
RX6.SoftTrg(1);


% --- Executes when user attempts to close playSnd.
function playSnd_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to playSnd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isappdata(handles.playSnd,'RX6')
    RX6 = getappdata(handles.playSnd,'RX6');
    RX6.Halt;
end
% Hint: delete(hObject) closes the figure
delete(hObject);


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over stim_idlelist.
function stim_idlelist_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to stim_idlelist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function softGain_Callback(hObject, eventdata, handles)
% hObject    handle to softGain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of softGain as text
%        str2double(get(hObject,'String')) returns contents of softGain as a double


% --- Executes during object creation, after setting all properties.
function softGain_CreateFcn(hObject, eventdata, handles)
% hObject    handle to softGain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in trgSrc.
function trgSrc_Callback(hObject, eventdata, handles)
% hObject    handle to trgSrc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns trgSrc contents as cell array
%        contents{get(hObject,'Value')} returns selected item from trgSrc


% --- Executes during object creation, after setting all properties.
function trgSrc_CreateFcn(hObject, eventdata, handles)
% hObject    handle to trgSrc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function cntFrames_Callback(hObject, eventdata, handles)
% hObject    handle to cntFrames (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of cntFrames as text
%        str2double(get(hObject,'String')) returns contents of cntFrames as a double


% --- Executes during object creation, after setting all properties.
function cntFrames_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cntFrames (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in SoftTrg_3.
function SoftTrg_3_Callback(hObject, eventdata, handles)
% hObject    handle to SoftTrg_3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
RX6 = getappdata(handles.playSnd,'RX6');
tic
RX6.SoftTrg(3);
toc
fprintf('triggered!\n')


% --- Executes on selection change in channel_sel.
function channel_sel_Callback(hObject, eventdata, handles)
% hObject    handle to channel_sel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
send_ttl_in_other_chan_Callback(hObject, eventdata, handles); % when changing sound channel, change ttl channel too if selected
% Hints: contents = cellstr(get(hObject,'String')) returns channel_sel contents as cell array
%        contents{get(hObject,'Value')} returns selected item from channel_sel


% --- Executes during object creation, after setting all properties.
function channel_sel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to channel_sel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in imagingMode.
function imagingMode_Callback(hObject, eventdata, handles)
% hObject    handle to imagingMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of imagingMode


function nBaseFrame_Callback(hObject, eventdata, handles)
% hObject    handle to nBaseFrame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of nBaseFrame as text
%        str2double(get(hObject,'String')) returns contents of nBaseFrame as a double


% --- Executes during object creation, after setting all properties.
function nBaseFrame_CreateFcn(hObject, eventdata, handles)
% hObject    handle to nBaseFrame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in loopTrg3.
function loopTrg3_Callback(hObject, eventdata, handles)
% hObject    handle to loopTrg3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
nPresent = getappdata(handles.playSnd,'nPresent');
RX6 = getappdata(handles.playSnd,'RX6');
% nFrame = get(handles.cntFrames,'string'); nFrame = str2double(nFrame);
% nBaseFrame = get(handles.nBaseFrame,'string');  nBaseFrame = str2double(nBaseFrame);
% prompt = 'cycle how many times? (each cycle is 0.5sec long): ';
% nCycle = input(prompt);
% if ~isempty(nCycle)
nCycle = 50;
for i = 1:nCycle
    RX6.SoftTrg(3);
    pause(0.5);
end
% end

% --- Executes on button press in clear_uselist.
function clear_uselist_Callback(hObject, eventdata, handles)
% hObject    handle to clear_uselist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.stim_uselist,'value',1);
set(handles.stim_uselist,'string',{[]});
setappdata(handles.stim_uselist,'n_stim_use',0);


% --- Executes on selection change in sel_trg_src.
function sel_trg_src_Callback(hObject, eventdata, handles)
% hObject    handle to sel_trg_src (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns sel_trg_src contents as cell array
%        contents{get(hObject,'Value')} returns selected item from sel_trg_src


% --- Executes during object creation, after setting all properties.
function sel_trg_src_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sel_trg_src (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in sound_only.
function sound_only_Callback(hObject, eventdata, handles)
% hObject    handle to sound_only (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of sound_only


% --- Executes on button press in withITD.
function withITD_Callback(hObject, eventdata, handles)
% hObject    handle to withITD (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of withITD


% --- Executes on selection change in tdt_fs.
function tdt_fs_Callback(hObject, eventdata, handles)
% hObject    handle to tdt_fs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns tdt_fs contents as cell array
%        contents{get(hObject,'Value')} returns selected item from tdt_fs


% --- Executes during object creation, after setting all properties.
function tdt_fs_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tdt_fs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function nFramesBetween_Callback(hObject, eventdata, handles)
% hObject    handle to nFramesBetween (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of nFramesBetween as text
%        str2double(get(hObject,'String')) returns contents of nFramesBetween as a double


% --- Executes during object creation, after setting all properties.
function nFramesBetween_CreateFcn(hObject, eventdata, handles)
% hObject    handle to nFramesBetween (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function nFramesPlayout_Callback(hObject, eventdata, handles)
% hObject    handle to nFramesPlayout (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of nFramesPlayout as text
%        str2double(get(hObject,'String')) returns contents of nFramesPlayout as a double


% --- Executes during object creation, after setting all properties.
function nFramesPlayout_CreateFcn(hObject, eventdata, handles)
% hObject    handle to nFramesPlayout (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in load_previous_setting.
function load_previous_setting_Callback(hObject, eventdata, handles)
% hObject    handle to load_previous_setting (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% select a mat file from sound file folder
[fn,pn] = uigetfile('*.mat','please select past sound file',getappdata(handles.playSnd,'stimfile_dir'));
if fn
    hMat = load(fullfile(pn,fn));
    % set values for the settings
    try  
        % set(handles.trgSrc,'Value',hMat.trgSrcVal); % trigger source
        set(handles.nRepeat,'String',hMat.nRepeatString);
        set(handles.atten,'String',hMat.attenString);
        set(handles.softGain,'String',hMat.softGainString);
        set(handles.tdt_fs,'Value',hMat.tdtFsVal);
        % set(handles.channel_sel,'Value',hMat.chanSelVal);
        set(handles.nBaseFrame,'String',hMat.nBaseFrameString);
        set(handles.nFramesPlayout,'String',hMat.nFramesPlayoutString);
        set(handles.nFramesBetween,'String',hMat.nFramesBetweenString);
    catch
        report_status('uncompatible sound file selected!');
    end
end



function exp_info_Callback(hObject, eventdata, handles)
% hObject    handle to exp_info (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of exp_info as text
%        str2double(get(hObject,'String')) returns contents of exp_info as a double


% --- Executes during object creation, after setting all properties.
function exp_info_CreateFcn(hObject, eventdata, handles)
% hObject    handle to exp_info (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in load_preset_stim_seq.
function load_preset_stim_seq_Callback(hObject, eventdata, handles)
% hObject    handle to load_preset_stim_seq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[fn,pn] = uigetfile('*.mat','please select preset stim sequence file',get(handles.stim_path,'string'));
if fn
    hMat = load(fullfile(pn,fn));
    preset_stim_seq = hMat.preset_stim_seq;
    % set values for the settings
%     try  
        %set(handles.trgSrc,'Value',2); % 2: frame clk
        set(handles.nBaseFrame,'String',num2str(preset_stim_seq.nBaseFrame));
        % construct nFramesPlayoutString
        nFramesPlayoutString = '[';
        for i = 1:length(preset_stim_seq.nFramesPlayout)
            if i<length(preset_stim_seq.nFramesPlayout)
                nFramesPlayoutString = [nFramesPlayoutString  num2str(preset_stim_seq.nFramesPlayout(i)) ','];
            else
                nFramesPlayoutString = [nFramesPlayoutString  num2str(preset_stim_seq.nFramesPlayout(i)) ']'];
            end
            
        end
        set(handles.nFramesPlayout,'String',nFramesPlayoutString);
        % construct nFramesBetweenString
        nFramesBetweenString = '[';
        for i = 1:size(preset_stim_seq.nFramesBetween,1)
            nFramesBetweenString = [nFramesBetweenString num2str(preset_stim_seq.nFramesBetween(i,1)) ',' ...
                num2str(preset_stim_seq.nFramesBetween(i,2)) ';'];
        end
        nFramesBetweenString = [nFramesBetweenString ']'];
        set(handles.nFramesBetween,'String',nFramesBetweenString);
        % construct nRepeat string
        nRepeatString = '[';
        for i = 1:length(preset_stim_seq.nRep)
            if i<length(preset_stim_seq.nRep)
                nRepeatString = [nRepeatString  num2str(preset_stim_seq.nRep(i)) ','];
            else
                nRepeatString = [nRepeatString  num2str(preset_stim_seq.nRep(i)) ']'];
            end
        end
        set(handles.nRepeat,'String',nRepeatString);
        % construct atten string
        attenString = '{';
        for i = 1:length(preset_stim_seq.atten)
            atten_tmp = preset_stim_seq.atten{i};
            atten_tmp_string = '[';
            for j = 1:length(atten_tmp)
                if j < length(atten_tmp)
                    atten_tmp_string = [atten_tmp_string num2str(atten_tmp(j)) ,','];
                else
                    atten_tmp_string = [atten_tmp_string num2str(atten_tmp(j)) ,']'];
                end
            end
            if i < length(preset_stim_seq.atten)
                attenString = [attenString atten_tmp_string ','];
            else
                attenString = [attenString atten_tmp_string '}'];
            end
        end
        set(handles.atten,'String',attenString);
        % print out the folders to use
        for i = 1:length(preset_stim_seq.subfolder)
            fprintf('stim folder %2d: \n%s\n',i,preset_stim_seq.subfolder{i});
        end
        % if random-sequential mode, inform user when next set will start
        stimSeq = preset_stim_seq.stimSeq(:,1);
        folderID = preset_stim_seq.stimFolderID(stimSeq);
%         if strcmp(preset_stim_seq.mode,'random-sequential')
%             for i = 1:length(preset_stim_seq.subfolder)
%                 ind = find(folderID==i);
%                 fprintf('stim set %2d, first stim starts at frame %d, last one at frame %d\n',...
%                     i,...
%                     preset_stim_seq.stimOnFrame(ind(1)),...
%                     preset_stim_seq.stimOnFrame(ind(end)));
%                 
%             end
%             
%         end
        setappdata(handles.playSnd,'preset_stim_seq',preset_stim_seq);
        setappdata(handles.playSnd,'preset_stim_seq_filename',fn);
%     catch
%         error('uncompatible stim seq file selected!');
%     end
end

% --- Executes on button press in use_this_folder.
function use_this_folder_Callback(hObject, eventdata, handles)
% hObject    handle to use_this_folder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if getappdata(handles.stim_idlelist,'n_stim_idle')>=1
    idx = get(handles.stim_idlelist,'value');
    subfolder = get(handles.stim_idlelist,'string');
    if ~iscell(subfolder)
        subfolder = cellstr(subfolder);
    end
    putStimtoUse(handles,subfolder{idx});
else
end

% --- Executes on button press in send_ttl_in_other_chan.
function send_ttl_in_other_chan_Callback(hObject, eventdata, handles)
% hObject    handle to send_ttl_in_other_chan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of send_ttl_in_other_chan
val = get(handles.send_ttl_in_other_chan,'Value');
if val == 1 % stim selected
    chan_sel = get(handles.channel_sel,'value');
    if chan_sel == 1 % sound in channel 1
        setappdata(handles.playSnd,'ttl_channel',2) % ttl in channel 2
    elseif chan_sel == 2
        setappdata(handles.playSnd,'ttl_channel',1) % ttl in channel 2
    end
    set(handles.send_ttl_in_other_chan,'String',sprintf('Send TTL in channel %d',getappdata(handles.playSnd,'ttl_channel')));
else
    setappdata(handles.playSnd,'ttl_channel',0); % default no ttl
    set(handles.send_ttl_in_other_chan,'String','Send TTL in other channel');
end

% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over send_ttl_in_other_chan.
function send_ttl_in_other_chan_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to send_ttl_in_other_chan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
