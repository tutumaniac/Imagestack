classdef RectRoi < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here

    properties
        Coordinates
        Roi_Mask
        RoiObj
    end
    
    methods
        function obj = RectRoi(n,Coordinates,Roi_Mask)
            if nargin ~= 0
                obj(n) = RectRoi;
                if nargin == 1
                    for i = 1:n
                        obj(i) = RectRoi;
                    end
                elseif nargin == 3
                    for i = 1:n
                        obj(i).Coordinates = Coordinates{i};
                        obj(i).Roi_Mask = Roi_Mask{i};
                    end
                end      
            end
        end
        
        function getRoi(obj,AxesHandle)
            % function used to set the roi
            if nargin == 1
                AxesHandle = gca;
            end
            
            obj.RoiObj = imrect(AxesHandle);
            obj.getMaskAndPos();
            delete(obj.RoiObj)
        end
        
        function getMaskAndPos(obj)
            obj.Roi_Mask = obj.RoiObj.createMask;
            obj.Coordinates = obj.RoiObj.getPosition;
        end
            
        
        function drawRoi(obj,AxesHandle,Color)
            if nargin == 1
                Color = 'm';
                AxesHandle = gca;
            elseif nargin == 2
                Color = 'm';
            end

            obj.RoiObj = imrect(AxesHandle,obj.Coordinates);
            obj.RoiObj.setColor(Color);
            
            % get thinner lines
            tmp = findobj(obj.RoiObj,'Type','Line');
            
            for i = 1:length(tmp)
                set(tmp(i),'Linewidth',0.5);
            end
            
            obj.RoiObj.addNewPositionCallback(@(src,evnt)obj.getMaskAndPos());       
        end
    end
end