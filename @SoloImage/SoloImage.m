classdef SoloImage < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Img
        Name
    end
    
    methods
        function obj = SoloImage(Img,Name)
            if nargin ~= 0           
                obj.Img = Img;
                obj.Name = Name;
            end
        end
        
        function FigHandle = drawImage(obj,varargin)
            
            % draw Image
            % check for valid number of arguments 
            minargs = 1;
            maxargs = 9;
            narginchk(minargs, maxargs)
            
            [Min,Max] = getExtrema(obj);
            % default properties % call function just like u would call
            % plot or image with the property names below
            props.Colormap = 'jet';
            props.AxesHandle = gca;
            props.caxis = [Min,Max];
            props.scale = 'Lin';
            Properties = fieldnames(props);
            
            for i = 1:length(varargin)
                for j = 1:length(Properties)
                    if strcmp(varargin{i},Properties{j}) == 1
                        props.(varargin{i}) = varargin{i+1};
                    end
                end
            end
            % parse Inputs
            SoloImage.parseDrawInputs(props);
            
            axes(props.AxesHandle)
            colormap(props.Colormap)

            if strcmpi('lin',props.scale) == 1
                    FigHandle = imagesc(obj.Img);
                    caxis(props.caxis)
            elseif strcmpi('log10',props.scale) == 1
                    props.caxis(props.caxis < 1) = 1;
                    Int_tmp = obj.Img;
                    Int_tmp(Int_tmp < 1) = 1;
                    FigHandle = imagesc(log10(Int_tmp));
                    caxis(log10(props.caxis))
            elseif strcmpi('Ln',props.scale) == 1
                    props.caxis(props.caxis < 1) = 1;
                    Int_tmp = obj.Img;
                    Int_tmp(Int_tmp < 1) = 1;
                    FigHandle = imagesc(log(Int_tmp));
                    caxis(log(props.caxis))
            end
            
        end
        
        function [Min,Max] = getExtrema(obj)
            % get the minimum and the maximum intensity values of Img Matrix
            Min = min(min(obj.Img));
            Max = max(max(obj.Img));
        end
        
        function [Int,Fehler,bounds] = FindPeak(obj,Roi)
           [Int,Fehler,bounds,~] = SkewnessSeed(obj.Img,Roi);
        end
        
    end
    
    methods (Static)
        
        function [ScaleProperties,ColormapProperties] = parseDrawInputs(props)
            ScaleProperties = {'Lin','Log10','Ln'};
            ColormapProperties = {'jet','hsv','hot','cool','spring','summer',...
                'autumn','winter','gray','bone','copper','pink','lines'};
            if nargin == 0
               return 
            end
            
            if sum(strcmpi(props.scale,ScaleProperties)) ~= 1
                format = '';
                for k = 1:length(ScaleProperties)
                    format = [format ' %s'];
                end
                error(['proper properties: ' format],ScaleProperties{:})
            end
            if sum(strcmpi(props.Colormap,ColormapProperties)) ~= 1
                format = '';
                for k = 1:length(ColormapProperties)
                    format = [format ' %s'];
                end
                error(['proper properties: ' format],ScaleProperties{:})
            end
        end
        
        function [Im, header] = imageread(filename, format, dim, colorDepth)
            % IMAGEREAD - Reads an image (img, tif or tiff, ff, edf)
            %
            %   [Im, <header>] = imageread(filename, format, dim, <colorDepth>)
            %
            %   Im         : Image matrix of dimension dim as read from file.
            %   header     : Header data for edf and tif formats, returned as a string
            %                array.
            %   filename   : Filename (+ path (absolute or relative)) of the file to
            %                to be read as string
            %   format     : 'img'  - binaries of the .img format
            %                'tif'  - tif format with extension .tif
            %                'tiff' - tif format with extension .tiff
            %                'ff'   - tvx flatfield tif format (= float tif)
            %                         with extension .tif
            %                'edf'  - edf: ESRF data format as .edf
            %   dim        : Matrix dimension as vector, e.g. dim = [xdim, ydim]
            %   colorDepth : Color-depth of the .img file in number of bits
            %                (default is 32 bit for PILATUS 2 images)
            %                Values can be 8, 16, 32, or 64 for integer arrays
            %                (e.g. 16 for a 16 bit PILATUS 1 image),
            %                or use -1 if you want to load floating points of format
            %                'double', e.g. if you want to load an image that is
            %                already flatfield corrected.
            %
            %  <argument> depicts an optional argument.
            
            %==========================================================================
            %
            % FUNCTION: imageread.m
            %           ===========
            %
            % $Date: 2014/07/02 13:39:46 $
            % $Author: herger $
            % $Revision: 1.10 $
            % $Source: /import/cvs/X/PILATUS/App/lib/X_PILATUS_Matlab/imageread.m,v $
            % $Tag: $
            %
            %
            % <IMAGEREAD> - Reads an image (img, tif or tiff, ff)
            %
            % Author(s):            R. Herger (RH)
            % Co-author(s):         C.M. Schlepuetz (CS)
            %                       S.A. Pauli (SP)
            % Address:              Surface Diffraction Station
            %                       Materials Science Beamline X04SA
            %                       Swiss Light Source (SLS)
            %                       Paul Scherrer Institut
            %                       CH - 5232 Villigen PSI
            % Created:              2005/06/23
            %
            % Change Log:
            % -----------
            %
            % 2014/07/02 (FT)
            % - header of edf files is obtained differently now and should
            %   suit more .edf files
            % 2005/07/05 (RH):
            % - output argument no longer optional
            %
            % 2005/11/07 (CS):
            % - set default color depth for .img files to 32 bit, added optional
            %   argument 'colorDepth' to read also images with different color depths.
            %
            % 2006/02/17 (SP):
            % - 32bit tif files are readable as well now.
            %
            % 2006/02/20 (RH):
            % - changed the colorDepth to unsigned integers.
            % - imageread can also handle data of type double.
            %
            % 2006/10/17 (RH):
            % - edf format can now also be read.
            % - header for tif and edf are now returned as string array.
            % - compatible for extensions .tif or .tiff
            %
            % 2006/11/30 (CS):
            % - included error check whether the number of elements read from file are
            %   equal to the number of elements requested (=prod(dim)).
            %
            % 2006/12/11 (RH)
            % - added cvs tag information for first release
            
            %==========================================================================
            %  Main function - <imageread>
            %                  ===========
            
            %----------------------
            % check input arguments
            
            % are there 3 input arguments?
            narginchk(3, 4)
            
            % is filename of type string?
            if(~ischar(filename))
                error(strcat('Invalid input for ''filename'' in function imageread.\n', ...
                    'Use ''help imageread'' for further information.'), ...
                    '');
            end
            
            % is format img, tif, tiff, ff or edf?
            
            if ((strcmpi(format,'img') | strcmpi(format,'tif') | ...
                    strcmpi(format,'tiff') | strcmpi(format,'ff') | ...
                    strcmpi(format,'edf')) ~= 1)
                error(strcat('Invalid input for ''format'' in function imageread.\n', ...
                    'Use ''help imageread'' for further information.'), ...
                    '');
            end
            
            % is dim a vector of size [1 2]?
            if (~isequal(size(dim), [1 2]))
                error(strcat('Invalid input for ''dim'' in function imageread.\n', ...
                    'Use ''help imageread'' for further information.'), ...
                    '');
            end
            
            % is colorDepth equal to 8, 16, 32, or 64?
            if (nargin < 4)
                colorDepth = 32;
            end;
            if (colorDepth ~= 8 && colorDepth ~= 16 && ...
                    colorDepth ~= 32 && colorDepth ~= 64 && ...
                    colorDepth ~= -1)
                error(strcat('Invalid input for ''colorDepth'' in function imageread.', ...
                    '\nUse ''help imageread'' for further information.'), ...
                    '');
            end;
            
            if (colorDepth == -1)
                colorDepthFormat = 'double';
            else
                switch colorDepth
                    case 8
                        colorDepthFormat = 'uint8';
                    case 16
                        colorDepthFormat = 'uint16';
                    case 32
                        colorDepthFormat = 'uint32';
                    case 64
                        colorDepthFormat = 'uint64';
                end
            end
            
            %----------------------
            % check output argument
            
            % is 1 output argument specified?
            nargoutchk(1, 2)
            
            %-----------
            % read image
            
            % initialize length of headers
            % Note that the ESRF data format (EDF) header has been arbitrarily
            % set to 1024 bytes since this is the most common implementation
            % at the ESRF. Nevertheless, the EDF data format can store more than
            % one header (and therefore more than one image) of n*512 bytes in
            % one file.
            % The description of the EDF can be found at:
            % http://www.esrf.fr/computing/expg/subgroups/general/format/Format.html
            tifheaderlength = 4096;
            
            % prepare filename without extension
            [pathstr, fname] = fileparts(filename);
            
            switch lower(format)
                
                % read img
                case 'img'
                    filename = fullfile(pathstr, strcat(fname, '.img'));
                    % check if file exists
                    if(exist(filename, 'file') == 0);
                        eid = sprintf('File:%s:DoesNotExist',  filename);
                        error(eid, 'File %s does not exist!', filename);
                    end;
                    % open and read the file
                    [ifImg] = fopen (filename);
                    % there is no header in the case of img
                    header = [];
                    % read the data
                    [data, ncount] = fread (ifImg, inf, colorDepthFormat);
                    fclose (ifImg);
                    
                    % read tif or tiff
                case {'tif', 'tiff'}
                    filenames = fullfile(pathstr, strcat(fname, '.tif'));
                    filenamel = fullfile(pathstr, strcat(fname, '.tiff'));
                    % check if file exists
                    if ((exist(filenames, 'file') == 0) && ...
                            (exist(filenamel, 'file') == 0));
                        eid = sprintf('File:%s:DoesNotExist',  filename);
                        error(eid, 'File %s does not exist!', filename);
                    elseif (exist(filenames, 'file') == 2)
                        filename = filenames;
                    else
                        filename = filenamel;
                    end
                    
                    header = ''; % header is generally not of interest for tiff type files
                    % read tiff and convert to double
                    data = double(imread(filename));
                    ncount = numel(data);
                    
                    % read ff tif
                case 'ff'
                    filename = fullfile(pathstr, strcat(fname, '.tif'));
                    % check if file exists
                    if(exist(filename, 'file') == 0);
                        eid = sprintf('File:%s:DoesNotExist',  filename);
                        error(eid, 'File %s does not exist!', filename);
                    end;
                    [ifFf]=fopen(filename);
                    % read the header and convert to a string
                    [header]=char(fread(ifFf, tifheaderlength)');
                    % read the data
                    [data,ncount]=fread(ifFf, inf, 'float32');
                    fclose(ifFf);
                    
                    % read edf
                case 'edf'
                    filename = fullfile(pathstr, strcat(fname, '.edf'));
                    % check if file exists
                    if(exist(filename, 'file') == 0);
                        eid = sprintf('File:%s:DoesNotExist',  filename);
                        error(eid, 'File %s does not exist!', filename);
                    end;
                    % open and read the file, convert to double
                    [ifEdf]=fopen(filename);
                    tline = 'line';
                    header = '';
                    while strcmp(tline(1),' ') ~= 1
                        tline = fgets(ifEdf); %skip the header
                        header = [header tline];
                    end
                    
                    % read the data
                    [data,ncount]=fread(ifEdf, inf, colorDepthFormat);
                    fclose(ifEdf);
            end
            
            % check if number of retrieved elements agrees with requested image
            % dimensions:
            if (prod(dim) ~= ncount)
                eid = sprintf('ImageRead:%s:WrongNumberOfElementsInFile',mfilename);
                error(eid,'%s\n%s',...
                    'The number of elements found in the data file does not agree ',...
                    'with the number of requested elements given by dim');
            else
                Im = reshape(data,dim(1),dim(2));
                Im = Im';
            end
        end
        
    end
    
end