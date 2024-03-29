function varargout = FundTrader(varargin)
%FUNDTRADER M-file for FundTrader.fig
%      FUNDTRADER, by itself, creates a new FUNDTRADER or raises the existing
%      singleton*.
%
%      H = FUNDTRADER returns the handle to a new FUNDTRADER or the handle to
%      the existing singleton*.
%
%      FUNDTRADER('Property','Value',...) creates a new FUNDTRADER using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to FundTrader_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      FUNDTRADER('CALLBACK') and FUNDTRADER('CALLBACK',hObject,...) call the
%      local function named CALLBACK in FUNDTRADER.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help FundTrader

% Last Modified by GUIDE v2.5 28-Jun-2019 22:51:56

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @FundTrader_OpeningFcn, ...
                   'gui_OutputFcn',  @FundTrader_OutputFcn, ...
                   'gui_LayoutFcn',  [], ...
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


% --- Executes just before FundTrader is made visible.
function FundTrader_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)
SysInit
SysConnect

try
    m=load('D:\work\FundMonitorParallel\appdata\Data.mat');
    data=m.data(:,[1:4 7:13]);
    ratio=zeros(size(data,1),4);
    adjust=cell2mat(m.data(:,40:45));
    iopv=cell2mat(m.data(:,8));
    nume=[adjust(:,2)-adjust(:,1) adjust(:,3:4)*0.21 -adjust(:,5)*0.19]; deno=adjust(:,6).*iopv;
    ratio=nume./repmat(deno,[1 4])*100;
    data(:,8:11)=num2cell(ratio);
    set(handles.FundMonitor, 'Data', data);
    save('..\appdata\Data.mat','data')
    load('D:\work\FundMonitorParallel\appdata\StkAcct.mat');
    acctId=unique(data(:,4));
    [lia locb]=ismember(acctId,StkAcct(:,1));
    for i=1:length(acctId)
        AcctLogin(acctId{i},StkAcct{locb(i),2});
    end
catch ex
end

%基金类别
load('..\appdata\FundInfo.mat');
handles.FundInfo = FundInfo;

%合约、上下限
Basis.ihCont = get(handles.IHCont, 'String');
Basis.ifCont = get(handles.IFCont, 'String');
Basis.icCont = get(handles.ICCont, 'String');
Basis.ihLimitLo = str2double(get(handles.IHLimitLo, 'String'));
Basis.ifLimitLo = str2double(get(handles.IFLimitLo, 'String'));
Basis.icLimitLo = str2double(get(handles.ICLimitLo, 'String'));
Basis.ihLimitHi = str2double(get(handles.IHLimitHi, 'String'));
Basis.ifLimitHi = str2double(get(handles.IFLimitHi, 'String'));
Basis.icLimitHi = str2double(get(handles.ICLimitHi, 'String'));
handles.Basis = Basis;

% 创建时钟
handles.timer = timer();
set(handles.timer,'ExecutionMode','fixedspacing');
set(handles.timer,'Period',3);
set(handles.timer,'TimerFcn',{@hedge_callback,handles});

% Choose default command line output for FundTrader
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes FundTrader wait for user response (see UIRESUME)
% uiwait(handles.FigFundTrader);


% 定时查询基金价格、净值，刷新表格
function hedge_callback(hObject, eventdata, handles)
tic;
    disp('time')
t=SysCurrentTime; dv=datevec(t); %当前时间
sec=dv(4)*3600+dv(5)*60;
% if sec<34200||sec>54000 % <9:30||>15:00
%     set(handles.StartMonitor, 'Enable', 'on');
%     set(handles.StopMonitor, 'Enable', 'off');
%     set(handles.ArbiTrade, 'Enable', 'off');
%     set(handles.StopTrade, 'Enable', 'off');
%     stop(hObject); %如不停止，则可24小时运行
%     return;
% end
% if sec>41400&&sec<46800 % 11:30< && <13:00
%     return;
% end

