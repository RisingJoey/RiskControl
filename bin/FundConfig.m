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

% Last Modified by GUIDE v2.5 12-Feb-2019 09:12:13

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


% --- Executes on button press in Save.
function Save_Callback(hObject, eventdata, handles)
% hObject    handle to Save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
stkId = get(handles.StkId, 'String');
checkId = regexp(stkId, '^[0-9]{6}$', 'ONCE');
if isempty(checkId)
    errordlg('基金代码格式错误，应为六位数字','保存','modal');
    return;
end
redemptionId = get(handles.RedemptionId, 'String');
checkId = regexp(redemptionId, '^[0-9]{6}$', 'ONCE');
if isempty(checkId)
    errordlg('申赎代码格式错误，应为六位数字','保存','modal');
    return;
end
targetAmt = str2num(get(handles.TargetAmt, 'String'));
checkAmt = isempty(targetAmt) || targetAmt<0;
if checkAmt
    errordlg('成交金额格式错误，应为非负数','保存','modal');
    return;
end
buyRatio=str2num(get(handles.BuyRatio,'String'));
sellRatio=str2num(get(handles.SellRatio,'String'));
checkRatio = isempty(buyRatio) || isempty(sellRatio) || sellRatio-buyRatio<0.0005;
if checkRatio
    errordlg('买入、卖出价位格式错误','保存','modal');
    return;
end

if ~isfield(handles, 'config'); return; end

stkName = get(handles.StkName, 'String');
exchStr=get(handles.ExchId,'String');
exchVal=get(handles.ExchId,'Value');
stkAcctStr=get(handles.StkAcct,'String');
stkAcctVal=get(handles.StkAcct,'Value');
indexStr=get(handles.Index,'String');
indexVal=get(handles.Index,'Value');

checkId = ismember({handles.FundInfo.stkId}, stkId);
checkAcct = ismember({handles.FundInfo.stkAcct}, stkAcctStr(stkAcctVal));
check = checkId & checkAcct;
errorflag = 0;
switch handles.config
    case 'add'
        if any(check)
            h = errordlg({'相同基金代码与资金账户组合已存在：', ...
                ['基金代码：' stkId], ...
                ['资金账户：' stkAcctStr{stkAcctVal}]}, '重复基金','modal');
            uiwait(h);
            errorflag = 1;
        else
            handles.FundInfo = [handles.FundInfo; handles.FundInfo(end)];
            handles.FundInfo(end).stkId = stkId;
            handles.FundInfo(end).stkName = stkName;
            handles.FundInfo(end).redemptionId = redemptionId;
            handles.FundInfo(end).exchId = exchStr{exchVal};
            handles.FundInfo(end).stkAcct = stkAcctStr{stkAcctVal};
            handles.FundInfo(end).index = indexStr{indexVal};
            handles.FundInfo(end).buyRatio = buyRatio;
            handles.FundInfo(end).sellRatio = sellRatio;
            handles.FundInfo(end).targetAmt = targetAmt;
        end
    case 'mod'
        ind = find(check);
        for i = 1 : length(ind)
            if ind(i) ~= handles.selected
                h = errordlg({'相同基金代码与资金账户组合已存在：' 
                    ['基金代码：' stkId], ...
                    ['资金账户：' stkAcctStr{stkAcctVal}]}, '重复基金','modal');
                uiwait(h);
                errorflag = 1;
                break;
            end
        end
        if ~errorflag
            handles.FundInfo(handles.selected).stkId = stkId;
            handles.FundInfo(handles.selected).stkName = stkName;
            handles.FundInfo(handles.selected).redemptionId = redemptionId;
            handles.FundInfo(handles.selected).exchId = exchStr{exchVal};
            handles.FundInfo(handles.selected).stkAcct = stkAcctStr{stkAcctVal};
            handles.FundInfo(handles.selected).index = indexStr{indexVal};
            handles.FundInfo(handles.selected).buyRatio = buyRatio;
            handles.FundInfo(handles.selected).sellRatio = sellRatio;
            handles.FundInfo(handles.selected).targetAmt = targetAmt;
        end
end
if ~errorflag
    h = gcf;
    handles.changed = 1;
    guidata(h, handles);
    uiresume(h);
    set(h, 'Visible', 'off');
end

% --- Executes on button press in Cancel.
function Cancel_Callback(hObject, eventdata, handles)
% hObject    handle to Cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
h = gcf;
if isfield(handles, 'FundInfo')
    handles.changed = 0;
    guidata(h, handles);
    uiresume(h);
    set(h, 'Visible', 'off');
else
    delete(h);
end


% --- Executes when user attempts to close FigFundConfig.
function FigFundConfig_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to FigFundConfig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
h = gcf;
if isfield(handles, 'FundInfo')
    handles.changed = 0;
    guidata(h, handles);
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


% --- Executes on selection change in ExchId.
function ExchId_Callback(hObject, eventdata, handles)
% hObject    handle to ExchId (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ExchId contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ExchId


% --- Executes during object creation, after setting all properties.
function ExchId_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ExchId (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function StkName_Callback(hObject, eventdata, handles)
% hObject    handle to StkName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of StkName as text
%        str2double(get(hObject,'String')) returns contents of StkName as a double


% --- Executes during object creation, after setting all properties.
function StkName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to StkName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in StkAcct.
function StkAcct_Callback(hObject, eventdata, handles)
% hObject    handle to StkAcct (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns StkAcct contents as cell array
%        contents{get(hObject,'Value')} returns selected item from StkAcct


% --- Executes during object creation, after setting all properties.
function StkAcct_CreateFcn(hObject, eventdata, handles)
% hObject    handle to StkAcct (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
load('..\appdata\StkAcct.mat');
set(hObject, 'String', StkAcct(:,1));


function RedemptionId_Callback(hObject, eventdata, handles)
% hObject    handle to RedemptionId (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of RedemptionId as text
%        str2double(get(hObject,'String')) returns contents of RedemptionId as a double


% --- Executes during object creation, after setting all properties.
function RedemptionId_CreateFcn(hObject, eventdata, handles)
% hObject    handle to RedemptionId (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in Index.
function Index_Callback(hObject, eventdata, handles)
% hObject    handle to Index (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns Index contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Index


% --- Executes during object creation, after setting all properties.
function Index_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Index (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function TargetAmt_Callback(hObject, eventdata, handles)
% hObject    handle to TargetAmt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of TargetAmt as text
%        str2double(get(hObject,'String')) returns contents of TargetAmt as a double


% --- Executes during object creation, after setting all properties.
function TargetAmt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TargetAmt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function BuyRatio_Callback(hObject, eventdata, handles)
% hObject    handle to BuyRatio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of BuyRatio as text
%        str2double(get(hObject,'String')) returns contents of BuyRatio as a double


% --- Executes during object creation, after setting all properties.
function BuyRatio_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BuyRatio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function SellRatio_Callback(hObject, eventdata, handles)
% hObject    handle to SellRatio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SellRatio as text
%        str2double(get(hObject,'String')) returns contents of SellRatio as a double


% --- Executes during object creation, after setting all properties.
function SellRatio_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SellRatio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
