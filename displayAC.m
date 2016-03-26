function varargout = displayAC(varargin)
% Display the AC curve required
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @displayAC_OpeningFcn, ...
                   'gui_OutputFcn',  @displayAC_OutputFcn, ...
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

% --- Executes just before displayAC is made visible.
function displayAC_OpeningFcn(hObject, eventdata, handles, varargin)
% Choose default command line output for diab_gui
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);
% This sets up the initial plot - only do when we are invisible
% so window can get raised using displayAC.
if strcmp(get(hObject,'Visible'),'off')
    plot([0 20],[0 0]);
    xlim([0 20]);ylim([0 1]);
end

if (nargin<7)
    fprintf('Input: data_fname, miss_rate, method, cont_ind\n');
    return;
end
data_fname = varargin{1};
miss_rate = varargin{2};
method = varargin{3};
cont_ind = varargin{4};
eval_fname = sprintf('%s_%s_eval.mat',data_fname,num2str(miss_rate));
if ~exist(eval_fname,'file')
    fprintf('No results.\n');
    return;
end
load(eval_fname);
%'sknn_eval','sknn_cols','sknn_colConf','sknn_colRate','knn_eval','mi_eval','lc_eval','cf_eval'

handles.miss_rate = miss_rate;
handles.method = method;
handles.sknn_eval = sknn_eval;
handles.knn_eval = knn_eval;
handles.mi_eval = mi_eval;
handles.lc_eval = lc_eval;
handles.cf_eval = cf_eval;
switch handles.method
    case 'SKNN'
        plot(handles.sknn_eval(1,:),handles.sknn_eval(2,:),'b-','LineWidth',2);
    case 'KNN'
        plot(handles.knn_eval(1,:),handles.knn_eval(2,:),'--','Color',[0.4 0.4 0.4],'LineWidth',2);
    case 'MI'
        plot(handles.mi_eval(1,:),handles.mi_eval(2,:),'-o', 'LineWidth',2,'MarkerSize',8,'Color','r');
    case 'LC'
        plot(handles.lc_eval(1,:),handles.lc_eval(2,:),'-.','LineWidth',2,'Color',[1 0 1]);
    case 'CF'
        plot(handles.cf_eval(1,:),handles.cf_eval(2,:),'-*k','LineWidth',1.5,'MarkerSize',8,'Color',[0.4627 0.5373 0.2078]);
end
legend(handles.method,'Location','southwest');
xlim([0 20]);set(gca,'XTick',0:1:20);set(gca,'XTickLabel',0:5:100);
ylim([0 1]);
xlabel('Completion Rate (%)'); ylabel('Accuracy');
title_str = sprintf('Missing Rate = %s%s',num2str(handles.miss_rate*100),'%');
title(title_str);


%data_fname = 'clinic_data.txt';
%cont_ind = [2 3 4];
type_name = {'Categorical' 'Numerical'};
switch data_fname
    case 'clinic_data.txt'
        attr_names = {'PFI Number','Admission Year','Admission Mon','Admission Weekday','Admission Hour',...
            'Race','Ethnic','Age','ICD-9 Code','Insurance Type','Number of Staying Days','Zipcode'};
        type_idx = ones(1,12);
        type_idx(cont_ind) = 2;
        attr_types = {type_name{type_idx}};
    case 'adult_data.txt'
        attr_names = {'Age','Work Class','Final Weight','Education','Num of Educations','Marital Status',...
            'Occupation','Relationship','Race','Gender','Capital Gains','Capital Losses','Hours Per Week',...
            'Native Country','Incomes > 50K'};
        type_idx = ones(1,15);
        type_idx(cont_ind) = 2;
        attr_types = {type_name{type_idx}};
    case 'census_data.txt'
        attr_names = {'Age','Class of Worker','Industry','Occupation','Education','Wage Per Hour','Last Education',...
            'Marital Status','Major Industry Code','Major Occupation Code','Race','Hispanic Origin','Gender',...
            'Member of a Labor Union','Reason for Unemployment','Full or Part Time','Capital Gains','Capital Losses',...
            'Divdends from Stocks','Tax Filer Status','Region of Previous Residence','State of Previous Residence',...
            'Detailed Household and Family Status','Detailed Household Summary in Household','Instance',...
            'Migration Code-change in msa','Migration Code-change in reg','Migration Code-move within reg',...
            'Live in This House 1 Year Ago','Migration prev res in Sunbelt','Num Persons Worked for Employer',...
            'Family Members under 18','Country of Birth Father','Country of Birth Mother','Country of Birth Self',...
            'Citizenship','Unknown','Own Business or Self Employed','Unknown','Weeks Worked in Year',...
            'Unkown','Year Incomes Whether > 50K'};
        type_idx = ones(1,42);
        type_idx(cont_ind) = 2;
        attr_types = {type_name{type_idx}};
    otherwise
        attr_names = {};
        attr_types = {};
end
handles.attr_names = attr_names';
handles.attr_types = attr_types';

