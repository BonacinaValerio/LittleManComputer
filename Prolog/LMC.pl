%%%% -*- Mode: Prolog -*-
%%%% LMC.pl

%%% ---INTERPRETE---

%%% Modifica il flag
noFlag(X, Y, Flag) :-
    X == Y,
    !,
    Flag = noflag.
noFlag(_, _, Flag) :-
    Flag = flag.

%%% Sostituisci un valore indicizzato in una lista
replace([_|T], 0, X, [X|T]).
replace([H|T], I, X, [H|R]):-
    I > -1,
    NI is I-1,
    replace(T, NI, X, R),
    !.
replace(L, _, _, L).

execution_loop(state(Acc, Pc, Mem, In, Out, Flag), FinalOut) :-
    validateInOutMem(In),
    validateInOutMem(Out),
    validateInOutMem(Mem),
    initial_validate(Acc, Pc, Mem, Flag),
    !,
    exec_loop(state(Acc, Pc, Mem, In, Out, Flag), FinalOut).

%%% Loop
exec_loop(halted_state(_, _, _, _, Out, _), Out) :-
    !.
exec_loop(state(Acc, Pc, Mem, In, Out, Flag), FinalOut) :-
    one_instruction(state(Acc, Pc, Mem, In, Out, Flag), NewState),
    !,
    exec_loop(NewState, FinalOut).

%%% Gestione errori: numero di celle di memoria errato
%%%                  pc errato
%%%                  accumulatore errato
%%%                  flag errato
initial_validate(_, _, Mem, _) :-
    length(Mem, L),
    L \= 100,
    !,
    traceback_error(3),
    fail.
initial_validate(_, Pc, _, _) :-
    Pc < 0,
    !,
    traceback_error(4, Pc),
    fail.
initial_validate(_, Pc, _, _) :-
    Pc >= 100,
    !,
    traceback_error(4, Pc),
    fail.
initial_validate(Acc, Pc, _, _) :-
    Acc < 0,
    !,
    traceback_error(5, Pc),
    fail.
initial_validate(Acc, Pc, _, _) :-
    Acc >= 1000,
    !,
    traceback_error(5, Pc),
    fail.
initial_validate(_, _, _, X) :-
    X \= flag,
    X \= noflag,
    !,
    traceback_error(7),
    fail.
initial_validate(_, _, _, _) :-
    !.

%%% Controllo che in input ci siano solo interi nel range [0:999]
validateInOutMem([]) :-
    !.
validateInOutMem([X | T]) :-
    integer(X),
    X >= 0,
    X < 1000,
    !,
    validateInOutMem(T).
validateInOutMem([_ | _]) :-
    traceback_error(6),
    fail.

%%% Rileva l'istruzione corrente
isThisInstruction(Pc, Mem, X, Y, ArgOfInstr) :-
    nth0(Pc, Mem, Instr),
    Instr >= X,
    Instr < Y,
    ArgOfInstr is Instr - X.
isThisInstruction(Pc, Mem, X) :-
    nth0(Pc, Mem, X1),
    X1 == X.

%%% Evita l'overflow del Program Counter (99 + 1 = 0)
program_counter(99, 0) :-
    !.
program_counter(Pc, Pc1) :-
    Pc1 is Pc + 1.

%%% Gestione errori: stato iniziale in halted
%%%                  preleva elemento in coda di input vuota
one_instruction(halted_state(_, Pc, _, _, _, _), _) :-
    !,
    traceback_error(0, Pc),
    fail.
one_instruction(state(_, Pc, Mem, [], _, _), _) :-
    isThisInstruction(Pc, Mem, 901),
    !,
    traceback_error(1, Pc),
    fail.

%%% Halt
one_instruction(state(Acc, Pc, Mem, In, Out, Flag),
                halted_state(Acc, Pc, Mem, In, Out, Flag)):-
    isThisInstruction(Pc, Mem, 0, 100, _),
    !.

