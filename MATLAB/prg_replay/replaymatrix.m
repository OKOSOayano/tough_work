%speed control
kt=0.3;   %1 for normal speed, <1 for run quick, >1 for run slow

%channel number
nADC=8;
nIO=8;

%label mapping
labelList=struct('label',...
                    {'c','l','r','u','d','o','a','1','2','3','4','5'},...
                'labelStr',...
                    {'click-center','left to right','right to left','up','down','clockwise','anticlockwise',...
                    'left-up','right-up','right-down','left-down','center'}...
                 );

%load data, format: timestamp, 64 channel data +
%1byte(255)+1byte(255)+label
data=load('../save/20130816h14m40.txt');

%timestamp
timeStamp=data(:,1)*3600+data(:,2)*60+data(:,3);
nSample=size(timeStamp,1);
%remap timeStamp
timeStamp=(timeStamp(end)-timeStamp(1))*(1:nSample)/nSample;

%where to plot    
posPlotOrigin= [0.10 0.2 0.3 0.6];
posPlotProc= [0.50 0.2 0.3 0.6];          

label=cast(data(:,end)+' ','char');

    if size(posPlotOrigin,2)==4
        subplot('Position',posPlotOrigin);
        hPlotOrigin = mesh(1:nADC,nIO:-1:1,zeros(nIO,nADC),'FaceColor','interp');
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
        hTxtTime = text(nADC/2,nIO+1,1,'start',...
            'HorizontalAlignment','center','fontsize',20);

    end
    
    if size(posPlotProc,2)==4
        subplot('Position',posPlotProc);
        hPlotProc = mesh(1:nADC,nIO:-1:1,zeros(nIO,nADC),'FaceColor','flat');
        axis tight;
        xlabel('adc');
        ylabel('ctrl');
        view([0 0 1]);
        grid on;
        colorLim=0.5;
        zlim([-1.5,1.5]);
        caxis([-colorLim colorLim]);
        colorbar;
        hLegend=text(nADC/2,nIO+1,1,'null',...
            'HorizontalAlignment','center','fontsize',20);

    end


set(gcf,'color',[1 1 1]);
    
%plot pressure distribution as video stream
    tic;
for i=1:nSample
    %current time
    set(hTxtTime,'string',...
        sprintf('%02d:%02d',floor(timeStamp(i)/60),...
            floor((timeStamp(i)-floor(timeStamp(i)/60)*60))));
    
    if i>1 && label(i)~=label(i-1)
        flagFound=0;
        for j=1:size(labelList,2)
            if strcmp(labelList(j).label,label(i))
                set(hLegend,'string',labelList(j).labelStr);
                flagFound=1;
                break;
            end
        end
        if flagFound==0
            if (label(i)>='a' && label(i)<='z') ...
               ||(label(i)>'A' && label(i)<='Z')
                set(hLegend,'string',label(i));
            else
                set(hLegend,'string','null');
            end
        end
    end
    %wait till next frame
    pause(kt*timeStamp(i)-toc);
    
    %map from raw data to voltage measured from ADC
    V_k=2.94/255;
    V_shift=0;
    
    dataLocal=data(i,3+(1:nIO*nADC));
    VADC=reshape(dataLocal(1:nIO*nADC),nADC,nIO)'*V_k+V_shift;
    VADCChan=VADC-repmat(mean(VADC,2),1,nADC);
    
    if i==1
        VADCDC=VADCChan;
    else
        VADCDC=(VADCDC*29+VADCChan)/30;
    end
    %display
    set(hPlotOrigin,'zdata',(VADC));
    set(hPlotProc,'zdata',(VADCChan));
    
 end