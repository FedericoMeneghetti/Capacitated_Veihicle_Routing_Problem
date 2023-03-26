function newR = opt2(R, distance)

%   L'operazione base è sostituire la coppia di archi(ab,cd) con la coppia
%   (ac,bd). L'algoritmo esamina tutte le possibili coppie di archi della 
%   route e applica lo scambio migliore. Questa procedura viene iterata 
%   fino a quando la lunghezza della route decresce.

R = R(1:end-1);
n = length(R);


% Inizializzazione
max_improvement = -2*max(max(distance));    
i = 0;
b = R(n);


% Il seguente loop esplora tutte le coppie di vertici (ab,cd)
while i < n-2
    a = b;
    i = i+1;
    b = R(i);
    j = i+1;
    d = R(j);
    while j < n
        c = d;
        j = j+1;
        d = R(j);
        improvement = distance(a,b)+distance(c,d)-distance(a,c)-distance(b,d);
        if improvement > max_improvement
            max_improvement = improvement;  % si seleziona lo scambio migliore
            imin = i;
            jmin = j;
        end
    end
end


% Se lo scambio migliore accorcia la lunghezza della route, allora lo si
% effettua
if max_improvement > 0
    R(imin:jmin-1) = R(jmin-1:-1:imin);
end

for i = 2:length(R)
    if R(i) == 1
        R = [R(i:end) R(1:i-1)];
    end
end
newR = [R 1];
return