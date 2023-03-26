function tot_dist = obj_function(RoutesList, distance)

tot_dist = 0;
for i = 1:length(RoutesList)
    for j = 1:length(RoutesList{i})-1
        tot_dist = tot_dist + distance(RoutesList{i}(j),RoutesList{i}(j+1));
    end
end

return