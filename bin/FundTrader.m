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

% Last Modified by GUIDE v2.5 03-Jun-2019 17:13:59

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
AcctLogin('000000000109','666666');
% 基金信息
load('..\appdata\State.mat');
ip = char(java.net.InetAddress.getLocalHost());
if strcmpi(State.ip, ip)
    load('..\appdata\FundInfo.mat');
    [data pointer] = refresh_table(FundInfo);
    set(handles.FundMonitor, 'Data', render(data));
    save('..\appdata\Data.mat','data','pointer');
end

% 创建时钟
handles.timer = timer();
set(handles.timer,'ExecutionMode','fixedspacing');
set(handles.timer,'Period',3);
set(handles.timer,'TimerFcn',{@hedge_callback,handles});
set(handles.timer,'StartFcn',{@init_callback,handles});
set(handles.timer,'StopFcn',{@stop_callback,handles});

% Choose default command line output for FundTrader
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes FundTrader wait for user response (see UIRESUME)
% uiwait(handles.FigFundTrader);


% 刷新表格
function [new_data new_pointer] = refresh_table(FundInfo)
new_data = cell(length(FundInfo),33); new_data(:,:) = {0};
new_data(:,1) = {FundInfo.stkId};
new_data(:,2) = {FundInfo.stkName};
new_data(:,6) = {FundInfo.buyRatio};
new_data(:,7) = {FundInfo.sellRatio};
new_data(:,12) = {FundInfo.exchId};
new_data(:,13) = {FundInfo.redemptionId};
new_data(:,14) = {FundInfo.stkAcct};
new_data(:,15) = {FundInfo.index};
% 持仓
% new_data(:,16);
% 盘口价、量
% new_data(:,17);
% new_data(:,18);
% new_data(:,19);
% new_data(:,20);
% 买一溢价率、卖一折价率
% new_data(:,21);
% new_data(:,22);
% 交易量、交易均价、交易额
% new_data(:,23);
% new_data(:,24);
% new_data(:,25);
% new_data(:,26);
% new_data(:,27);
% new_data(:,28);
% 昨收盘价及指数现价、昨收盘价
% new_data(:,29);
% new_data(:,30);
% new_data(:,31);
% 目标成交额、合计成交额
new_data(:,32)={FundInfo.targetAmt};
% new_data(:,33);
[new_data, new_pointer] = sortrows(new_data,[15 1]);
total = cell(1,33);
total{1,1} = '合计'; total{1,32} = sum([FundInfo.targetAmt]);
new_pointer = [new_pointer; size(new_data,1)+1];
new_data = [new_data; total];
% % 读取原有数据
% load('..\appdata\Data.mat');
% [lia locb]= ismember(strcat(new_data(:,1),new_data(:,3)),strcat(data(:,1),data(:,3)));
% new_data(lia,4:6) = data(locb(lia),4:6);
% new_data(lia,9:12) = data(locb(lia),9:12);
% new_data(lia,23:28) = data(locb(lia),23:28);
% [new_data, new_pointer] = sortrows(new_data,[15 1]);