%%% Somma
one_instruction(state(Acc, Pc, Mem, In, Out, _),
                state(Acc1, Pc1, Mem, In, Out, Flag1)) :-
    isThisInstruction(Pc, Mem, 100, 200, Arg),
    !,
    nth0(Arg, Mem, Value),    % Estrapola il valore della cella
    X2 is Acc + Value,        % Esegui la somma
    Acc1 is X2 mod 1000,
    %% Calcola il modulo 1000 e metti il risultato nell'accumulatore
    noFlag(Acc1, X2, Flag1),  % Verifica il flag
    program_counter(Pc, Pc1). % Incremento del PC

%%% Sottrazione
one_instruction(state(Acc, Pc, Mem, In, Out, _),
                state(Acc1, Pc1, Mem, In, Out, Flag1)) :-
    isThisInstruction(Pc, Mem, 200, 300, Arg),
    !,
    nth0(Arg, Mem, Value),    % Estrapola il valore della cella
    X2 is Acc - Value,        % Esegui la sottrazione
    Acc1 is X2 mod 1000,
    %% Calcola il modulo 1000 e metti il risultato nell'accumulatore
    noFlag(Acc1, X2, Flag1),  % Verifica il flag
    program_counter(Pc, Pc1). % Incremento del PC

%%% Store
one_instruction(state(Acc, Pc, Mem, In, Out, Flag),
                state(Acc, Pc1, Mem1, In, Out, Flag)) :-
    isThisInstruction(Pc, Mem, 300, 400, Arg),
    !,
    replace(Mem, Arg, Acc, Mem1),
    %% Sostituisci il valore nella cella di memoria
    program_counter(Pc, Pc1).       % Incremento del PC

%%% Load
one_instruction(state(_, Pc, Mem, In, Out, Flag),
                state(Acc1, Pc1, Mem, In, Out, Flag)) :-
    isThisInstruction(Pc, Mem, 500, 600, Arg),
    !,
    nth0(Arg, Mem, Acc1),      % Sostituisci il valore dell'accumulatore
    program_counter(Pc, Pc1).  % Incremento del PC

%%% Branch
one_instruction(state(Acc, Pc, Mem, In, Out, Flag),
                state(Acc, Pc1, Mem, In, Out, Flag)) :-
    isThisInstruction(Pc, Mem, 600, 700, Pc1),
    !.

%%% Branch if zero
one_instruction(state(Acc, Pc, Mem, In, Out, Flag),
                state(Acc, Pc1, Mem, In, Out, Flag)) :-
    isThisInstruction(Pc, Mem, 700, 800, Pc1),
    Acc == 0,   % Branch se l'accumulatore e' uguale a 0 e il flag e' assente
    Flag == noflag,
    !.

%%% Branch if positive
one_instruction(state(Acc, Pc, Mem, In, Out, Flag),
                state(Acc, Pc1, Mem, In, Out, Flag)) :-
    isThisInstruction(Pc, Mem, 800, 900, Pc1),
    Flag == noflag,    % Branch se il flag e' assente
    !.

%%% Altrimenti non saltare (BRP/BRZ)
one_instruction(state(Acc, Pc, Mem, In, Out, Flag),
                state(Acc, Pc1, Mem, In, Out, Flag)) :-
    isThisInstruction(Pc, Mem, 700, 800, _),
    !,
    program_counter(Pc, Pc1).  % Incremento del PC
one_instruction(state(Acc, Pc, Mem, In, Out, Flag),
                state(Acc, Pc1, Mem, In, Out, Flag)) :-
    isThisInstruction(Pc, Mem, 800, 900, _),
    !,
    program_counter(Pc, Pc1).  % Incremento del PC

%%% Input
%%% Metti il primo elemento della coda di input nell'accumulatore
one_instruction(state(_, Pc, Mem, [H | T], Out, Flag),
                state(H, Pc1, Mem, T, Out, Flag)) :-
    isThisInstruction(Pc, Mem, 901),
    !,
    program_counter(Pc, Pc1).  % Incremento del PC

%%% Output
one_instruction(state(Acc, Pc, Mem, In, Out, Flag),
                state(Acc, Pc1, Mem, In, Out1, Flag)) :-
    isThisInstruction(Pc, Mem, 902),
    !,
    append(Out, [Acc], Out1),  % Aggiungi l'accumulatore nella coda di output
    program_counter(Pc, Pc1).  % Incremento del PC

