classdef ImageClass < SoloImage
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        DiffractometerObj = SixCircleDiff.empty
        DetectorObj = Detector.empty
        CrystalClassObj = CrystalClass.empty
        SampleObj
        norm
        NormFaktor
    end
    
    methods
        function obj = ImageClass(Img,Name,DiffractometerObj,DetectorObj,CrystalClassObj,SampleObj,norm,NormFaktor)
            if nargin == 0
                super_args = {};
            elseif nargin == 8
                super_args{1} = Img;
                super_args{2} = Name;
            end
            obj = obj@SoloImage(super_args{:});
            if nargin ~= 0
                obj.DiffractometerObj = DiffractometerObj;
                obj.DetectorObj = DetectorObj;
                obj.CrystalClassObj = CrystalClassObj;
                obj.SampleObj = SampleObj;
                obj.norm = norm;
                obj.NormFaktor  = NormFaktor;
            end
        end
        
        function setCrystalClassObj(obj,NewCrystalClassObj)
            obj.CrystalClass = NewCrystalClassObj;
        end
        
        function setDiffractometerObj(obj,NewDiffractometerObj)
            obj.DiffractometerObj = NewDiffractometerObj;
        end
        
        function setDetectorObj(obj,NewDetectorObj)
            obj.DetectorObj = NewDetectorObj;
        end
        
        function setNormFaktor(obj,NewNormFaktor)
            obj.NormFaktor = NewNormFaktor;
        end
        
        function setNorm(obj,NewNorm)
           obj.norm = NewNorm; 
        end
        
        function [H,K,L] = getRSM(obj)
            % determine the reciprocal space map for the image
            [Dist_x,Dist_y] = obj.DetectorObj.getDistance();
            [n_x,m_x] = size(Dist_x);
            dist_z = reshape(Dist_x,1,[]);
            dist_x = reshape(Dist_y,1,[]);
            HKL = obj.DiffractometerObj.getQSurf(dist_x,dist_z);
            
            % convert to meshgrid form
            H = reshape(squeeze(HKL(1,:)),[n_x,m_x]);
            K = reshape(squeeze(HKL(2,:)),[n_x,m_x]);
            L = reshape(squeeze(HKL(3,:)),[n_x,m_x]);
        end
        
        function intergrateImage(obj,roi)
            
            x_min = roi(1);
            x_max = roi(2);
            y_min = roi(3);
            y_max = roi(4);
            
            [H,K,L] = obj.getRSM;
            
            H = H(y_min:y_max,x_min:x_max);
            K = K(y_min:y_max,x_min:x_max);
            L = L(y_min:y_max,x_min:x_max);
            Int = obj.Img(y_min:y_max,x_min:x_max);
        end
        
        
        
        function [h,k,l] = getPosHKL(obj)
            % determine the h,k,l values for the central spot of detektor
             HKL = obj.DiffractometerObj.getQSurf();
             h = HKL(1);
             k = HKL(2);
             l = HKL(3);
        end
        %         function [F_corr,Error_corr] = substractBackground(obj)
