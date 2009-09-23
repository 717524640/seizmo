function print_time_left(act_step,tot_step,redraw)

% print_time_left(act_step,tot_step) prints the remaining time in a
% computation when act_step steps out of tot_steps have been made.
%
% This code must be called at the end of the step act_step (and not at the
% beginning).
%
% To reduce the computaton overhead, the code will only be active if
% floor(percentage) has changed in the last step (this can easy be
% removed by deleting the first 'if' condition).

% Made by Nicolas Le Roux on this beautiful day of July, 20th, 2005
% Distribute this code as much as you want.
% You can send any comment at lerouxni@iro.umontreal.ca

% lots of edits by Garrett Euler
% - internal timer
% - dropped print_same_line (uses backspace & keeps track of last line)
% - allow for redraw after some event (like a warning)

% Percentage completed

old_perc_complete = floor(100*(act_step-1)/tot_step);
perc_complete = floor(100*act_step/tot_step);

persistent nb i

if ~act_step && old_perc_complete == perc_complete
else
    % internally keep track of output length and timer
    if(~exist('nb','var') || isempty(nb)); nb=0; end
    if(~exist('i','var') || isempty(i)); i=tic; end
    if(nargin==3 && redraw); nb=0; end
    
	% Time spent so far

	time_spent = toc(i);

	% Estimated time per step

	est_time_per_step = time_spent/act_step;

	% Estimated remaining time. tot_step - act_step steps are still to make

	est_rem_time = (tot_step - act_step)*est_time_per_step;

	str_steps = [' ' num2str(act_step) '/' num2str(tot_step)];

	% Correctly print the remaining time

	if (floor(est_rem_time/60) >= 1)
		str_time = ...
			[' ' num2str(floor(est_rem_time/60)) 'm' ...
			num2str(floor(rem(est_rem_time,60))) 's'];
	else
		str_time = ...
			[' ' num2str(floor(rem(est_rem_time,60))) 's'];
	end

	% Create the string [***** x    ] act_step/tot_step (1:10:36)

	str_pb = progress_bar(perc_complete);

	str_tot = strcat(str_pb, str_steps, str_time);

	% Print it
    fprintf(1,strcat(repmat('\b',1,nb),str_tot,'\n'));
    nb=numel(str_tot); % account for %% and linefeed
end

if act_step == tot_step
    nb=[]; i=[];
end