handles.output = hObject;
guidata(hObject, handles);
handles.uitable1.Data = [handles.attr_names handles.attr_types];
handles.uitable1.ColumnName = {'Attribute Name','Type'};
handles.uitable1.ColumnWidth = {210 89};
handles.text1.String = sprintf('Attributes of %s',data_fname);

if ~isempty(sknn_cols)
    cols_num = length(sknn_cols);
    top_cut = min([5, cols_num]);
    end_cut = max([1, cols_num-4]);
    top5_data = [sknn_cols(1:top_cut)' sknn_colConf(1:top_cut)' sknn_colRate(1:top_cut)'];
    end5_data = [sknn_cols(end_cut:cols_num)' sknn_colConf(end_cut:cols_num)' sknn_colRate(end_cut:cols_num)'];
else
    top5_data = [];
    end5_data = [];
end
handles.uitable2.Data = top5_data;
handles.uitable2.RowName = [];
handles.uitable2.ColumnWidth = {30 66 65};
handles.uitable2.ColumnName = {'No.','Entropy','Accuracy'};
handles.text2.String = 'Top 5 Attributes wrt Entropy';
handles.uitable4.Data = end5_data;
handles.uitable4.RowName = [];
handles.uitable4.ColumnWidth = {30 66 65};
handles.uitable4.ColumnName = {'No.','Entropy','Accuracy'};
handles.text3.String = 'Bottom 5 Attributes wrt Entropy';
handles.text4.String = {'* Both Entropy and Accuracy are average values of each attribute',...
    'This measurement is only appliable when using SKNN'};



% UIWAIT makes displayAC wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = displayAC_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --------------------------------------------------------------------
function FileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to FileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function OpenMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to OpenMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
file = uigetfile('*.fig');
if ~isequal(file, 0)
    open(file);
end

% --------------------------------------------------------------------
function PrintMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to PrintMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
printdlg(handles.figure1)

% --------------------------------------------------------------------
function CloseMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to CloseMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
selection = questdlg(['Close ' get(handles.figure1,'Name') '?'],...
                     ['Close ' get(handles.figure1,'Name') '...'],...
                     'Yes','No','Yes');
if strcmp(selection,'No')
    return;
end

delete(handles.figure1)


% --- Executes on button press in checkbox1.
function checkbox1_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkbox1
input = get(hObject,'Value');
if (input==1)
    %plot([0 20],[1 0]);
    methods = {};
    if (~isempty(handles.sknn_eval))
        plot(handles.sknn_eval(1,:),handles.sknn_eval(2,:),'b-','LineWidth',2);
        methods = [methods 'SKNN'];
        hold on;
    end
    if (~isempty(handles.knn_eval))
        plot(handles.knn_eval(1,:),handles.knn_eval(2,:),'--','Color',[0.4 0.4 0.4],'LineWidth',2);
        methods = [methods 'KNN'];
        hold on;
    end
    if (~isempty(handles.mi_eval))
        plot(handles.mi_eval(1,:),handles.mi_eval(2,:),'-o', 'LineWidth',2,'MarkerSize',8,'Color','r');
        methods = [methods 'MI'];
        hold on;
    end
    if (~isempty(handles.lc_eval))
        plot(handles.lc_eval(1,:),handles.lc_eval(2,:),'-.','LineWidth',2,'Color',[1 0 1]);
        methods = [methods 'LC'];
        hold on;
    end
    if (~isempty(handles.cf_eval))
        plot(handles.cf_eval(1,:),handles.cf_eval(2,:),'-*k','LineWidth',1.5,'MarkerSize',8,'Color',[0.4627 0.5373 0.2078]);
        methods = [methods 'CF'];
        hold on;
    end
    hold off;
    legend(methods,'Location','southwest');
else
    %plot([0 20],[0.5 0.5]);
    
    switch handles.method
    case 'SKNN'
        plot(handles.sknn_eval(1,:),handles.sknn_eval(2,:),'b-','LineWidth',2);
    case 'KNN'
        plot(handles.knn_eval(1,:),handles.knn_eval(2,:),'--','Color',[0.4 0.4 0.4],'LineWidth',2);
    case 'MI'
        plot(handles.mi_eval(1,:),handles.mi_eval(2,:),'-o', 'LineWidth',2,'MarkerSize',8,'Color','r');
    case 'LC'
        plot(handles.lc_eval(1,:),handles.lc_eval(2,:),'-.','LineWidth',2,'Color',[1 0 1]);
    case 'CF'
        plot(handles.cf_eval(1,:),handles.cf_eval(2,:),'-*k','LineWidth',1.5,'MarkerSize',8,'Color',[0.4627 0.5373 0.2078]);
    end
    legend(handles.method,'Location','southwest');
end
xlim([0 20]);set(gca,'XTick',0:1:20);set(gca,'XTickLabel',0:5:100);
ylim([0 1]);
xlabel('Completion Rate (%)'); ylabel('Accuracy');
title_str = sprintf('Missing Rate = %s%s',num2str(handles.miss_rate*100),'%');
title(title_str);


% --- Executes during object creation, after setting all properties.
function uitable1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to uitable1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function uitable2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to uitable2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function uitable3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to uitable3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function uitable4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to uitable4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function text1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function text2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function text3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