%             
%             [Int_sub,Error_sub] = substractBackground@ImagePlusRoi(obj);
%             % determine area of surface unit cell
%             Area = obj.CrystalClassObj.getAreaSurfaceUnitCell();
%             
%             Int_corr = obj.DiffractometerObj.correctIntensity(Int_sub,obj.NormFaktor,obj.norm,Area,'stationary');
%             
%             F_corr = sqrt(Int_corr);
%             % relativ Error of structure Factor
%             Error_corr = 0.5*Error_sub;
%             
%         end
        
        function plotRSM(obj,AxesHandle)
            if nargin == 1
                AxesHandle = gca;
            end
            
            [H,K,L] = obj.getRSM();
            p = surf(AxesHandle,H,K,L,obj.Img);
            set(p,'LineStyle','none')
        end
        
        function [Int_corr,Int_error] = correctImage(obj)
            
            % determine area of surface unit cell
            Area = obj.CrystalClassObj.getAreaSurfaceUnitCell();
            % convert from Angstrom to meter
            Area = Area*10^-20;
            % Area of the sample
            Sample_Area = obj.SampleObj.getSampleArea;
            
            Int = obj.Img;
            %determine relativ statistical error
            Int_error = sqrt(Int);
            Int_error = Int_error.*(Int.^-1);
            % 0/0 = NaN
            Int_error(isnan(Int_error) == 1) = 0;
            
            Int_corr = obj.DiffractometerObj.correctIntensity(Int,obj.NormFaktor,obj.norm,Area,'reciprocal',Sample_Area);
        end
       
    end
    
    methods(Static)
        
        function images = getImage(energy,ph,specular,NormFaktor,filename)
            % create a stack of images
            if nargin == 4
                filename = Image.uigetfile({'*.edf';'*.img'},'Multiselect','on');
            end
            
            [~,~,ext] = fileparts(filename{1});
            switch ext
                case '.edf'
                    for i = 1:length(filename)
                        disp(i)
                        images(i) = ImageClass.ImportEdf(energy,ph,specular,NormFaktor,filename{i});
                    end
                case '.img'
                    images = Image.ImportSLS(filename);
            end        
        end
        
        function [obj] = ImportEdf(energy,ph,specular,NormFaktor,filename)
            % load Edf-Files(ESRF) and get all sorts of Information
            
            fid = fopen(filename);
            tline = 'line';
            
            while strcmp(tline(1),' ') ~= 1
                tline = fgetl(fid);
                
                if strfind(tline,'Dim_1')
                    %get first dimension of image
                    tmp = textscan(tline,'%s %s %f %s');
                    img.Dim_1 = tmp{3};
                end
                
                if strfind(tline,'Dim_2')
                    %get second dimension of image
                    tmp = textscan(tline,'%s %s %f %s');
                    img.Dim_2 = tmp{3};
                end
                
                if strfind(tline,'d_sample_det')
                    %get second dimension of image
                    tmp = textscan(tline,'%s %s %f %s');
                    img.d_sample_det = tmp{3};
                end
                
                if strfind(tline,'pixel_zero_y')
                    %get the zero pixel in first dimension
                    tmp = textscan(tline,'%s %s %f %s');
                    img.pixel_zero_y = tmp{3};
                end
                
                if strfind(tline,'pixel_zero_x')
                    %get the zero pixel in second dimension
                    tmp = textscan(tline,'%s %s %f %s');
                    img.pixel_zero_x = tmp{3};
                end
                
                if strfind(tline,'pixel_size_y')
                    %get pixelsize in first dimension
                    tmp = textscan(tline,'%s %s %f %s');
                    img.pixel_size_y = tmp{3};
                end
                
                if strfind(tline,'pixel_size_x')
                    %get pixelsize in second dimension
                    tmp = textscan(tline,'%s %s %f %s');
                    img.pixel_size_x = tmp{3};
                end
                
                if strfind(tline,'sample_pos')
                    %get the lattice parameters and angles
                    tmp = textscan(tline,'%s %s %f %f %f %f %f %f %s');
                    img.a = tmp{3};
                    img.b = tmp{4};
                    img.c = tmp{5};
                    img.alpha = tmp{6};
                    img.beta = tmp{7};
                    img.gamma = tmp{8};
                end
                
                if strfind(tline,'UB_pos')
                    %get UB matrix
                    tmp = textscan(tline,'%s %s %f %f %f %f %f %f %f %f %f %s');
                    UB_Mat = tmp(3:11);
                    img.UB = reshape(cell2mat(UB_Mat),3,3)';
                end
                
                if strfind(tline,'counter_pos')
                    %get counter values
                    i = 0;
                    tmp = tline;
                    while isempty(tmp) ~=1
                        i = i + 1;
                        [counter_pos{i}, tmp] = strtok(tmp);
                    end
                    counter_pos = counter_pos(3:end-1);
                    
                end

                if strfind(tline,'counter_mne')
                    %get counter names
                    i = 0;
                    tmp = tline;
                    while isempty(tmp) ~=1
                        i = i + 1;
                        [counter_mne{i}, tmp] = strtok(tmp);
                    end
                    counter_mne = counter_mne(3:end-1);
                end
                
                if strfind(tline,'motor_pos')
                    %get counter values
                    i = 0;
                    tmp = tline;
                    while isempty(tmp) ~=1
                        i = i + 1;
                        [motor_pos{i}, tmp] = strtok(tmp);
                    end
                    motor_pos = motor_pos(3:end-1);
                    
                end
                
                if strfind(tline,'motor_mne')
                    %get counter names
                    i = 0;
                    tmp = tline;
                    while isempty(tmp) ~=1
                        i = i + 1;
                        [motor_mne{i}, tmp] = strtok(tmp);
                    end
                    motor_mne = motor_mne(3:end-1);
                end
                
            end
            
            for i = 1:length(motor_pos)
                img.(motor_mne{i}) = str2double(motor_pos{i});
            end
            
            for i = 1:length(counter_pos)
                img.(counter_mne{i}) = str2double(counter_pos{i});
            end
            
            % rename motors so they fit to the Vlieg paper
            img.gam = img.gamcnt;
            img.del = img.delcnt;
            img.om = img.thcnt;
            img.alp = img.mucnt;
            
            % set normalization Factor
            img.norm = (img.mon*img.transm)^-1;
            
            img.Img = Image.loadImage(fid,img.Dim_1,img.Dim_2,'int32');
            fclose(fid);
            
            DiffractometerObj = SixCircleDiff(img.alp,img.del,img.gam,img.om,img.chi,img.phi,ph,specular,energy,img.UB);
            CrystalClassObj = CrystalClass(img.a,img.b,img.c,img.alpha,img.beta,img.gamma);
            DetectorObj = Detector(img.Dim_1,img.Dim_2,img.d_sample_det,img.pixel_zero_y,...
                img.pixel_zero_x,img.pixel_size_y,img.pixel_size_x);
            obj = ImageClass(img.Img,DiffractometerObj,DetectorObj,CrystalClassObj,img.norm,NormFaktor);
        end
    end
end

