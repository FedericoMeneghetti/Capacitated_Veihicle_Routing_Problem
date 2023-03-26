function [best_RoutesList, tabu] = TANEC(amax, bmax, M, P, tmin, tmax, RoutesList, demand, capacity, distance, tabu, East, North)

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

    % Calcoliamo il centroide di R2
    [C2x, C2y] = my_centroid(East(R2(1:end-1)), North(R2(1:end-1)));
 
    ratios1 = [];
    for i = 2:length(R1)-1

        % Per ogni i in R1, si trova il centroide di R1 escludendo il 
        % vertice i
        [C1x, C1y] = my_centroid(setdiff(East(R1), East(R1(i)), 'stable'), setdiff(North(R1), North(R1(i)), 'stable'));
        
        % Si calcola la distanza tra C1 e il vertice i
        d1 = round(10 * sqrt(((East(R1(i)) - C1x).^2) + ((North(R1(i)) - C1y).^2)));
        
        % Si calcola la distanza tra C2 e il vertice i
        d2 = round(10 * sqrt(((East(R1(i)) - C2x).^2) + ((North(R1(i)) - C2y).^2)));
        
        ratios1 = [ratios1 d1/d2];
    end
    
    % I vertici vengono ordinati rispetto al rapporto d1/d2
    [ratios1,J1] = sort(ratios1, 'descend');
    
    %  Calcoliamo il centroide di R1
    [C1x, C1y] = my_centroid(East(R1(1:end-1)), North(R1(1:end-1)));
    
    ratios2 = [];

    % Si effettua la stessa procedura con R2
    for i = 2:length(R2)-1
        [C2x, C2y] = my_centroid(setdiff(East(R2), East(R2(i)), 'stable'), setdiff(North(R2), North(R2(i)), 'stable'));
        
        d1 = round(10 * sqrt(((East(R2(i)) - C2x).^2) + ((North(R2(i)) - C2y).^2)));
        d2 = round(10 * sqrt(((East(R2(i)) - C1x).^2) + ((North(R2(i)) - C1y).^2)));
        
        ratios2 = [ratios2 d1/d2];
    end
    
    [ratios2,J2] = sort(ratios2, 'descend');
    
    % Si selezionano i nodi da scambiare
    r1 = R1(2:end-1);
    r1 = r1(J1);
    nodes_R1 = r1(1:mu);
    
    r2 = R2(2:end-1);
    r2 = r2(J2);
    nodes_R2 = r2(1:pi);

    % Calcoliamo la domanda totale associata ai nodi da scambiare
    mu_demand = sum(demand(nodes_R1));
    pi_demand = sum(demand(nodes_R2));
    
    i = mu+1;
    j = pi+1;

    % Verifichiamo che siano soddisfatti i vincoli di capacità
    while((demand_R1-mu_demand+pi_demand >= capacity(I1)) || ...
            (demand_R2-pi_demand+mu_demand >= capacity(I2))) == true
    
    % Se non si soddisfa il vincolo di capacità, si sostituisce il nodo con
    % domanda maggiore con il nodo successivo di r1.
        if i <= length(r1)
            [m,idx] = max(demand(nodes_R1));
            nodes_R1 = setdiff(nodes_R1, nodes_R1(idx), 'stable');
            nodes_R1 = [nodes_R1 r1(i)];
        else
            mu = 0;
            nodes_R1 = [];
        end
        i = i+1;
   
        % Si effettua la stessa operazione con r2.
        if j <= length(r2)
            [m,idx] = max(demand(nodes_R2));
            nodes_R2 = setdiff(nodes_R2, nodes_R2(idx), 'stable');
            nodes_R2 = [nodes_R2 r2(j)];
        else
            pi = 0;
            nodes_R2 = [];
        end
        j = j+1;

        % Si calcola la domanda associata
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
        min_extra_miliage = max(max(distance));
        indexPosition = 0;
        for i = 1:length(R2)-1
            extra_miliage = distance(node, R2(i)) + distance(node, R2(i+1)) - distance(R2(i),R2(i+1));
            if (extra_miliage < min_extra_miliage)
                min_extra_miliage = extra_miliage;
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