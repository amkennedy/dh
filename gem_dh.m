function [msg,status] = gem_dh(pn_source,fn_source,template,sitecode,profile,pn_dest,pn_plots,html,email,fn_dest,reprocess)
%Data harvester function template for post-processing streaming sensor data cached on a file system
%
%syntax: [msg,status] = data_harvester(pn_source,fn_source,template,sitecode,profile,pn_dest,pn_plots,html,email,fn_destreprocess)
%
%input:
%   pn_source = local fle system or network path to the raw data file (string - required; for demo use 'demo')
%   fn_source = raw data filename (string - required; for demo use 'sample_data_toa5.dat')
%   template = metadata template to apply (string - required; for demo use 'Harvest_Demo')
%   sitecode = site code value to add to data set (string - optional; default = '' for none)
%   profile = profile identifier in harvest_info.m and harvest_plot_info.m to use
%      for generating data indices and plot pages (string - optional; default = 'demo')
%   pn_dest = local file system or network path for saving processed data files, containing a
%      'data' subdirectory (string - optional; default = 'data' directory in pn_source)
%   pn_plots = path name for plots (string - optional; default = '' for no plots)
%   html = option to render data and plot index files in HTML format (i.e. runs XSL transforms on XML)
%      0 = no
%      1 = yes (default)
%   email = email address or array of addresses to send post-harvest error 
%       reports to (string or cell array of strings - optional; default = '' for none)
%   fn_dest = processed data filename (string - optional; default = fn_source with .mat extension)
%   reprocess = option to reprocess files and generate indices and plots even if no new records are harvested
%      0 = no (default)
%      1 = yes
%
%output:
%   msg = status message
%   status = numeric status code (1 = success, 0 = error)
%
%notes:
%   1) this is a starter template for creating data harvesting workflows in the 
%      GCE Data Toolbox for MATLAB
%   2) after editing the template, rename the function from "data_harvester" to something
%      application-specific (e.g. 'harvest_campbell_met') by revising the header and saving
%      the m-file using the new function name with .m extension (e.g. 'harvest_campbell_met.m')
%   3) to run the new harvest workflow, type the function name with appropriate arguments from
%      the MATLAB command line or by including the function call in 'harvest_timers.mat' and 
%      and starting harvests by calling 'start_harvesters.m')
%   4) import filter and plot variables are based on sample data file 'sample_data_toa5.dat';
%      edit these sections to match your data format, template and column names
%
%by Wade Sheldon <sheldon@uga.edu>, GCE-LTER Project, University of Georgia
%
%last updated: 14-Feb-2014

%init output
status = 0;

%check for required arguments
if nargin >= 3
   
   %validate source path and file
   if isdir(pn_source) && exist([pn_source,filesep,fn_source],'file') == 2
      
      %
      %validate input and supply defaults for omitted arguments
      %
      
      %check for sitecode argument
      if exist('sitecode','var') ~= 1
         sitecode = '';  %no site code
      end
      
      %check for template argument
      if exist('template','var') ~= 1
         template = '';
      end
      
      %check for profile argument
      if exist('profile','var') ~= 1
         profile = '';
      end
      if isempty(profile)
         profile = 'demo';
      end
      
      %check for html argument
      if exist('html','var') ~= 1 || html ~= 0
         html = 1;
      end         
      
      %check for email
      if exist('email','var') ~= 1
         email = '';
      elseif ~isempty(email) && ischar(email)
         email = cellstr(email);  %convert to cell array
      end
      
      %check for reprocess flag
      if exist('reprocess','var') ~= 1 || reprocess ~= 1
         reprocess = 0;
      end
      
      %check for terminal path separator on pn_source
      pn_source = clean_path(pn_source);
      
      %validate destination path
      if exist('pn_dest','var') ~= 1
         pn_dest = '';
      end
      if isempty(pn_dest) || ~isdir(pn_dest)
         pn_dest = pn_source;  %use source path
      else
         pn_dest = clean_path(pn_dest);  %remove terminal path separator
      end
      
      %check for data subdirectory, create if not present
      if ~isdir([pn_dest,filesep,'data'])
         if length(pn_dest) > 5 && strcmp([filesep,'data'],pn_dest(length(pn_dest)-4:end))
            %remove data subdirectory from pn_dest
            pn_dest = pn_dest(1:end-5);
         else
            %create data subdirectory
            status = mkdir(pn_dest,'data');
         end
      end
      
      %generate data path from pn_dest
      pn_data = [pn_dest,filesep,'data'];
      
      %check for destination file
      if exist('fn_dest','var') ~= 1
         [~,fn_base] = fileparts(fn_source);  %get base filename of source file
         fn_dest = [fn_base,'.mat'];  %append .mat suffix
      end
      
      %validate plot path, check for 'plots' subdirectory and add if not present
      if exist('pn_plots','var') ~= 1
         pn_plots = '';
      elseif ~isdir(pn_plots)
         pn_plots = '';
      else
         pn_plots = clean_path(pn_plots);  %remove terminal path separator
         if ~strcmp([filesep,'plots'],pn_plots(length(pn_plots)-5:end))
            if ~isdir([pn_plots,filesep,'plots'])
               status = mkdir(pn_plots,'plots');
            end
            pn_plots = [pn_plots,filesep,'plots'];
         end
      end
      
      %
      %code for importing the source data - revise the import filter and syntax to suit data
      %
      
      %Example: imports CSI TOA5 data using specified template, calculating a serial date and
      %assigning the 'EST' timezone to date/time columns; note that QA/QC flags will be
      %assigned automatically based on criteria in the template
      [data,msg] = gem_energy_import( ...
          'GREENHouse_1.csv', ...
          'C:\Users\kennedad\Dropbox\gce_datatools_380_gce_production\userdata');
      
