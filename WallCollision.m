%%Albert Vong, 2022

function [xpos_final, ypos_final, theta_final] = WallCollision(spark_xpos, spark_ypos, spark_theta, Proj_Spd, arena_edge, game_time_increment)
    %Suggest new update positions
    x_vel = Proj_Spd * round(cos(spark_theta),2); y_vel = Proj_Spd * round(sin(spark_theta),2);


    x_pos_update = x_vel * game_time_increment; %Update X
    y_pos_update = y_vel * game_time_increment; %Update Y

    %Collision Detection (We'll update all the positions normally)
    %We will then "amend" the ones that go outside the boundary by placing them at the boundary and randomizing their velocity
    spark_xpos = spark_xpos + x_pos_update; spark_ypos = spark_ypos + y_pos_update;
    
    %Check if updated positions are beyond x boundaries
    x_coll_idx = (abs(spark_xpos) - arena_edge/2) >= 0; %This is still m x n
    x_coll_idx = reshape(x_coll_idx',[],numel(spark_xpos)); %This is now laid flat for indexing

    spark_xpos = reshape(spark_xpos',[],numel(spark_xpos)); %Lay the spark_xpos_corr flat, so we can correct
    spark_xpos(x_coll_idx) = arena_edge/2 * sign(spark_xpos(x_coll_idx)); %Setting the positions to the arena edge
    spark_xpos = reshape(spark_xpos,[size(x_pos_update,2) size(x_pos_update,1)])'; %Resetting the spark position tensor back to m x n
    
    %Updating the velocities
    x_vel = reshape(x_vel',[],numel(x_vel));
    x_vel(x_coll_idx) = -x_vel(x_coll_idx); %Reversing sign if they collided
    x_vel = reshape(x_vel,[size(x_pos_update,2) size(x_pos_update,1)])';

    
    %Do the same thing for y
    y_coll_idx = (abs(spark_ypos) - arena_edge/2) >= 0; %This is still m x n
    y_coll_idx = reshape(y_coll_idx',[],numel(spark_ypos)); %This is now laid flat for indexing

    spark_ypos = reshape(spark_ypos',[],numel(spark_ypos)); %Lay the spark_xpos_corr flat, so we can correct
    spark_ypos(y_coll_idx) = arena_edge/2 * sign(spark_ypos(y_coll_idx)); %Setting the positions to the arena edge
    spark_ypos = reshape(spark_ypos,[size(y_pos_update,2) size(y_pos_update,1)])'; %Resetting the spark position tensor back to m x n
    
    %Updating y velocities
    y_vel = reshape(y_vel',[],numel(y_vel));
    y_vel(y_coll_idx) = -y_vel(y_coll_idx); %Reversing sign if they collided
    y_vel = reshape(y_vel,[size(y_pos_update,2) size(y_pos_update,1)])'; %Reshaping back to regular form


    %Updating the final position values
    xpos_final = spark_xpos; ypos_final = spark_ypos;

    %Correctly randomizing velocity based on the domain you lie in (don't think I can vectorize this)
    %The way the velocity vector changes is dependent on the wall you hit.
    for ii = 1:size(y_vel,1)
        for jj = 1:size(y_vel,2)
            if x_vel(ii,jj) >= 0
                theta_final(ii,jj) = atan(y_vel(ii,jj)/x_vel(ii,jj));
            elseif x_vel(ii,jj) <= 0
                %Domain of atan is -pi/2 to pi/2, need to shift this if the x vector is negative to second/third domains
                theta_final(ii,jj) = atan(y_vel(ii,jj)/x_vel(ii,jj)) + pi;
            end
        end
    end

end