%%% Gestione errori: opcode non valido
one_instruction(state(_, Pc, _, _, _, _), _) :-
    !,
    traceback_error(2, Pc),
    fail.


%%% ---COMPILATORE---

%%% Controllo se una stringa rappresenta un intero
is_a_number(L1, String, X) :-
    string_length(String, L),
    L1 is L + 1,
    !,
    term_string(X, String),
    integer(X).
is_a_number(L1, String, X) :-
    get_string_code(L1, String, A),
    A >= 48,
    A =< 57,
    !,
    L2 is L1 + 1,
    is_a_number(L2, String, X).
is_a_number(_, _, _) :-
    !,
    fail.

%%% Gestione e generazione del numero di celle di memoria mancanti
number_instructions(Mem, Mem1) :-
    length(Mem, L),
    L == 0,
    !,
    randseq(99, 99, OtherMem),
    append([0], OtherMem, Mem1).
number_instructions(Mem, Mem1) :-
    length(Mem, L),
    L < 100,
    !,
    X1 is 100 - L,
    randseq(X1, 99, OtherMem),
    append(Mem, OtherMem, Mem1).
number_instructions(Mem, Mem) :-
    !.

%%% Launcher compilatore e interprete
lmc_run(FileName, In, Out) :-
    nonvar(FileName),
    nonvar(In),
    var(Out),
    lmc_load(FileName, Mem),
    execution_loop(state(0, 0, Mem, In, [], noflag), Out).

%%% Launcher compilatore, restituisce la memoria dello stato iniziale
lmc_load(Filename, Mem) :-
    open(Filename, read, In),
    read_string(In, _, String),
    parse(String, Mem),
    close(In).

%%% Rimuovi i commenti
removeComment(Line, NewLine) :-
    string_to_list(Line, List_char),
    comment(List_char, List_char, NewLineList),
    string_to_list(NewLine, NewLineList),
    !.
comment([], Line, Line) :-
    !.
comment([_], Line, Line) :-
    !.
comment([47, 47 | T], Line, NewLine) :-
    !,
    append(NewLine, [47, 47 | T], Line).
comment([_, Y | T], Line, NewLine) :-
    !,
    comment([Y | T], Line, NewLine).

%%% Parse generale
parse(Input, InitialMem) :-
    split_string(Input, "\n", "\s\t\n", L),
    preParseLine(L, DictE, L1, 0),
    %% Rimuove i commenti e righe vuote, crea il dizionario delle etichette,
    %% gestione del case-insensive
    length(L1, Len),
    !,
    validate_length(Len),  % Controllo che le istruzioni assembly siano <= 100
    parseLine(L1, DictE, Mem),  % Parse effettivo delle istruzioni
    number_instructions(Mem, InitialMem). % generazione del resto della memoria

%%% controllo numero di istruzioni
validate_length(Len) :-
    Len =< 100,
    !.
validate_length(_) :-
    traceback_error(8),
    fail.

%%% Preparazione per il parse (Rimozione commenti e righe vuote, crea il
%%% dizionario delle etichette per il parse effettivo)
preParseLine([], [], _, _) :-
    !.
preParseLine([H | T], [E | T1], [L2 | T2], Index) :-
    removeComment(H, L),      % Rimuove i commenti
    L \= "",                  % Continua se la riga senza commento non e' vuota
    !,
    string_upper(L, L1),          % Tutto in maiuscolo per il case-insensitive
    split_string(L1, "\s\t", "\s\t", L2),  % Da stringha a lista di parole
    Newindex is Index + 1,        % Creo l'indice per la riga dopo
    get_etichette(L2, E, Index),
    %% Restituisce l'etichetta associata alla riga se esiste
    preParseLine(T, T1, T2, Newindex).
preParseLine([_ | T], T1, T2, Index) :-
    !,
    preParseLine(T, T1, T2, Index).  % La riga vuota viene ignorata

%%% Restituisce le etichette se sono presenti (non effettua alcun
%%% controllo su possibili errori)
get_etichette([E, _, _], etichetta(E, Index), Index) :-
    !.
