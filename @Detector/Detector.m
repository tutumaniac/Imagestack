classdef Detector < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % y-dimension of detector
        Dim_y
        % x-dimension of detector
        Dim_x
        % distance between detector and sample
        d_sample_det
        % coordinates of the central spot on the detector
        % (pixel that is hit when all angles of the diffractometer = 0)
        zero_y
        zero_x
        % pixel length in(m or something) of both detector directions
        size_y
        size_x
    end
    
    methods
        function obj = Detector(Dim_y,Dim_x,d_sample_det,zero_y,zero_x,size_y,size_x)
            if nargin ~= 0
                obj.Dim_y = Dim_y;
                obj.Dim_x = Dim_x;
                obj.d_sample_det = d_sample_det;
                obj.zero_y = zero_y;
                obj.zero_x = zero_x;
                obj.size_y = size_y;
                obj.size_x = size_x;
            end
        end
        
        function [Dist_x,Dist_y] = getDistance(obj) % only holds true for BM25 up to now
            % nach J. Appl. Cryst. (2013). 46, 1162–1170
            
            %Pixel des Detektors
            Pixel_x = 1:obj.Dim_x;
            Pixel_y = 1:obj.Dim_y;
            
            % relative Entfernung vom "Ursprungspixel"
            % up to now this is only true for ID_03
            dist_x = -((Pixel_x - obj.zero_x)*obj.size_x)/obj.d_sample_det;
            % not sure whether this is correct. Maybe dist_y = -dist_y;
            % however this is not that crucial if ur only aim is to
            % determine the structure factor of from one rocking curve
            dist_y = ((Pixel_y - obj.zero_y)*obj.size_y)/obj.d_sample_det;
            
            % Entfernungen von jedem Pixel bestimmen
            [Dist_x,Dist_y] = meshgrid(dist_x,dist_y);
            Dist_x = Dist_x';
            Dist_y = Dist_y';
        end
    end
    
end