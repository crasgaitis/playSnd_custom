function playSnd_timer_startfcn(obj,event,handles)

%     
%         setappdata(handles.playSnd,'waitForTrg',1);
%         setappdata(handles.playSnd,'nStimPlayed',0);
%         nPresent = getappdata(handles.playSnd,'nPresent');
%         report_status(handles,sprintf('Waiting for trigger, stim 1 / %d',nPresent));
%         
% 
%         
%         setappdata(handles.playSnd,'stimfile_dir',...
%                 stimfile_dir);
%         allStim = getappdata(handles.playSnd,'allStim');
%         nStimPlayed = 0;
%         stimfile_name = sprintf('stim_file_%s.mat',datestr(now,'yyyy-mm-dd_HH-MM-SS'));
%         setappdata(handles.playSnd,'stimfile_name',stimfile_name);
%         save(fullfile(stimfile_dir,stimfile_name),'allStim','nStimPlayed','-v7.3');
%         hMat = matfile(fullfile(stimfile_dir,stimfile_name),'Writable',true); % create a handle for .mat file just created
%         setappdata(handles.playSnd,'hMat',hMat); % save handle to .mat file as appdata
%         % let's assume by now cheetah has been successfully connected
%         if cheetahMode
%         end
        

        
        %%
        setappdata(handles.playSnd,'waitForTrg',1);
        setappdata(handles.playSnd,'nStimPlayed',0);
        nPresent = getappdata(handles.playSnd,'nPresent');
        report_status(handles,sprintf('Waiting for trigger, stim 1 / %d',nPresent)); 
        
        cheetahMode = getappdata(handles.playSnd,'cheetahMode');
        if cheetahMode
            GetCheetahEvent; % flush all previous events
        end
%         if cheetahMode
%             %hCheetah = findall(0,'type','figure','tag','cheetah_helper'); % find handle of cheetah_helper
%             hCheetah = findobj('tag','cheetah_helper');
%             if isempty(hCheetah)
%                 error('cheetah_helper is not running!');
%             end
%             stimfile_dir = getappdata(hCheetah,'cheetah_dir');
%             GetCheetahEvent; % flush all previous events
%         else
            
            stimfile_dir = getappdata(handles.playSnd,'stimfile_dir');
% 
%         end
        
        allStim = getappdata(handles.playSnd,'allStim');
        nStimPlayed = 0;
        stimfile_name = sprintf('sound_file_%s_%s.mat',...
            datestr(now,'yyyy-mm-dd_HH-MM-SS'),get(handles.exp_info,'String'));
        setappdata(handles.playSnd,'stimfile_name',stimfile_name);
        save(fullfile(stimfile_dir,stimfile_name),'allStim','nStimPlayed','-v7.3');   
        hMat = matfile(fullfile(stimfile_dir,stimfile_name),'Writable',true); % create a handle for .mat file just created
        setappdata(handles.playSnd,'hMat',hMat); % save handle to .mat file as appdata
        if get(handles.sel_long_stim,'value')
            setappdata(handles.playSnd,'nSegPlayed',0);
            setappdata(handles.playSnd,'stimInfoSaved',0);
        end
        RX6 = getappdata(handles.playSnd,'RX6');
        RX6.SoftTrg(1); % start!
        RX6.SoftTrg(2); % reset all counters in TDT circuit to 0

return


function report_status(handles,message)
set(handles.status_str,'string',message,'visible','on');
display(sprintf('\n%s\n',message));
drawnow;