classdef ImagePlusRoiStackClass < handle
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        ImageArray = ImagePlusRoi.empty;
        counters
    end
    
    methods
        function obj = ImagePlusRoiStackClass(ImageArray)
            if nargin ~= 0
                if isa(ImageArray,'ImagePlusRoiStackClass')
                    obj = ImageArray;
                    return
                end
                obj.ImageArray = ImageArray;
                obj.setCounters()
            end
        end
        
        function setCounters(obj)
            obj.counters.N = 1:length(obj.ImageArray);
            obj.counters.IntSub = zeros(1,length(obj.ImageArray));
            obj.counters.ErrorSub = zeros(1,length(obj.ImageArray));
        end
        
        function removeImage(obj,ImgNumbers)
            for i = length(ImgNumbers):-1:1
                obj.ImageArray(ImgNumbers(i)) = [];
                Names = obj.getCounterNames();
                for j = 1:length(Names)
                    obj.counters.(Names{j})(ImgNumbers(i)) = [];
                end
            end
        end
        
        function Names = getImageNames(obj)
            Names = {obj.ImageArray.Name};
        end
        
        function addCounters(obj,Counters)
            FieldNames = fieldnames(Counters);
            for i = 1:length(FieldNames)
                FieldSize = size(Counters.(FieldNames{i}));
                
                boolean = gt(FieldSize,1);% which dimension are greater than 1
                if isequal(boolean,[1 1]) || size(FieldSize,2) > 2
                    error('Wrong Input Format. Counter %s needs to be a vector',FieldNames{i})
                elseif isequal(boolean,[1 0])
                    obj.counters.(FieldNames{i}) = Counters.(FieldNames{i})';
                else
                    obj.counters.(FieldNames{i}) = Counters.(FieldNames{i});
                end 
            end
        end
        
        function resetCounters(obj)
            FieldNames = fieldnames(obj.counters);
            for i = 1:length(FieldNames)
                if strcmp(FieldNames{i},{'N','IntSub','ErrorSub'}) == 0
                    obj.counters = rmfield(obj.counters.(FieldNames{i}));
                end
            end
            
        end
        
        function getStructureFactor(obj)
            
            for i = 1:length(obj.ImageArray)
                [Int_sub(i),Error_sub(i)] = obj.ImageArray(i).substractBackground();
            end
            obj.counters.IntSub = Int_sub;
            obj.counters.ErrorSub = Error_sub;
        end
        
        function Names = getCounterNames(obj)
            Names = fieldnames(obj.counters);
        end
        
        function plotCounters(obj,x_Axes_Name,y_Axes_Name,varargin)
            %x_scale, y_scale, x_norm_Name, y_norm_Name
            
            %check if proper number of inputs is provided
            narginchk(3,13)
            
            % default properties % call function just like u would call
            % plot or image with the property names below
            props.AxesHandle = gca;
            props.x_scale = 'Lin';
            props.y_scale = 'Lin';
            props.x_norm_Name = '';
            props.y_norm_Name = '';
            Properties = fieldnames(props);
            
            for i = 1:length(varargin)
                for j = 1:length(Properties)
                    if strcmpi(varargin{i},Properties{j}) == 1
                        props.(varargin{i}) = varargin{i+1};
                    end
                end
            end
            
            x_Axes_Counter = obj.counters.(x_Axes_Name);
            y_Axes_Counter = obj.counters.(y_Axes_Name);
            
            % normalize if name of counters is provided
            if isempty(props.x_norm_Name) == 0
                x_norm = obj.counters.(props.x_norm_Name);
                x_Axes_Counter = x_Axes_Counter.*((x_norm).^-1);
            end
            
            % normalize if name of counters is provided
            if isempty(props.y_norm_Name) == 0
                y_norm = obj.counters.(props.y_norm_Name);
                y_Axes_Counter = y_Axes_Counter.*((y_norm).^-1);
            end
            
            % find out how to plot the counters
            boolean = strcmpi({props.x_scale,props.y_scale},'Lin');
            
            if isequal(boolean,[1 1])
                plot(props.AxesHandle,x_Axes_Counter,y_Axes_Counter)
            elseif isequal(boolean,[1 0])
                semilogy(props.AxesHandle,x_Axes_Counter,y_Axes_Counter)
            elseif isequal(boolean,[0 1])
                semilogx(props.AxesHandle,x_Axes_Counter,y_Axes_Counter)
            elseif isequal(boolean,[0 0])
                loglog(props.AxesHandle,x_Axes_Counter,y_Axes_Counter)
            end
            
            xlabel(props.AxesHandle,x_Axes_Name)
            ylabel(props.AxesHandle,y_Axes_Name)
%             % if structure Factor on y-axis display errorbars aswell
%             if strcmp(x_Axes_Name,'IntSub') == 0 && strcmp(y_Axes_Name,'IntSub') == 1
%                 Abs_Error = obj.counters.ErrorSub.*y_Axes_Counter;
%                 errorbar(x_Axes_Counter,y_Axes_Counter,Abs_Error,...
%                     'Parent',AxesHandle)
%             else
%                 plot(AxesHandle,x_Axes_Counter,y_Axes_Counter)
%             end
            

        end
        
        function WriteCounters(obj,CounterNames,filename)
            % write Counters to a text file
            if nargin == 2
                [filename pathname] = uiputfile();
                filename = [pathname filename];
            end
            
            % create CellStructure of Counters to be written into File
            Cellstruct{length(obj.counters.(CounterNames{1}))+1,length(CounterNames)} = ' ';
            Cellstruct(1,:) = CounterNames;
            
            for i = 1:length(CounterNames)
                Cellstruct(2:end,i) = num2cell(obj.counters.(CounterNames{i}));
            end
            
            ImagePlusRoiStackClass.FileWrite(filename,Cellstruct)
        end
        
        function saveImageStack(obj,filename)
            if nargin == 1
                [filename,pathname] = uiputfile({'*.mat'},'Save ImageStack object');
                filename = [pathname filename];
            end
            save(filename,'obj')
        end
    end
    
    methods (Static)
        function FileWrite(filename,CellStruct)
            % Arrange urData as a Cellstructure
            [nrow,ncol] = size(CellStruct);
            
            fid = fopen(filename,'w');
            % write Data
            for j = 1:nrow % change row
                for i = 1:ncol %write row first, if input is string write a string if it is numeric write a number
                    if ischar(CellStruct{j,i}) == 1
                        type = '%s';
                    elseif isnumeric(CellStruct{j,i}) == 1
                        type = '%f';
                    end
                    
                    if i == ncol
                        fprintf(fid,[type '\n'],CellStruct{j,i});
                        continue
                    end
                    fprintf(fid,[type '\t'],CellStruct{j,i});
                end
            end
            fclose(fid);
        end
        
        function ImageStackObj = ReloadImageStack(filename)
            if nargin == 0
                [filename,pathname] = uigetfile({'*.mat'},'Save ImageStack object');
                filename = [pathname filename];
            end
            
            load(filename);% always called obj
            ImageStackObj = obj;
        end
    end
    
end

