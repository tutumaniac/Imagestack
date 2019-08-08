function [Data] = loadImageInfo(filename)

    if(exist(filename, 'file') == 0);
        eid = sprintf('File:%s:DoesNotExist',  filename);
        error(eid, 'File %s does not exist!', filename);
    end;
    
    % is filename of type string?
    if(~ischar(filename))
        error('Invalid input for ''filename'' in function loadImageInfo.');
    end
    
    % get file extension
    [~,~,ext] = fileparts(filename);
    
    % allowed file extensions
    format = {'.scan','.tsf'};
    % is file format tsf or scan?
    if sum(strcmp(ext,format)) == 0
        error('Invalid input %s for ''format'' in function loadImageInfo.',ext);
    end
    
    fid = fopen(filename);
    
    % differentiate for the different type of files
    switch ext
        case '.scan'
            while feof(fid) ~= 1
                % Datei zeilenweise auslesen
                tline = fgetl(fid);
                
                if strfind(tline,'#N') == 1
                    tmp = textscan(tline,'%s %f');
                    MotorAnzahl = tmp{2};
                end
                % get MotorNames and Values
                if strfind(tline,'#L') == 1
                    
                    Format_MotorName = '%s';
                    Format_Motor = '';
                    
                    for j = 1:MotorAnzahl
                        if j ~= MotorAnzahl
                            Format_MotorName = [Format_MotorName ' %s'];
                            Format_Motor = [Format_Motor ' %f'];
                        else
                            Format_MotorName = [Format_MotorName ' %s'];
                            Format_Motor = [Format_Motor ' %f \n'];
                        end
                    end
                      
                    MotorNames = textscan(tline, Format_MotorName);
                    tmp = MotorNames;
                    MotorNames = tmp(2:end);
 
                    MotorData = textscan(fid, Format_Motor);
                end
            end
            
            for i = 1:length(MotorNames)
                Data.(MotorNames{i}{1}) = MotorData{i};
            end
  
        case '.tsf'
            % get first line
            tline = fgetl(fid);
            %get counter values
            i = 0;
            % determine the structure of the file by the header
            Format = '';
            tmp = tline;
            while isempty(tmp) ~=1
                i = i + 1;
                [MotorNames{i}, tmp] = strtok(tmp);
                Format = [Format ' %f'];
            end
            
            MotorData = textscan(fid,Format);
            
            for i = 1:length(MotorNames)
                Data.(MotorNames{i}) = MotorData{i};
            end
    end
end