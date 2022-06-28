%%Albert Vong, 2022

function [EDPS,varargout] = SparkSimulation(numticks, varargin)
    ip = inputParser;
    
    ip.addRequired('numticks',@isnumeric)
    ip.addParameter('arena_edge',160,@isnumeric)
    ip.addParameter('proj_spd', 100,@isnumeric)
    ip.addParameter('cast_spd',8,@isnumeric)
    ip.addParameter('proj_num',12,@isnumeric)
    ip.addParameter('duration',3,@isnumeric)
    ip.addParameter('pierce',1,@isnumeric)
    ip.addParameter('boss_coords',[40,0,4],@isnumeric)
    ip.addParameter('player_coords',[0 0],@isnumeric)
    ip.addParameter('recordpos',true)
    ip.addParameter('theta_rand',pi/7);

    
    parse(ip,numticks,varargin{:});

    %Assign variables
    inputs = ip.Results;
    %Spark Params
    Proj_Spd = inputs.proj_spd; %Projectile Speed
    Cast_Spd = inputs.cast_spd; %Cast Speed
    Proj_Num = inputs.proj_num; %Projectile Number
    Dur = inputs.duration; %Spark Duration (in seconds)
    Pierce = inputs.pierce; %Pierce (0 Pierce is 0 Pierce in game, the spark stops counting hits after 1 collision)
    %Arena/Hitbox Params
    arena_edge = inputs.arena_edge; %Edge length, this would be a square with edge boundaries x = +-80, y = +-80
    boss = inputs.boss_coords; %Boss coordinates
    player = inputs.player_coords; %Player coordinates
    
    Record_Pos = inputs.recordpos; %Are we recording the results and outputting them? This will save positions, and additional details
    %Simulation Params
    serverticks = inputs.numticks; %Number of server ticks
    theta_rand = inputs.theta_rand; %How much a spark's angle can change during one server tick
    
    %Spark Variables
    %Each row represents values from a new spark cast. Each cast is treated differently for the purposes of hit calculations
    spark_xpos = []; spark_ypos = []; %X and Y Positions
    spark_theta = []; %Angle of the sparks trajectory from 0 to 2 pi (or 0 to 360 degrees)
    spark_hit = []; %This is a 1d tensor that tracks if a cast has hit and is on the global cooldown (1 if gcd, 0 if primed for hitting)
    spark_dur = []; %This is a 1d tensor where each element represents the global server time at which the spark cast expires
    hits_rmn = []; %This is a 2d tensor where each row represents a cast, and each row element represents the number of remaining hits (e.g. Pierce = 1,
                   %then you have two hits total per spark. Each time you hit, one of the sparks' hits_rmn number will go down by 1, until 0.
    
    %Server Variables
    spark_cd = 0; %This denotes the next time spark is able to cast
    spark_hit_cd = 0.66; %Spark global cast hit cooldown (check the wiki for this number)
    cast_time = 1/Cast_Spd; %The amount of time between casts (not factoring in server ticks)
    server_cd = 33e-3; %This represents the minimum amount of time the server is able to process casting/hitting (same as COC)
    
    %We increment the simulation at half the rate of server cooldowns, so we can better catch
    %high speed sparks as they pass through the boss (collision checks)
    game_time_increment = server_cd/2;
    hit_counter = 0;
    
    %Defining a kernel which will be used to calculate the average hit damage (see end of function)
    one_second_idx = round(1/game_time_increment);
    kernel = zeros(1,one_second_idx); kernel(1) = 1; kernel(end) = -1;
    
    clear recorded_stats
    %This contains all relevant parameters, can be more detailed if record_pos = true
    global recorded_stats
    recorded_stats(serverticks).dummy = 0;

    %Turning warnings off
    warning('off','MATLAB:declareGlobalBeforeUse');
    %%
    % Begin Simulation
    for ii = 1:serverticks %server ticks

        game_time = game_time_increment * ii;


        %Step 0: Removing Sparks whose durations have vanished

        spark_remove_idx = (spark_dur <= game_time);

        %Remove sparks using the identified indices (that have expired)
        %This code works even in the case when spark_remove_idx is null (nothing found)
        %2D matrix removal
        spark_xpos(spark_remove_idx,:) = [];
        spark_ypos(spark_remove_idx,:) = [];
        spark_theta(spark_remove_idx,:) = [];
        hits_rmn(spark_remove_idx,:) = [];

        %1D matrix removal
        spark_hit(spark_remove_idx) = [];
        spark_dur(spark_remove_idx) = [];


        %Step 1: Casting Spark
        if game_time >= spark_cd
            %1. Initializing the spark pos vector
            spark_xpos = [spark_xpos;ones(1,Proj_Num)*player(1)]; spark_ypos = [spark_ypos;ones(1,Proj_Num) * player(2)];

            %2. Initializing the spark velocity vector
            %Randomize a theta vector in a cone
%           theta_vec = rand(1,Proj_Num) * pi*(14/20) - pi*(7/20);
            %Shoot thetas in a cone with the same trajectory every time
            theta_vec = linspace(-pi/10,pi/10,Proj_Num);
            
            %Use the theta vector to initialize the velocities
            spark_theta = [spark_theta; theta_vec];

            %3. Initializing the spark gcd check
            spark_hit = [spark_hit; 0];

            %4. Initializing the spark duration counter
            spark_dur = [spark_dur; game_time + Dur];

            %5. Initialize the pierce counter
            hits_rmn = [hits_rmn; ones(1,Proj_Num) * (Pierce+1)];
            
            %Old version accounting for server tick
            %spark_cd = server_cd * ceil(game_time/server_cd) + cast_time;
            %At what global time can we cast the next spark
            spark_cd = spark_cd + cast_time; %so we don't get these weird truncating values, we'll assume that we've casted as fast as we could
        end

        %Step 2 and 3: Position Update + Collision Checking

        %Random Walk Theta Change, Sparks can shift theta every time change
        theta_diff = theta_rand; %About a degree change of 2
        random_walk_theta = rand(size(theta_vec,1),size(theta_vec,2)) * 2*theta_diff - theta_diff;

        %Update the thetas
        spark_theta = spark_theta + random_walk_theta;

        %Advancing Positions + Wall Collision Checking
        [spark_xpos, spark_ypos, spark_theta] = WallCollision(spark_xpos, spark_ypos, spark_theta, Proj_Spd, arena_edge, game_time_increment);

        %Step 4: Target Collision Check
        %Spark_hit has the global cooldown times for every volley of sparks that hit
        %Hit_counter is a global counter for EVERY spark hit that has happened in the simulation
        %up until that point.
        [spark_hit, hits_rmn, hit_counter] = BossCollision(spark_xpos, spark_ypos, boss, spark_hit, game_time, server_cd, spark_hit_cd, hits_rmn, hit_counter);

        %Step 5: Recording Positions and other statistics

        RecordPositions(spark_xpos,spark_ypos,spark_hit,recorded_stats, ii, game_time, Record_Pos, hit_counter);


        %Step 6: Turning off hitchecks
        spark_gcd_over = (spark_hit <= game_time);
        %Resetting hitchecks whose cds have expired
        spark_hit(spark_gcd_over) = 0;

    end
    
    %When to start calculating stats (i.e. after reaching steady state)
    median_calc_start = min(length(recorded_stats)-50,500);

    %Deprecated Code below (2 lines), ignore
    %median_val = median([recorded_stats(median_calc_start:end).hits])/spark_hit_cd;
    %mean_val = mean([recorded_stats(median_calc_start:end).hits])/spark_hit_cd;
    
    %Taking every hitcounter value at every time point after steady state
    hits = [recorded_stats(median_calc_start:end).hitcounter];

    %Taking a rolling difference using convolution
    %This allows us to essentially get the total number of hits that occurred
    %between two server times that are 1 second apart.
    %This allows us to get a large sample size of "hits per second" for every possible "second" that occurred
    %There is alot of variance in hits, so this is the best way to do it IMO
    hps_rolling = conv(hits,kernel,'valid');

    %Calculating statistics using the rolling differences
    mean_hps = mean(hps_rolling);
    median_hps = median(hps_rolling);
    stdv_hps = std(hps_rolling);
    
    %Outputs
    EDPS = [mean_hps median_hps stdv_hps];
    varargout{1} = recorded_stats;


end