get_etichette([X, Y], etichetta(X, Index), Index) :-
    istruzioniNoArg(Y, _),
    !.
get_etichette([_ | _], etichetta(0, Index), Index):-
    !.

%%% Parse effettivo delle istruzioni riga per riga
parseLine([], _, []) :-
    !.
parseLine([L | T], DictE, [C | T1]) :-
    one_instructionA(L, DictE, C),  % Gestione errori e parse singola riga
    parseLine(T, DictE, T1).        % Chiamata ricorsiva

%%% [Gestione errore] Riga da 4 parole o piu'
one_instructionA([_, _, _, _ | _], _, _) :-
    !,
    traceback_error(9),
    fail.

%%% Riga da 3 parole
%%% [Gestione errore] L'etichetta e' un numero o una Keyword
one_instructionA([X, _, _], _, _) :-
    is_a_number(1, X, _),
    traceback_error(10),
    !,
    fail.
one_instructionA([X, _, _], _, _) :-
    istruzioni(X, _),
    !,
    traceback_error(11),
    fail.
one_instructionA([X, _, _], _, _) :-
    istruzioniNoArg(X, _),
    !,
    traceback_error(11),
    fail.

%%% [Gestione errore] L'istruzione non identifica alcuna operazione che
%%% prevede parametri
one_instructionA([_, X, Y], DictE, C):-
    istruzioni(X, _),
    !,
    parse_one_instructionA([X, Y], DictE, C).
    %% Viene effettuato il parse rimuovendo l'etichetta
one_instructionA([_, _, _], _, _) :-
    !,
    traceback_error(12),
    fail.

%%% Riga da 2 parole
%%% [Gestione errore] La prima parola e' un numero o una Keyword di
%%% istruzione che non prevede parametri (ad eccezione della "DAT")
one_instructionA([X, _], _, _) :-
    is_a_number(1, X, _),
    traceback_error(10),
    !,
    fail.
one_instructionA([X, _], _, _) :-
    istruzioniNoArg(X, _),
    X \= "DAT",
    traceback_error(12),
    !,
    fail.
%%% Se la prima parola e' un istruzione con parametri viene parsata
one_instructionA([X, Y], DictE, C) :-
    istruzioni(X, _),  % La prima parola e' un istruzione
    !,
    parse_one_instructionA([X, Y], DictE, C).
    %% viene effettuato il parse direttamente

%%% Altrimenti la prima parola e' quindi un etichetta
%%% [Gestione errore] La seconda parola non e' una Keyword di un istruzione
%%% che non prevede parametri
one_instructionA([_, Y], DictE, C) :-
    istruzioniNoArg(Y, _),  % La seconda parola e' un istruzione no arg
    !,
    parse_one_instructionA([Y], DictE, C).
    %% Viene effettuato il parse rimuovendo l'etichetta
one_instructionA([_, _], _, _) :-
    !,
    traceback_error(15), % Istruzione non valida
    fail.

%%% Riga da 1 parola
%%% [Gestione errore] La prima parola e' un numero o una Keyword di
%%% istruzione che prevede parametri (ad eccezione della "DAT")
one_instructionA([X], _, _) :-
    is_a_number(1, X, _),
    traceback_error(10),
    !,
    fail.
one_instructionA([X], _, _) :-
    istruzioni(X, _),
    X \= "DAT",
    traceback_error(13),
    !,
    fail.
one_instructionA([X], DictE, C) :-
    istruzioniNoArg(X, _),  % La parola e' un istruzione no args
    !,
    parse_one_instructionA([X], DictE, C).
    %% Viene effettuato il parse direttamente
one_instructionA([_], _, _) :-
    !,
    traceback_error(15),
    fail.

%%% Estrai il numero della cella di memoria associata all'etichetta data
getEtichetta(_, [], _) :-   % [Errore] Etichetta mai allocata
    !,
    traceback_error(14),
    fail.
getEtichetta(X, [etichetta(X, Index) | _], Index) :-
    !.
getEtichetta(X, [etichetta(_, _) | T], Index) :-
    !,
    getEtichetta(X, T, Index).

