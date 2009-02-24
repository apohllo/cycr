;(csetq *PATH* "/home/fox/src/nlp/wsd/cyc/~A")
(csetq *PATH* "/mnt/cyc/export/~A")
;(csetq *WORDS-PATH* (format nil *PATH* "m_100_en_hasla.txt"))
(csetq *WORDS-PATH* (format nil *PATH* "all_english.txt"))
(csetq *WORDS-FILE* "")
(csetq *WORDS-OUTPUT* "")
(csetq *WORDS-OUTPUT-PROP* "")
(csetq *WORDS-MISSING* "")

(define load-code () (load (format nil *PATH* "words_reader.lisp")))
(define next-word () 
  (clet (
	 (word  (read *WORDS-FILE* nil))
	)
      (pif (null word) (ret '(("EOF" :eof))) ())
      (clet (
	     (denotations (denotation-mapper (format nil "~A" word)))
	     (correct-denots ())
	    )
	(pif (consp denotations)
	     ()
	     (princ (format nil "~A~%" word) *WORDS-MISSING*)
	)
;	(csetq *PROP-WORD* word)
	(cdolist (denot denotations) 
		 (pif (denot-word-p denot word) (cpush denot correct-denots) nil)
	)
;	(csetq denotations (mremove-if #'prop-word-p denotations))
	(ret (reverse correct-denots))
      )
  )
)

(define symbol-str (symbol)
   (ret (cdr (caar 
      (cyc-query `(#$prettyString-Canonical ,symbol ?w) #$EnglishMt)
   )))
)

; same as above but prettyString (without canonical) is used,
; so it can return many results
(define symbol-strs (symbol)
  (clet ((result ()))
	(cdolist (el (cyc-query `(#$prettyString ,symbol ?w) #$EnglishMt))
		 (cpush (cdar el) result))
	(ret result))
)

(define print-names (symbols output) 
   (cdolist (el symbols) 
	    (princ (format nil "~A" el) output)
	    (princ (format nil "  ~S" 
		      (strip-s (symbol-str el) "type of ")) 
	      output)
;	    (terpri output)
   )
)
(define min-genls-flat (concept stop-words) 
  ;(ret (remove-invalid (min-genls concept #$EverythingPSC) stop-words))
  ;CycNounLearnerMt UniversalVocabularyMt
  (ret (remove-invalid (min-genls concept #$CycNounLearnerMt) stop-words))
)
(define min-isa-flat (concept stop-words) 
  ;(ret (remove-invalid (min-isa concept #$EverythingPSC) stop-words))
  (ret (remove-invalid (min-isa concept #$CycNounLearnerMt) stop-words))
)

(define read-all () 
  (clet ( 
	  (stop-words (read-stop))
	  (output nil)
	 )
    (cdo ((words (next-word) (next-word))) 
       ((equal words '(("EOF" :eof))))
       (cdolist (word words)
         (pif (consp word)
              (progn 
		(pif (isa? (cdr word) #$Individual) 
         (csetq output *WORDS-OUTPUT-PROP*)
         (csetq output *WORDS-OUTPUT*))
    (princ (format nil "~A[~A]" 
                   (car word)
                   (cdr word)
                   ) 
           output)
		(print-names (min-genls-flat (cdr word) stop-words) output)
		(princ " ISA" output)
		(print-names (min-isa-flat (cdr word) stop-words) output)
		(terpri output)
	      ) 
	      ()
	  )
       )
    )
  )
)

; my implementation of the mapcar function
(defmacro mmapcar (fun elems) 
  (clet ((var (gensym)))
        (ret `(clet ((result nil)) 
	      (cdolist (,var ,elems) 
		       (cpush  (funcall ,fun ,var ) result) ) 
	      (reverse result))
	 )
  )
)

; removes elements from list if the fun returns nil
(define mremove-if (fun elems)
  (remove-if #'null (mmapcar fun elems))
)

;T if denotation's word equals word
(define denot-word-p (denot word) 
  (fif (equal (car denot) word) denot nil))

;T if the car of the cons is equal to word 
(define prop-word-p (el word) 
  (fif (equal (car (eval el)) word) (eval el) nil))


(define open-words ()
  (csetq *WORDS-FILE* (open-text *WORDS-PATH* :input))
)

(define open-missing ()
  (csetq *WORDS-MISSING* (open-text (format nil *PATH* "missing.txt") :output))
)

(define close-words ()
  (close *WORDS-FILE*))


(define open-output (version) 
  (csetq *WORDS-OUTPUT* 
	 (open-text (format nil *PATH* (format nil "pohl_cyc_~A.txt" version)) :output))
  (csetq *WORDS-OUTPUT-PROP* 
	 (open-text (format nil *PATH* (format nil "pohl_cyc_prop_~A.txt" version)) :output))
)

;close output file
(define close-output () 
  (close *WORDS-OUTPUT*)
  (close *WORDS-OUTPUT-PROP*)
)

;returns the stop-list 
(define read-stop ()
  (clet ((stop-file (open-text (format nil *PATH* "stop_list.txt") :input))
	 (stop-words (read stop-file))
	 )
    (close stop-file)
    (ret stop-words)
  )
)

; removes sequence #removed from the beginning of the sequence #sequence 
 (define strip-s (sequence removed) 
   (ret(fif (eq 0 (search removed sequence))
	    (subseq sequence (length removed))
	    sequence))
)

;main transforming loop
(define main-prog (version) 
    (open-words)
    (open-output version)
    (open-missing)
    (read-all)
    (close-words)
    (close-output) 
    (close *WORDS-MISSING*)
)

(define  remove-invalid (elements invalid) 
  (clet ( (result () ) )
	(cdolist (el elements) 
		 (pif (null (cor (member el invalid)
				 (cand (nart-p el) 
				       (intersection invalid (nart-hl-formula el)) ))) 
		      (cpush el result) ()) 
		 )
	(ret result) 
  )
)

(define term-mts (term) 
  (clet ((result ())) 
        (cdolist (e (gather-index-in-any-mt term)) 
                 (csetq result (adjoin (assertion-mt e) result))) 
        result) 
)

(define any-assertion? (term mt)
  (with-mt mt (pif (gather-index term) T ())))
