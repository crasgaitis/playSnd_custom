function playSnd_timer_callback_workForAll(varargin) %obj,event,handles,rig,useFrameClk
handles = varargin{3};
RX6 = getappdata(handles.playSnd,'RX6');
% enable = RX6.GetTagVal('enable');
% enable2 = RX6.GetTagVal('enable2');
% cnt_trg = RX6.GetTagVal('cnt_trg');
% bufPos = RX6.GetTagVal('bufPos');
% counter = RX6.GetTagVal('counter');
%
% fprintf('enable = %d ; enable2 = %d ; cnt_trg = %d ; bufPos = %d ; counter = %d\n',...
%     enable,enable2,cnt_trg,bufPos,counter);
% switch get(handles.trgSrc,'value')
%     case 1 % UserP(0.0)
%         useFrameClk = 0;
%     case 2 % Frame Clk
%         useFrameClk = 1;
% end
useFrameClk = getappdata(handles.playSnd,'useFrameClk');

if get(handles.sel_other,'value')
    nStimPlayed = getappdata(handles.playSnd,'nStimPlayed');
    nPresent = getappdata(handles.playSnd,'nPresent');
    nPlayedRX6 = RX6.GetTagVal('nPlayedRX6');
    if useFrameClk
        cnt = RX6.GetTagVal('cnt_frame');
        set(handles.cnt_txt,'string',num2str(cnt));
    end
    
    if nStimPlayed < nPlayedRX6 % meaning a stim just finished playing, need to update gui
        RX6.SoftTrg(2); % reset buf position
        nStimPlayed = nStimPlayed + 1;
        setappdata(handles.playSnd,'nStimPlayed',nStimPlayed);
        %-- save info of stim just played
        tic
        stimSeq = getappdata(handles.playSnd,'stimSeq');
        fprintf('\nsaving...\n')
        setappdata(handles.playSnd,sprintf('stimPlayedID%d',nStimPlayed),stimSeq(nStimPlayed,1));
        setappdata(handles.playSnd,sprintf('stimPlayedAtten%d',nStimPlayed),stimSeq(nStimPlayed,2));
        if getappdata(handles.playSnd,'cheetahMode')
            setappdata(handles.playSnd,sprintf('stimPlayedEvent%d',nStimPlayed),GetCheetahEvent);
        end
        toc
        %-- check how many stim to be played
        if  nStimPlayed >= nPresent
            % finished playing all presentations of stimuli
            report_status(handles,'Finished playing all stimuli!');
            TDT_TIMER = getappdata(handles.playSnd,'TDT_TIMER');
            if isvalid(TDT_TIMER)
                stop(TDT_TIMER);delete(TDT_TIMER);
            end
            setappdata(handles.playSnd,'armed',0);
            set(handles.toggle_arm_disarm,'value',0,'string','Arm');
            
        else
            %             report_status(handles,sprintf('Finished. Loading stim %d / %d',nStimPlayed + 1,nPresent));
            [wav,nSamps] = playSnd_load_next_stim(handles,nStimPlayed + 1);
            %% set TDT circuit tags for next stimulus
            %             succeeded = playSnd_set_TDT_tags(handles,wav,nSamps,useFrameClk);
            %             if ~succeeded
            %                 return
            %             end
            
            if size(wav,1)~=1 % if wav not a row vector
                wav = wav';
            end
            tic
            
            %------ below is the old version of writing data JL 02222016 --
            
            %             if ~RX6.WriteTagV('data',0,wav); % WriteTagV takes row vectors
            %                 report_status(handles,'error setting tag data!');
            %                 return
            %             end
            %             if ~RX6.SetTagVal('bufSzCmp',nSamps-1);
            %                 report_status(handles, 'error setting tag bufSzCmp!');
            %                 return
            %             end
            %             if ~isempty(ITD)  % if ITD is nonempty then we are doing experiments in owl! 1/25/2016
            %                 if ~RX6.SetTagVal('delay1',1 ) % ITD cannot be smaller than 0.01ms or 10 microseconds
            %                     report_status(handles,'error setting delay2 value!');
            %                     return
            %                 end
            %                 if ~RX6.SetTagVal('delay2',1 - ITD) % ITD cannot be smaller than 0.01ms or 10 microseconds
            %                     report_status(handles,'error setting delay2 value!');
            %                     return
            %                 end
            %             end
            
            
            if ~RX6.SetTagVal('bufSzCmp',nSamps-1);
                report_status(handles, 'error setting tag bufSzCmp!');
                succeeded = 0;
                return
            end
            
            if ~RX6.WriteTagV('data',0,wav); % WriteTagV takes row vectors
                report_status(handles,'error setting tag data!');
                succeeded = 0;
                return
            end
            
            % set the # of frame for next stim onset
            stimOnFrame = getappdata(handles.playSnd,'stimOnFrame');
            disp(stimOnFrame+"STIM")
            if ~isnan(stimOnFrame) % if work with cheetah stimOnFrame will always be nan
                
        
                if ~RX6.SetTagVal('frame2cnt',stimOnFrame(nStimPlayed+1)); % WriteTagV takes row vectors %%TAB TAB
                    report_status(handles,'error setting cnf_frame!');
                    succeeded = 0;
                    return
                end
            end
            t_write = toc;
            fprintf('time to write data: %f \n',t_write);
            
            if ~RX6.SetTagVal('ttl_val',5)
                %     report_status(handles,'error setting tag channel_sel!');
                %     succeeded = 0;
                %     return
                warning('failed to set ttl val')
            else
                disp('succeeded setting ttl val')
            end

            playSnd_set_atten(handles,nStimPlayed + 1);
            
            report_status(handles,sprintf('Waiting for trigger, stim %d / %d',nStimPlayed + 1,nPresent));
            
        end
        
    end
    
    if RX6.GetTagVal('playing')
        report_status_on_gui(handles,sprintf('playing stim %d / %d...',nStimPlayed+1,nPresent));
    end
    