try
    disp('data')
    m=load('D:\work\FundMonitorParallel\appdata\Data.mat');
    data=m.data(:,[1:4 7:15]);
    ratio=zeros(size(data,1),4);
    adjust=cell2mat(m.data(:,40:45));
    iopv=cell2mat(m.data(:,8));
    nume=[adjust(:,2)-adjust(:,1) adjust(:,3:4)*0.21 -adjust(:,5)*0.19]; deno=adjust(:,6).*iopv;
    ratio=nume./repmat(deno,[1 4])*100;
    data(:,8:11)=num2cell(ratio);
    acctId=unique(m.data(:,4));
    data(:,12:13)={0};
    for i=1:length(acctId)
        info.acctId=acctId{i};
        model=MMS_GetMarketMakerPriceModel2(info);
        increment=[{model.stkId}' {model.buyPriceIncrement2}' {model.sellPriceIncrement2}'];
        [lia locb]=ismember(strcat(data(:,1),data(:,4)),strcat(increment(:,1),acctId(i)));
        data(lia,12:13)=increment(locb(lia),2:3);
    end

    disp('basis')
    %指数价格
    indexId = {'000016','000300','000905'};
    exchId = {'0','0','0'};
    indexList = struct('exchId',exchId, 'stkId', indexId);
    quotaS = StkQuotaList(indexList);
    idxPrice = [quotaS.newPrice];
    futId={handles.Basis.ihCont,handles.Basis.ifCont,handles.Basis.icCont};
    quotaF = FutQuotaList('F',futId);
    futPrice = [quotaF.newPrice];
    basis=futPrice-idxPrice;
    
    t=toc;
    disp(['Time elapsed ' num2str(t) 's']);
    set(handles.FundMonitor, 'Data', data);
    save('..\appdata\Data.mat','data')
catch e
    disp(e.message);
end


% --- Outputs from this function are returned to the command line.
function varargout = FundTrader_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes when selected cell(s) is changed in FundTrader.
function FundMonitor_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to FundTrader (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)
if ~isempty(eventdata.Indices)
    selected = eventdata.Indices;
    handles.selected = selected(1);
    guidata(hObject, handles);
end


% --- Executes when user attempts to close FigFundTrader.
function FigFundTrader_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to FigFundTrader (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
if isfield(handles, 'timer') && isvalid(handles.timer)
    stop(handles.timer);
end
try
    load('D:\work\FundMonitorParallel\appdata\StkAcct.mat');
    load('..\appdata\Data.mat');
    acctId=unique(data(:,4));
    [lia locb]=ismember(acctId,StkAcct(:,1));
    for i=1:length(acctId)
        AcctLogout(acctId{i},StkAcct{locb(i),2});
    end
catch ex
end
%SysDisconnect
delete(hObject);

% --- Executes on button press in StartMonitor.
function StartMonitor_Callback(hObject, eventdata, handles)
% hObject    handle to StartMonitor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% 启动时钟
start(handles.timer);
set(handles.StartMonitor, 'Enable', 'off');
set(handles.StopMonitor, 'Enable', 'on');

% --- Executes on button press in StopMonitor.
function StopMonitor_Callback(hObject, eventdata, handles)
% hObject    handle to StopMonitor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% 停止时钟
stop(handles.timer);
set(handles.StartMonitor, 'Enable', 'on');
set(handles.StopMonitor, 'Enable', 'off');


% --- Executes on button press in ArbiTrade.
function ArbiTrade_Callback(hObject, eventdata, handles)
% hObject    handle to ArbiTrade (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.ArbiTrade, 'Enable', 'off');
set(handles.StopTrade, 'Enable', 'on');
State.mode = 1;
save('..\appdata\State.mat','State');


% --- Executes on button press in StopTrade.
function StopTrade_Callback(hObject, eventdata, handles)
% hObject    handle to StopTrade (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.ArbiTrade, 'Enable', 'on');
set(handles.StopTrade, 'Enable', 'off');
State.mode = 0;
save('..\appdata\State.mat','State');


% --- Executes on button press in MMSStart.
function MMSStart_Callback(hObject, eventdata, handles)
% hObject    handle to MMSStart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles,'selected')
    load('..\appdata\Data.mat');
    info.stkId=data(handles.selected,1);
    info.acctId=data(handles.selected,4);
    info.offerStatus='1';
    %MMS_ModifyOrderStatus2(info);
end

% --- Executes on button press in MMSStop.
function MMSStop_Callback(hObject, eventdata, handles)
% hObject    handle to MMSStop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles,'selected')
    load('..\appdata\Data.mat');
    info.stkId=data(handles.selected,1);
    info.acctId=data(handles.selected,4);
    info.offerStatus='0';
    %MMS_ModifyOrderStatus2(info);
