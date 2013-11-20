

function maskRecord(action,param)
global hPlotOrigin hPlotProc;
global hTxtUSBPort;
global startBtHndl stopBtHndl;
global hLegend;

global pTtyUSB;
global pSaveFile;

global channelNumMax;
global lenPlot2D nShort nLong;
global flagValue2Vol kValue2Vol shiftValue2Vol;
global flagJustStarted;
global flagLiveProc;

global dataRaw; %all the original data from serial port
global lenDataRaw;
global label;
global labelList;

global step;

global ADCMatrix;

global nADC nIO;
nADC=8;
nIO=8;
%nIO=12;

serialPortName = '3'; 
%for mac
%serialPortName='M4A9N70S';
%serialPortName='M4A9N746';
folderSave='../save/';

channelNumMax=4;
step=1e-4;
flagLiveProc=0;

%config for display
 

%config for display    

%for eating - big screen
    lenPlot2D=40;   %the last 30 point as what ploted
    nShort=150;    %as simple action 2 second
    nLong=30*20;  %plot last 1min

    posPlotOrigin= [0.10 0.2 0.3 0.6];
    posPlotProc= [0.50 0.2 0.3 0.6];          

    %label list
    labelList=struct('label',...
                    {'c','l','r','u','d','o','a','1','2','3','4','5'},...
                'labelStr',...
                    {'click-center','left to right','right to left','up','down','clockwise','anticlockwise',...
                    'left-up','right-up','right-down','left-down','center'}...
                 );
       
    flagValue2Vol = 1;  %convert value to voltage
    kValue2Vol=-2.5/16777215;
    shiftValue2Vol=2.5; %value 0->2.5V
    
    if nargin<1,
        action='initialize';
    end

%start
switch action
case 'initialize',  
    close all;
    figInterface=figure( ...
        'Name','serail port data display', ...
        'NumberTitle','off', ...
        'Visible','off', ...
        'DoubleBuffer','on', ...
        'Position',[100 100 800 600],...
        'Color', [0.5 0.5 0.5], ...
        'BackingStore','off',...
        'KeyPressFcn',{@changeLabel});
    axes( ...
        'Units','normalized', ...
        'Position',[0.03 0.03 0.75 0.90], ...
        'Visible','off', ...
        'NextPlot','replace');

    text(0,0,'Press the "Start" to start data acquisition', ...
        'HorizontalAlignment','center');
    axis([-1 1 -1 1]);
    
% the USB configuration
    txtPosUSBPort=[0.9 0.91 0.1 0.04];
    hTxtUSBPort = uicontrol(...
        'Style','edit',...
        'HorizontalAlignment','left',...
        'Units','normalized',...
        'BackgroundColor',[1 1 1], ...
        'String',serialPortName, ...
        'Position',txtPosUSBPort);
    
% The START button
    labelStr='Start';
    
    btnPos=[0.9 0.85 0.1 0.04];
    startBtHndl=uicontrol( ...
        'Style','pushbutton', ...
        'Units','normalized', ...
        'Position',btnPos, ...
        'String',labelStr, ...
        'Enable','on',...
        'Interruptible','on', ...
        'Callback','maskRecord(''start'')');
    
