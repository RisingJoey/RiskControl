function varargout = FundConfig(varargin)
% FUNDCONFIG MATLAB code for FundConfig.fig
%      FUNDCONFIG, by itself, creates a new FUNDCONFIG or raises the existing
%      singleton*.
%
%      H = FUNDCONFIG returns the handle to a new FUNDCONFIG or the handle to
%      the existing singleton*.
%
%      FUNDCONFIG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FUNDCONFIG.M with the given input arguments.
%
%      FUNDCONFIG('Property','Value',...) creates a new FUNDCONFIG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before FundConfig_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to FundConfig_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help FundConfig

% Last Modified by GUIDE v2.5 29-Jun-2019 23:52:55

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @FundConfig_OpeningFcn, ...
                   'gui_OutputFcn',  @FundConfig_OutputFcn, ...
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


% --- Executes just before FundConfig is made visible.
function FundConfig_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to FundConfig (see VARARGIN)


% Choose default command line output for FundConfig
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

FundInfo=handles.FundInfo;

% UIWAIT makes FundConfig wait for user response (see UIRESUME)
% uiwait(handles.FigFundConfig);


% --- Outputs from this function are returned to the command line.
function varargout = FundConfig_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


function data=refresh(FundInfo)
data=[];
num=length(FundInfo);
info=struct2cell(FundInfo)';
loops=floor(length(FundInfo)/20); remains=loops*20+1;
for i=1:loops
    bi=(i-1)*20+1; ei=i*20;
    data=[data info(bi:ei,:)];
end
if remains<=num
    data=[data [info(remains:end,:);cell((loops+1)*20-num,2)]];
end


% --- Executes on button press in AddFund.
function AddFund_Callback(hObject, eventdata, handles)
% hObject    handle to AddFund (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
stkId = get(handles.StkId, 'String');
checkId = regexp(stkId, '^[0-9]{6}$', 'ONCE');
if isempty(checkId)
    errordlg('基金代码应为六位数字','保存','modal');
    return;
end
stkType = get(handles.StkType, 'String');
if isempty(stkType)
    errordlg('基金类别不能为空','保存','modal');
    return;
end

if ~isfield(handles, 'FundInfo'); return; end

check = ismember({handles.FundInfo.stkId}, stkId);
if any(check)
    h = errordlg(['基金代码已存在：' stkId], '提示','modal');
    uiwait(h);
else
    info.stkId = stkId;
    info.stkType = stkType;
    handles.FundInfo = [handles.FundInfo; info];
    handles.changed = 1;
    data=refresh(handles.FundInfo);
    set(handles.FundList,'Data',data);
    h = gcf;
    guidata(h, handles);
end


% --- Executes when user attempts to close FigFundConfig.
function FigFundConfig_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to FigFundConfig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
h = gcf;
if isfield(handles, 'FundInfo')
    uiresume(h);
    set(h, 'Visible', 'off');
else
    delete(h);
end


function StkId_Callback(hObject, eventdata, handles)
% hObject    handle to StkId (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of StkId as text
%        str2double(get(hObject,'String')) returns contents of StkId as a double


% --- Executes during object creation, after setting all properties.
function StkId_CreateFcn(hObject, eventdata, handles)
% hObject    handle to StkId (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function StkType_Callback(hObject, eventdata, handles)
% hObject    handle to StkType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of StkType as text
%        str2double(get(hObject,'String')) returns contents of StkType as a double


% --- Executes during object creation, after setting all properties.
function StkType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to StkType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in DelFund.
function DelFund_Callback(hObject, eventdata, handles)
% hObject    handle to DelFund (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
stkId = get(handles.StkId, 'String');
checkId = regexp(stkId, '^[0-9]{6}$', 'ONCE');
if isempty(checkId)
    return;
end

if ~isfield(handles, 'FundInfo'); return; end

check = ismember({handles.FundInfo.stkId}, stkId);
if any(check)
    handles.FundInfo(check) = [];
    handles.changed = 1;
    data=refresh(handles.FundInfo);
    set(handles.FundList,'Data',data);
    h = gcf;
    guidata(h, handles);
else
    h = errordlg(['基金代码不存在：' stkId], '提示','modal');
    uiwait(h);
end


% --- Executes when selected cell(s) is changed in FundList.
function FundList_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to FundList (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)
if ~isempty(eventdata.Indices)
    selected = eventdata.Indices;
    if isfield(handles, 'FundInfo')
        idx=selected(1)+((selected(2)+mod(selected(2),2))/2-1)*20;
        if idx<=length(handles.FundInfo)
            set(handles.StkId, 'String',handles.FundInfo(idx).stkId);
            set(handles.StkType, 'String',handles.FundInfo(idx).stkType);
            set(handles.DelFund, 'Enable','on');
        else
            set(handles.StkId, 'String','');
            set(handles.StkType, 'String','');
            set(handles.DelFund, 'Enable','off');
        end
    else
        set(handles.StkId, 'String','');
        set(handles.StkType, 'String','');
        set(handles.DelFund, 'Enable','off');
    end
end