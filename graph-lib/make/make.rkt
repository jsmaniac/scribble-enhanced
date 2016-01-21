#lang at-exp typed/racket

(require "lib.rkt")

(displayln "Make started")

;(current-directory "..")

(run! (list (find-executable-path-or-fail "sh")
            "-c"
            @string-append{
 found_long_lines=0
 for i in `find \
 \( -path ./lib/doc/bracket -prune -and -false \) \
 -or \( -name compiled -prune -and -false \) \
 -or -name '*.rkt'`
 do
 x=`cat "$i" \
 | awk '{if (length > 80) print NR "\t" length "\t" $0}' \
 | sed -e 's/^\([0-9]*\t[0-9]*\t.\{80\}\)\(.*\)$/\1\x1b[0;30;41m\2\x1b[m/'`
 if test -n "$x"; then
 found_long_lines=1
 printf '\033[1;31m%s:\033[m\n' "$i" && printf "%s\n" "$x"
 fi
 done
 exit $found_long_lines
 }))

(run! (list(find-executable-path-or-fail "sh")
           "-c"
           @string-append{
 printf "\033[m"; grep -i TODO --with-filename --line-number --color=yes -- \
 `find \
 \( -path ./lib/doc/bracket -prune -and -false \) \
 -or \( -name compiled -prune -and -false \) \
 -or -name '*.rkt'`}))

;; TODO: should directly exclude them in find-files-by-extension.
(define excluded-dirs (list "docs/"
                            "bug/"
                            "lib/doc/bracket/"
                            "lib/doc/math-scribble/"
                            "lib/doc/MathJax/"))
(define (exclude-dirs [files : (Listof Path)]
                      [excluded-dirs : (Listof String) excluded-dirs])
  (filter-not (λ ([p : Path])
                (ormap (λ ([excluded-dir : String])
                         (string-prefix? excluded-dir (path->string p)))
                       excluded-dirs))
              files))