% The STOP button
    labelStr='Stop';
    btnPos=[0.9 0.80 0.1 0.04];
    stopBtHndl=uicontrol( ...
        'Style','pushbutton', ...
        'Units','normalized', ...
        'Position',btnPos, ...
        'String',labelStr, ...
        'Enable','off',...
        'Interruptible','on', ...
        'Callback','maskRecord(''stop'')');

    %parameters

    set(figInterface,'Visible','on');
       
    figure(figInterface);

    
    %Initial data
    dataRaw=0;

    ADCMatrix = zeros(nIO,nADC);    
    set(gcf,'color',[1 1 1]);
    

    if size(posPlotOrigin,2)==4
        subplot('Position',posPlotOrigin);
        hPlotOrigin = mesh(1:nADC,nIO:-1:1,ADCMatrix,'FaceColor','interp');
        text(nADC+1,nIO+1,1,'1','color','k','BackgroundColor',[0.9 0.9 0]);
        text(0,nIO+1,1,'2','color','k','BackgroundColor',[0.9 0.9 0]);
        text(0,0,1,'3','color','k','BackgroundColor',[0.9 0.9 0]);
        text(nADC+1,0,'4','color','k','BackgroundColor',[0.9 0.9 0]);
        axis tight;
        zlim([0 3]);
        view([0 0 1]);
        caxis([0 3]);
        xlabel('adc');
        ylabel('ctrl');
        colorbar;
    end
    
    if size(posPlotProc,2)==4
        subplot('Position',posPlotProc);
        hPlotProc = mesh(1:nADC,nIO:-1:1,ADCMatrix,'FaceColor','flat');
        axis tight;
        xlabel('adc');
        ylabel('ctrl');
        view([0 0 1]);
        grid on;
        colorLim=0.5;
        zlim([-1.5,1.5]);
        caxis([-colorLim colorLim]);
        colorbar;
    end
    label=' ';
    hLegend=text(1,9,'null','fontsize',20);
    
    
%====================================
case 'start',
% typedef struct TicyTagMsg
% {
% 	uint16_t src;
% 	uint16_t cnt;
% 	uint16_t capValue[CHANNELNUMSEND];
% 	uint16_t sendTimes;
% }TicyTagMsg_t;
    
    label=' ';

    %create file to save data
    timeCurr= clock;
    if ~exist(folderSave,'dir')
        mkdir(folderSave);
    end
    pSaveFile = fopen(  [folderSave,num2str(timeCurr(1),'%04d'),...
                        num2str(timeCurr(2),'%02d'),...
                        num2str(timeCurr(3),'%02d'),...
                        'h',num2str(timeCurr(4),'%02d'),...
                        'm',num2str(timeCurr(5),'%02d'),'.txt'],...
                     'wt+');           

    %create serial port
    serialPortName=get(hTxtUSBPort,'string');
      
   pTtyUSB = serial(['COM',serialPortName]);
%     pTtyUSB = serial(['COM',serialPortName]);
    
    pTtyUSB.BaudRate=115200;
    pTtyUSB.InputBufferSize=4096;
    pTtyUSB.BytesAvailableFcnMode='byte';
    pTtyUSB.BytesAvailableFcnCount=(10+nIO*nADC+5)*2; %set twice as package size
    pTtyUSB.BytesAvailableFcn=@clearSerial;
    
    if strcmp(pTtyUSB.Status,'open')
        close(pTtyUSB);
    end
        
    lenDataRaw=0;
    
    disp('if dead here, check which tty ports is valid');
    fopen(pTtyUSB);
    
    set(stopBtHndl,'Enable','on');
    set(startBtHndl,'Enable','off');
    flagJustStarted=1;

case 'stop',
    fclose(pSaveFile);
    fclose (pTtyUSB);
    delete(pTtyUSB);
    set(stopBtHndl,'Enable','off');
    set(startBtHndl,'Enable','on');
    
end


function clearSerial(obj,event)

global dataRaw;     %all the original data from serial port
global lenDataRaw;
global hPlotOrigin hPlotProc;

global pSaveFile;

global label;

global flagJustStarted;

global countRemoveDC VADCDC;
global nADC nIO;

    if flagJustStarted
        countRemoveDC=0;
    end
    
    if obj.BytesAvailable>0
        [dataBuffTmpt,count]= fread(obj,obj.BytesAvailable,'char');
        timeStamp=clock;
        timeStampStr=[num2str(timeStamp(4),'%02d'),':',...
                    num2str(timeStamp(5),'%02d'),':',...
                    num2str(timeStamp(6),'%02.3f')];
    else
        return;
    end
       
    %put it with data left from last time
    if lenDataRaw==0
        dataRaw=dataBuffTmpt;
        lenDataRaw=count;
    else
        dataRaw=[dataRaw;dataBuffTmpt];
        lenDataRaw=lenDataRaw+count;
    end
    
    %extract data
    nDataPerPackage=nADC*nIO+2;
    
    remainBuffLen=nDataPerPackage+40;  %keep at least 1 package in buffer
    packageTerminator = 126;    %special char is 126
    i=1;
    iMax=lenDataRaw-remainBuffLen;
    findFlag=0;
    while(i<iMax)   %remain at least one package
        %search for the first package head
         if dataRaw(i) ~= packageTerminator
             i=i+1;
         else
             if dataRaw(i+1)==packageTerminator && dataRaw(i+2)==0                
                 findFlag=1;
                 i=i+3;
                 break;
             else
                 i=i+1;
             end
         end      
    end
    
    %if find data
    if findFlag==1
        iMax=lenDataRaw-remainBuffLen;    %forget the first 3 data in advance
