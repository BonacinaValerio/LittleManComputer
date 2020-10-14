;;; ---INTERPRETE---

;;; Loop
(defun execution-loop (state)
  (let ((state_var (rest state)))
    (cond ((and (validate state_var)
                (validate_list (getf state_var :mem))
                (validate_list (getf state_var :in))
                (validate_list (getf state_var :out))) (exec_loop state))
          (T nil))))

(defun exec_loop (state)
  (cond ((null state) nil)
        (t (let ((prefix (first state))
                 (state_var (rest state)))
             (cond ((eql prefix 'halted-state) (getf state_var :out))
                   ((eql prefix 'state) (exec_loop (one-instruction state)))
                   (T nil))))))

;;; Gestione errori: stato iniziale malformato
;;;                  accumulatore errato
;;;                  pc errato
;;;                  numero di celle di memoria errato
;;;                  flag errato  
(defun validate (lst)
  (let ((acc (getf lst :acc -1))
        (pc (getf lst :pc -1))
        (mem (getf lst :mem '()))
        (in (getf lst :in -1))
        (out (getf lst :out -1))
        (flag (getf lst :flag 'not_found)))
    (cond ((and (atom in) (not (eql in '()))) (traceback_error 17) nil)
          ((and (atom out) (not (eql out '()))) (traceback_error 17) nil) 
          ((/= 12 (list-length lst)) (traceback_error 17) nil) 
          ((< acc 0) (traceback_error 5) nil)
          ((>= acc 1000) (traceback_error 5) nil)
          ((< pc 0) (traceback_error 4) nil)
          ((>= pc 100) (traceback_error 4) nil)
          ((/= 100 (list-length mem)) (traceback_error 3) nil)
          ((and (not (eql flag 'flag)) (not (eql flag 'noflag))) 
           (traceback_error 7) nil)
          (t t))))

;;; Controllo che in input ci siano solo interi nel range [0:999]
(defun validate_list (lst)
  (cond ((null lst) t)
        ((not (numberp (first lst))) (traceback_error 6) nil)
        ((and (integerp (first lst))
              (>= (first lst) 0)
              (< (first lst) 1000)) (validate_list (rest lst)))
        (t (traceback_error 6) nil)))

;;; Rileva l'istruzione corrente
(defun is_this_instruction (instr x y)
  (and (>= instr x) (< instr y)))
(defun is_this_instruction_noarg (instr x)
  (= instr x))

;;; singola istruzione
(defun one-instruction (state)
  (let ((prefix (first state))
        (state_var (rest state))
        (acc (getf (rest state) :acc))
        (pc (getf (rest state) :pc))
        (mem (getf (rest state) :mem))
        (in (getf (rest state) :in))
        (out (getf (rest state) :out))
        (flag (getf (rest state) :flag))
        (instr (nth (getf (rest state) :pc) (getf (rest state) :mem))))
;; Gestione errori: stato iniziale in halted
;;                  preleva elemento in coda di input vuota
    (cond ((eql prefix 'halted-state) (traceback_error 0) nil)
          ((and (is_this_instruction_noarg instr 901) (null in)) 
           (traceback_error 1) nil)
          ;; Halt
          ((is_this_instruction instr 0 100) 
           (cons 'halted-state state_var))
          ;; Somma
          ((is_this_instruction instr 100 200) 
           (somma acc pc mem in out instr))
          ;; Sottrazione
          ((is_this_instruction instr 200 300) 
           (sottrazione acc pc mem in out instr))
          ;; Store
          ((is_this_instruction instr 300 400) 
           (store acc pc mem in out flag instr))
          ;; Load
          ((is_this_instruction instr 500 600) 
           (lda pc mem in out flag instr))
          ;; Branch
          ((is_this_instruction instr 600 700) 
           (bra acc mem in out flag instr))
          ;; Branch if zero
          ((is_this_instruction instr 700 800) 
           (brz pc acc mem in out flag instr))
          ;; Branch if positive
          ((is_this_instruction instr 800 900) 
           (brp pc acc mem in out flag instr))
          ;; Input
          ((is_this_instruction_noarg instr 901) 
           (input pc mem in out flag))
          ;; Output
          ((is_this_instruction_noarg instr 902) 
           (output acc pc mem in out flag))
          ;; Gestione errori: opcode non valido
          (t (traceback_error 2) nil)
          )))

;;; Evita l'overflow del Program Counter (99 + 1 = 0)
(defun program_counter (pc)
  (cond ((= pc 99) 0)
        (t (+ pc 1))))

;;; Modifica il flag
(defun no_flag (x y)
  (cond ((= x y) 'noflag)
        ((/= x y) 'flag)))

;;; Sostituisci un valore indicizzato in una lista
(defun replace_elem (mem arg acc)
  (cond
    ((null mem) ())
    ((= arg 0) (cons acc (rest mem)))
    (t (cons (first mem) 
             (replace_elem (rest mem) (- arg 1) acc)))))

;;; somma
(defun somma (acc pc mem in out instr)
  (let ((sum (+                       ; Esegui la somma
              (nth (- instr 100) mem) ; Estrapola il valore della cella
              acc)) 
        ;; Calcola il modulo 1000 e metti il risultato nell'accumulatore
        (acc1 (mod (+
                    (nth (- instr 100) mem) 
                    acc) 
                   1000)))
    (list 'state 
          :acc acc1
          :pc (program_counter pc)    ; Incremento del PC
          :mem mem 
          :in in 
          :out out 
          :flag (no_flag sum acc1)))) ; Verifica il flag

;;; sottrazione  
(defun sottrazione (acc pc mem in out instr)
  (let ((sub (-                         ; Esegui la sottrazione
              acc
              (nth (- instr 200) mem))) ; Estrapola il valore della cella 
        ;; Calcola il modulo 1000 e metti il risultato nell'accumulatore
        (acc1 (mod (- 
                    acc
                    (nth (- instr 200) mem))
                   1000)))
    (list 'state 
          :acc acc1
          :pc (program_counter pc)    ; Incremento del PC
          :mem mem 
          :in in 
          :out out 
          :flag (no_flag sub acc1)))) ; Verifica il flag

;;; store
(defun store (acc pc mem in out flag instr) 
  (list 'state 
          :acc acc
          :pc (program_counter pc)    ; Incremento del PC
          :mem (replace_elem mem (- instr 300) acc) 
          ;; Sostituisci il valore nella cella di memoria
          :in in 
          :out out 
          :flag flag))

;;; load
(defun lda (pc mem in out flag instr) 
  (list 'state 
          :acc (nth (- instr 500) mem) 
          ;; Sostituisci il valore dell'accumulatore
          :pc (program_counter pc)     ; Incremento del PC
          :mem mem
          :in in 
          :out out 
          :flag flag))

;;; branch
(defun bra (acc mem in out flag instr) 
  (list 'state 
          :acc acc 
          :pc (- instr 600)    ; Modifica il PC
          :mem mem
          :in in 
          :out out 
          :flag flag))

;;; branch if zero
(defun brz (pc acc mem in out flag instr)
  ;; Branch se l'accumulatore è uguale a 0 e il flag è assente
  (let ((newpc (cond ((and (= acc 0) (eql flag 'noflag)) (- instr 700))
                     ;; Altrimenti non saltare
                     (t (program_counter pc))))) ; Incremento del PC
    (list 'state 
          :acc acc 
          :pc newpc
          :mem mem
          :in in 
          :out out 
          :flag flag)))

;;; branch if positive
(defun brp (pc acc mem in out flag instr)
  ;; Branch se il flag è assente
  (let ((newpc (cond ((eql flag 'noflag) (- instr 800))
                     ;;  Altrimenti non saltare
                     (t (program_counter pc))))) ; Incremento del PC
    (list 'state 
          :acc acc 
          :pc newpc
          :mem mem
          :in in 
          :out out 
          :flag flag)))

;;; input
(defun input (pc mem in out flag)
  ;; Metti il primo elemento della coda di input nell'accumulatore
  (let ((newacc (pop in)))
    (list 'state 
          :acc newacc 
          :pc (program_counter pc) ; Incremento del PC
          :mem mem
          :in in 
          :out out 
          :flag flag)))

;;; output
(defun output (acc pc mem in out flag)
  (list 'state 
        :acc acc 
        :pc (program_counter pc) ; Incremento del PC
        :mem mem
        :in in 
        :out (append out (list acc)) 
        ;; Aggiungi l'accumulatore nella coda di output
        :flag flag))

;;; ---COMPILATORE---

;;; Launcher compilatore e interprete
(defun lmc-run (filename in)
  ;; Parse delle istruzioni in celle di memoria
  (let ((mem (lmc-load filename)))
    ;; Se la memoria è nil (errore rilevato) ritorna nil
    (cond ((null mem) nil) 
          ;; Altrimenti forma lo stato iniziale e chiama l'interprete
          (t (execution-loop (list 'state 
                                   :acc 0 
                                   :pc 0
                                   :mem mem
                                   :in in 
                                   :out '() 
                                   :flag 'noflag))))))

;;; Launcher compilatore, restituisce la memoria dello stato iniziale
(defun lmc-load (filename)
  (let ((input (with-open-file 
                   (in filename :direction :input :if-does-not-exist :error) 
                (read-list-from in))))
    ;; parse delle istruzioni riga per riga
    (parse input)))

;;; leggi dal file
(defun read-list-from (input-stream)
  ;; Restituisci una lista delle righe trovate nel file
  (let ((e (read-line input-stream nil 'eof)))
    (unless (eq e 'eof)
      ;; Gestione case-insensitive
      (cons (string-upcase e) (read-list-from input-stream)))))

;;; Parse generale
(defun parse (input)
        ;; Rimuovi i commenti e righe vuote, esegui lo split delle righe in
        ;; liste di parole
  (let ((preparse (remove nil 
                          (split_words (rmv_comment_emptyline input)))))
    ;; Controllo che le istruzioni assembly siano <= 100
    (cond ((<= (length preparse) 100) (check_error 
                                      ;; Controllo possibili errori
                                       (number_instruction 
                                        ;; Generazione del resto della memoria
                                        (parse_line
                                        ;; Parse effettivo delle istruzioni 
                                         (remove nil 
                                         ;; Rimuovi elementi inutili
                                                 (get_etichette preparse 0)) 
                                                 ;; Crea il dizionario delle
                                                 ;; etichette
                                         preparse))))
          ;; Gestione errore: struzioni > 100
          (t (traceback_error 8) nil))))

;;; Controllo possibili errori
(defun check_error (parse)
  ; Se nella memoria è presente nil è stato trovato un errore
  (cond ((null (member nil parse)) parse)
        (t nil)))

;;; Crea lista di numeri random 
(defun rnd-list (limit count)
  (cond ((<= count 0) nil)
        (t (cons (random limit)
                 (rnd-list limit (1- count))))))

;;; Gestione e generazione del numero di celle di memoria mancanti
(defun number_instruction (parse)
  (cond ((< (length parse) 100) (append parse 
                                        (rnd-list 99 (- 100 (length parse)))))
        (t parse)))

;;; Rimuovi i commenti e righe vuote
(defun rmv_comment_emptyline (input)
  (let ((line (first input)))
    (cond ((null line) nil)
          (t (cons (comment (coerce line 'list)) 
                   (rmv_comment_emptyline (rest input)))))))

(defun comment (line)
  (cond ((null (first line)) nil)
        ((and (>= (length line) 2) 
              (equal (first line) #\/) 
              (equal (second line) #\/)) nil)
        (t (cons (first line) (comment (rest line))))))

;;; Split da stringa a lista di parole
(defun split_words (lst) 
  (cond ((null lst) nil)
        (t (cons (split (first lst)) (split_words (rest lst))))))

(defun split (lst)
  (cond ((null (first lst)) nil)
        ((equal (first lst) #\Space) (split (rest lst)))
        (t (cons (word_single lst) (split (word_rest lst))))))

(defun word_single (word)
  (cond ((or (equal (first word) #\Space) 
             (null (first word))) nil)
        (t (concatenate 'string 
                        (string (first word)) 
                        (word_single (rest word))))))

(defun word_rest (wrest)
  (cond ((or (equal (first wrest) #\Space) 
             (null (first wrest))) wrest)
        (t (word_rest (rest wrest)))))

;;; Restituisce le etichette se sono presenti (non effettua alcun
;;; controllo su possibili errori)
(defun get_etichette (preparse index)
  (cond ((null (first preparse)) nil)
        (t (cons (get_etichette_line (first preparse) index) 
                 (get_etichette (rest preparse) (+ index 1))))))

(defun get_etichette_line (line index)
  (cond ((= (length line) 3) (list (read-from-string (first line)) index))
        ((and (= (length line) 2)
              (in_these_instr (second line)
                              (instruction_noarg))) 
         (list (read-from-string (first line)) index))
        (t nil)))

;;; Controllo se l'istruzione data fa parte della lista di istruzioni data
(defun in_these_instr (instr list_instr)
  (equal (read-from-string instr)
         (find (read-from-string instr) 
               list_instr)))

;;; Parse effettivo delle istruzioni riga per riga
(defun parse_line (dict_etichette preparse)
  (cond ((null preparse) nil)
                 ;; Gestione errori e parse singola riga
        (t (cons (one_instructionA dict_etichette (first preparse)) 
                 ;; Chiamata ricorsiva
                 (parse_line dict_etichette (rest preparse))))))

;;; Controllo errori e parse riga valida
(defun one_instructionA (dict_etichette line)
  (let ((len (length line))
        (one (first line))
        (two (second line))
        (three (third line)))
           ;; [Gestione errore] Riga da 4 parole o più
    (cond ((>= len 4) (traceback_error 9) nil)
           ;; Riga da 3 parole
          ((= len 3) (cond ((is_a_number one) 
                            (traceback_error 10) nil)
                           ;; [Gestione errore] L'etichetta è un numero
                           ((in_these_instr one (instruction_arg)) 
                            (traceback_error 11) nil)
                           ((in_these_instr one (instruction_noarg)) 
                            (traceback_error 11) nil)
                           ;; [Gestione errore] L'etichetta è una keyword
                           ((in_these_instr two (instruction_arg)) 
                            (parse_one_instructionA dict_etichette 
                                                    (list two three)))
                           ;; Viene effettuato il parse rimuovendo l'etichetta
                           (t (traceback_error 12) nil)))
                           ;; [Gestione errore] L'istruzione non identifica 
                           ;; alcuna operazione che prevede parametri
           ;; Riga da 2 parole
          ((= len 2) (cond ((is_a_number one) (traceback_error 10) nil)
                           ;; [Gestione errore] L'etichetta è un numero
                           ((and (in_these_instr one (instruction_noarg))
                                 (not (equal "DAT" one))) 
                            (traceback_error 12) nil)
                           ;; [Gestione errore] L'etichetta è una keyword di
                           ;; istruzione che non prevede parametri 
                           ;; (ad eccezione della "DAT")
                           ((in_these_instr one (instruction_arg)) 
                            (parse_one_instructionA dict_etichette 
                                                    (list one two)))
                           ;; Se la prima parola è un istruzione con parametri
                           ;; viene parsata
                           ;; Altrimenti la prima parola è quindi un etichetta
                           ((in_these_instr two (instruction_noarg))
                            (parse_one_instructionA dict_etichette 
                                                    (list two)))
                           ;; Se la seconda parola è un istruzione no arg
                           ;; viene parsata
                           (t (traceback_error 15) nil)))
                           ;; [Gestione errore] Istruzione non valida
           ;; Riga da 1 parola
          ((= len 1) (cond ((is_a_number one) (traceback_error 10) nil)
                           ;; [Gestione errore] La parola è un numero
                           ((and (in_these_instr one (instruction_arg))
                                 (not (equal "DAT" one))) 
                            (traceback_error 13) nil)
                           ;; [Gestione errore] La parola è un keyword 
                           ;; di istruzione che prevede parametri 
                           ;; (ad eccezione della "DAT")
                           ((in_these_instr one (instruction_noarg))
                            (parse_one_instructionA dict_etichette 
                                                    (list one)))
                           ;; La parola è un istruzione no args
                           ;; viene parsata
                           (t (traceback_error 15) nil))))))
                           ;; [Gestione errore] Istruzione non valida

;;; parse riga valida
(defun parse_one_instructionA (dict_etichette instr)
  (let ((len (length instr))
        (instruction (first instr))
        (arg (second instr)))
    (cond ((= len 2) (cond ((and (is_a_number arg) 
                                 ;; Istruzione con arg numerici
                                 (in_these_instr instruction 
                                                 (instruction_arg))
                                 (>= (parse-integer arg) 0)
                                 (< (parse-integer arg) 100))
                                 ;; Arg in range [0:99] 
                            (+ (parse-integer arg) 
                               (get_instruction instruction)))
                            ;; Creo l'istruzione
                           ((and (is_a_number arg)
                                 ;; Istruzione con arg numerici
                                 (in_these_instr instruction 
                                                 (instruction_noarg))
                                 (in_these_instr instruction 
                                                 (instruction_arg))
                                 ;; L'istruzione è una DAT
                                 (>= (parse-integer arg) 0)
                                 (< (parse-integer arg) 1000))
                                 ;;  Arg in range [0:999]
                            (+ (parse-integer arg) 
                               (get_instruction instruction)))
                            ;; Creo l'istruzione
                           ((is_a_number arg) (traceback_error 16) nil)
                           ;; [Gestione errore] Il parametro è un numero 
                           ;; fuori dal range [0:99]/[0:999]
                           ((and (in_these_instr instruction 
                                                 (instruction_noarg))
                                 (in_these_instr instruction 
                                                 (instruction_arg))) 
                            (traceback_error 15) nil)
                           ;; [Gestione errore] Il parametro è un etichetta 
                           ;; passata ad una DAT
                           ((and (is_etichetta dict_etichette arg)
                                 ;; Se esiste l'etichetta
                                 (in_these_instr instruction 
                                                 (instruction_arg))) 
                            (+ (get_etichetta dict_etichette arg)
                               ;; Trova la cella di memoria associata
                               ;; all'etichetta
                               (get_instruction instruction)))
                            ;; Creo l'etichetta
                           ;; Parse istruzioni con args di etichette
                           (t (traceback_error 14) nil)))
                           ;; [Gestione errore] Etichetta mai allocata
          ((= len 1) (cond ((in_these_instr instruction 
                                            (instruction_noarg)) 
                            (get_instruction instruction))
                            ;; Creo l'istruzione
                           (t (traceback_error 15) nil))))))
                           ;; [Gestione errore] Istruzione non valida

;;; Prelievo valori numerici associati all'istruzione data
(defun get_instruction (instruction)
  (let ((instr_list (list 'ADD 100
                          'SUB 200
                          'STA 300
                          'LDA 500
                          'BRA 600
                          'BRZ 700
                          'BRP 800
                          'DAT 0
                          'HLT 0
                          'INP 901
                          'OUT 902)))
    (getf instr_list (read-from-string instruction))))

;;; Dichiarazione delle istruzioni arg e noarg
(defun instruction_noarg ()
  '(HLT
    INP
    OUT
    DAT))

(defun instruction_arg ()
  '(ADD
    SUB
    STA
    LDA
    BRA
    BRZ
    BRP
    DAT))

;;; Controllo se una stringa rappresenta un intero
(defun is_a_number (string)
  (integerp (read-from-string (substitute #\. #\, string))))

;;; Controllo se l'etichetta data è stata dichiarata
(defun is_etichetta (dict_etichette arg)
  (cond ((null dict_etichette) nil)
        ((not (equal (getf (first dict_etichette) (read-from-string arg) nil)
                     nil)) t)
        (t (is_etichetta (rest dict_etichette) arg))))

;;; Estrai il numero della cella di memoria associata all'etichetta data
(defun get_etichetta (dict_etichette arg)
  (cond ((null dict_etichette) nil)
        ((equal (getf (first dict_etichette) (read-from-string arg) nil)
                nil) (get_etichetta (rest dict_etichette) arg))
        (t (getf (first dict_etichette) (read-from-string arg)))))

;;; Traceback errori
(defun traceback_error (id)
  (prin1 (getf (dict_error) id)))

;;; Lista errori
(defun dict_error ()
  '(0 "Interprete: Errore. 
Impossibile elaborare un'halted_state."
    1 "Interprete: Errore. 
Non e' stato trovato alcun valore nella coda di input."
    2 "Interprete: Errore. 
Istruzione non valida."
    3 "Interprete: Errore. 
Numero celle di memoria errato"
    4 "Interprete: Errore. 
Program counter ha assunto un valore non consentito."
    5 "Interprete: Errore. 
Accumulatore ha assunto un valore non consentito."
    6 "Interprete: Errore. 
La memoria o la coda di input o di output presenta un valore non consentito"
    7 "Interprete: Errore. 
Il valore del flag deve essere rappresentato solo dai termini: flag/noflag"
    8 "Compilatore: Errore. 
Il numero di istruzioni supera lo spazio di memoria disponibile"
    9 "Compilatore: Errore. 
Impossibile contenere sulla stessa riga più di 3 parole"
    10 "Compilatore: Errore. 
Impossibile usare come etichetta un numero"
    11 "Compilatore: Errore. 
Impossibile usare come etichetta una keyword"
    12 "Compilatore: Errore. 
Impossibile passare parametri ad un'instruzione non adatta per questo scopo"
    13 "Compilatore: Errore. 
Non è stato trovato alcun parametro per un'istruzione che ne necessitava"
    14 "Compilatore: Errore. 
Impossibile trovare il valore di un'etichetta mai allocata."
    15 "Compilatore: Errore. 
Istruzione non valida."
    16 "Compilatore: Errore. 
Impossibile inserire argomenti fuori dai loro range stabiliti."
    17 "Interprete: Errore. 
Stato iniziale malformato."))