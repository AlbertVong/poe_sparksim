%Albert Vong, 2022

function [spark_hit_updated, hits_rmn, hit_counter_final] = BossCollision(spark_xpos, spark_ypos, boss, spark_hit, game_time, server_cd, spark_hit_cd, hits_rmn, hit_counter)
    %Note
    %Boss = [x, y, r], where x and y are positions and r is the radius
  
    %Sparks have an inherent collision hitbox (I'm going to assume this is 0.5).
    %This means the spark center coordinate must be within a radius of (boss radius + spark radius) to register a hit.
    %This is using a Euclidean distance metric (I realize that Manhattan distance is technically used afaik, but too lazy to resim at this point)
    collision_detected = sqrt((spark_xpos - boss(1)).^2 + (spark_ypos - boss(2)).^2) <= (boss(3)+0.5);
    
    %This only accounts for collisions from sparks that have hits remaining (i.e. pierces remaining)
    %and are off gcd
    collision_valid = logical(collision_detected.*(hits_rmn>0));

    %Gives you a column vector of the summation of "True" values aka which casts have hit the boss during this server tick
    collisions = sum(double(collision_valid),2);
    
    %We make it so everything that collided (that was off cd) gets a new cooldown (global time at which its rearmed)
    %This inadvertently updates the sparks that are already on cooldown, but we overwrite this value in the end of this function
    %This way of programming is much easier since we don't need to do array resizing
    
    %Old statement accounting for server ticks (1 line below)
    %spark_hit_updated = double(collisions>0) * (server_cd * ceil(game_time/server_cd) + spark_hit_cd);
    
    %New statement ignoring server ticks
    %This tensor gives us the new global server times at which every cast of spark that hit in this server tick will be re-armed and
    %ready for a second hit. The sparks are "disarmed" for the next ~0.66 seconds
    spark_hit_updated = double(collisions>0) * (game_time + spark_hit_cd);
    
    
    %Checking pierces and "true hits"

    %Need to check each row (cast of spark) individually, and then take the first valid element and subtract it by 1
    for ii = 1:size(spark_xpos,1)
        samecast_hit = hits_rmn(ii,squeeze(collision_valid(ii,:)));
        %Checking if we have any valid hits, otherwise we do nothing
        %Also we check if this cast of sparks is OFF GCD, otherwise we do NOT count the hit.
        if ~isempty(samecast_hit) && spark_hit(ii) == 0
            samecast_hit(1) = samecast_hit(1) - 1; %Subtract the number of remaining hits by 1 from the first valid projectile

            %We subtract 1 from the first spark that is valid and reassign this value to the hit counter matrix
            %All other sparks that hit do NOT get subtracted, since we don't want to double count subtractions for pierce

            hits_rmn(ii,squeeze(collision_valid(ii,:))) = samecast_hit;

            %This increments for every single time we subtract pierces from any spark (i.e. a hit)
            hit_counter = hit_counter + 1;
        end
    end

    %We overwrite any of the cooldowns that were updated with the old cooldown
    %Doing it this way allows us to preserve existing cooldowns while adding new cooldowns for re-armed sparks, without array resizing
    spark_hit_updated(spark_hit>0) = spark_hit(spark_hit>0);
    
    hit_counter_final = hit_counter;
    
end