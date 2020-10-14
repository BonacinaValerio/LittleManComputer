## ARCHITETTURA DEL LMC

Il LMC è composto dalle seguenti componenti: 

 1. Una **memoria** di 100 celle numerate tra 0 e 99. Ogni cella può     contenere un numero tra 0 e 999. Non viene effettuata alcuna distinzione tra dati e istruzioni: a seconda del momento il contenuto di una certa cella può essere interpretato come un’istruzione (con una semantica che verrà spiegata in seguito) oppure come un dato (e, ad esempio, essere sommato ad un altro valore).
 2. Un **registro accumulatore** (inizialmente zero).
 3. Un **program counter**. Il program counter contiene l’indirizzo dell’istruzione da eseguire ed è inizialmente zero. Se non viene sovrascritto da altre istruzioni (salti condizionali e non condizionali) viene incrementato di uno ogni volta che un’istruzione  viene eseguita. Se raggiunge il valore 999 e viene incrementato il valore successivo è zero.
 4. Una **coda di input**. Questa coda contiene tutti i valori forniti in input al LMC, che sono necessariamente numeri compresi tra 0 e 999. Ogni volta che l’LMC legge un valore di input esso viene eliminato dalla coda.
 5. Una **coda di output**. Questa coda è inizialmente vuota e contiene tutti i valori mandati in output dal LMC, che sono necessariamente numeri compresi tra 0 e 999. La coda è strutturata in modo tale da avere in testa il primo output prodotto e come ultimo elemento l’ultimo output prodotto: i valori di output sono quindi in ordine cronologico.
 6. Un **ﬂag**. Ovvero un singolo bit che può essere acceso o spento. Inizialmente esso è zero (ﬂag assente). Solo le istruzioni aritmetiche modiﬁcano il valore del ﬂag e, in particolare, un ﬂag a uno (ﬂag presente) indica che l’ultima operazione aritmetica eseguita ha prodotto un risultato maggiore di 999 o minore di 0. Un ﬂag assente indica invece che il valore prodotto dall’ultima operazione aritmetica ha prodotto un risultato compreso tra 0 e 999.

La seguente tabella rappresenta come le istruzioni presenti in memoria debbano essere interpretate: 

| Valore | Nome Istruzione    | Significato                                                                                                                                                                                                                                                                                                                           |
|--------|--------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1xx    | Addizione          | Somma il contenuto della cella di memoria xx con il valore contenuto nell’accumulatore e scrive il valore risultante nell’accumulatore. Il valore salvato nell’accumulatore è la somma modulo 1000. Se la somma non supera 1000 il ﬂag è impostato ad assente, se invece raggiunge o supera 1000 il ﬂag è impostato a presente.       |
| 2xx    | Sottrazione        | Sottrae il contenuto della cella di memoria xx dal valore contenuto nell’accumulatore e scrive il valore risultante nell’accumulatore. Il valore salvato nell’accumulatore è la differenza modulo 1000. Se la differenza è inferiore a zero il ﬂag è impostato a presente, se invece è positiva o zero il ﬂag è impostato ad assente. |
| 3xx    | Store              | Salva il valore contenuto nell’accumulatore nella cella di memoria avente indirizzo xx. Il contenuto dell’accumulatore rimane invariato.                                                                                                                                                                                              |
| 5xx    | Load               | Scrive il valore contenuto nella cella di memoria di indirizzo xx nell’accumulatore. Il contenuto della cella di memoria rimane invariato.                                                                                                                                                                                            |
| 6xx    | Branch             | Salto non condizionale. Imposta il valore del program counter a xx.                                                                                                                                                                                                                                                                   |
| 7xx    | Branch if zero     | Salto condizionale. Imposta il valore del program counter a xx solamente se il contenuto dell’accumulatore è zero e se il ﬂag è assente.                                                                                                                                                                                              |
| 8xx    | Branch if positive | Salto condizionale. Imposta il valore del program counter a xx solamente se il ﬂag è assente.                                                                                                                                                                                                                                         |
| 901    | Input              | Scrive il contenuto presente nella testa della coda in input nell’accumulatore e lo rimuove dalla coda di input.                                                                                                                                                                                                                      |
| 902    | Output             | Scrive il contenuto dell’accumulatore alla ﬁne della coda di output. Il contenuto dell’accumulatore rimane invariato.                                                                                                                                                                                                                 |
| 0xx    | Halt               | Termina l’esecuzione del programma. Nessuna ulteriore istruzione viene eseguita.                                                                                                                                                                                                                                                      |

