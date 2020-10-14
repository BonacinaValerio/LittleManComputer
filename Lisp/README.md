# IMPLEMENTAZIONI (LISP)

Lo stato del LMC deve essere rappresentato da una lista della seguente forma nel caso non sia stata ancora eseguita una istruzione di halt:

    (STATE :ACC <Acc> :PC <PC> :MEM <Mem> :IN <In> :OUT <Out> :FLAG <Flag>)

Nel caso contrario bisogna usare halted_state invece di state:

    (HALTED-STATE :ACC <Acc> :PC <PC> :MEM <Mem> :IN <In> :OUT <Out> :FLAG <Flag>)

# FUNZIONI PRINCIPALI

 - `(one-instruction State)` : 	
La funzione ritorna un nuovo stato dopo l'esecuzione di una singola istruzione a partire da State. La funzione ritorna nil nei seguenti casi:
	1. Lo stato State è un halting-state, ovvero il sistema è stato arrestato e non può eseguire istruzioni.
	2. L'istruzione da eseguire è di input ma la coda di input è vuota.
	3. L'istruzione da eseguire non è valida.

 - `(execution-loop State)` : 
La funzione ritorna la coda di output nel momento in cui viene raggiunto uno stato di stop partendo dallo stato iniziale del LMC rappresentato da State.
 - `(lmc-load Filename)` :
	Si preoccupa di leggere un file che contiene un codice assembler e che produce il contenuto "iniziale" della memoria sistema (una lista di 100 numeri tra 0 e 999).
 - `(lmc-run Filename Inp)` :
Si preoccupa di leggere un file che contiene un codice assembler, lo carica con lmc-load, imposta la coda di input al valore fornito e produce un output che è il valore ritornato dell'invocazione di execution-loop.

# CASI DI ERRORE/RITORNO NIL (IMPORTANTE!!)

 1. Interprete: 
	- Impossibile elaborare un'halted-state (one-instruction).
    - Non e' stato trovato alcun valore nella coda di input (one-instruction).
    - Istruzione non valida (one-instruction).
    - Numero celle di memoria errato (è stato passato a execution-loop una memoria di lunghezza diversa da 100).
    - Program counter ha assunto un valore non consentito (PC<0 oppure >=100).
    - Accumulatore ha assunto un valore non consentito. (ACC<0 oppure >=1000).
    - La memoria o la coda di input o di output presenta un valore non consentito (i valori consentiti per queste liste sono numeri >=0 e <1000).
    - Il valore del flag non è rappresentato dai termini flag o noflag.
 2. Compilatore:
    - Il numero di istruzioni supera lo spazio di memoria disponibile (numero di istruzione assembly >100).
    - Impossibile contenere sulla stessa riga più di 3 parole.
    - Impossibile usare come etichetta un numero.
    - Impossibile usare come etichetta una keyword.
    - Impossibile passare parametri ad un'istruzione non adatta per questo scopo (es. INP 12).
    - Non è stato trovato alcun parametro per un'istruzione che ne necessitava (es. ADD, SUB).
    - Impossibile trovare il valore di un'etichetta mai allocata.
    - Istruzione non valida. (es SOMMA 12, DAT ETICHETTA)
    - Impossibile inserire argomenti fuori dai loro range stabiliti (i range stabiliti sono [0:99] per le istruzioni con args e [0:999] per la DAT).

## CASI PARTICOLARI

 - Se vengono dichiarate due etichette uguali il programma non ritorna nil ma considera valida la prima etichetta dichiarata.
 - Le etichette considerate valide sono quelle ALFANUMERICHE quindi etichette del tipo "1ciao" sono consentite.
