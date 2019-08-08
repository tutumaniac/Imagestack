function varargout = ImageStack(varargin)
% IMAGESTACK MATLAB code for ImageStack.fig
%      IMAGESTACK, by itself, creates a new IMAGESTACK or raises the existing
%      singleton*.
%
%      H = IMAGESTACK returns the handle to a new IMAGESTACK or the handle to
%      the existing singleton*.
%
%      IMAGESTACK('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IMAGESTACK.M with the given input arguments.
%
%      IMAGESTACK('Property','Value',...) creates a new IMAGESTACK or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ImageStack_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ImageStack_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ImageStack

% Last Modified by GUIDE v2.5 03-Dec-2014 11:09:13

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ImageStack_OpeningFcn, ...
                   'gui_OutputFcn',  @ImageStack_OutputFcn, ...
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
end

% --- Executes just before ImageStack is made visible.
function ImageStack_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ImageStack (see VARARGIN)

    % Choose default command line output for ImageStack
    handles.output = hObject;
    
    % what kind of rois are allowed
    handles.Config.RoiKinds = {'RectRoi','PolyRoi'};
    % set variable for saving and loading path
    handles.Config.safe_path = cd;
    handles.Config.load_path = cd;
    % defaults for images
%     handles.Config.ImgDim = [516 516];
%     handles.Config.ImgCdepth = 32;
    
    handles.Config.ImgDim = [581 256];
    handles.Config.ImgCdepth = 16;
    % set default Roi Colors
    handles.Config.RoiColor = [1 0 1]; %magenta
    handles.Config.BgColor = [0 0 0]; %black
    
    
    % reset all sort of stuff
    handles = resetData(handles);
    
    % hide stuff because it doesnt have use yet and can cause mistakes
    set(handles.StackAxes,'Visible','off')
    set(handles.listboxFiles,'Visible','off')
    set(handles.SetRoiButton,'Visible','off')
    set(handles.SetBgButton,'Visible','off')
    set(handles.ProcessButton,'Visible','off')
    set(handles.Menubar_Save,'Visible','off')
    set(handles.Menubar_Color,'Visible','off')
    set(handles.IntAxes,'Visible','off')
    set(handles.Scaletext,'Visible','off')
    set(handles.Colormaptext,'Visible','off')
    set(handles.ColorSliderMax,'Visible','off')
    set(handles.ColorSliderMin,'Visible','off')
    set(handles.img_scale_pop_up,'Visible','off')
    set(handles.Colormap_Popup,'Visible','off')
    set(handles.Add_Image_Information_Button,'Visible','off')
    set(handles.norm_y_axes_popup,'Visible','off')
    set(handles.norm_x_axes_popup,'Visible','off')
    set(handles.uipanel_y_axes,'Visible','off')
    set(handles.uipanel_x_axes,'Visible','off')
    set(handles.uipanel_norm_x,'Visible','off')
    set(handles.uipanel_norm_y,'Visible','off')
    set(handles.RemoveImgBut,'Visible','off')
    
    % enable resizing
    fhandles = findobj(handles.figure1,'type','uicontrol','-or',...
            'type','uipanel','-or',...
            'type','axes');
    for i = 1:length(fhandles)
        set(fhandles(i),'units','normalized');
%         pos{i} = get(fhandles(i),'position');
    end
    set(handles.figure1,'resize','on')
    
    % Update handles structure
    guidata(hObject, handles);
end

% --- Executes on button press in RemoveImgBut.
function RemoveImgBut_Callback(hObject, eventdata, handles)
% hObject    handle to RemoveImgBut (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    state = getGuiState(handles);

    handles.ImageStack.removeImage(state.listboxFilesValue);

    NewImageNames = handles.ImageStack.getImageNames;

    if state.listboxFilesValue > length(NewImageNames)
        set(handles.listboxFiles,'Value',length(NewImageNames));
    end
    set(handles.listboxFiles,'String',handles.ImageStack.getImageNames);
    setColorSlider(handles);
    drawImage(handles)
    drawPlot(handles)

end


% --- Executes on selection change in listboxFiles.
function listboxFiles_Callback(hObject, eventdata, handles)
% hObject    handle to listboxFiles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    setColorSlider(handles);
    drawImage(handles)
    drawPlot(handles)
end

% --- Executes on button press in ProcessButton.
function ProcessButton_Callback(hObject, ~, handles)
% hObject    handle to ProcessButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    
    % determine StructureFactor
    handles.ImageStack.getStructureFactor();
    
    set_Popups(handles);
    drawImage(handles);
    drawPlot(handles);
    
    % Update handles structure
    guidata(hObject, handles);
end

% --- Executes on button press in SetRoiButton.
function SetRoiButton_Callback(hObject, ~, handles)
% hObject    handle to SetRoiButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    [state] = getGuiState(handles);
    RoiType = 'Peak';
    
    % how many boxes?
    RoiNumber = inputdlg('Set Number of Boxes!');
    if isempty(RoiNumber) == 1 % return if cancel is pressed
        return
    end
    RoiNumber = str2double(cell2mat(RoiNumber));
    
    % choose the type of Roi (rectangular or polygon)
    liststr = handles.Config.RoiKinds;
    
    [ImNum,ok] = listdlg('PromptString','Select what type of Roi',...
        'SelectionMode','single',...
        'InitialValue',1,...
        'ListString',liststr);
    
    if ok == 0
        return
    end
    
    RoiKind = handles.Config.RoiKinds{ImNum};
     
    % find out which images are supposed to get this particular roi
    NumImgTot = length(handles.ImageStack.ImageArray);
    liststr{NumImgTot} = 0;
    for i = 1:NumImgTot;
        liststr{i} = ['Image No. ' num2str(i)];
    end

    [ImNum,ok] = listdlg('PromptString','Select Images For which Roi should be definied:',...
        'SelectionMode','multiple',...
        'InitialValue',state.listboxFilesValue,...
        'ListString',liststr);
    
    if ok == 0
        return
    end
    
    % reset the rois of chosen images
    for i = 1:length(ImNum)
        handles.ImageStack.ImageArray(ImNum(i)).resetRoi(RoiType);
    end
    
    % get the rois for the image in focus
    for i = 1:RoiNumber
        handles.ImageStack.ImageArray(state.listboxFilesValue).getRoi(RoiType,RoiKind,i,handles.StackAxes);
        drawImage(handles)
    end
    
    % set the rois for the other chosen images
    for i = 1:length(ImNum)
        if ImNum(i) ~= state.listboxFilesValue % this has been set before
            RoiArrayObj = handles.ImageStack.ImageArray(state.listboxFilesValue).(RoiType);
            handles.ImageStack.ImageArray(ImNum(i)).setRoi(RoiType,RoiArrayObj);
        end
    end   

    % Update handles structure
    guidata(hObject, handles);
end

% --- Executes on button press in SetBgButton.
function SetBgButton_Callback(hObject, ~, handles)
% hObject    handle to SetBgButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    [state] = getGuiState(handles);
    RoiType = 'Bg';
    
    % how many boxes?
    RoiNumber = inputdlg('Set Number of Boxes!');
    if isempty(RoiNumber) == 1 % return if cancel is pressed
        return
    end
    RoiNumber = str2double(cell2mat(RoiNumber));
    
    % choose the type of Roi (rectangular or polygon)
    liststr = handles.Config.RoiKinds;
    
    [ImNum,ok] = listdlg('PromptString','Select what type of Roi',...
        'SelectionMode','single',...
        'InitialValue',1,...
        'ListString',liststr);
    
    if ok == 0
        return
    end
    
    RoiKind = handles.Config.RoiKinds{ImNum};
     
    % find out which images are supposed to get this particular roi
    NumImgTot = length(handles.ImageStack.ImageArray);
    liststr{NumImgTot} = 0;
    for i = 1:NumImgTot;
        liststr{i} = ['Image No. ' num2str(i)];
    end

    [ImNum,ok] = listdlg('PromptString','Select Images For which Roi should be definied:',...
        'SelectionMode','multiple',...
        'InitialValue',state.listboxFilesValue,...
        'ListString',liststr);
    
    if ok == 0
        return
    end
    
    % reset the rois of chosen images
    for i = 1:length(ImNum)
        handles.ImageStack.ImageArray(ImNum(i)).resetRoi(RoiType);
    end
    
    % get the rois for the image in focus
    for i = 1:RoiNumber
        handles.ImageStack.ImageArray(state.listboxFilesValue).getRoi(RoiType,RoiKind,i,handles.StackAxes);
        drawImage(handles)
    end
    
    % set the rois for the other chosen images
    for i = 1:length(ImNum)
        RoiArrayObj = handles.ImageStack.ImageArray(state.listboxFilesValue).(RoiType);
        handles.ImageStack.ImageArray(ImNum(i)).setRoi(RoiType,RoiArrayObj);
    end
    % Update handles structure
    guidata(hObject, handles);
end

% --- Executes on selection change in img_scale_pop_up.
function img_scale_pop_up_Callback(~, ~, handles)
% hObject    handle to img_scale_pop_up (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    drawImage(handles)
end

% --- Executes on selection change in Colormap_Popup.
function Colormap_Popup_Callback(~, ~, handles)
% hObject    handle to Colormap_Popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    drawImage(handles)
end

% --- Executes on selection change in x_Axes_Popup.
function x_Axes_Popup_Callback(~, ~, handles)
% hObject    handle to x_Axes_Popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    drawImage(handles)
    drawPlot(handles)
end

% --- Executes on selection change in y_Axes_Popup.
function y_Axes_Popup_Callback(~, ~, handles)
% hObject    handle to y_Axes_Popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    drawPlot(handles)
end

function handles = resetData(handles)
    % set second delete ImageStack
    handles.ImageStack = [];
end

function set_Popups(handles)
% Enable the different counters for the two Popup_axes
    CounterNames = handles.ImageStack.getCounterNames();
    [ScaleProperties,ColormapProperties] = SoloImage.parseDrawInputs();
    
    set(handles.img_scale_pop_up,'String',ScaleProperties);
    set(handles.Colormap_Popup,'String',ColormapProperties);
    
    % necessary due to varying number of counters if Value was greater than
    % the number of Counternames the popups wouldnt work anymore
    if length(CounterNames) < get(handles.x_Axes_Popup,'Value')
        set(handles.x_Axes_Popup,'Value',1)
    end
    set(handles.x_Axes_Popup,'String',CounterNames);
    
    % necessary due to varying number of counters if Value was greater than
    % the number of Counternames the popups wouldnt work anymore
    if length(CounterNames) < get(handles.y_Axes_Popup,'Value')
        set(handles.y_Axes_Popup,'Value',1)
    end
    set(handles.y_Axes_Popup,'String',CounterNames);
    
    % necessary due to varying number of counters if Value was greater than
    % the number of Counternames the popups wouldnt work anymore
    if length(CounterNames) < get(handles.norm_y_axes_popup,'Value')
        set(handles.norm_y_axes_popup,'Value',1)
    end
    set(handles.norm_y_axes_popup,'String',CounterNames);
    
    % necessary due to varying number of counters if Value was greater than
    % the number of Counternames the popups wouldnt work anymore
    if length(CounterNames) < get(handles.norm_x_axes_popup,'Value')
        set(handles.norm_x_axes_popup,'Value',1)
    end
    set(handles.norm_x_axes_popup,'String',CounterNames);  
end

function setGuiStuff(handles)
    % show stuff
    set(handles.StackAxes,'Visible','on')
    set(handles.listboxFiles,'Visible','on')
    set(handles.SetRoiButton,'Visible','on')
    set(handles.SetBgButton,'Visible','on')
    set(handles.ProcessButton,'Visible','on')
    set(handles.Menubar_Save,'Visible','on')
    set(handles.Menubar_Color,'Visible','on')
    set(handles.x_Axes_Popup,'Visible','on')
    set(handles.y_Axes_Popup,'Visible','on')
    set(handles.IntAxes,'Visible','on')
    set(handles.Scaletext,'Visible','on')
    set(handles.Colormaptext,'Visible','on')
    set(handles.ColorSliderMax,'Visible','on')
    set(handles.ColorSliderMin,'Visible','on')
    set(handles.img_scale_pop_up,'Visible','on')
    set(handles.Colormap_Popup,'Visible','on')
    set(handles.Add_Image_Information_Button,'Visible','on')
    set(handles.uipanel_y_axes,'Visible','on')
    set(handles.uipanel_x_axes,'Visible','on')
    set(handles.uipanel_norm_x,'Visible','on')
    set(handles.uipanel_norm_y,'Visible','on')
    set(handles.RemoveImgBut,'Visible','on')
    
    %set listbox stuff
    
    set(handles.listboxFiles,'String',handles.ImageStack.getImageNames)
    set(handles.listboxFiles,'Value',1)
    
end

function [state] = getGuiState(handles)

    state.listboxFilesValue = get(handles.listboxFiles,'Value');
    % get ColorSliderValue (needs to be integer)
    state.ColorSliderMinValue = round(get(handles.ColorSliderMin,'Value'));
    % get ColorSliderValue (needs to be integer)
    state.ColorSliderMaxValue = round(get(handles.ColorSliderMax,'Value'));
    % get x_Axes_Popup infos
    x_Axes_Popup_String = get(handles.x_Axes_Popup,'String');
    x_Axes_Popup_Value = get(handles.x_Axes_Popup,'Value');
    state.x_ActiveString = x_Axes_Popup_String{x_Axes_Popup_Value};
    % get y_Axes_Popup infos
    y_Axes_Popup_String = get(handles.y_Axes_Popup,'String');
    y_Axes_Popup_Value = get(handles.y_Axes_Popup,'Value');
    state.y_ActiveString = y_Axes_Popup_String{y_Axes_Popup_Value};
    % get img_scale_pop_up infos
    img_scale_pop_up_String = get(handles.img_scale_pop_up,'String');
    img_scale_pop_up_Value = get(handles.img_scale_pop_up,'Value');
    state.img_scale = img_scale_pop_up_String{img_scale_pop_up_Value};
    % get img_scale_pop_up infos
    Colormap_Popup_String = get(handles.Colormap_Popup,'String');
    Colormap_Popup_Value = get(handles.Colormap_Popup,'Value');
    state.colormap = Colormap_Popup_String{Colormap_Popup_Value};
    % get x_Axes_Buttongroup infos
    state.x_Scale = get(get(handles.uipanel_x_axes,'SelectedObject'),'String');
    % get x_Axes_Buttongroup infos
    state.y_Scale = get(get(handles.uipanel_y_axes,'SelectedObject'),'String');    
    % get normalize x_axes_Buttongroup infos(is the active Radiobutton yes
    % or no?)
    norm_x_State = get(get(handles.uipanel_norm_x,'SelectedObject'),'String');
    if strcmp(norm_x_State,'No')
        state.x_norm_Name = '';
    elseif strcmp(norm_x_State,'Yes')
        x_norm_Popup_String = get(handles.norm_x_axes_popup,'String');
        x_norm_Popup_Value = get(handles.norm_x_axes_popup,'Value');
        state.x_norm_Name = x_norm_Popup_String{x_norm_Popup_Value};
    end
    % get normalize y_axes_Buttongroup infos(is the active Radiobutton yes
    % or no?)
    norm_y_State = get(get(handles.uipanel_norm_y,'SelectedObject'),'String');
    if strcmp(norm_y_State,'No')
        state.y_norm_Name = '';
    elseif strcmp(norm_y_State,'Yes')
        y_norm_Popup_String = get(handles.norm_y_axes_popup,'String');
        y_norm_Popup_Value = get(handles.norm_y_axes_popup,'Value');
        state.y_norm_Name = y_norm_Popup_String{y_norm_Popup_Value};
    end
end

function drawImage(handles)
    
    [state] = getGuiState(handles);
    % get the Values of the counter that is chosen in x_Popupmenu
    CounterValues = handles.ImageStack.counters.(state.x_ActiveString);
    
    c_axis = getC_axisValue(handles,state.listboxFilesValue,state.ColorSliderMaxValue,state.ColorSliderMinValue);
    
    % draw the i-th image of imagestack and title
    handles.ImageStack.ImageArray(state.listboxFilesValue).drawImage(...
        'AxesHandle',handles.StackAxes,...
        'Colormap',state.colormap,...
        'caxis',c_axis,...
        'PeakColor',handles.Config.RoiColor,...
        'BgColor',handles.Config.BgColor,...
        'scale',state.img_scale);
    % set title of the image to the element chosen in x_axes_Popup
    title(handles.StackAxes,[state.x_ActiveString ' = ' num2str(CounterValues(state.listboxFilesValue))...
        '; Image No. ' num2str(state.listboxFilesValue)])
end

function drawPlot(handles)
    [state] = getGuiState(handles);
    handles.ImageStack.plotCounters(state.x_ActiveString,state.y_ActiveString,...
        'AxesHandle',handles.IntAxes,...
        'x_scale',state.x_Scale,...
        'y_scale',state.y_Scale,...
        'x_norm_Name',state.x_norm_Name,...
        'y_norm_Name',state.y_norm_Name);

    % get the Values of the axes of the image in focus and plot them too to
    % link the plot to the image
    XData = get(get(handles.IntAxes,'Children'),'XData');
    YData = get(get(handles.IntAxes,'Children'),'YData');
    x_Pos = XData(state.listboxFilesValue);
    y_Pos = YData(state.listboxFilesValue);
    
    hold(handles.IntAxes,'on')
    plot(handles.IntAxes,x_Pos,y_Pos,...
        'Marker','x',...
        'Color','r',...
        'Markersize',20)
    hold(handles.IntAxes,'off')
end

function setColorSlider(handles)
    [state] = getGuiState(handles);
    
    % get the maxima of the image in focus
    [Min Max] = handles.ImageStack.ImageArray(state.listboxFilesValue).getExtrema();
    % get all Values
    New_Values = Min:Max;
    
    % set StackSlider Options properly
    sliderMax = length(New_Values); % Number of Values = Difference of Values + 1
    sliderMin = 1;
    sliderStep = [1, 1] / (sliderMax - sliderMin);
    
    set(handles.ColorSliderMax,'Max',sliderMax)
    set(handles.ColorSliderMax,'Value',sliderMax)
    set(handles.ColorSliderMax,'Min',sliderMin)
    set(handles.ColorSliderMax,'SliderStep',sliderStep)
    
    set(handles.ColorSliderMin,'Max',sliderMax)
    set(handles.ColorSliderMin,'Value',sliderMin)
    set(handles.ColorSliderMin,'Min',sliderMin)
    set(handles.ColorSliderMin,'SliderStep',sliderStep)
end

function c_axis = getC_axisValue(handles,listboxFilesValue,ColorSliderMaxValue,ColorSliderMinValue)

    [Min Max] = handles.ImageStack.ImageArray(listboxFilesValue).getExtrema();
    
    ColorMap = Min:Max;

    Max_map = ColorMap(ColorSliderMaxValue);
    Min_map = ColorMap(ColorSliderMinValue);
    
    c_axis = [Min_map Max_map];
end

% --- Executes on slider movement.
function ColorSliderMax_Callback(~, ~, handles)
% hObject    handle to ColorSliderMax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    
    % take care that Sliders are in ranges they are allowed to be
    MaxVal = get(handles.ColorSliderMax,'Max') - round(get(handles.ColorSliderMax,'Value'));
    MinVal = get(handles.ColorSliderMin,'Max') - round(get(handles.ColorSliderMin,'Value'));
        
    if MaxVal >= MinVal
       set(handles.ColorSliderMax,'Value',get(handles.ColorSliderMax,'Max') - MinVal + 1)
    end
    
    drawImage(handles)
end

% --- Executes on slider movement.
function ColorSliderMin_Callback(~, ~, handles)
% hObject    handle to ColorSliderMin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % take care that Sliders are in ranges they are allowed to be
    MaxVal = round(get(handles.ColorSliderMax,'Value'));
    MinVal = round(get(handles.ColorSliderMin,'Value'));
        
    if MinVal >= MaxVal
       set(handles.ColorSliderMin,'Value',MaxVal - 1)
    end
    
    drawImage(handles)
end

% --- Executes on button press in Add_Image_Information_Button.
function Add_Image_Information_Button_Callback(hObject, ~, handles)
% hObject    handle to Add_Image_Information_Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    [filename,pathname] = uigetfile({'*.tsf';'*.scan'},'Select File','Multiselect','off',handles.Config.load_path);
    if isequal(filename,0) == 1
        return
    end
    handles.Config.load_path = pathname;
    filename = [pathname filename];
    
    Counters = loadImageInfo(filename);
    
    handles.ImageStack.addCounters(Counters);
    % reset the popups and add the additional counters
    set_Popups(handles);
    
    
    % Update handles structure
    guidata(hObject, handles);
end

% --- Executes when selected object is changed in uipanel_y_axes.
function uipanel_y_axes_SelectionChangeFcn(~, ~, handles)
% hObject    handle to the selected object in uipanel_y_axes 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
    drawPlot(handles)
end

% --- Executes when selected object is changed in uipanel_x_axes.
function uipanel_x_axes_SelectionChangeFcn(~, ~, handles)
% hObject    handle to the selected object in uipanel_x_axes 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
    drawPlot(handles)
end

% --- Executes on selection change in norm_x_axes_popup.
function norm_x_axes_popup_Callback(~, ~, handles)
% hObject    handle to norm_x_axes_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    drawPlot(handles)
end

% --- Executes on selection change in norm_y_axes_popup.
function norm_y_axes_popup_Callback(~, ~, handles)
% hObject    handle to norm_y_axes_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    drawPlot(handles)
end

% --- Executes when selected object is changed in uipanel_norm_y.
function uipanel_norm_y_SelectionChangeFcn(hObject, ~, handles)
% hObject    handle to the selected object in uipanel_norm_y 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

    % show/hide norm_y_axes_popup depending on radiobutton choice
    switch get(hObject,'String')
        case 'Yes'
            set(handles.norm_y_axes_popup,'Visible','on');
        case 'No'
            set(handles.norm_y_axes_popup,'Visible','off');
    end
    drawPlot(handles)
end

% --- Executes when selected object is changed in uipanel_norm_x.
function uipanel_norm_x_SelectionChangeFcn(hObject, ~, handles)
% hObject    handle to the selected object in uipanel_norm_x 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
    
    % show/hide norm_y_axes_popup depending on radiobutton choice
    switch get(hObject,'String')
        case 'Yes'
            set(handles.norm_x_axes_popup,'Visible','on');
        case 'No'
            set(handles.norm_x_axes_popup,'Visible','off');
    end
    drawPlot(handles)
end

% --------------------------------------------------------------------
function LoadImageStackBar_Callback(hObject, ~, handles)
% hObject    handle to LoadImageStackBar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    [filename,pathname] = uigetfile({'*.edf';'*.img';'*.tif';'*.tiff'},'Select File','Multiselect','on',handles.Config.load_path);
    if isequal(filename,0) == 1
        return
    elseif iscell(filename) == 0
        filename = cellstr(filename);
    end
    handles.Config.load_path = pathname;
    
    % get necessary information on Image(number of pixels in each direction
    % and colordepth(int 8 16 32 64)
    prompt = {'Detector Dimension','ColorDepth'};
    dlg_title = 'Image specimens';
    num_lines = 1;
    def = {num2str(handles.Config.ImgDim),num2str(handles.Config.ImgCdepth)};
    specimens = inputdlg(prompt,dlg_title,num_lines,def);
    if isempty(specimens) == 1
       return 
    end
    
    
    dim = str2num(specimens{1});
    ColorDepth = str2num(specimens{2});
    [~,~,format] = fileparts(filename{1});
    format = format(2:end);
    
    % create the data
    h = waitbar(0,'loading...');
    n = length(filename);
    for i = 1:n
        disp(i)
        filename_tmp = [pathname filename{i}];
        [Img{i},~] = SoloImage.imageread(filename_tmp, format, dim, ColorDepth);
        ImagePlusRoiObjs(i) = ImagePlusRoi(Img{i},filename{i});
        waitbar(i/n) % show process
    end
    close(h)
    
    ImageStack = ImagePlusRoiStackClass(ImagePlusRoiObjs);
    
    % reset attributes from former imagestack
    handles = resetData(handles);
    
    handles.ImageStack = ImageStack;
    
    set_Popups(handles);
    setGuiStuff(handles);
    setColorSlider(handles);
    drawImage(handles);
    drawPlot(handles);
    
    handles.Config.ImgDim = dim;
    handles.Config.ImgCdepth = ColorDepth;

    % Update handles structure
    guidata(hObject, handles);
end

% --------------------------------------------------------------------
function ReloadImageStackBar_Callback(hObject, ~, handles)
% hObject    handle to ReloadImageStackBar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    [filename,pathname] = uigetfile({'*.mat'},'Reload ImageStack object','Multiselect','off',handles.Config.load_path);
    if isequal(filename,0) == 1
        return
    end
    handles.Config.load_path = pathname;
    filename = [pathname filename];
    
    ImageStackObj = ImagePlusRoiStackClass.ReloadImageStack(filename);
    % reset attributes from former imagestack
    handles = resetData(handles);
    
    handles.ImageStack = ImagePlusRoiStackClass(ImageStackObj);
    
    set_Popups(handles);
    setGuiStuff(handles);
    setColorSlider(handles);
    drawImage(handles);
    drawPlot(handles);
    
    % Update handles structure
    guidata(hObject, handles);
end

% --------------------------------------------------------------------
function SaveImageStackBar_Callback(hObject, ~, handles)
% hObject    handle to SaveImageStackBar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    %save the ImageStack
    [filename,pathname] = uiputfile({'*.mat'},'Save ImageStack object',handles.Config.safe_path);
    if isequal(filename,0) == 1
        return
    end
    handles.Config.safe_path = pathname;
    filename = [pathname filename];
            
    handles.ImageStack.saveImageStack(filename);

    % Update handles structure
    guidata(hObject, handles);
end

% --------------------------------------------------------------------
function SaveDataBar_Callback(hObject, ~, handles)
% hObject    handle to SaveDataBar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    [filename pathname] = uiputfile({'*.txt'},'Save as *.txt File',handles.Config.safe_path);

    if isequal(filename,0) == 1
        return
    end
    handles.Config.safe_path = pathname;
    
    filename = [pathname filename];
    
    liststr = handles.ImageStack.getCounterNames();
    
    [Counters,ok] = listdlg('PromptString','Select Counters to be written:',...
        'SelectionMode','multiple',...
        'ListString',liststr);
    
    if ok == 0 %no elements were choosen
        return
    end
    
    CounterNames{length(Counters)} = '';
    for i = 1:length(Counters)
        CounterNames{i} = cell2mat(liststr(Counters(i)));
    end
    
    handles.ImageStack.WriteCounters(CounterNames,filename)
    % Update handles structure
    guidata(hObject, handles);
end

% --------------------------------------------------------------------
function RoiColorBar_Callback(hObject, ~, handles)
% hObject    handle to RoiColorBar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    
    handles.Config.RoiColor = uisetcolor(handles.Config.RoiColor);
    
    drawImage(handles)
    % Update handles structure
    guidata(hObject, handles);
end

% --------------------------------------------------------------------
function BgColorBar_Callback(hObject, ~, handles)
% hObject    handle to BgColorBar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    
    handles.Config.BgColor = uisetcolor(handles.Config.BgColor);
    
    drawImage(handles)
    % Update handles structure
    guidata(hObject, handles);
end

% --- Outputs from this function are returned to the command line.
function varargout = ImageStack_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

%% only createFcns from here out on. Do not change

% --- Executes during object creation, after setting all properties.
function x_Axes_Popup_CreateFcn(hObject, ~, ~)
% hObject    handle to x_Axes_Popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

% --- Executes during object creation, after setting all properties.
function y_Axes_Popup_CreateFcn(hObject, ~, ~)
% hObject    handle to y_Axes_Popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

% --- Executes during object creation, after setting all properties.
function ColorSliderMax_CreateFcn(hObject, ~, ~)
% hObject    handle to ColorSliderMax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
end

% --- Executes during object creation, after setting all properties.
function img_scale_pop_up_CreateFcn(hObject, ~, ~)
% hObject    handle to img_scale_pop_up (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes during object creation, after setting all properties.
function Colormap_Popup_CreateFcn(hObject, ~, ~)
% hObject    handle to Colormap_Popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes during object creation, after setting all properties.
function norm_y_axes_popup_CreateFcn(hObject, ~, ~)
% hObject    handle to norm_y_axes_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes during object creation, after setting all properties.
function norm_x_axes_popup_CreateFcn(hObject, ~, ~)
% hObject    handle to norm_x_axes_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes during object creation, after setting all properties.
function ColorSliderMin_CreateFcn(hObject, ~, ~)
% hObject    handle to ColorSliderMin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
end

% --- Executes during object creation, after setting all properties.
function listboxFiles_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listboxFiles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
