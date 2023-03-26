function [best_solution] = tabu_search(Nmax, amax, bmax, M, P, tmin, tmax, distance, demand, capacity, RoutesList, East, North) 

% Inizializzazione
tabu = zeros(1,4);
numNodes = length(distance);

% Definiamo la migliore soluzione corrente e il valore della relativa
% funzione obiettivo.
best_solution = RoutesList;
obj_best_solution = obj_function(RoutesList, distance);  

% A ogni iterazione si applicano TANE e TANEC e si valuta la migliore
for n = 1:Nmax
    [RoutesList_TANE, tabu] = TANE(amax, bmax, M, P, tmin, tmax, RoutesList, demand, capacity, distance, tabu);
    [RoutesList_TANEC, tabu] = TANEC(amax, bmax, M, P, tmin, tmax, RoutesList, demand, capacity, distance, tabu, East, North);
    
    if (obj_function(RoutesList_TANE, distance) < obj_function(RoutesList_TANEC, distance))
        RoutesList = RoutesList_TANE;
        obj_solution = obj_function(RoutesList, distance);
    else
        RoutesList = RoutesList_TANEC;
        obj_solution = obj_function(RoutesList, distance);
    end
    
    % Si aggiorna la matrice dei tabu
    num_tabu = size(tabu,1);
    j = 1;
    for i = 1:num_tabu
        if tabu(j,1) < 2
            tabu = [tabu(1:j-1, :); tabu(j+1:end,:)];
            j = j-1;
        else
            tabu(j,1) = tabu(j,1) - 1;
        end
        j = j+1;
    end    
   
    % Ogni 5*numNodes iterazioni, l'algoritmo controlla se è stata trovata 
    % una soluzione migliore, altrimenti ritorna alla soluzione
    % precedentemente trovata.
    if mod(n,5*numNodes) == 0
        if obj_solution < obj_best_solution
            obj_best_solution = obj_solution;
            best_solution = RoutesList;
            
        else
            RoutesList = best_solution;
        end
    end
    
end
return
    
    
    
    
   