%       [data,msg] = imp_campbell_toa5( ...
%          fn_source, ... %file to import
%          pn_source, ... %path to file
%          template, ...  %metadata template to apply
%          1, ...         %option to add a serial date column calculated from the time stamp
%          'EST' ...      %time zone metadata to apply to date/time column units/description for conversions
%          );
          
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
            
         end
         
         %document anomalies (missing values and flags from QA/QC rules)
         data = add_anomalies( ...
            data, ...   %data structure to update
            23, ...     %date format (see 'help datestr')
            '-', ...    %date range separator
            1, ...      %option to document missing values
            [], ...     %column selection ([] = all)
            1 ...       %overwrite existing anomalies to prevent redundancy
            );
         
         %
         %code for appending the data to existing data goes here
         %
         
         %append data to existing file, if present, updating the title to include the overall date range
         if exist([pn_data,filesep,fn_dest],'file') == 2
         
            %append data - returning merged data structure
            [data,msg0] = append_data( ...
               data, ...                         %new data to append
               [pn_data,filesep,fn_dest], ...    %existing file to append to
               'data', ...                       %data structure variable name
               'date_append', ...                %merge option (append new records)
               'new_date', ...                   %title option (use title in data, but update dates)
               0, ...                            %fixflags option (do not lock)
               0 ...                             %save option (do not save - save handled later)
               );      
            
            %generate warning message if necessary
            if ~isempty(msg0)
               if reprocess == 0
                  data = [];  %clear data unless reprocess flag is set
               end
               if isempty(msg)
                  msg = ['a warning occurred appending the data (',msg0,')'];
               else
                  msg = [msg,'; a warning occurred appending the data (',msg0,')'];
               end
            end
            
         end
         
         %
         %code for padding date gaps and finalizing the structure goes here
         %
         
         if ~isempty(data)
         
            %fills date gaps based on the finest time step in the data series, padding data columns
            %with NaN for numeric, '' for string values, replicating non-data columns and regenerating
            %date/time columns
            data = pad_date_gaps( ...
               data, ...  %data structure to update
               [], ...    %date column ([] = auto)
               1, ...     %remove duplicates option (1 = yes)
               1 ...      %replicate non-data values option (1 = yes)
               );
           
           col = name2col(data,'kWh11');
                %convert PPT_INST from in to mm
                if ~isempty(col)
                    [data,msg] = add_calcexpr(data, ...
                        '[NaN ; diff(kWh11)]', ...            %calculate precip using 0.05mm/tip correction factor
                        'kWh11_DIFF', ...                       %new column name
                        'kWh', ...                               %new column units
                        'kWh Usage', ...  %description
                        col+1, ...                              %position
                        0, ...                                  %replicate scalar values (no)
                        'x<0=''I'';x>5=''I''', ...             %Q/C flag criteria for the new column
                        'calculation');                           %variable type of the new column
                end

            %add columns Year, YearDay and Hours derived for date/time information
            %replacing any existing Year, YearDay and Hours columns
%             data = add_year_yearday_hours(data);
            
%             
%             datecol = name2col(data,'Date');
%             dt = datestr2num('Date')
            
            
            
         end
            
         
         %
         %code for saving data file and generating export formats goes here
         %
         
         if ~isempty(data)
            
            %save .mat file to destination
            save([pn_data,filesep,fn_dest],'data')
            
            %send the signature email that summarizes the features of
                %this data harvest process
                signature_email(sitecode, data);
                
