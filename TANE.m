function [best_RoutesList, tabu] = TANE(amax, bmax, M, P, tmin, tmax, RoutesList, demand, capacity, distance, tabu)

% Definiamo la migliore soluzione corrente e il valore della relativa
% funzione obiettivo.
best_distance = obj_function(RoutesList, distance);
best_RoutesList = RoutesList;

best_nodes_R1 = [];
best_nodes_R2 = [];

for i = 1:amax
    
    % Determiniamo le routes R1, R2 tra cui effettuare lo scambio dei nodi
    I = datasample(1:length(RoutesList),2, 'Replace', false);
    I1 = I(1);
    I2 = I(2);
    R1 = RoutesList{I1};
    R2 = RoutesList{I2};

    % Calcoliamo la domanda delle routes
    demand_R1 = sum(demand(R1));
    demand_R2 = sum(demand(R2));

    % Determiniamo mu, il numero di nodi da scambiare da R1 a R2. Se la
    % lunghezza della route è <=3 si pone mu = 0, dato che il numero di
    % routes deve rimanere costante.
    if length(R1) > 3
        mu = datasample(0:min(M, length(R1)-3),1);
    else
        mu = 0;
    end
    
    % Determiniamo pi, il numero di nodi da scambiare da R2 a R1
    if length(R2) > 3
        pi = datasample(0:min(P, length(R2)-3),1);
    else
        pi = 0;
    end

    % Campioniamo i nodi da scambiare
    nodes_R1 = datasample(R1(2:end-1), mu, 'Replace', false);
    nodes_R2 = datasample(R2(2:end-1), pi, 'Replace', false);
    
    % Calcoliamo la domanda totale associata ai nodi da scambiare
    mu_demand = sum(demand(nodes_R1));
    pi_demand = sum(demand(nodes_R2));

    % Verifichiamo che siano soddisfatti i vincoli di capacità, altrimenti
    % si ripetono i passi precendenti a partire dalla selezione del numero
    % di nodi da campionare.
    while((demand_R1-mu_demand+pi_demand >= capacity(I1)) || ...
            (demand_R2-pi_demand+mu_demand >= capacity(I2))) == true
        if length(R1) > 3
            mu = datasample(0:min(M, length(R1)-3),1);
        else
            mu = 0;
        end

        if length(R2) > 3
            pi = datasample(0:min(P, length(R2)-3),1);
        else
            pi = 0;
        end

        nodes_R1 = datasample(R1(2:end-1), mu, 'Replace', false);
        nodes_R2 = datasample(R2(2:end-1), pi, 'Replace', false);

        mu_demand = sum(demand(nodes_R1));
        pi_demand = sum(demand(nodes_R2));
    end 

    % Eliminiamo i nodi da scambiare dalle routes a cui appartengono
    R2 = [setdiff(R2, nodes_R2,'stable') 1];
    R1 = [setdiff(R1, nodes_R1,'stable') 1];
    
    % Inseriamo i nodi di R1 in R2
    nodes_to_add = nodes_R1;
    while(length(nodes_to_add)>0)
        [m,I] = min(distance(nodes_to_add,R2));
        [m,j] = min(m);
        indexNode = I(j);
        
        if length(nodes_to_add) > 1
            node = nodes_to_add(indexNode);
        else
            node = nodes_to_add;
        end
       
        % Si utilizza il criterio dell'extra mileage
        min_extra_mileage = max(max(distance));
        indexPosition = 0;
        for i = 1:length(R2)-1
            extra_mileage = distance(node, R2(i)) + distance(node, R2(i+1)) - distance(R2(i),R2(i+1));
            if (extra_mileage < min_extra_mileage)
                min_extra_mileage = extra_mileage;
                indexPosition = i;
            end
        end
        
        R2 = [R2(1:indexPosition) node R2(indexPosition+1:end)];
        if length(nodes_to_add) > 1
            nodes_to_add = [nodes_to_add(1:indexNode-1) nodes_to_add(indexNode+1:end)];
        else 
           nodes_to_add = [];
        end
    end

    
    % Inseriamo i nodi di R2 in R1
    nodes_to_add = nodes_R2;
    while(length(nodes_to_add)>0)
        [m,I] = min(distance(nodes_to_add,R1));
        [m,j] = min(m);
        indexNode = I(j);
        
        if length(nodes_to_add) > 1
            node = nodes_to_add(indexNode);
        else
            node = nodes_to_add;
        end
        
        % Si utilizza il criterio dell'extra mileage
        min_extra_miliage = max(max(distance));
        indexPosition = 0;
        for i = 1:length(R1)-1
            extra_miliage = distance(node, R1(i)) + distance(node, R1(i+1)) - distance(R1(i),R1(i+1));
            if (extra_miliage < min_extra_miliage)
                min_extra_miliage = extra_miliage;
                indexPosition = i;
            end
        end

        R1 = [R1(1:indexPosition) node R1(indexPosition+1:end)];
        if length(nodes_to_add) > 1
            nodes_to_add = [nodes_to_add(1:indexNode-1) nodes_to_add(indexNode+1:end)];
        else 
            nodes_to_add = [];  
        end
    end
    
    
    % Si operano incroci tra archi mediante la funzione 2_opt 
    for k = 1:bmax
        if length(R1)-1 > 3
            R1 = opt2(R1, distance);
        end
        if length(R2)-1 > 3
            R2 = opt2(R2, distance);
        end
    end
    
    % Aggiorniamo la lista delle routes 
    RoutesList{I1} = R1;
    RoutesList{I2} = R2;
    
    % Calcoliamo la funzione obiettivo
    tot_dist = obj_function(RoutesList, distance);
    
    % Verifichiamo che la soluzione non sia un tabu, dove tabu è della
    % forma tabu[i,:] = [k, nodo, origine, destinazione]
    found_tabu = 0;
    
    for i = 1:mu
        for k = 1:size(tabu,1)
            if (tabu(k,2) == nodes_R1(i)) == 1
                if (tabu(k,3) == R2 ) == 1 
                    if(tabu(k,4) == R1) == 1
                        found_tabu = 1;
                    end
                end
            end
        end
    end
    
    for i = 1:pi
        for k = 1:size(tabu,1)
            if (tabu(k,2) == nodes_R2(i)) == 1
                if (tabu(k,3) == R1) == 1 
                    if (tabu(k,4) == R2) == 1
                        found_tabu = 1;
                    end
                end
            end
        end
    end
        
    % Se troviamo una soluzione migliore non-tabu aggiorniamo la migliore 
    % soluzione corrente
    if(tot_dist < best_distance && found_tabu == 0)
        best_RoutesList = RoutesList;
        best_distance = tot_dist;
        best_nodes_R1 = nodes_R1;
        best_nodes_R2 = nodes_R2;
    end
end

% Determiniamo il numero di iterazioni per il tabu
t = randi([tmin, tmax],1);    

% Inseriamo i nuovi tabu
for i = 1:length(best_nodes_R1)
    tabu = [tabu; [t, best_nodes_R1(i), I1, I2]];
end

for j = 1:length(best_nodes_R2)
    tabu = [tabu; [t, best_nodes_R2(j), I2, I1]];
end

return