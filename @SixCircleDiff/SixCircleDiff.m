classdef SixCircleDiff < handle
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lambda
        UB
        % alp,del,gam,om,nu are the angles of the Diffractometer as specified in
        % J. AppL. Cryst. (2011). 44, 73-83
        alp
        del
        gam
        om
        chi
        phi
        % fraction of horizontal polarization
        ph
        % 'specular';'non-specular';'reflectivity'
        scantype
    end
    
    properties (Constant,Hidden)
        % see J. AppL. Cryst. (2011). 44, 73-83
        Alpha = @(alp)...
            [1 0 0;...
            0 cos(alp) -sin(alp);...
            0 sin(alp) cos(alp)];
        Omega = @(om)...
            [cos(om) sin(om) 0;...
            -sin(om) cos(om) 0;...
            0 0 1];
        Chi =@(chi)...
            [cos(chi) 0 sin(chi);...
            0 1 0;...Circ
            -sin(chi) 0 cos(chi)];
        Phi =@(phi)...
            [cos(phi) sin(phi) 0;...
            -sin(phi) cos(phi) 0;...
            0 0 1];
        Delta = @(del)...
            [cos(del) sin(del) 0;...
            -sin(del) cos(del) 0;...
            0 0 1];
        Gamma = @(gam)...
            [1 0 0;...
            0 cos(gam) -sin(gam);...
            0 sin(gam) cos(gam)];
        Nu = @(nu)...
            [cos(nu) 0 sin(nu);...
            0 1 0;...
            -sin(nu) 0 cos(nu)];
    end
    methods
        function obj = SixCircleDiff(alp,del,gam,om,chi,phi,ph,scantype,energy,UB)
            if nargin ~= 0
                %UB needs to be supplied in Angstroms
                obj.alp = alp;
                obj.del = del;
                obj.gam = gam;
                obj.om = om;
                obj.chi = chi;
                obj.phi = phi;
                obj.ph = ph;
                obj.UB = UB;
                obj.scantype = scantype;
                obj.setLambda(energy);
            end
        end
        
        function setLambda(obj,energy)
            %wavelength in Angstrom because UB matrix is in angstrom
            h = 6.62606957*10^-34;
            c = 2.99792458*10^8;
            e = 1.602176565*10^-19;
            Energy = energy*e;
            
            obj.lambda = (10^10)*((h*c)/Energy);
        end
        
        function [HKL] = getQSurf(obj,dist_x,dist_z)
            % J. Appl. Cryst. (2013). 46, 1162–1170 + % J. A.ppL Cryst. (1993). 26, 706-716
            % dist_x is in delta and dist_z is in gamma direction for this set up
            
            if nargin == 1
                dist_x = 0;
                dist_z = 0;
            end
            % get Matrices for all Motors and the UB-Matrix
            UB_1 = obj.UB^-1;
            Phi_1 = obj.Phi(obj.phi*(pi/180))^-1;
            Chi_1 = obj.Chi(obj.chi*(pi/180))^-1;
            Omega_1 = obj.Omega(obj.om*(pi/180))^-1;
            Alpha_1 = obj.Alpha(obj.alp*(pi/180))^-1;
            Delta_ = obj.Delta(obj.del*(pi/180));
            Gamma_ = obj.Gamma(obj.gam*(pi/180));
            
            % incoming X-Ray in laboratory frame
            K_in_lab = [0;1;0]*((2*pi)/obj.lambda);
            % norm of the incidence vector in 1/m
            norm_K_in = norm(K_in_lab);
            % create an incidence vector for every pixel on the detector
            K_in_lab = repmat(K_in_lab,1,length(dist_x));
            % transform the incoming vector to the alpha coordinate system
            K_in_alp = Alpha_1*K_in_lab;
            
            % out-going X-Ray in Detector frame, each colomn represents the
            % out-going vector for one particular pixel of the detector
            K_out_det = zeros(3,length(dist_x));
            K_out_det(1,:) = dist_x;
            K_out_det(2,:) = 1;
            K_out_det(3,:) = dist_z;
            % determine the norm for each out-going vector
            norm_K_out = sqrt(sum(abs(K_out_det).^2,1));
            % rescale K_out to the same length as the incoming vector in 1/m
            % this is necessary because the vectors were stretched to get the
            % different directions for each pixel this is elastic scattering
            for i = 1:size(K_out_det,1)
                K_out_det(i,:) = norm_K_in*(K_out_det(i,:)./norm_K_out);
            end
            % transform K_out to the alpha coordinate system
            K_out_alp = Delta_*Gamma_*K_out_det;
            % transform the scattering vector to surface coordinates
            HKL = UB_1*Phi_1*Chi_1*Omega_1*(K_out_alp - K_in_alp);
        end
        
        function Int_corr = correctIntensity(obj,Int_raw,NormFaktor,Norm,Area_Surf,Type,Sample_Area)
            % correctIntensity corrects the Intensity measured by
            % SixCirclediffratometer
            % Int_raw: is the uncorrected intensity

            % Norm: Is the correctionfactor for attenuation and ring current
            % NormFaktor: Is an 'artificial' Factor to scale the Data(e.g. for very small)
            % intensities, so numerical error is negligible
            % Area_surf is the area of the surface unit cell(e.g. a*b for
            % orthogonal vectors) in [m^2]
            
            Alp = obj.alp*(pi/180);
            Del = obj.del*(pi/180);
            Gam = obj.gam*(pi/180);

            
            % provide lambda in 1/m
            Lambda = obj.lambda*10^(-10);
            
            % classical electron radius
            r_e = 2.8179403267*10^(-15);
            % polarization factor
            P = SixCircleDiff.PolarisationFactor(Alp,Del,Gam,obj.ph);
            
            switch Type
                case 'stationary'
                    switch obj.scantype
                        case 'non-specular'
                            Lor = SixCircleDiff.LorentzianFactor(Gam);
                            Int_corr = Sample_Area^-1*(r_e^(-2))*(Area_Surf.^2).*(Lambda.^(-2)).*...
                                NormFaktor.*Norm.*Int_raw.*((P.*Lor).^-1);
                        case 'specular'
                            Lor = SixCircleDiff.LorentzianFactor(Alp);
                            Int_corr = Sample_Area^-1*(r_e^(-2))*(Area_Surf.^2).*(Lambda.^(-2)).*...
                                NormFaktor.*Norm.*Int_raw.*((P.*Lor).^-1);
                        case 'reflectivity'
                            Int_corr = NormFaktor.*Norm.*Int_raw.*((P).^-1);
                    end
                    
                case 'reciprocal'
                    Int_corr = Sample_Area^-1*(r_e^(-2))*Area_Surf*...
                        NormFaktor.*Norm.*Int_raw.*(P).^-1;
            end
            
        end
    end
    
    methods (Static)
        
        function Lor = LorentzianFactor(beta_out) % beta_out = gamma for vertical and om for horizontal
            % Correction for LorentzianFachtor
            Lor = sin(beta_out).^-1;
        end
        
        function P = PolarisationFactor(alp,del,gam,ph) % this nomenclature only holds true for vertical geometry
            % Correction for PolarisationFactor
            Pver = 1 - (sin(del).*cos(gam)).^2;
            Phor = 1 - (sin(alp).*cos(del).*cos(gam) + cos(alp).*sin(gam)).^2;
            P = ph*Phor + (1-ph)*Pver;
        end
        
        function AA = ActiveArea(angle) % only needs to be considered for small slits which is generally not the case
            AA = sin(angle).^-1;
        end
        
    end
    
end