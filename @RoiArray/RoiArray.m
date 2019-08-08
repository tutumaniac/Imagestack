classdef RoiArray < handle
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        RoiObjArray
    end
    
    methods
        function obj = RoiArray(RoiObjArray)
            if nargin~= 0
                if nargin == 1
                    obj.RoiObjArray = RoiObjArray;
                end
            end
        end
        
        function rmvRoi(obj,Number)
            %Einträge aus Array entfernen
            Anzahl = length(Number);
            
            for i = Anzahl:-1:1;
                obj.RoiObjArray(Number(i)) = [];
            end
        end
        
        function addRoi(obj,NewRoiObjArray)
            
            NumObj_alt = length(obj.RoiObjArray);
            NumObj_tmp = length(NewRoiObjArray);
            NumObj_neu = NumObj_alt + NumObj_tmp;
            
            obj.RoiObjArray(NumObj_alt+1:NumObj_neu) = NewRoiObjArray(1:NumObj_tmp);
        end
        
    end 
end