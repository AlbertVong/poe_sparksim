%Albert Vong, 06/27/2022
%Path of Exile Spark Effective DPS Spark Simulation
%Run and advance these code blocks.
%Uses array broadcasting so get MATLAB 2021 (idk if Octave supports this).

clear all
%Define Arena
arena_length = 160; %Edge length, this would be a square with edge boundaries x = +-80, y = +-80

%Enemy Coordinates
boss = [40, 0, 3]; %x, y, r

%Player coordinates
player = [0, 0]; %x, y


%% IF COMPUTING ONE RUN, RUN THIS
global recorded_stats
clear recorded_stats

Proj_Spd = 50 * 2; %50 is the base cast speed, 2 is whatever is in POB (check google sheet)
Cast_Spd = 12;
Proj_Num = 5; 
Dur = 6;
Pierce = 0; %0 pierce is 0 pierce (i.e. sparks hit once)

%Note: If you want to play a movie of the sim, set recordpos = true. Then skip the next few code blocks (run and advance)
%The first argument is the number of server ticks (set to 1e4 as default).

[EDPS, recorded_stats] = SparkSimulation(1e4, theta_rand=pi/20,arena_edge=arena_length, proj_spd = Proj_Spd, cast_spd=Cast_Spd, proj_num = Proj_Num, ...
                                        duration=Dur, pierce=Pierce, boss_coords = boss, player_coords=player,...
                                        recordpos=true);



%% IF COMPUTING A COMBIONATION OF PARAMETERS, RUN THIS

%Define Experimental Variables
%Assume ball lightnings base movement speed is 36 units per second
%Its projectile speed value on the wiki is 400 (datamining)
%Spark's datamined projectile speed is 560
%Therefore, spark's base projectile speed should be around 48 * 560/400 = 50.4 (seems ok with in game testing)
Proj_Spd_rng = 50 * (1.5:0.5:4);
Cast_Spd_rng = 7.5:0.5:13;
Proj_Num_rng = [14 15 17];
Dur_rng = 2:0.3:2.3; %I should do 2.3 and 2 after
Pierce = [0 1 3 5];

Param_combs = combvec(Proj_Spd_rng,Cast_Spd_rng,Proj_Num_rng,Dur_rng,Pierce);


%% COMBINATORIAL SIMULATION
tic
parfor ii = 1:size(Param_combs,2)
    Proj_Spd = Param_combs(1,ii);
    Cast_Spd = Param_combs(2,ii);
    Proj_Num = Param_combs(3,ii);
    Dur = Param_combs(4,ii);
    Pierce = Param_combs(1,ii);

    EDPS(ii,:) = SparkSimulation(1e4, theta_rand=pi/20, arena_edge=arena_length, proj_spd = Proj_Spd, cast_spd=Cast_Spd, proj_num = Proj_Num, ...
                                        duration=Dur, pierce=Pierce, boss_coords = boss, player_coords=player,...
                                        recordpos=false);
end
toc
%% Saving Combinatorial Parameters
savename = 'combinatorial_mediumarena_2_2.3_duration_finalsim.mat';
save(savename,'EDPS','boss','arena_length','Pierce','Cast_Spd_rng','Dur_rng','Proj_Num_rng','Proj_Spd_rng','Param_combs');



%% Movie of spark sim

%Skip here if you want to play a movie of the sparks after a single run sim.

%This only works if recordpos=True on the single run function.

%Figure
h = figure('units','normalized','outerposition',[0 0 1 1]);
h.Position = [1.5740   -0.0380    0.5750    0.8259];

%Axes
ax = gca; 
ax.NextPlot = 'replaceChildren';
ax.XLim = [-arena_length/2 arena_length/2]; ax.YLim = [-arena_length/2 arena_length/2]; axis manual
h.Visible = 'off';
%CHANGE THE VIDEO FILE NAME HERE.
v = VideoWriter('simple_sim_example.mp4', 'MPEG-4');
v.FrameRate = 60;

open(v);
hold on

loops = length(recorded_stats); %True number of loops
% movie_loops = 60/fps; %We're going to repeat the frames X number of times to it appears to be slower
M(loops) = struct('cdata',[],'colormap',[]); %Movie frames (not used)

%Note: ax1 is the hypercube map, ax2 is the wavelength indicator
for j = 1:300%loops
    %Plotting the red line plus spectra
   
    %Sparks that have hit already
    x_spark_viable = recorded_stats(j).x_viable;
    y_spark_viable = recorded_stats(j).y_viable;
    %Sparks that can hit the target
    x_spark_reload = recorded_stats(j).x_reload;
    y_spark_reload = recorded_stats(j).y_reload;
    
    time_plot = recorded_stats(j).time;
    
    text(0,arena_length/2-15,strcat('Time: ',num2str(time_plot)),'FontSize',16);
    %Plot "Boss"
    rectangle('Position',[boss(1:2)-boss(3) boss(3)*2 boss(3)*2],'Curvature',[1 1],'FaceColor',[235 229 52]/255);

    %Plot Exile
    rectangle('Position',[player(1)-2 player(2)-2 4 4],'FaceColor',[0 0 0]);
    
    %Plot Sparks
    
    scatter(x_spark_viable,y_spark_viable,15,'r','*');
    scatter(x_spark_reload,y_spark_reload,15,'b','*');  
     
    drawnow
    set(gcf, 'color', 'white');
    M(j) = getframe(gca);
    writeVideo(v,M(j));
    
    %Clear curent figure for next rendering
    cla
end
close(v);
h.Visible = 'on';