%                 tEnd = toc;
%                 matlabmail({'adam.kennedy@oregonstate.edu'}, ['All the columns from' sitecode 'have been processed. This includes: ' data.name(1,1:length(data.name)) '...'], ...
%                     ['Last harvester completed processing ' datestr(now) ' and required ' num2str(tEnd) ' seconds.']);
            
%             %generate name for csv file
%             [~,fn_base] = fileparts(fn_dest);
%             fn_csv = [fn_base,'.csv'];
            
%             %export .csv file with separate metadata in FLED style with q/c flag columns for all
%             %data/calc columns (see 'help exp_ascii' for all options)
%             exp_ascii( ...
%                data, ...     %data structure to export
%                'csv', ...    %file format to export
%                fn_csv, ...   %filename for CSV file
%                pn_data, ...  %file path for CSV file
%                '', ...       %title string ('' = use data set title)
%                'SB', ...     %header format ('SB' = brief header with separate metadata file -meta.txt)
%                'MD', ...     %flag display format ('MD' = flag columns for all data/calc columns)
%                'FLED' ...    %metadata style
%                );
            
%             %generate name for html file
%             fn_html = [pn_data,filesep,fn_base,'-data.html'];
%             
%             %export -data.html file for previewing the data
%             gceds2html( ...
%                data, ...         %data structure to export
%                [], ...           %column list (default = all)
%                [], ...           %headings (default = column names)
%                'column', ...     %orientation (column or row)
%                'data-table', ... %css id of table (default)
%                1, ...            %html header option (generate complete html header)
%                '', ...           %css url (none - generated embedded CSS styles)
%                fn_html ...       %filename for html file
%                );
            
         end
         
         %
         %code for plotting or other operations goes here
         %
         
         %index the destination directory to create/update XML index and data set summary pages
         harvest_datapages_xml( ...
            pn_dest, ...     %base pathname containing files to index
            '', ...          %subdirectories in pn_dest to index
            profile, ...     %profile name in harvest_info.m
            html, ...        %set HTML format option to transform XML to HTML
            '', ...          %set interval to automatic
            'MD' ...         %flag display format ('MD' = flag columns for all data/calc columns)
            );         
         
         %generate plots using stored configuration info in demo/harvest_plot_info.m if pn_plots provided
         if ~isempty(data) && ~isempty(pn_plots)
            
            msg0 = harvest_webplots_xml( ...
               fn_dest, ...   %filename of data structure to plot 
               pn_data, ...   %pathname containing fn_dest
               pn_plots, ...  %pathname for plot files
               profile, ...   %profile name in harvest_plot_info.m
               'week', ...    %plot interval
               html ...       %set HTML format option to transform XML to HTML
               );
            
            %check for plotting error - add to status message
            if ~isempty(msg0)
               if isempty(msg)
                  msg = msg0;
               else
                  msg = [msg,'; ',msg0];
               end
            end
            
         end         
         
      end
      
      %generate status output
      if isempty(msg)
          msg = ['successfully harvested data from ',pn_source,filesep,fn_source];
          status = 1;
      end
      
      %generate status to console
      if isempty(msg)
          X = [sitecode,' we are done here'];
          disp(X)
      end
      
      %send post-harvest email if specified
      if ~isempty(email)
         
         %perform quality checks on harvested data
         msg_check = harvest_check( ...
            data, ...  %data structure to check
            3, ...     %number of days back to check from current date
            0, ...     %threshold for total missing values
            0, ...     %threshold for total flagged values
            0, ...     %threshold for missing values in any one day
            0, ...     %threshold for flagged values in any one day
            100 ...    %wordwrap column for text to email
            );
         
         %send email if any checks fail
         %(note: Internet preferences must be set in MATLAB before sendmail can be called -
         %see 'help sendmail' for information)
         if ~isempty(msg_check)
            try
               sendmail(email,'Quality report from data_harvester.m',msg_check);
            catch e
               msg = [msg,'; an error occurred sending a post-harvest email (',e.message,')'];
            end
         end
      end
      
   else
      
      %generate appropriate error message
      if nargin < 3
         msg = 'insufficient arguments for function';
      elseif ~isdir(pn_source)
         msg = [pn_source,' is not a valid path'];
      else
         msg = [fn_source,' is not present in ',pn_source];
      end
      
   end
   
else
   msg = 'source path and filename are required';
end