end


% --- Executes on button press in MMSStartAll.
function MMSStartAll_Callback(hObject, eventdata, handles)
% hObject    handle to MMSStartAll (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
load('d:\work\FundMonitorParallel\appdata\Data.mat')
ch=char(data(:,1));
lia=ismember(cellstr(ch(:,1:3)),{'511' '518'});
data(lia,:)=[];
for i=length(data(:,1))
    info.stkId=data{i,1};
    info.acctId=data{i,4};
    info.optId='88240';
    info.offerStatus='1';
    MMS_ModifyOrderStatus2(info);
end

% --- Executes on button press in MMSStopAll.
function MMSStopAll_Callback(hObject, eventdata, handles)
% hObject    handle to MMSStopAll (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
load('d:\work\FundMonitorParallel\appdata\Data.mat')
ch=char(data(:,1));
lia=ismember(cellstr(ch(:,1:3)),{'511' '518'});
data(lia,:)=[];
for i=length(data(:,1))
    info.stkId=data{i,1};
    info.acctId=data{i,4};
    info.optId='88240';
    info.offerStatus='0';
    MMS_ModifyOrderStatus2(info);
end

% --- Executes on button press in IncSellBatch.
function IncSellBatch_Callback(hObject, eventdata, handles)
% hObject    handle to IncSellBatch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in DecSellBatch.
function DecSellBatch_Callback(hObject, eventdata, handles)
% hObject    handle to DecSellBatch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in ScaleAdjust.
function ScaleAdjust_Callback(hObject, eventdata, handles)
% hObject    handle to ScaleAdjust (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in ExpoAdjust.
function ExpoAdjust_Callback(hObject, eventdata, handles)
% hObject    handle to ExpoAdjust (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in listbox4.
function listbox4_Callback(hObject, eventdata, handles)
% hObject    handle to listbox4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox4 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox4


% --- Executes during object creation, after setting all properties.
function listbox4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function IFCont_Callback(hObject, eventdata, handles)
% hObject    handle to IFCont (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of IFCont as text
%        str2double(get(hObject,'String')) returns contents of IFCont as a double


% --- Executes during object creation, after setting all properties.
function IFCont_CreateFcn(hObject, eventdata, handles)
% hObject    handle to IFCont (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ICCont_Callback(hObject, eventdata, handles)
% hObject    handle to ICCont (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ICCont as text
%        str2double(get(hObject,'String')) returns contents of ICCont as a double


% --- Executes during object creation, after setting all properties.
function ICCont_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ICCont (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function IFLimitLo_Callback(hObject, eventdata, handles)
% hObject    handle to IFLimitLo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of IFLimitLo as text
%        str2double(get(hObject,'String')) returns contents of IFLimitLo as a double


% --- Executes during object creation, after setting all properties.
function IFLimitLo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to IFLimitLo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ICLimitLo_Callback(hObject, eventdata, handles)
% hObject    handle to ICLimitLo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ICLimitLo as text
%        str2double(get(hObject,'String')) returns contents of ICLimitLo as a double


% --- Executes during object creation, after setting all properties.
function ICLimitLo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ICLimitLo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function IFLimitHi_Callback(hObject, eventdata, handles)
% hObject    handle to IFLimitHi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of IFLimitHi as text
%        str2double(get(hObject,'String')) returns contents of IFLimitHi as a double


% --- Executes during object creation, after setting all properties.
function IFLimitHi_CreateFcn(hObject, eventdata, handles)
% hObject    handle to IFLimitHi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ICLimitHi_Callback(hObject, eventdata, handles)
% hObject    handle to ICLimitHi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ICLimitHi as text
%        str2double(get(hObject,'String')) returns contents of ICLimitHi as a double


% --- Executes during object creation, after setting all properties.
function ICLimitHi_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ICLimitHi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function IHCont_Callback(hObject, eventdata, handles)
% hObject    handle to IHCont (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of IHCont as text
%        str2double(get(hObject,'String')) returns contents of IHCont as a double


% --- Executes during object creation, after setting all properties.
function IHCont_CreateFcn(hObject, eventdata, handles)
% hObject    handle to IHCont (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function IHLimitLo_Callback(hObject, eventdata, handles)
% hObject    handle to IHLimitLo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of IHLimitLo as text
%        str2double(get(hObject,'String')) returns contents of IHLimitLo as a double


% --- Executes during object creation, after setting all properties.
function IHLimitLo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to IHLimitLo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function IHLimitHi_Callback(hObject, eventdata, handles)
% hObject    handle to IHLimitHi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of IHLimitHi as text
%        str2double(get(hObject,'String')) returns contents of IHLimitHi as a double


% --- Executes during object creation, after setting all properties.
function IHLimitHi_CreateFcn(hObject, eventdata, handles)
% hObject    handle to IHLimitHi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in IncSell.
function IncSell_Callback(hObject, eventdata, handles)
% hObject    handle to IncSell (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in IncBuy.
function IncBuy_Callback(hObject, eventdata, handles)
% hObject    handle to IncBuy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in DecSell.
function DecSell_Callback(hObject, eventdata, handles)
% hObject    handle to DecSell (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in DecBuy.
function DecBuy_Callback(hObject, eventdata, handles)
% hObject    handle to DecBuy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in RefreshLimit.
function RefreshLimit_Callback(hObject, eventdata, handles)
% hObject    handle to RefreshLimit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%合约、上下限
Basis.ihCont = get(handles.IHCont, 'String');
Basis.ifCont = get(handles.IFCont, 'String');
Basis.icCont = get(handles.ICCont, 'String');
Basis.ihLimitLo = str2double(get(handles.IHLimitLo, 'String'));
Basis.ifLimitLo = str2double(get(handles.IFLimitLo, 'String'));
Basis.icLimitLo = str2double(get(handles.ICLimitLo, 'String'));
Basis.ihLimitHi = str2double(get(handles.IHLimitHi, 'String'));
Basis.ifLimitHi = str2double(get(handles.IFLimitHi, 'String'));
Basis.icLimitHi = str2double(get(handles.ICLimitHi, 'String'));
handles.Basis = Basis;
guidata(hObject, handles);

% --- Executes on button press in IncBuyBatch.
function IncBuyBatch_Callback(hObject, eventdata, handles)
% hObject    handle to IncBuyBatch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in DecBuyBatch.
function DecBuyBatch_Callback(hObject, eventdata, handles)
% hObject    handle to DecBuyBatch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function SellIncrement_Callback(hObject, eventdata, handles)
% hObject    handle to SellIncrement (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SellIncrement as text
%        str2double(get(hObject,'String')) returns contents of SellIncrement as a double


% --- Executes during object creation, after setting all properties.
function SellIncrement_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SellIncrement (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function BuyIncrement_Callback(hObject, eventdata, handles)
% hObject    handle to BuyIncrement (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of BuyIncrement as text
%        str2double(get(hObject,'String')) returns contents of BuyIncrement as a double


% --- Executes during object creation, after setting all properties.
function BuyIncrement_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BuyIncrement (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in SetBatch.
function SetBatch_Callback(hObject, eventdata, handles)
% hObject    handle to SetBatch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
h = openfig('FundConfig.fig','reuse');
set(h, 'Name', '基金信息');
hs = guihandles(h);
load('..\appdata\FundInfo.mat');
hs.FundInfo=FundInfo;
num=length(FundInfo);
info=struct2cell(FundInfo)';
loops=floor(num/20); remains=loops*20+1;
data=[];
for i=1:loops
    bi=(i-1)*20+1; ei=i*20;
    data=[data info(bi:ei,:)];
end
if remains<=num
    data=[data [info(remains:end,:);cell((loops+1)*20-num,2)]];
end
set(hs.FundList,'Data',data);
guidata(h, hs);
uiwait(h);
hs = guidata(h);
if isfield(hs,'changed')
    FundInfo = hs.FundInfo;
    save('..\appdata\FundInfo.mat', 'FundInfo');
    handles.FundInfo = FundInfo;
    guidata(hObject, handles);
end
delete(h);



function BatchName_Callback(hObject, eventdata, handles)
% hObject    handle to BatchName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of BatchName as text
%        str2double(get(hObject,'String')) returns contents of BatchName as a double


% --- Executes during object creation, after setting all properties.
function BatchName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BatchName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
