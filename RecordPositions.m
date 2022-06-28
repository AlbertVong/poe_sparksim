%%Albert Vong, 2022

function RecordPositions(spark_xpos,spark_ypos,spark_hit,recorded_stats, ii, game_time,Record_Pos, hit_counter)
    global recorded_stats
    
    spark_hitbool = spark_hit > 0;
    %Optionally Record all x, y positions
    if Record_Pos == true
        
        spark_x_viable = spark_xpos(spark_hitbool,:); spark_y_viable = spark_ypos(spark_hitbool,:);
        spark_x_reload = spark_xpos(~spark_hitbool,:); spark_y_reload = spark_ypos(~spark_hitbool,:);

        %Flattening out the position vectors for storage
        spark_x_viable = reshape(spark_x_viable',1,[]); spark_y_viable = reshape(spark_y_viable',1,[]);
        spark_x_reload = reshape(spark_x_reload',1,[]); spark_y_reload = reshape(spark_y_reload',1,[]);

        %Putting them inside the data structure
        recorded_stats(ii).x_viable = spark_x_viable; %Sparks that have hit
        recorded_stats(ii).y_viable = spark_y_viable; %Sparks that have hit
        recorded_stats(ii).x_reload = spark_x_reload; %Sparks ready to hit (off gcd)
        recorded_stats(ii).y_reload = spark_y_reload; %Sparks ready to hit (off gcd)

    end

    %Recording number of sparks tha thave hit in the past 0.66 seconds
    %Hiding some stats for now
%     recorded_stats(ii).hits = length(spark_hit(spark_hitbool)); %Total hits at a given point in time
    recorded_stats(ii).hitcounter = hit_counter; %Summation of all past hits
    recorded_stats(ii).time = game_time;

    

end