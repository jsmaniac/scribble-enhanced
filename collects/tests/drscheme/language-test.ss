(define language (make-parameter "<<not a language>>"))

(define (set-language close-dialog?)
  (set-language-level! (language) close-dialog?)
  (unless close-dialog?
    (with-handlers ([exn:user? (lambda (x) (void))])
      (fw:test:button-push "Show Details"))))

(define (test-setting setting-name value expression result)
  (fw:test:set-check-box! setting-name value)
  (let ([f (get-top-level-focus-window)])
    (fw:test:button-push "OK")
    (wait-for-new-frame f))
  (let* ([drs (get-top-level-focus-window)]
	 [interactions (ivar drs interactions-text)])
    (clear-definitions drs)
    (type-in-definitions drs expression)
    (do-execute drs)
    (let* ([got (fetch-output drs)])
      (unless (string=? result got)
	(printf "FAILED: ~a ~a test~n expected: ~a~n     got: ~a~n" (language) expression result got)))
    '(dump-memory-stats)))

(define (test-hash-bang)
  (let* ([expression (format "#!~n1")]
	 [result "1"]
	 [drs (get-top-level-focus-window)]
	 [interactions (ivar drs interactions-text)])
    (clear-definitions drs)
    (type-in-definitions drs expression)
    (do-execute drs)
    (let* ([got (fetch-output drs)])
      (unless (string=? "1" got)
	(printf "FAILED: ~a ~a test~n expected: ~a~n     got: ~a~n"
		(language) expression result got)))))

(define (mred)
  (parameterize ([language "Graphical without Debugging (MrEd)"])
    (generic-settings #f)
    (generic-output #t #t #f)
    (set-language #f)
    (test-setting "Unmatched cond/case is an error" #t "(cond [#f 1])" "cond or case: no matching clause")
    
    (test-hash-bang)

    (let ([drs (wait-for-drscheme-frame)])
      (clear-definitions drs)
      (set-language #t)
      (do-execute drs))
    
    (test-expression "(error 'a \"~a\" 1)" "a: 1")
    (test-expression "(error \"a\" \"a\")" "a \"a\"")

    (test-expression "(time 1)" (format "[cpu time: 0 real time: 0 gc time: 0]~n1"))

    (test-expression "(list make-posn posn-x posn-y posn?)" "reference to undefined identifier: make-posn")
    (test-expression "set-posn-x!" "reference to undefined identifier: set-posn-x!")
    (test-expression "set-posn-y!" "reference to undefined identifier: set-posn-y!")

    (test-expression "true" "reference to undefined identifier: true")
    (test-expression "mred^" "compile: illegal use of an expansion-time value name in: mred^")
    (test-expression "(eq? 'a 'A)" "#t")
    (test-expression "(set! x 1)" "set!: cannot set undefined identifier: x")
    (test-expression "(cond [(= 1 2) 3])" "")
    (test-expression "(cons 1 2)" "(1 . 2)")
    (test-expression "'(1)" "(1)")
    (test-expression "(define shrd (box 1)) (list shrd shrd)"
		     "(#&1 #&1)")
    (test-expression "(local ((define x x)) 1)" "define-values: illegal use (not at top-level) in: (#%define-values (x) x)")
    (test-expression "(if 1 1 1)" "1")
    (test-expression "(+ 1)" "1")
    (test-expression "1.0" "1.0")
    (test-expression "#i1.0" "1.0")
    (test-expression "3/2" "3/2")
    (test-expression "1/3" "1/3")
    (test-expression "(list 1)" "(1)")
    (test-expression "argv" "#0()")))

(define (mzscheme)
  (parameterize ([language "Textual without Debugging (MzScheme)"])
    (generic-settings #f)
    (generic-output #t #t #f)
    (set-language #f)
    (test-setting "Unmatched cond/case is an error" #t "(cond [#f 1])" "cond or case: no matching clause")
    
    (test-hash-bang)

    (let ([drs (wait-for-drscheme-frame)])
      (clear-definitions drs)
      (set-language #t)
      (do-execute drs))
    
    (test-expression "(error 'a \"~a\" 1)" "a: 1")
    (test-expression "(error \"a\" \"a\")" "a \"a\"")
    
    (test-expression "(time 1)" (format "[cpu time: 0 real time: 0 gc time: 0]~n1"))

    (test-expression "(list make-posn posn-x posn-y posn?)" "reference to undefined identifier: make-posn")
    (test-expression "set-posn-x!" "reference to undefined identifier: set-posn-x!")
    (test-expression "set-posn-y!" "reference to undefined identifier: set-posn-y!")

    (test-expression "true" "reference to undefined identifier: true")
    (test-expression "mred^" "reference to undefined identifier: mred^")
    (test-expression "(eq? 'a 'A)" "#t")
    (test-expression "(set! x 1)" "set!: cannot set undefined identifier: x")
    (test-expression "(cond [(= 1 2) 3])" "")
    (test-expression "(cons 1 2)" "(1 . 2)")
    (test-expression "'(1)" "(1)")
    (test-expression "(define shrd (box 1)) (list shrd shrd)"
		     "(#&1 #&1)")
    (test-expression "(local ((define x x)) 1)" "define-values: illegal use (not at top-level) in: (#%define-values (x) x)")
    (test-expression "(if 1 1 1)" "1")
    (test-expression "(+ 1)" "1")
    (test-expression "1.0" "1.0")
    (test-expression "#i1.0" "1.0")
    (test-expression "3/2" "3/2")
    (test-expression "1/3" "1/3")
    (test-expression "(list 1)" "(1)")
    (test-expression "argv" "#0()")))

(define (mred-debug)
  (parameterize ([language "Graphical (MrEd)"])
    (generic-settings #f)
    (generic-output #t #t #t)
    (set-language #f)
    (test-setting "Unmatched cond/case is an error" #t "(cond [#f 1])" "no matching cond clause")
    (set-language #f)
    (test-setting "Signal undefined variables when first referenced" #t "(letrec ([x x]) 1)"
		  "Variable x referenced before definition or initialization")
    (set-language #f)
    (test-setting "Signal undefined variables when first referenced" #f "(letrec ([x x]) 1)" "1")
    
    (test-hash-bang)

    (let ([drs (wait-for-drscheme-frame)])
      (clear-definitions drs)
      (set-language #t)
      (do-execute drs))
    
    (test-expression "(error 'a \"~a\" 1)" "a: 1")
    (test-expression "(error \"a\" \"a\")" "a \"a\"")

    (test-expression "(time 1)" (format "[cpu time: 0 real time: 0 gc time: 0]~n1"))

    (test-expression "(list make-posn posn-x posn-y posn?)" "reference to undefined identifier: make-posn")
    (test-expression "set-posn-x!" "reference to undefined identifier: set-posn-x!")
    (test-expression "set-posn-y!" "reference to undefined identifier: set-posn-y!")

    (test-expression "true" "reference to undefined identifier: true")
    (test-expression "mred^" "signature: invalid use of signature name mred^")
    (test-expression "(eq? 'a 'A)" "#t")
    (test-expression "(set! x 1)" "set!: cannot set undefined identifier: x")
    (test-expression "(cond [(= 1 2) 3])" "")
    (test-expression "(cons 1 2)" "(1 . 2)")
    (test-expression "'(1)" "(1)")
    (test-expression "(define shrd (box 1)) (list shrd shrd)"
		     "(#&1 #&1)")
    (test-expression "(local ((define x x)) 1)"
		     "definition: invalid position for internal definition")
    (test-expression "(letrec ([x x]) 1)" "1")
    (test-expression "(if 1 1 1)" "1")
    (test-expression "(+ 1)" "1")
    (test-expression "1.0" "1.0")
    (test-expression "#i1.0" "1.0")
    (test-expression "3/2" "3/2")
    (test-expression "1/3" "1/3")
    (test-expression "(list 1)" "(1)")
    (test-expression "argv" "#0()")))

(define (mzscheme-debug)
  (parameterize ([language "Textual (MzScheme)"])
    (generic-settings #f)
    (generic-output #t #t #t)
    (set-language #f)
    (test-setting "Unmatched cond/case is an error" #t "(cond [#f 1])" "no matching cond clause")
    (set-language #f)
    (test-setting "Signal undefined variables when first referenced" #t "(letrec ([x x]) 1)"
		  "Variable x referenced before definition or initialization")
    (set-language #f)
    (test-setting "Signal undefined variables when first referenced" #f "(letrec ([x x]) 1)" "1")
    
    (test-hash-bang)

    (let ([drs (wait-for-drscheme-frame)])
      (clear-definitions drs)
      (set-language #t)
      (do-execute drs))
    
    (test-expression "(error 'a \"~a\" 1)" "a: 1")
    (test-expression "(error \"a\" \"a\")" "a \"a\"")

    (test-expression "(time 1)" (format "[cpu time: 0 real time: 0 gc time: 0]~n1"))

    (test-expression "(list make-posn posn-x posn-y posn?)" "reference to undefined identifier: make-posn")
    (test-expression "set-posn-x!" "reference to undefined identifier: set-posn-x!")
    (test-expression "set-posn-y!" "reference to undefined identifier: set-posn-y!")

    (test-expression "true" "reference to undefined identifier: true")
    (test-expression "mred^" "reference to undefined identifier: mred^")
    (test-expression "(eq? 'a 'A)" "#t")
    (test-expression "(set! x 1)" "set!: cannot set undefined identifier: x")
    (test-expression "(cond [(= 1 2) 3])" "")
    (test-expression "(cons 1 2)" "(1 . 2)")
    (test-expression "'(1)" "(1)")
    (test-expression "(define shrd (box 1)) (list shrd shrd)"
		     "(#&1 #&1)")
    (test-expression "(local ((define x x)) 1)"
		     "definition: invalid position for internal definition")
    (test-expression "(letrec ([x x]) 1)" "1")
    (test-expression "(if 1 1 1)" "1")
    (test-expression "(+ 1)" "1")
    (test-expression "1.0" "1.0")
    (test-expression "#i1.0" "1.0")
    (test-expression "3/2" "3/2")
    (test-expression "1/3" "1/3")
    (test-expression "(list 1)" "(1)")
    (test-expression "argv" "#0()")))

(define (zodiac-beginner)
  (parameterize ([language "Beginning Student"])
    (zodiac)
    (generic-output #f #f #t)
    
    (test-hash-bang)

    (let ([drs (wait-for-drscheme-frame)])
      (clear-definitions drs)
      (set-language #t)
      (do-execute drs))
    
    (test-expression "(error 'a \"~a\" 1)"
		     "procedure error: expects 2 arguments, given 3: 'a \"~a\" 1")
    (test-expression "(error \"a\" \"a\")"
		     "error: expected a symbol and a string, got \"a\" and \"a\"")
    
    (test-expression "(time 1)" "reference to undefined identifier: time")

    (test-expression "(list make-posn posn-x posn-y posn?)" "(cons make-posn (cons posn-x (cons posn-y (cons posn? empty))))")
    (test-expression "set-posn-x!" "reference to undefined identifier: set-posn-x!")
    (test-expression "set-posn-y!" "reference to undefined identifier: set-posn-y!")

    (test-expression "true" "true")
    (test-expression "mred^" "reference to undefined identifier: mred^")
    (test-expression "(eq? 'a 'A)" "false")
    (test-expression "(set! x 1)" "reference to undefined identifier: set!")
    (test-expression "(cond [(= 1 2) 3])" "no matching cond clause")
    (test-expression "(cons 1 2)" "cons: second argument must be of type <list>, given 1 and 2")
    (test-expression "'(1)" "quote: misused: '(1) is not a symbol")
    (test-expression "(define shrd (box 1)) (list shrd shrd)"
		     "(cons (box 1) (cons (box 1) empty))")
    (test-expression "(local ((define x x)) 1)"
		     "definition: must be at the top level")
    (test-expression "(letrec ([x x]) 1)"
		     "illegal application: first term in application must be a function name")
    (test-expression "(if 1 1 1)" "Condition value is neither true nor false: 1")
    (test-expression "(+ 1)" "+: expects at least 2 arguments, given 1: 1")
    (test-expression "1.0" "1")
    (test-expression "#i1.0" "#i1.0")
    (test-expression "3/2" "1.5")
    (test-expression "1/3" "1/3")
    (test-expression "(list 1)" "(cons 1 empty)")
    (test-expression "argv" "reference to undefined identifier: argv")))

(define (zodiac-intermediate)
  (parameterize ([language "Intermediate Student"])
    (zodiac)
    (generic-output #t #f #t)
    (set-language #f)
    (test-setting "Signal undefined variables when first referenced" #t "(local ((define x x)) 1)"
		  "Variable x referenced before definition or initialization")
    (set-language #f)
    (test-setting "Signal undefined variables when first referenced" #f "(local ((define x x)) 1)" "1")
    
    (test-hash-bang)

    (let ([drs (wait-for-drscheme-frame)])
      (clear-definitions drs)
      (set-language #t)
      (do-execute drs))
    
    (test-expression "(error 'a \"~a\" 1)"
		     "procedure error: expects 2 arguments, given 3: 'a \"~a\" 1")
    (test-expression "(error \"a\" \"a\")"
		     "error: expected a symbol and a string, got \"a\" and \"a\"")
    
    (test-expression "(time 1)" (format "[cpu time: 0 real time: 0 gc time: 0]~n1"))

    (test-expression "(list make-posn posn-x posn-y posn?)" "(list make-posn posn-x posn-y posn?)")
    (test-expression "set-posn-x!" "reference to undefined identifier: set-posn-x!")
    (test-expression "set-posn-y!" "reference to undefined identifier: set-posn-y!")

    (test-expression "true" "true")
    (test-expression "mred^" "reference to undefined identifier: mred^")
    (test-expression "(eq? 'a 'A)" "false")
    (test-expression "(set! x 1)" "reference to undefined identifier: set!")
    (test-expression "(cond [(= 1 2) 3])" "no matching cond clause")
    (test-expression "(cons 1 2)" "cons: second argument must be of type <list>, given 1 and 2")
    (test-expression "'(1)" "(list 1)")
    (test-expression "(define shrd (box 1)) (list shrd shrd)"
		     "(list (box 1) (box 1))")
    (test-expression "(local ((define x x)) 1)" "Variable x referenced before definition or initialization")
    (test-expression "(letrec ([x x]) 1)" "Variable x referenced before definition or initialization")
    (test-expression "(if 1 1 1)" "Condition value is neither true nor false: 1")
    (test-expression "(+ 1)" "+: expects at least 2 arguments, given 1: 1")
    (test-expression "1.0" "1")
    (test-expression "#i1.0" "#i1.0")
    (test-expression "3/2" "1.5")
    (test-expression "1/3" "1/3")
    (test-expression "(list 1)" "(list 1)")
    (test-expression "argv" "reference to undefined identifier: argv")))

(define (zodiac-advanced)
  (parameterize ([language "Advanced Student"])
    (zodiac)
    (generic-output #t #t #t)
    (set-language #f)
    (test-setting "Signal undefined variables when first referenced" #t "(local ((define x x)) 1)" 
		  "Variable x referenced before definition or initialization")
    (set-language #f)
    (test-setting "Signal undefined variables when first referenced" #f "(local ((define x x)) 1)" "1")
    
    (test-hash-bang)

    (let ([drs (wait-for-drscheme-frame)])
      (clear-definitions drs)
      (set-language #t)
      (do-execute drs))
    
    (test-expression "(error 'a \"~a\" 1)"
		     "procedure error: expects 2 arguments, given 3: 'a \"~a\" 1")
    (test-expression "(error \"a\" \"a\")"
		     "error: expected a symbol and a string, got \"a\" and \"a\"")
    
    (test-expression "(time 1)" (format "[cpu time: 0 real time: 0 gc time: 0]~n1"))

    (test-expression "(list make-posn posn-x posn-y posn?)" "(list make-posn posn-x posn-y posn?)")
    (test-expression "set-posn-x!" "set-posn-x!")
    (test-expression "set-posn-y!" "set-posn-y!")

    (test-expression "true" "true")
    (test-expression "mred^" "reference to undefined identifier: mred^")
    (test-expression "(eq? 'a 'A)" "false")
    (test-expression "(set! x 1)" "set!: cannot set undefined identifier: x")
    (test-expression "(cond [(= 1 2) 3])" "no matching cond clause")
    (test-expression "(cons 1 2)" "cons: second argument must be of type <list>, given 1 and 2")
    (test-expression "'(1)" "(list 1)")
    (test-expression "(define shrd (box 1)) (list shrd shrd)"
		     "(shared ((-1- (box 1))) (list -1- -1-))")
    (test-expression "(local ((define x x)) 1)" "Variable x referenced before definition or initialization")
    (test-expression "(letrec ([x x]) 1)" "Variable x referenced before definition or initialization")
    (test-expression "(if 1 1 1)" "1")
    (test-expression "(+ 1)" "+: expects at least 2 arguments, given 1: 1")
    (test-expression "1.0" "1")
    (test-expression "#i1.0" "#i1.0")
    (test-expression "3/2" "1.5")
    (test-expression "1/3" "1/3")
    (test-expression "(list 1)" "(list 1)")
    (test-expression "argv" "reference to undefined identifier: argv")))

(define (zodiac)
  (generic-settings #t)
  
  (set-language #f)
  (test-setting "Print booleans as true and false" #t "#t #f" (format "true~nfalse"))
  (set-language #f)
  (test-setting "Print booleans as true and false" #f "#t #f" (format "#t~n#f"))
  
  (set-language #f)
  (test-setting "Unmatched cond/case is an error" #t "(cond [false 1])" "no matching cond clause"))

(define (generic-settings false/true?)
  (set-language #f)
  (test-setting "Case sensitive" #t "(eq? 'a 'A)" (if false/true? "false" "#f"))
  (set-language #f)
  (test-setting "Case sensitive" #f "(eq? 'a 'A)" (if false/true? "true" "#t"))
  (set-language #f)
  (test-setting "Unmatched cond/case is an error" #f
		(format "(cond [~a 1])" (if false/true? "false" "#f"))
		""))

(define (generic-output list? quasi-quote? zodiac?)
  (let* ([drs (wait-for-drscheme-frame)]
	 [expression (format "(define x (box 4/3))~n(list x x)")]
	 [set-output-choice
	  (lambda (option show-sharing rationals pretty?)
	    (set-language #f)
	    (fw:test:set-radio-box! "Output Style" option)
	    (when show-sharing
	      (fw:test:set-check-box!
	       "Show sharing in values"
	       (if (eq? show-sharing 'on) #t #f)))
	    (when rationals
	      (fw:test:set-check-box!
	       "Print rationals in whole/part notation"
	       (if (eq? rationals 'on) #t #f)))
	    (fw:test:set-check-box!
	     "Use pretty printer to format values"
	     pretty?)
	    (let ([f (get-top-level-focus-window)])
	      (fw:test:button-push "OK")
	      (wait-for-new-frame f)))]
	 [test
	  ;; answer must either be a string, or a procedure that accepts both zero and 1
	  ;; argument. When the procedure accepts 1 arg, the argument is `got' and
	  ;; the result must be a boolean indicating if the result was satisfactory.
	  ;; if the procedure receives no arguments, it must return a descriptive string
	  ;; for the error message
	  (lambda (option show-sharing rationals pretty? answer)
	    (set-output-choice option show-sharing rationals pretty?)
	    (do-execute drs)
	    (let ([got (fetch-output drs)])
	      (unless (if (procedure? answer)
			  (answer got)
			  (whitespace-string=? answer got))
		(printf "FAILED ~a ~a, sharing ~a, rationals ~a, got ~s expected ~s~n"
			(language) option show-sharing rationals got
			(answer)))))])
    
    (clear-definitions drs)
    (type-in-definitions drs expression)
    
    (test "write" 'off #f #t "(#&4/3 #&4/3)")    
    (test "write" 'on #f #t "(#0=#&4/3 #0#)")
    (when quasi-quote?
      (test "Quasiquote" 'off 'off #t "`(,(box 4/3) ,(box 4/3))")
      (test "Quasiquote" 'off 'on #t "`(,(box (+ 1 1/3)) ,(box (+ 1 1/3)))")
      (test "Quasiquote" 'on 'off #t "(shared ((-1- (box 4/3))) `(,-1- ,-1-))")
      (test "Quasiquote" 'on 'on #t "(shared ((-1- (box (+ 1 1/3)))) `(,-1- ,-1-))"))
    (test "Constructor" 'off 'off #t
	  (if list?
	      "(list (box 4/3) (box 4/3))"
	      "(cons (box 4/3) (cons (box 4/3) empty))"))
    (test "Constructor" 'off 'on #t
	  (if list?
	      "(list (box (+ 1 1/3)) (box (+ 1 1/3)))"
	      "(cons (box (+ 1 1/3)) (cons (box (+ 1 1/3)) empty))"))
    (test "Constructor" 'on 'off #t
	  (if list? 
	      "(shared ((-1- (box 4/3))) (list -1- -1-))"
	      (format "(shared ((-1- (box 4/3))) (cons -1- (cons -1- empty)))")))
    (test "Constructor" 'on 'on #t
	  (if list?
	      "(shared ((-1- (box (+ 1 1/3)))) (list -1- -1-))"
	      (format "(shared ((-1- (box (+ 1 1/3)))) (cons -1- (cons -1- empty)))")))


    ;; setup comment box
    (clear-definitions drs)
    (fw:test:menu-select "Edit" "Insert Text Box")
    (fw:test:keystroke #\a)
    (fw:test:keystroke #\b)
    (fw:test:keystroke #\c)

    ;; test comment box in print-convert and print-convert-less settings
    (test "Constructor" 'on 'on #t (if zodiac? "[abc]" "'non-string-snip"))
    (test "write" 'on #f #t (if zodiac? "[abc]" "non-string-snip"))

    ;; setup write / pretty-print difference
    (clear-definitions drs)
    (for-each fw:test:keystroke
	      (string->list
	       "(define(f n)(cond((zero? n)null)[else(cons n(f(- n 1)))]))(f 40)"))
    (test "Constructor" 'on 'on #f
	  (case-lambda
	   [(x) (not (member #\newline (string->list x)))]
	   [() "no newlines in result"]))
    (test "Constructor" 'on 'on #t
	  (case-lambda
	   [(x) (member #\newline (string->list x))]
	   [() "newlines in result (may need to make the window smaller)"]))
    (test "write" #f #f #f
	  (case-lambda
	   [(x) (not (member #\newline (string->list x)))]
	   [() "no newlines in result"]))
    (test "write" #f #f #t
	  (case-lambda
	   [(x) (member #\newline (string->list x))]
	   [() "newlines in result (may need to make the window smaller)"]))))

(define (whitespace-string=? string1 string2)
  (let loop ([i 0]
	     [j 0]
	     [in-whitespace? #t])
    (cond
      [(= i (string-length string1)) (only-whitespace? string2 j)]
      [(= j (string-length string2)) (only-whitespace? string1 i)]
      [else (let ([c1 (string-ref string1 i)]
		  [c2 (string-ref string2 j)])
	      (cond
		[in-whitespace?
		 (cond
		   [(whitespace? c1)
		    (loop (+ i 1)
			  j
			  #t)]
		   [(whitespace? c2)
		    (loop i
			  (+ j 1)
			  #t)]
		   [else (loop i j #f)])]
		[(and (whitespace? c1)
		      (whitespace? c2))
		 (loop (+ i 1)
		       (+ j 1)
		       #t)]
		[(char=? c1 c2)
		 (loop (+ i 1)
		       (+ j 1)
		       #f)]
		[else #f]))])))

(define (whitespace? c)
  (or (char=? c #\newline)
      (char=? c #\space)
      (char=? c #\tab)
      (char=? c #\return)))

(define (only-whitespace? str i)
  (let loop ([n i])
    (cond
      [(= n (string-length str))
       #t]
      [(whitespace? (string-ref str n))
       (loop (+ n 1))]
      [else #f])))

;; whitespace-string=? tests
'(map (lambda (x) (apply equal? x))
     (list (list #t (whitespace-string=? "a" "a"))
	   (list #f (whitespace-string=? "a" "A"))
	   (list #f (whitespace-string=? "a" " "))
	   (list #f (whitespace-string=? " " "A"))
	   (list #t (whitespace-string=? " " " "))
	   (list #t (whitespace-string=? " " "  "))
	   (list #t (whitespace-string=? "  " "  "))
	   (list #t (whitespace-string=? "  " " "))
	   (list #t (whitespace-string=? "a a" "a a"))
	   (list #t (whitespace-string=? "a a" "a  a"))
	   (list #t (whitespace-string=? "a  a" "a a"))
	   (list #t (whitespace-string=? " a" "a"))
	   (list #t (whitespace-string=? "a" " a"))
	   (list #t (whitespace-string=? "a " "a"))
	   (list #t (whitespace-string=? "a" "a "))))

(define (test-expression expression expected)
  (let* ([drs (wait-for-drscheme-frame)]
	 [interactions-text (ivar drs interactions-text)]
	 [last-para (send interactions-text last-paragraph)])
    (send interactions-text set-position
	  (send interactions-text last-position)
	  (send interactions-text last-position))
    (type-in-interactions drs expression)
    (type-in-interactions drs (string #\newline))
    (wait-for-computation drs)
    (let ([got
	   (fetch-output
	    drs
	    (send interactions-text paragraph-start-position (+ last-para 1))
	    (send interactions-text paragraph-end-position
		  (- (send interactions-text last-paragraph) 1)))])
      (unless (whitespace-string=? got expected)
	(printf "FAILED: ~a expected ~s to produce ~s, got ~s instead~n"
		(language) expression expected got)))))


;; clear teachpack
(let ([drs (wait-for-drscheme-frame)])
  (fw:test:menu-select "Language" "Clear All Teachpacks"))

(zodiac-beginner)
(zodiac-intermediate)
(zodiac-advanced)
(mzscheme-debug)
(mred-debug)
(mzscheme)
(mred)