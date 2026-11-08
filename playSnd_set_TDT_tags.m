function succeeded = playSnd_set_TDT_tags(varargin)
succeeded = 1;
switch nargin
    case  3
        handles = varargin{1};
        wav = varargin{2};
        nSamps = varargin{3};
        
    case 4
        handles = varargin{1};
        wav = varargin{2};
        nSamps = varargin{3};
        useFrameClk = varargin{4};
    case 5
        handles = varargin{1};
        wav = varargin{2};
        nSamps = varargin{3};
        useFrameClk = varargin{4};
        ITD = varargin{5};
    case 6
        handles = varargin{1};
        wav = varargin{2};
        nSamps = varargin{3};
        useFrameClk = varargin{4};
        ITD = varargin{5};
        gain2 = varargin{6};
end

% switch get(handles.trgSrc,'value')
%     case 1 % UserP(0.0)
%         useFrameClk = 0;
%     case 2 % Frame Clk
%         useFrameClk = 1;
% end

RX6 = getappdata(handles.playSnd,'RX6');


% ------------ commented JL 1/25/2016 --------------------------
% if get(handles.cheetahMode,'value')
%     if ~RX6.SetTagVal('bufSz',nSamps);
%         report_status(handles,'error setting tag bufSz!');
%         succeeded = 0;
%         return
%     end
%     if ~RX6.SetTagVal('nCycle',getappdata(handles.playSnd,'nCycle'))
%         report_status(handles,'error setting tag nCycle!');
%         succeeded = 0;
%         return
%     end
% end

if get(handles.imagingMode,'value')
    if useFrameClk    
        stimOnFrame = getappdata(handles.playSnd,'stimOnFrame');
        if ~RX6.SetTagVal('frame2cnt',stimOnFrame(1))
            report_status(handles,'error setting tag frame2cnt!');
            succeeded = 0;
            return
        end
    else
    end
    if get(handles.sound_only,'value') % if checked, set trg source to SoftTrg such that do not require frame clk to play sound
        RX6.SetTagVal('trg_sel',2);
    else
        switch get(handles.trgSrc,'value')
            case 1
                RX6.SetTagVal('trg_sel',0);
            case 2
                RX6.SetTagVal('trg_sel',1);
        end
    end
end
if size(wav,1)~=1 % if wav not a row vector
    wav = wav';
end
if ~RX6.SetTagVal('bufSzCmp',nSamps-1)
    report_status(handles, 'error setting tag bufSzCmp!');
    succeeded = 0;
    return
end

if ~RX6.WriteTagV('data',0,wav); % WriteTagV takes row vectors
    report_status(handles,'error setting tag data!');
    succeeded = 0;
    return
end
    
chan_sel = get(handles.channel_sel,'value');
if ~RX6.SetTagVal('channel_sel',chan_sel)
    report_status(handles,'error setting tag channel_sel!');
    succeeded = 0;
    return
end
if ~RX6.SetTagVal('ttl_chan',3-chan_sel) % need to set this channel regardless of whether we needed it
    warning('failed to set ttl_chan')
else
    disp('succeeded setting ttl_chan')
end

ttl_chan = getappdata(handles.playSnd,'ttl_channel'); % however if we don't really need it, output 0 V
if ttl_chan~=0
    if ~RX6.SetTagVal('ttl_val',5)
        warning('failed to set ttl val')
    else
        disp('succeeded setting ttl val')
    end
else
    if ~RX6.SetTagVal('ttl_val',0)
        warning('failed to set ttl val')
    else
        disp('succeeded setting ttl val')
    end
end

return

function report_status(handles,message)
set(handles.status_str,'string',message,'visible','on');
display(sprintf('\n%s\n',message));
drawnow;