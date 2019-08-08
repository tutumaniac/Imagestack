classdef ImagePlusRoi < SoloImage
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Peak
        Bg
    end
    
    methods
        function obj = ImagePlusRoi(Img,Name,RoiArrayObjPeak,RoiArrayObjBg)
            if nargin == 0
                super_args = {};
            elseif nargin > 0
                super_args{1} = Img;
                super_args{2} = Name;
            end
            obj = obj@SoloImage(super_args{:});
            
            if nargin ~= 0
                if nargin == 4
                    obj.Peak = RoiArrayObjPeak;
                    obj.Bg = RoiArrayObjBg;
                end
            end
        end
        
        function [Int,Error,N] = IntInRoi(obj,RoiType,RoiNumbers)
            % Roi needs to be of type cell: Roi{j}{i}
            % Roi{i} is the j-th Region of interest
            % Roi{i}{j}(1) is the x coordinate of one corner of i-th Roi
            % Roi{i}{j}(2) is the y coordinate of one corner of i-th Roi
            % Roi must be rectangular this means j = 4;
            % Int is cumulative intensity in all Rois
            % Error is statistical error of cumulative intensity in all Rois
            % N is the number of pixels in all Rois
            
            narginchk(2,3)
            % if no Roi is specified yet
            if isempty(obj.(RoiType)) == 1
                Int = 0;
                N = 0;
                Error = 0;
                return
            elseif nargin == 2
                RoiNumbers = 1:length(obj.(RoiType).RoiObjArray);
            end
            
            for i = 1:length(RoiNumbers)
                % all intensity in image 
                ImageMask = obj.(RoiType).RoiObjArray(RoiNumbers(i)).Roi_Mask.*obj.Img;
                
                Int(i) = sum(sum(ImageMask));
                ImageMask(ImageMask == 0) = [];
                N(i) = numel(ImageMask);
            end
            
            % total intensity
            Int = sum(Int);
            % (absolute) statistical error
            Error = sqrt(Int);
            
            % total number of pixels
            N = sum(N);
        end
        
        function [Int_sub,Error_sub] = substractBackground(obj)
            % get Int in Peak Roi(s)
            [Int_Peak,~,N_Peak] = obj.IntInRoi('Peak');
            % get Int in Bg Roi(s)
            [Int_Bg,~,N_Bg] = obj.IntInRoi('Bg');
            
            % cant divide by 0; this takes place if no Bg Roi is set
            if N_Bg == 0
               N_Bg = 1; 
            end
            
            Int_sub = Int_Peak - (N_Peak/N_Bg)*Int_Bg;
            Error_sub = sqrt(Int_Peak + ((N_Peak/N_Bg)*Int_Bg));
            
            % relativ Error of Intensity
            Error_sub = Error_sub/Int_sub;
        end
        
        function getRoi(obj,RoiType,RoiKind,RoiNumber,AxesHandle)
            if nargin == 4
               AxesHandle = gca; 
            end
            
            % create a new RoiArray if it is empty
            if isempty(obj.(RoiType)) == 1
                switch RoiKind
                    case 'RectRoi'
                        obj(1).(RoiType) = RoiArray(RectRoi(1));
                    case 'PolyRoi'
                        obj(1).(RoiType) = RoiArray(PolyRoi(1));
                end
            end
            
            %this applies otherwise
            % add as many (empty) rois as requested
            while RoiNumber > length(obj.(RoiType).RoiObjArray)
                switch RoiKind
                    case 'RectRoi'
                        obj.(RoiType).addRoi(RectRoi(1));
                    case 'PolyRoi'
                        obj.(RoiType).addRoi(PolyRoi(1));
                end
            end
            
            obj.(RoiType).RoiObjArray(RoiNumber).getRoi(AxesHandle);
                
        end
        
        function resetRoi(obj,RoiType)
            obj.(RoiType) = RoiArray.empty;
        end
        
        function setRoi(obj,RoiType,RoiArrayObj)
            % this is necessary due to 'strange' behavior concerning the
            % behaviour of the newpositioncallbacks of the rois
            RoiObjArray = RoiArrayObj.RoiObjArray;
            for i = 1:length(RoiObjArray)
                switch class(RoiObjArray(i))
                    case 'RectRoi'
                        RoiObjArray_tmp(i) = RectRoi(1,{RoiObjArray(i).Coordinates},{RoiObjArray(i).Roi_Mask});
                    case 'PolyRoi'
                        RoiObjArray_tmp(i) = PolyRoi(1,{RoiObjArray(i).Coordinates},{RoiObjArray(i).Roi_Mask});
                end
            end
            
            RoiObjArray = RoiObjArray_tmp;
            RoiArrayObj = RoiArray(RoiObjArray);
            obj.(RoiType) = RoiArrayObj;
        end
        
        function [Min,Max] = getExtrema(obj)
            [Min,Max] = getExtrema@SoloImage(obj);
        end
        
        function drawImage(obj,varargin)
            minargs = 1;
            maxargs = 13;
            narginchk(minargs, maxargs)
            
            [Min,Max] = getExtrema(obj);
            % default properties
            props.Colormap = 'jet';
            props.AxesHandle = gca;
            props.caxis = [Min,Max];
            props.PeakColor = 'm';
            props.BgColor = 'k';
            props.scale = 'Lin';
            Properties = fieldnames(props);
            
            for i = 1:length(varargin)
                for j = 1:length(Properties)
                    if strcmp(varargin{i},Properties{j}) == 1
                       props.(varargin{i}) = varargin{i+1}; 
                    end
                end
            end
                      
            drawImage@SoloImage(obj,...
                'AxesHandle',props.AxesHandle,'Colormap',props.Colormap,...
                'scale',props.scale,'caxis',props.caxis);
         
            if isempty(obj.Peak) == 0
                for i = 1:length(obj.Peak.RoiObjArray)
                    obj.Peak.RoiObjArray(i).drawRoi(props.AxesHandle,props.PeakColor)
                end
            end
            if isempty(obj.Bg) == 0
                for i = 1:length(obj.Bg.RoiObjArray)
                    obj.Bg.RoiObjArray(i).drawRoi(props.AxesHandle,props.BgColor)
                end
            end
        end
        
        function [Int,Fehler,bounds] = FindPeak(obj,RoiType,RoiNumber)
            Roi = obj.(RoiType).RoiObjArray(RoiNumber);
            [Int,Fehler,bounds] = FindPeak@SoloImage(obj,Roi);
        end
    end
    
end