else
    
    nStimPlayed = getappdata(handles.playSnd,'nStimPlayed');
    nPresent = getappdata(handles.playSnd,'nPresent');
    %     fprintf('bufPos0 = %d ; bufPos1 = %d ; ', RX6.GetTagVal('bufPos0'),RX6.GetTagVal('bufPos1'));
    %     fprintf('enable0 = %d ; enable1 = %d ;\n', RX6.GetTagVal('enable0'),RX6.GetTagVal('enable1'));
    %         bufPos = RX6.GetTagVal('bufPos');
    %         fprintf('bufPos = %d ; nSegPlayed = %d ;\n',bufPos,nSegPlayed);
    
    if RX6.GetTagVal('playing')
        if ~getappdata(handles.playSnd,'stimInfoSaved')
            tic
            setappdata(handles.playSnd,'stimInfoSaved',1);
            stimSeq = getappdata(handles.playSnd,'stimSeq');
            fprintf('\nsaving...\n')
            nStimPlayed = nStimPlayed+1; setappdata(handles.playSnd,'nStimPlayed',nStimPlayed);
            setappdata(handles.playSnd,sprintf('stimPlayedID%d',nStimPlayed),stimSeq(nStimPlayed,1));
            setappdata(handles.playSnd,sprintf('stimPlayedAtten%d',nStimPlayed),stimSeq(nStimPlayed,2));
            if getappdata(handles.playSnd,'cheetahMode')
                setappdata(handles.playSnd,sprintf('stimPlayedEvent%d',nStimPlayed),GetCheetahEvent);
            end
            t_saving = toc;
            fprintf('saving complete, time spent: %f\n',t_saving);
        end
        
        report_status_on_gui(handles,sprintf('playing stim %d / %d',nStimPlayed,nPresent));
        setappdata(handles.playSnd,'waitForTrg',0);
        
        nSegPlayed = RX6.GetTagVal('nPlayedRX6');
        if nSegPlayed > getappdata(handles.playSnd,'nSegPlayed') % just finished one segment, time to write new segment into buffer
            fprintf('number of segment(s) played: %d, more to go\n',nSegPlayed);
            setappdata(handles.playSnd,'nSegPlayed',nSegPlayed);
            nSamps_seg = getappdata(handles.playSnd,'nSamps_seg');
            
            try
                if nSegPlayed+2 <= getappdata(handles.playSnd,'nSeg')
                    
                    write_pos = mod(nSegPlayed+1,2)*nSamps_seg;
                    tic
                    data = return_segment(handles,nSegPlayed+2);
                    tload = toc;
                    fprintf('time to load data: %f\n',tload);
                    tic
                    if ~RX6.WriteTagV('data',write_pos,... %h.wave(nSegPlayed+2,:)
                            data);
                        fprintf('error writing data');
                    end
                    twrite = toc;
                    fprintf('time to write data: %f\n',twrite);
                end
            catch
                fprintf('wrong here\n')
            end
        else
            setappdata(handles.playSnd,'nSegPlayed',nSegPlayed);
            
        end
        
    else
        
        nSegPlayed = RX6.GetTagVal('nPlayedRX6');
        
        if  nSegPlayed >= getappdata(handles.playSnd,'nSeg')
            fprintf('number of segment(s) played: %d \n',nSegPlayed);
            
            % finished playing all presentations of stimuli
            report_status(handles,'Finished playing all stimuli!');
            
            TDT_TIMER = getappdata(handles.playSnd,'TDT_TIMER');
            if isvalid(TDT_TIMER)
                stop(TDT_TIMER);delete(TDT_TIMER);
            end
            setappdata(handles.playSnd,'armed',0);
            set(handles.toggle_arm_disarm,'value',0,'string','Arm');
        else
            if useFrameClk
                cnt = RX6.GetTagVal('cnt_frame');
                set(handles.base_cnt,'string',num2str(cnt));
                set(handles.cnt_txt,'string','0');
            end
        end
    end
    
end


return

function report_status(handles,message)
set(handles.status_str,'string',message,'visible','on');
display(sprintf('\n%s\n',message));
drawnow;


function report_status_on_gui(handles,message)
set(handles.status_str,'string',message,'visible','on');
drawnow;