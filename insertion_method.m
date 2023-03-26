function [routes,seeds] = insertion_method(capacity, demand, distance)
numNodes = size(distance,1);
numVehicles = length(capacity);


% I seeds vengono scelti di modo da massimizzare la distanza tra tra di essi
% e l'origine. 

% Costruiamo un vettore "s" dove i primi numVehicles elementi sono i seeds.
% Essi vengono inseriti in modo da massimizzare il minimo delle distanze 
% con i seeds precenti e con l'origine.

[M, I] = max(distance);
s = zeros(1,numNodes);
s(1) = 1;   % il primo seed è l'origine
s(2) = I(1);    % Il secondo seed è il nodo più distante dall'origine
min_dist = zeros(1,numNodes);

% Si aggiugono gli altri seeds
for j = 3:numVehicles+1
    for i = 2:numNodes
        min_dist(i) = min (distance(i,s(1:j-1)));
    end
    [M, I] = max(min_dist);
    s(j) = I;
end


% I restanti elementi del vettore "s" sono i nodi da inserire, ordinati 
% secondo la distanza rispetto all'origine.
for i = numVehicles+2:numNodes
    distance_copy = distance;
    distance_copy(1,s(1:i-1)) = 0;
    [M, I] = max(distance_copy(1,:));
    s(i) = I;
end


% Definiamo il vettore dei seeds e dei nodi da aggiungere a partire dal
% vettore "s".
seeds = s(1:numVehicles+1);
nodes_to_add = s(numVehicles+2:end-1);


% Aggiorniamo il vettore delle capacità residue delle routes, rimuovendo la
% domanda dei rispettivi seeds.
for j = 1:numVehicles
    capacity(j) = capacity(j) - seeds(j+1);
end


% Definiamo una lista "routes" che contiene tutte le routes,
% rappresentate come vettori  
routes = {};


% Costruiamo le routes iniziali (origine, seme, origine)
for i = 1:numVehicles
    routes{i} = [1 seeds(i+1) 1];
end


%%% INSERIMENTO DEI NODI %%%

for k = 1:length(nodes_to_add)
    node = nodes_to_add(k);  
    min_extra_mileage = distance(seeds(1), seeds(2));
    indexRoute = 0;          % indica in quale route inserire il nodo
    indexPosition = 0;       % indica la posizione all'interno della route       
                             % in cui inserire il nodo
    for j = 1:numVehicles
        for i = 1:length(routes{j})-1
            extra_mileage = distance(node, routes{j}(i)) + distance(node, ...
                routes{j}(i+1)) - distance(routes{j}(i),routes{j}(i+1));
            if capacity(j) > demand(node)
                if (extra_mileage < min_extra_mileage)
                    min_extra_mileage = extra_mileage;
                    indexRoute = j;
                    indexPosition = i;
                end
            end
        end
    end

    % Inseriamo il nodo e aggiorniamo il vettore delle capacità residue
    routes{indexRoute} = [routes{indexRoute}(1:indexPosition) node routes{indexRoute}(indexPosition+1:end)];
    capacity(indexRoute) = capacity(indexRoute) - demand(node);
end