% 定时查询基金价格，计算基金净值，刷新表格
function hedge_callback(hObject, eventdata, handles)
load('..\appdata\Data.mat');
load('..\appdata\State.mat');
% State.mode = 2;
ip = char(java.net.InetAddress.getLocalHost());
if strcmpi(State.ip, ip)

    tic;
    t=datevec(SysCurrentTime); tn=datenum(t); dv=datevec(t); %当前时间
    sec=dv(4)*3600+dv(5)*60;
    if sec<34200||sec>54000 % <9:30||>15:00
        set(handles.StartMonitor, 'Enable', 'on');
        set(handles.StopMonitor, 'Enable', 'off');
        set(handles.ArbiTrade, 'Enable', 'off');
        set(handles.MMSOffer, 'Enable', 'off');
        set(handles.StopTrade, 'Enable', 'off');
        stop(hObject); %如不停止，则可24小时运行
        %save(['..\log\' datestr(today, 'yyyymmdd') '.mat'], 'data');
        return;
    end
    if sec>41400&&sec<46800 % 11:30< && <13:00
        return;
    end
    
    try
%         acctIds = unique(data(1:end-1,14));
%         knock = cell(0);
%         n=size(acctIds,1);
%         for i = 1 : size(acctIds,1)
%             condKnock.acctId = acctIds{i};
%             condKnock.queryType = 2;condKnock.stkType = 'A8';
%             maxRow = 10000; pageNum = 1;
%             try
%                 list = StkQueryKnockSum(condKnock,maxRow,pageNum);
%                 k=[{list.acctId}; {list.exchId}; {list.stkId}; {list.knockQty}; {list.knockPrice}; {list.knockAmt}; {list.internalOrderType}]';
%                 knock = [knock; k];
%             catch ex
%                 %data(i,23:25) = {0};
%             end
%         end
%         if ~isempty(knock)
%             [stkOrder im in] = unique(strcat(knock(:,3),knock(:,7)));
%             knockQtySum = accumarray(in,cell2mat(knock(:,4)));
%             knockAmtSum = accumarray(in,cell2mat(knock(:,6)));
%             [lia locb]= ismember(strcat(data(1:end-1,1),{'B'}),stkOrder);
%             data(lia,23) = num2cell(knockQtySum(locb(lia)));
%             data(lia,25) = num2cell(knockAmtSum(locb(lia)));
%             data(lia,24) = num2cell(knockAmtSum(locb(lia))./knockQtySum(locb(lia)));
%             [lia locb]= ismember(strcat(data(1:end-1,1),{'S'}),stkOrder);
%             data(lia,26) = num2cell(knockQtySum(locb(lia)));
%             data(lia,28) = num2cell(knockAmtSum(locb(lia)));
%             data(lia,27) = num2cell(knockAmtSum(locb(lia))./knockQtySum(locb(lia)));
%         end
        
        %指数价格
%         indexId = {'000300','000905','000016','000010','000018','000825','000852','000860','000865','399330','399967','399975'};
%         indexList = struct('exchId',{'0','0','0','0','0','0','0','0','0','1','1','1'}, 'stkId', indexId);
%         quota = StkQuotaList(indexList);
%         idxPrice = {quota.newPrice};
%         idxClose = {quota.closePrice};
%         [lia locb] = ismember(data(1:end-1,15),indexId);
%         data(lia,30) = idxPrice(locb(lia));
%         data(lia,31) = idxClose(locb(lia));
        
        % 查询价格、净值、盘口
        % 读取行情文件，如有必要重新查询
    QuotaT=[];
    try
        load('D:\work\DataCenter\data\QuotaT.mat');
    catch ex
    end
    if isempty(QuotaT) || (tn-datenum(QuotaT.time))*86400 > 5 %超过5s重新查询
        disp('Please run DataCenter:QueryQuota.')
        quotastr = cell(0); quotanum = [];
        try
            etf=struct('exchId',data(1:end-1,12), 'stkId', data(1:end-1,1));
            list=EtfQuotaList(etf);
            qs=[{list.exchId}; {list.stkId}]'; qs(:,end+1)={'F'};
            qn=[[list.newPrice]; [list.newNet]/1e3; [list.IOPV]; [list.closePrice]; [list.highPrice]; [list.lowPrice]; [list.knockAmt]; [list.totalKnockQty]]';
            qn=[qn cell2mat({list.buy}') cell2mat({list.buyAmt}') cell2mat({list.sell}') cell2mat({list.sellAmt}') cell2mat({list.buyNet}')/1e3 cell2mat({list.sellNet}')/1e3];
            quotastr = [quotastr; qs];
            quotanum = [quotanum; qn];
        catch ex
            disp(['QueryQuota: ' ex.message]);
        end
        time=SysCurrentTime;
        QuotaT.time=time; QuotaT.quotastr=quotastr; QuotaT.quotanum=quotanum;
        %save('D:\work\DataCenter\data\QuotaT.mat','QuotaT')
    end
    quotas = QuotaT.quotastr; quotan = QuotaT.quotanum;
    array0=zeros(size(data(:,1))); array1=ones(size(data(:,1)));
    iopv=array0;
    buyPrice1=array1*100; buyAmt1=array0;
    sellPrice1=array0; sellAmt1=array0;
    [lia locb] = ismember(data(1:end-1,1),quotas(:,2));
    data(lia,3) = num2cell(quotan(locb(lia),1));%price
    data(lia,4) = num2cell(quotan(locb(lia),2));%newnet
    iopv(lia) = quotan(locb(lia),2);%newnet
    data(lia,5) = num2cell((quotan(locb(lia),1)./quotan(locb(lia),2)-1)*100);
    data(lia,29) = num2cell(quotan(locb(lia),4));%close
    buyPrice1(lia)=quotan(locb(lia),9); buyAmt1(lia)=quotan(locb(lia),14);
    sellPrice1(lia)=quotan(locb(lia),19); sellAmt1(lia)=quotan(locb(lia),24);
    if any(~lia)
        etf=struct('exchId',data(~lia,18),'stkId',data(~lia,1));
        list=EtfQuotaList(etf); newPrice=[list.newPrice]; newNet=[list.newNet]/1e3;
        buyPrice=cell2mat({list.buy}');buyAmt=cell2mat({list.buyAmt}');
        sellPrice=cell2mat({list.sell}');sellAmt=cell2mat({list.sellAmt}');
        data(~lia,3) = num2cell(newPrice);
        data(~lia,4) = num2cell(newNet);
        iopv(~lia) = newNet;
        data(~lia,5) = num2cell((newPrice./newNet-1)*100);
        buyPrice1(~lia) = buyPrice(:,1); buyAmt1(~lia) = buyAmt(:,1);
        sellPrice1(~lia) = sellPrice(:,1); sellAmt1(~lia) = sellAmt(:,1);
    end
    if any(iopv==0)
        disp('')
        return;
    end
        
        
        data(1:end-1,17) = num2cell(buyPrice1);
        data(1:end-1,18) = num2cell(buyAmt1);
        data(1:end-1,19) = num2cell(sellPrice1);
        data(1:end-1,20) = num2cell(sellAmt1);
        
        %调整交易量 计算折溢价率
        sellAmt1 = floor(sellAmt1/100)*100;
%         buyAmt1 = min([buyAmt1 cell2mat(data(:,16))],[],2);
        prem = buyPrice1 ./ iopv * 100 - 100;   %买一溢价率
        disc = sellPrice1 ./ iopv * 100 - 100;  %卖一折价率
        data(1:end-1,21) = num2cell(prem);
        data(1:end-1,22) = num2cell(disc);
        
        %无可用持仓时停止卖出报价
%         posit = cell2mat(data(1:end-1,16));
%         prem(posit == 0) = -100; %溢价率设为最小
%         buyRatio = cell2mat(data(1:end-1,6));
%         sellRatio = cell2mat(data(1:end-1,7));
%         disc(~buyRatio) = 100;  %折价率设为最大
%         prem(~sellRatio) = -100;  %溢价率设为最小
        
        %净成交量、额
        trade = cell2mat(data(1:end-1,23:28));
        data(1:end-1,33) = num2cell((trade(:,6) + trade(:,3)) /1e4);
        trade = [trade; sum(trade,1)];
        data(:,8) = num2cell(trade(:,4) - trade(:,1));
        data(:,9) = num2cell((trade(:,6) - trade(:,3)) /1e4);
        data(1:end-1,10) = num2cell((trade(1:end-1,6) - trade(1:end-1,3)) ./ (trade(1:end-1,4) - trade(1:end-1,1) + 1e-9));
        data(1:end-1,11) = num2cell(cell2mat(data(1:end-1,10)) ./ cell2mat(data(1:end-1,4)) * 100 - 100);
        
        %报价策略
        switch State.mode
            case 1
                
            case 2
                n = size(data,1);
                for i = 1 : n - 1
                    flag = 0;
                    if trade(i,1) == 0 && trade(i,4) == 0, continue, end %无交易价格
                    netAmount = max(abs(trade(i,3)-trade(i,6)),1e4);
                    %if sellFlag(i) && posit(i) > 0 && trade(i,1) >= trade(i,4) && buyPrice1(i) > trade(i,2) %卖出标记 有持仓 净买入 买一价>=买入均价 卖出
                    if buyPrice1(i) >= (data{i,30}/data{i,31}+data{i,7})*data{i,29}	%卖出标记 有持仓 净买入 买一价>=买入均价 卖出&& trade(i,1) > trade(i,4)  %max(trade(i,2),data{i,30}/data{i,31}*data{i,29})
                        sellAmount = buyPrice1(i) * buyAmt1(i);
                        orderQty = buyAmt1(i);
%                         if sellAmount > netAmount
%                             orderQty = floor(netAmount / buyPrice1(i));
%                         end
                        orderInfo.exchId = data{i,12}; orderInfo.stkId = data{i,1};
                        orderInfo.acctId = data{i,14}; orderInfo.orderType = 'S';
                        orderInfo.orderQty = orderQty; orderInfo.orderPrice = buyPrice1(i);
                        disp(datestr(now,'yyyy-mm-dd HH:MM:SS'));
                        disp(orderInfo);
                        flag=1;
                        try
                            info = StkMakeOrder(orderInfo);
                        catch ex
                            disp(ex.message);
                        end
                    %elseif buyFlag(i) && trade(i,4) >= trade(i,1) && sellPrice1(i) < trade(i,5) %买入标记 净卖出 卖一价<=卖出均价 买入
                    end
                    if sellPrice1(i) <= (data{i,30}/data{i,31}+data{i,6})*data{i,29}	%买入标记 净卖出 卖一价<=卖出均价 买入&& trade(i,4) > trade(i,1)  %min(trade(i,5),data{i,30}/data{i,31}*data{i,29})
                        buyAmount = sellPrice1(i) * sellAmt1(i);
                        orderQty = sellAmt1(i);
%                         if buyAmount > netAmount
%                             orderQty = ceil(netAmount / sellPrice1(i) / 100) * 100;
%                         end
                        orderInfo.exchId = data{i,12}; orderInfo.stkId = data{i,1};
                        orderInfo.acctId = data{i,14}; orderInfo.orderType = 'B';
                        orderInfo.orderQty = orderQty; orderInfo.orderPrice = sellPrice1(i);
                        disp(datestr(now,'yyyy-mm-dd HH:MM:SS'));
                        disp(orderInfo);
                        flag=1;
                        try
                            info = StkMakeOrder(orderInfo);
                        catch ex
                            disp(ex.message);
                        end
                    end
%                     if flag
%                         flag2 = 0;
%                         try
%                             info = StkMakeOrder(orderInfo);
%                             flag2 = 1;
%                         catch ex
%                             disp(ex.message);
% %                             tick = ceil(orderInfo.orderPrice)*0.001;
% %                             switch orderInfo.orderType
% %                                 case 'B'
% %                                     orderInfo.orderPrice = orderInfo.orderPrice - tick;
% %                                 case 'S'
% %                                     orderInfo.orderPrice = orderInfo.orderPrice + tick;
% %                             end
% %                             try
% %                                 info = StkMakeOrder(orderInfo);
% %                                 flag2 = 1;
% %                             catch ex2
% %                                 disp(ex2.message);
% %                             end
%                         end
%                         if flag2
%                             tmp = [datestr(now,'HHMMSS'); struct2cell(orderInfo)]';
%                             formatSpec = [datestr(now,'HHMMSS') ': ' orderInfo.orderType '\t%d\t%.3f\t%d\r\n'];
%                             fprintf(file, formatSpec, [str2double(orderInfo.stkId) orderInfo.orderPrice orderInfo.orderQty]);
%                             orderP = [tmp info.contractNum];
%                             filename = ['..\log\order' datestr(today, 'yyyymmdd') '.mat'];
%                             if exist(filename,'file')
%                                 load(filename);
%                                 order = [order; orderP];
%                             else
%                                 order = orderP;
%                             end
%                             save(filename, 'order');
%                         end
%                     end
                end
        end
    catch e
        stop(hObject); %发生异常则停止报价
        set(handles.StartMonitor, 'Enable', 'on');
        set(handles.StopMonitor, 'Enable', 'off');
        set(handles.ArbiTrade, 'Enable', 'on');
        set(handles.StopTrade, 'Enable', 'off');
        State.mode = 0;
        save('..\appdata\State.mat','State');
        errordlg({'发生异常，停止报价',['异常信息：' e.message]},'停止');
    end
    
    save('..\appdata\Data.mat','data','pointer');
    %fclose(file);
    
    t=toc;
    disp(['Time elapsed ' num2str(t) 's'])
end
set(handles.FundMonitor, 'Data', render(data));


function [rendered] = render(data)
rendered = [data(:,1:11) data(:,32:33)];
%价位显示百分数
rendered(1:end-1,6:7) = num2cell(cell2mat(rendered(1:end-1,6:7))*100);
%折溢价率突出显示
headr = {'<html><body bgcolor=#FFC7CE color=#9C0006 width=77 align=right>'};
headg = {'<html><body bgcolor=#C6EFC3 color=#006100 width=77 align=right>'};
tail = {'</body></html>'};
trade = cell2mat(rendered(1:end-1,8:9)); ratio = cell2mat(rendered(1:end-1,11));
non0 = trade(:,1)~=0;
if any(non0)
    rendered{end,11} = trade(non0,2)'*ratio(non0)/rendered{end,9};
    ratio = [ratio; rendered{end,11}];
end
checkRatio = [trade(:,1);rendered{end,8}] .* ratio; isR = checkRatio > 0; isG = checkRatio < 0;
row = find(isR);
rendered(isR,11) = strcat(repmat(headr,size(row)), num2str(ratio(row)), repmat(tail,size(row)));
row = find(isG);
rendered(isG,11) = strcat(repmat(headg,size(row)), num2str(ratio(row)), repmat(tail,size(row)));
%检查成交量
head = {'<html><body color=black bgcolor=yellow width=97 align=right>'};
trade = cell2mat(data(1:end-1,33));
checkAmt = trade < cell2mat(data(1:end-1,32));
row = find(checkAmt);
rendered(checkAmt,13) = strcat(repmat(head,size(row)), num2str(trade(row)), repmat(tail,size(row)));

% 初始化根网工具箱，登录账户
function init_callback(hObject, eventdata, handles)
load('..\appdata\State.mat');
ip = char(java.net.InetAddress.getLocalHost());
if strcmpi(State.ip, ip)
    load('..\appdata\StkAcct.mat');
    for i = 1 : size(StkAcct,1)
        AcctLogin(StkAcct{i,1}, StkAcct{i,2});
    end
end

% 登出账户，断开根网工具箱连接
function stop_callback(hObject, eventdata, handles)
load('..\appdata\State.mat');
ip = char(java.net.InetAddress.getLocalHost());
if strcmpi(State.ip, ip)
    load('..\appdata\StkAcct.mat');
    for i = 1 : size(StkAcct,1)
        AcctLogout(StkAcct{i,1}, StkAcct{i,2});
    end
    State.mode = 0;
    save('..\appdata\State.mat','State');
end


% --- Outputs from this function are returned to the command line.
function varargout = FundTrader_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in AddFund.
function AddFund_Callback(hObject, eventdata, handles)
% hObject    handle to AddFund (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
load('..\appdata\State.mat');
ip = char(java.net.InetAddress.getLocalHost());
if strcmpi(State.ip, ip)
    h = openfig('FundConfig.fig', 'reuse');
    set(h, 'Name', '新增基金');
    hs = guihandles(h);
    hs.config = 'add';
    load('..\appdata\FundInfo.mat');
    hs.FundInfo = FundInfo;
    guidata(h, hs);
    uiwait(h);
    hs = guidata(h);
    if hs.changed
        FundInfo = hs.FundInfo;
        [data pointer] = refresh_table(FundInfo);
        set(handles.FundMonitor, 'Data', render(data));
        save('..\appdata\FundInfo.mat', 'FundInfo');
        save('..\appdata\Data.mat', 'data', 'pointer');
    end
    delete(h);
end

% --- Executes on button press in ModFund.
function ModFund_Callback(hObject, eventdata, handles)
% hObject    handle to ModFund (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
load('..\appdata\State.mat');
ip = char(java.net.InetAddress.getLocalHost());
if strcmpi(State.ip, ip)
    h = openfig('FundConfig.fig', 'reuse');
    set(h, 'Name', '修改基金');
    hs = guihandles(h);
    hs.config = 'mod';
    hs.selected = handles.selected;
    load('..\appdata\FundInfo.mat');
    hs.FundInfo = FundInfo;
    set(hs.StkId, 'String', FundInfo(handles.selected).stkId);
    set(hs.StkName, 'String', FundInfo(handles.selected).stkName);
    set(hs.RedemptionId, 'String', FundInfo(handles.selected).redemptionId);
    set(hs.TargetAmt, 'String', num2str(FundInfo(handles.selected).targetAmt));
    set(hs.BuyRatio, 'String', num2str(FundInfo(handles.selected).buyRatio));
    set(hs.SellRatio, 'String', num2str(FundInfo(handles.selected).sellRatio));
    
    [lia, locb] = ismember(FundInfo(handles.selected).exchId, get(hs.ExchId, 'String'));
    if lia
        set(hs.ExchId, 'Value', locb);
    end
    [lia, locb] = ismember(FundInfo(handles.selected).index, get(hs.Index, 'String'));
    if lia
        set(hs.Index, 'Value', locb);
    end
    load('..\appdata\StkAcct.mat');
    [lia, locb] = ismember(FundInfo(handles.selected).stkAcct,StkAcct(:,1));
    if lia
        set(hs.StkAcct, 'Value', locb);
    end
    guidata(h, hs);
    uiwait(h);
    hs = guidata(h);
    if hs.changed
        FundInfo = hs.FundInfo;
        [data pointer] = refresh_table(FundInfo);
        set(handles.FundMonitor, 'Data', render(data));
        save('..\appdata\FundInfo.mat', 'FundInfo');
        save('..\appdata\Data.mat', 'data', 'pointer');
    end
    delete(h);
end

% --- Executes when selected cell(s) is changed in FundTrader.
function FundMonitor_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to FundTrader (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)
load('..\appdata\State.mat');
ip = char(java.net.InetAddress.getLocalHost());
if strcmpi(State.ip, ip)
    if ~isempty(eventdata.Indices)
        selected = eventdata.Indices;
        load('..\appdata\Data.mat');
        if selected(1) ~= size(data,1)
            set(handles.ModFund, 'enable', 'on');
            set(handles.DelFund, 'enable', 'on');
            handles.selected = pointer(selected(1));
            guidata(hObject, handles);
        else
            set(handles.ModFund, 'enable', 'off');
            set(handles.DelFund, 'enable', 'off');
        end
    end
end


% --- Executes on button press in DelFund.
function DelFund_Callback(hObject, eventdata, handles)
% hObject    handle to DelFund (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
load('..\appdata\State.mat');
ip = char(java.net.InetAddress.getLocalHost());
if strcmpi(State.ip, ip)
    choice = questdlg('确认删除基金？', '删除基金', '确认','取消','取消');
    switch choice
        case '确认'
            load('..\appdata\FundInfo.mat');
            FundInfo(handles.selected)=[];
            [data pointer] = refresh_table(FundInfo);
            set(handles.FundMonitor, 'Data', render(data));
            save('..\appdata\FundInfo.mat', 'FundInfo');
            save('..\appdata\Data.mat', 'data', 'pointer');
    end
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
SysDisconnect
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
set(handles.MMSOffer, 'Enable', 'on');

% --- Executes on button press in StopMonitor.
function StopMonitor_Callback(hObject, eventdata, handles)
% hObject    handle to StopMonitor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% 停止时钟
stop(handles.timer);
set(handles.StartMonitor, 'Enable', 'on');
set(handles.StopMonitor, 'Enable', 'off');
set(handles.MMSOffer, 'Enable', 'off');
set(handles.StopTrade, 'Enable', 'off');

load('..\appdata\State.mat');
ip = char(java.net.InetAddress.getLocalHost());
if strcmpi(State.ip, ip)
    State.mode = 0;
    save('..\appdata\State.mat','State');
end


% --- Executes on button press in ArbiTrade.
function ArbiTrade_Callback(hObject, eventdata, handles)
% hObject    handle to ArbiTrade (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.ArbiTrade, 'Enable', 'off');
set(handles.StopTrade, 'Enable', 'on');

load('..\appdata\State.mat');
ip = char(java.net.InetAddress.getLocalHost());
if strcmpi(State.ip, ip)
    State.mode = 1;
    save('..\appdata\State.mat','State');
end


% --- Executes on button press in StopTrade.
function StopTrade_Callback(hObject, eventdata, handles)
% hObject    handle to StopTrade (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.MMSOffer, 'Enable', 'on');
set(handles.StopTrade, 'Enable', 'off');

load('..\appdata\State.mat');
ip = char(java.net.InetAddress.getLocalHost());
if strcmpi(State.ip, ip)
    State.mode = 0;
    save('..\appdata\State.mat','State');
end


% --- Executes on button press in MMSOffer.
function MMSOffer_Callback(hObject, eventdata, handles)
% hObject    handle to MMSOffer (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.MMSOffer, 'Enable', 'off');
set(handles.StopTrade, 'Enable', 'on');

load('..\appdata\State.mat');
ip = char(java.net.InetAddress.getLocalHost());
if strcmpi(State.ip, ip)
    State.mode = 2;
    save('..\appdata\State.mat','State');
end


% --- Executes on button press in MMSStart.
function MMSStart_Callback(hObject, eventdata, handles)
% hObject    handle to MMSStart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
info.optId='88240';info.offerStatus='1';
acctId={'000000000101','000000000109'};
for i=1:length(acctId)
    AcctLogin(acctId{i},'666666');
    info.acctId=acctId{i};
    flag=MMS_ModifyOrderStatus2(info);
    switch flag
        case 0, disp([acctId{i} '双边报价启动成功']);
        otherwise, disp([acctId{i} '双边报价启动失败']);
    end
end

% --- Executes on button press in MMSStop.
function MMSStop_Callback(hObject, eventdata, handles)
% hObject    handle to MMSStop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
info.optId='88240';info.offerStatus='2';
acctId={'000000000101','000000000109'};
for i=1:length(acctId)
    AcctLogin(acctId{i},'666666');
    info.acctId=acctId{i};
    flag=MMS_ModifyOrderStatus2(info);
    switch flag
        case 0, disp([acctId{i} '双边报价停止成功']);
        otherwise, disp([acctId{i} '双边报价停止失败']);
    end
end

% --- Executes on button press in MMSIncrementUp.
function MMSIncrementUp_Callback(hObject, eventdata, handles)
% hObject    handle to MMSIncrementUp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in MMSIncrementDown.
function MMSIncrementDown_Callback(hObject, eventdata, handles)
% hObject    handle to MMSIncrementDown (see GCBO)
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