Alcuni devi valori non corrispondono a nessuna istruzione. Ad esempio tutti i numeri tra 400 e 499 non hanno un corrispettivo. Questo signiﬁca che corrispondono a delle istruzioni non valide (illegal instructions) e che LMC si fermerà con una condizione di errore. 
Quindi, ad esempio, se l’accumulatore contiene il valore 42, il program counter ha valore 10 ed il contenuto della cella numero 10 è 307, il LMC eseguirà una istruzione di store, dato che il valore è nella forma 3xx. In particolare, il contenuto dell’accumulatore, ovvero 42, verrà scritto nella cella di memoria numero 7 (dato che xx corrisponde a 07). Il program counter verrà poi incrementato di uno, assumendo il valore 11. La procedura verrà ripetuta ﬁnché non verrà incontrata un’istruzione di halt o un’istruzione non valida. 

## ASSEMBLY PER LMC

Oltre a fornire una simulazione per il LMC si deve essere anche in grado di passare da un programma scritto in codice assembly per LMC (che verrà successivamente dettagliato) al contenuto iniziale della memoria del LMC, convertendo quindi il codice assembly in codice macchina. 
Nel ﬁle sorgente assembly ogni riga contiene al più una etichetta ed una istruzione. Ogni istruzione corrisponde al contenuto di una cella di memoria. La prima istruzione assembly presente nel ﬁle corrisponderà al valore contenuto nella cella 0, la seconda al valore contenuto nella cella 1, e così via. 
| Istruzione | Valori possibili per xx | Signiﬁcato                                                                                                                   |
|------------|-------------------------|------------------------------------------------------------------------------------------------------------------------------|
| ADD xx     | Indirizzo o etichetta   | Esegui l’istruzione di addizione tra l’accumulatore e il valore contenuto nella cella indicata da xx                         |
| SUB xx     | Indirizzo o etichetta   | Esegui l’istruzione di sottrazione tra l’accumulatore e il valore contenuto nella cella indicata da xx                       |
| STA xx     | Indirizzo o etichetta   | Esegue una istruzione di store del valore dell’accumulatore nella cella indicata da xx                                       |
| LDA xx     | Indirizzo o etichetta   | Esegue una istruzione di load dal valore contenuto nella cella indicata da xx nell’accumulatore                              |
| BRA xx     | Indirizzo o etichetta   | Esegue una istruzione di branch non condizionale al valore indicato da xx                                                    |
| BRZ xx     | Indirizzo o etichetta   | Esegue una istruzione di branch condizionale (se l’accumulatore è zero e non vi è il ﬂag acceso) al valore indicato da xx.   |
| BRP xx     | Indirizzo o etichetta   | Esegue una istruzione di branch condizionale (se non vi è il ﬂag acceso) al valore indicato da xx.                           |
| INP        | Nessuno                 | Esegue una istruzione di input                                                                                               |
| OUT        | Nessuno                 | Esegue una istruzione di output                                                                                              |
| HLT        | Nessuno                 | Esegue una istruzione di halt                                                                                                |
| DAT xx     | Nessuno                 | Memorizza nella cella di memoria corrispondente a questa istruzione assembly il valore xx                                    |
| DAT        | Nessuno                 | Memorizza nella cella di memoria corrispondente a questa istruzione assembly il valore 0 (equivalente all’istruzione DAT 0). |

Ogni riga del ﬁle assembly con una istruzione può contenere prima dell’istruzione una etichetta, ovvero una stringa di caratteri usata per identiﬁcare la cella di memoria dove verrà salvata l’istruzione corrente. Le etichette possono poi essere utilizzate al posto degli indirizzi (ovvero numeri tra 0 e 99) all’interno del sorgente. Si veda, ad esempio: 
| Assembly  | Cella di memoria | Codice macchina |
|-----------|------------------|-----------------|
| BRA LABEL | 1                | 600             |

In questo caso l’etichetta presente nella prima riga assume il valore 0 tutte le volte che appare come argomento di un’altra istruzione. Per un esempio già completo si osservi: 

| Assembly      | Cella di memoria | Codice macchina |
|---------------|------------------|-----------------|
| LOAD LDA 0    | 0                | 500             |
|      OUT      | 1                | 902             |
|      SUB ONE  | 2                | 208             |
|      BRZ ONE  | 3                | 708             |
|      LDA LOAD | 4                | 500             |
|      ADD ONE  | 5                | 108             |
|      STA LOAD | 6                | 300             |
|      BRA LOAD | 7                | 600             |
| ONE  DAT 1    | 8                | 1               |

In questo caso ci sono due etichette (LOAD e ONE) che assumono valore 0 e 8 rispettivamente. Questo corrisponde alla cella di memoria dove la versione convertita in codice macchina dell’istruzione assembly presente nella stessa riga è stata salvata. Si noti inoltre come le etichette possano essere utilizzate prima di venire deﬁnite. Se una riga contiene una doppia barra (//) tutto il resto della riga deve venire ignorato e considerato come commento. L’assembly è inoltre case-insensitive e possono esserci uno o più spazi tra etichetta e istruzione e etichetta e argomento. 
Le seguenti istruzioni sono quindi tutte equivalenti: 

    ADD 3 
    Add 3 
    add 3 // Questo è un commento 
    ADD 3 // Aggiunte il valore della cella 3 all’accumulatore 
    aDD    3 