(define scrbl-files (exclude-dirs (find-files-by-extension ".scrbl")))
(define lp2-files (exclude-dirs (find-files-by-extension ".lp2.rkt")))
(define rkt-files (exclude-dirs (find-files-by-extension ".rkt")))
(define doc-sources (append scrbl-files lp2-files))
(define html-files
  (map (λ ([scrbl-or-lp2 : Path])
         (build-path "docs/"
                     (regexp-case (regexp-case (path->string scrbl-or-lp2)
                                               [#rx"\\.scrbl$" ".html"]
                                               [#rx"\\.lp2\\.rkt$" ".lp2.html"])
                                  [#rx"^web/" ""]
                                  [#rx"^" "docs/"])))
       doc-sources))
(define pdf-files
  (map (λ ([scrbl-or-lp2 : Path])
         (build-path "docs/"
                     (regexp-case (regexp-case (path->string scrbl-or-lp2)
                                               [#rx"\\.scrbl$" ".pdf"]
                                               [#rx"\\.lp2\\.rkt$" ".lp2.pdf"])
                                  [#rx"^web/" ""]
                                  [#rx"^" "docs/"])))
       doc-sources))
(define mathjax-links (map (λ ([d : Path])
                             (build-path d "MathJax"))
                           (remove-duplicates (map dirname html-files))))

(define-type ScribbleRenderers
  ; TODO: add --html-tree <n> and '(other . "…") to be future-proof.
  (U "--html" "--htmls" "--latex" "--pdf" "--dvipdf" "--latex-section"
     "--text" "--markdown"))
(: scribble (→ Path Path (Listof Path) (Listof Path) ScribbleRenderers Any))
(define (scribble file dest-file all-files all-dest-files renderer)
  (define dest-dir (dirname dest-file))
  (make-directory* dest-dir)
  (run `(,(find-executable-path-or-fail "scribble")
         ,renderer
         "--dest" ,dest-dir;,(build-path "docs/" (dirname file))
         "+m"
         "--redirect-main" "http://docs.racket-lang.org/"
         "--info-out" ,(path-append
                        dest-file
                        ".sxref")
         ,@(append-map (λ ([f : Path-String] [dst : Path-String])
                         : (Listof Path-String)
                         (let ([sxref (path-append dst ".sxref")])
                           (if (file-exists? sxref)
                               (list "++info-in" sxref)
                               (list))))
                       (remove file all-files)
                       (remove dest-file all-dest-files))
         ,file)))

(: scribble-all (→ (Listof Path) (Listof Path) ScribbleRenderers Any))
(define (scribble-all files dest-files renderer)
  ;; TODO: compile everything twice, so that the cross-references are correct.
  (for ([f (in-list files)]
        [dst (in-list dest-files)])
    (scribble f dst files dest-files renderer))
  (for ([f (in-list files)]
        [dst (in-list dest-files)])
    (scribble f dst files dest-files renderer)))

;(make-collection "phc" rkt-files (argv))
;(make-collection "phc" '("graph/all-fields.rkt") #("zo"))
;(require/typed compiler/cm [managed-compile-zo
;                            (->* (Path-String)
;                                 ((→ Any Input-Port Syntax)
;                                  #:security-guard Security-Guard)
;                                 Void)])
;(managed-compile-zo (build-path (current-directory) "graph/all-fields.rkt"))

;; make-collection doesn't handle dependencies due to (require), so if a.rkt
;; requires b.rkt, and b.rkt is changed, a.rkt won't be rebuilt.
;; This re-compiles each-time, even when nothing was changed.
;((compile-zos #f) rkt-files 'auto)

;; This does not work, because it tries to create the following directory:
;; /usr/local/racket-6.2.900.6/collects/syntax/parse/private/compiled/drracket/
;(require/typed compiler/cm [managed-compile-zo
;                            (->* (Path-String)
;                                 ((→ Any Input-Port Syntax)
;                                  #:security-guard Security-Guard)
;                                 Void)])
;(for ([rkt rkt-files])
;  (managed-compile-zo (build-path (current-directory) rkt)))

(run! `(,(find-executable-path-or-fail "raco")
        "make"
        "-j" "8"
        ,@rkt-files))

;; Create root MathJax link, must be done before the others
;; Otherwise make/proc thinks the (broken) link hasn't been created.
(make-directory* "docs/") ;; docs/ must be created before Depencency graph too
(unless (link-exists? (build-path "docs" "MathJax"))
  (make-file-or-directory-link (build-path 'up "lib" "doc" "MathJax")
                               (build-path "docs" "MathJax")))


;; Dependency graph, must be done before docs.
(begin
  (run! (list (find-executable-path-or-fail "racket")
              "make/dependency-graph.rkt"
              "graph/__DEBUG_graph__.rkt"
              "docs/deps.dot"))
  
  (run! (list (find-executable-path-or-fail "dot")
              "docs/deps.dot"
              "-Tpng"
              "-Nfontsize=12"
              "-o" "docs/deps.png"))
  
  (run! (list (find-executable-path-or-fail "dot")
              "docs/deps.dot"
              "-Tsvg"
              "-Nfontsize=12"
              "-o" "docs/deps.svg"))
  
  (run! (list (find-executable-path-or-fail "dot")
              "docs/deps.dot"
              "-Tpdf"
              "-o" "docs/deps.pdf")))

(make/proc
 (rules
  (list "zo" (append html-files
                     pdf-files
                     mathjax-links))
  (for/rules ([scrbl-or-lp2 doc-sources]
              [html html-files])
    (html)
    (scrbl-or-lp2)
    #;(scribble (list scrbl-or-lp2) doc-sources "--html")
    (scribble-all doc-sources html-files "--html"))
  (for/rules ([scrbl-or-lp2 doc-sources]
              [pdf pdf-files])
    (pdf)
    (scrbl-or-lp2)
    #;(scribble (list scrbl-or-lp2) doc-sources "--pdf")
    (scribble-all doc-sources pdf-files "--pdf"))
  (for/rules ([mathjax-link mathjax-links])
    (mathjax-link)
    ()
    (let* ([docs-mathjax-dir
            (simplify-path
             (apply build-path
                    `(same
                      ,@(build-list (sub1 (length (explode-path
                                                   (dirname mathjax-link))))
                                    (const 'up))
                      "MathJax"))
             #f)]
           [docs-or-lib-mathjax-dir
            (if (equal? (build-path "docs" "MathJax") mathjax-link)
                (build-path 'up "lib" "doc" "MathJax")
                docs-mathjax-dir)])
      (make-file-or-directory-link docs-or-lib-mathjax-dir
                                   mathjax-link))))
 (argv))

(run! `(,(find-executable-path-or-fail "raco")
        "test"
        "-j" "8"
        ,@(exclude-dirs rkt-files (list "make/"))))

(run! `(,(find-executable-path-or-fail "raco")
        "cover"
        "-d" "./docs/coverage"
        "-s" "doc"
        "-s" "test"
        "-f" "html"
        ,@(let ([travis (getenv "TRAVIS")])
            (if (and travis (string=? travis "true"))
                '("-f" "coveralls")
                '()))
        ,@(exclude-dirs rkt-files (list "make/"))))

(run! `(,(find-executable-path-or-fail "bash")
        "make/make-indexes.sh"
        "docs/"))

;; Old dependency graph
#|
(run! (list (find-executable-path-or-fail "bash")
            "-c"
            #<<EOF
(
  echo "digraph g {";
  (
    echo "(";
    raco show-dependencies \
      -x typed/racket -x racket/base -x racket \
      -g graph/__DEBUG_graph__.rkt;
      echo ")"
  ) \
  | racket -e '
      (require racket/format)
      (define (p l)
        (if (null? l)
          (void)
          (begin
            (for ([from (in-list (caddr l))])
              (displayln (format "\"~a\" -> \"~a\"" from (car l))))
            (p (cdddr l)))))
      (p (read))
    ';
  echo "}") \
  | dot -Tpdf -o docs/deps.pdf
EOF
            ))
|#