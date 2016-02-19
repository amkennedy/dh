function msg = nadp_dh %(pn_source,fn_source,qc_source,template,sitecode,profile,pn_dest,pn_plots,html,email,fn_dest,reprocess)

     
      %
      %code for importing the source data - revise the import filter and syntax to suit dat
      %this is a quick version of a dh, not best practice in general.
      
      load 'E:\temp\NADP\data\nadp_noahiv_2015.mat';
      sitecode = 'prim_nadp';    
      
      %check for valid data structure from import filter
      if gce_valid(data)
          
          %
          %code for basic data manipulation goes here
          %
          
          %check for optional sitecode, add to beginning of data set and document in metadata
          if ~isempty(sitecode)
              
              data = addcol( ...
                  data, ...        %date structure to update
                  sitecode, ...    %site code to add (will be replicated to all rows)
                  'Site', ...      %column name to assign
                  '', ...          %column units
                  'Site code', ... %column description
                  's', ...         %data type
                  'nominal', ...   %variable type
                  'none', ...      %numeric type
                  0, ...           %numeric precision
                  '', ...          %Q/C flagging criteria
                  1 ...            %column position in data set
                  );
              
              %update site metadata by looking up site in geo_polygons.mat
              data = add_sitemetadata( ...
                  data, ...    %data structure to update
                  'Site', ...  %site/location column name to match
                  '', ...      %site prefix to add
                  1 ...        %auto-polygons option for looking up polygons for matched points
                  );
              
              %check new records for duplicate records
              [data,msg] = cleardupes( ...
                  data, ...                   %data structure
                  {'Date'}, ...               %{data.name{2}}, ...        %date column
                  'verbose' ...               %logging option
                  );
              
          end
          
          if ~isempty(data)
              %master list of columns to interpolate
              interpcols = {'ActTemp','ActDepth'};
              
              %check for columns in active data structure, case-insensitively,
              %constraining to floating-point data columns
              cols = name2col(data,interpcols,0,'f','data');
              
              %interpolate any matched columns
              if ~isempty(cols)
                  [data,msg] = interp_missing(data, ...
                      'Date', ...
                      cols,...
                      'linear', ...
                      5, ...
                      inf ...
                      );
              end
          end
          
          col = name2col(data,{'ActDepth'}); % check for column to qc
          if ~isempty(col)
              % run the simiplepre.m post processor
              % Define constant variable col
              % This will define both the value and flag
              col         = {'ActDepth'};
              dt          = 'Date';
              
              % Convert to format for simple precip function
              %data        = flags2cols(data,flag_col);
              if ~isempty(col)
                  DateCol     = name2col(data,dt);
                  GaugeCol    = name2col(data,col);
                  FlagCol     = name2col(data,col);
                  %Use station CENMET for every 5min station, use CS2MET for every 15 minute station
                  Station     = 'CS2MET';
                  clear dt
                  
                  %Results = simplepre(GaugeCol, FlagCol, Station, data);
                  Results = simplepre2_j(GaugeCol, FlagCol, Station, data);
                  
                  Diffs_455       = cell2mat(Results(:,5));
                  Flag_Diffs_455  = Results(:,6);
                  
                  col = name2col(data,'ActDepth');
                  if ~isempty(col)
                      % add new column for corrected precip diffs
                      [data,msg] = addcol( ...
                          data, ...                                        % original data structure (required)
                          Diffs_455, ...                                       % an array of calculated values (required)
                          'PRECIP_TOT_ActDepth', ...                       % the name of the new column (required)
                          'mm', ...                                    % the units string for the new column (required)
                          'Increment corrected total precipitation', ...     % the description for the new column (optional - default = name)
                          'f', ...                                         % the data type of the new column (optional - default = 'f' or 's')
                          'data', ...                                      % the variable type of the new column (optional - default = 'calculation')
                          'continuous', ...                                 % the numerical type of the new column (optional)
                          2, ...                                           % the number of decimal places to use for text output
                          '', ...                                          % the flagging criteria for the new column (optional - default = '')
                          col+1 ...                                          % the column position (1 = beginning, [] = last)
                          );
                  end
                  
                  % add the flags to the ds generated by simplepre
                  % update diff_flag column with flags created by sub-function
                  col      = {'PRECIP_TOT_ActDepth'};        %values to be flagged
                  Icols    = name2col(data,col);
                  Irows    = [];
                  flag     = Flag_Diffs_455;                  %cell array of flags
                  
                  if ~isempty(col)
                      [data,msg] = addflags( ...
                          data, ...              % data structure to update (struct, required)
                          Icols, ...          %Icols = array of column names or numeric indicies to update (numeric or cell array of strings, required)
                          Irows, ...          %Irows = array of row numbers to update (numeric array, required, [] = all)
                          flag ...            %flag = flag character or array of flags matching Irows to assign (character or cell array, required)
                          );
                  end
              end
              %check new records for duplicate records
              [data,msg] = cleardupes( ...
                  data, ...                   %data structure
                  {'Date'}, ...               %{data.name{2}}, ...        %date column
                  'verbose' ...               %logging option
                  );
          end
      end
      
                

                
         
         
            

