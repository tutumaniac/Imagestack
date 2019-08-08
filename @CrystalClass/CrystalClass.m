classdef CrystalClass < handle
    %UNTITLED4 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        a
        b
        c
        alpha
        beta
        gamma
    end
    
    methods 
        
        function obj = CrystalClass(a,b,c,alpha,beta,gamma)
            if nargin ~= 0
                obj.a = a;
                obj.b = b;
                obj.c = c;
                obj.alpha = alpha;
                obj.beta = beta;
                obj.gamma = gamma;
            end
        end
        
        function [real] = getRealSpaceVectors(obj)
            Gamma = obj.gamma*(pi/180);
            real.a = obj.a*[1;0;0];
            real.b = obj.b*[cos(Gamma);sin(Gamma);0];
            real.c = obj.c*[0;0;1];
        end
        
        function [rec] = getRecSpaceVectors(obj)
            real = getRealSpaceVectors(obj);
            Factor = 2*pi/dot(real.a,cross(real.b,real.c));
            rec.a = Factor*cross(real.b,real.c);
            rec.b = Factor*cross(real.c,real.a);
            rec.c = Factor*cross(real.a,real.b);
        end
        
        function CarToCrys = CartesianToCrystal(obj)
            Gamma = obj.gamma*(pi/180);
            CarToCrys = inv([obj.a, obj.b*cos(Gamma),0;0,obj.b*sin(Gamma),0; 0 0 obj.c]);
        end
        
        function CrysToCar = CrystalToCartesian(obj)
            CarToCrys = obj.CartesianToCrystal();
            CrysToCar = inv(CarToCrys);
        end
        
        function Area = getAreaSurfaceUnitCell(obj)
            real = obj.getRealSpaceVectors;
            Area = norm(cross(real.a,real.b));
            
%             % Area in m^2
%             Area = obj.a*obj.b*sin(obj.gamma)*10^-20;
        end
        
    end 
end