%%% Dichiarazione istruzioni con args e istruzioni no args
istruzioni("ADD", 100).
istruzioni("SUB", 200).
istruzioni("STA", 300).
istruzioni("LDA", 500).
istruzioni("BRA", 600).
istruzioni("BRZ", 700).
istruzioni("BRP", 800).
istruzioni("DAT", 0).
istruzioniNoArg("HLT", 0).
istruzioniNoArg("INP", 901).
istruzioniNoArg("OUT", 902).
istruzioniNoArg("DAT", 0).

%%% Parse istruzioni con args numerici
%%% [Gestione errore] Il parametro e' un numero fuori dal range [0:99]/[0:999]
%%% o e' un etichetta passata alla DAT
parse_one_instructionA([Instr, Y], _, C) :-
    is_a_number(1, Y, Y1),
    istruzioni(Instr, Id),  % Arg in range [0:99]
    Y1 >= 0,
    Y1 < 100,
    !,
    C is Id + Y1. % Creo l'istruzione
parse_one_instructionA([Instr, Y], _, C) :-
    is_a_number(1, Y, Y1),
    istruzioni(Instr, Id),       % L'istruzione e' una DAT
    istruzioniNoArg(Instr, Id),  % Arg in range [0:999]
    Y1 >= 0,
    Y1 < 1000,
    !,
    C is Id + Y1. % Creo l'istruzione
parse_one_instructionA([_, Y], _, _) :-
    is_a_number(1, Y, _),
    !,
    traceback_error(16),
    fail.
parse_one_instructionA([Instr, _], _, _) :-
    istruzioni(Instr, Id),       % L'istruzione e' una DAT
    istruzioniNoArg(Instr, Id),  % e l'arg non e' un numero
    !,
    traceback_error(15),
    fail.

%%% Parse istruzioni con args di etichette
parse_one_instructionA([Instr, Y], DictE, C) :-
    !,
    getEtichetta(Y, DictE, Index),
    %% Trova la cella di memoria associata all'etichetta
    istruzioni(Instr, Id),
    C is Id + Index. % Creo l'istruzione

%%% Parse istruzioni senza args
parse_one_instructionA([X], _, C) :-
    !,
    istruzioniNoArg(X, C). % Creo l'istruzione

%%% Traceback errori
traceback_error(Id, Pc) :-
    !,
    error(Id, String),
    number_string(Pc, X),
    string_concat(String, X, String1),
    writef(String1).
traceback_error(Id) :-
    error(Id, String),
    writef(String).

%%% Lista errori
error(0, "Interprete: Errore.
Impossibile elaborare un'halted_state. PC = ").
error(1, "Interprete: Errore.
Non e' stato trovato alcun valore nella coda di input. PC = ").
error(2, "Interprete: Errore.
Istruzione non valida. PC = ").
error(3, "Interprete: Errore.
Numero celle di memoria errato").
error(4, "Interprete: Errore.
Program counter ha assunto un valore non consentito. PC = ").
error(5, "Interprete: Errore.
Accumulatore ha assunto un valore non consentito. PC = ").
error(6, "Interprete: Errore.
La memoria o la coda di input o di output presenta un valore non consentito").
error(7, "Interprete: Errore.
Il valore del flag deve essere rappresentato solo dai termini: flag/noflag").
error(8, "Compilatore: Errore.
Il numero di istruzioni supera lo spazio di memoria disponibile").
error(9, "Compilatore: Errore.
Impossibile contenere sulla stessa riga piu' di 3 parole").
error(10, "Compilatore: Errore.
Impossibile usare come etichetta un numero").
error(11, "Compilatore: Errore.
Impossibile usare come etichetta una keyword").
error(12, "Compilatore: Errore.
Impossibile passare parametri ad un'instruzione non adatta per questo scopo").
error(13, "Compilatore: Errore.
Non e' stato trovato alcun parametro per un'istruzione che ne necessitava").
error(14, "Compilatore: Errore.
Impossibile trovare il valore di un'etichetta mai allocata.").
error(15, "Compilatore: Errore.
Istruzione non valida.").
error(16, "Compilatore: Errore.
Impossibile inserire argomenti fuori dai loro range stabiliti.").