%         dataLocal=zeros(1,channelNumMax*2+2);
        dataLocal=zeros(1,nDataPerPackage);
        iDataPure=1;  %start to write 
        while(i<iMax)   %every time read out one package of data
            j=0;
            %skip 0x7E,0x42 and the first 10 bytes 
            while j<12  
                if dataRaw(i)==125
                    i=i+1;
                end
                j=j+1;
                i=i+1;
            end
            %read out the information
            for j=1:nDataPerPackage %64byte adc data+2byte count
                if dataRaw(i)==125
                    i=i+1;
                    if dataRaw(i)==94
                        dataLocal(j)=126;
                    else
                        dataLocal(j)=125;
                    end
                else
                    dataLocal(j)=dataRaw(i);
                end
                i=i+1;
            end
            %read out the count
            V_k=2.94/255;
            V_shift=0;
            
            VADC=reshape(dataLocal(1:nIO*nADC),nADC,nIO)'*V_k+V_shift;
            VADCChan=VADC-repmat(mean(VADC,2),1,nADC);
            
            %go till the end of package
            flagFullPackage=1;

            for j=1:2
                if dataRaw(i)==packageTerminator
                    flagFullPackage=0;
                    break;
                else
                    if dataRaw(i)==125
                        i=i+1;
                    end
                end
                i=i+1;
            end
            if(flagFullPackage)
                if dataRaw(i) ~= packageTerminator || dataRaw(i+1)~=packageTerminator || dataRaw(i+2)~=0
                    flagFullPackage=0;
                else
                    i=i+3;
                end
            end
            %print out detail
            if(flagFullPackage)
                iDataPure=iDataPure+1;
                disp([timeStampStr,':', num2str(count,'%4d'),'B read--',...
                    num2str(dataLocal(1:8),' %03d'),': ',label]);
                
                
%                 disp(VADC);
                %refresh 
                if flagJustStarted
                    VADCDC=VADCChan;
                else
                    VADCDC=(VADCDC*29+VADCChan)/30;
                end
                set(hPlotOrigin,'zdata',(VADC));
                set(hPlotProc,'zdata',(VADCChan));
                   
                %write file
                
             fprintf(pSaveFile,'%s \n',...
                [num2str(timeStamp(4),' %02d'),' ',...
                num2str(timeStamp(5),' %02d'),' ',...
                num2str(timeStamp(6),' %02.3f'),' ',...
                num2str(dataLocal,' %03d'), ' ',...     
                num2str(label-' ','%d')]);
            else
                break;
            end
        end
        
        
        %set data length values for next read out  
        if(i>3)
            dataRaw=dataRaw(i-3:lenDataRaw);
        end
        lenDataRaw=size(dataRaw,1);  
        
        if flagJustStarted
            flagJustStarted=0;
        end
    end
    
 %funciton changeLabel   
function changeLabel(src, event)
    global label;
    global hLegend;
    global labelList;
    label=event.Character;
    flagFound=0;
    for i=1:size(labelList,2)
        if strcmp(labelList(i).label,label)
            set(hLegend,'string',labelList(i).labelStr);
            flagFound=1;
            break;
        end
    end
    if flagFound==0
        if (label>='a' && label<='z') ...
           ||(label>'A' && label<='Z')
            set(hLegend,'string',label);
        else
            set(hLegend,'string','null');
        end
    end
    

