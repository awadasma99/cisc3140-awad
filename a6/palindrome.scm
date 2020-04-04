(define palindrome
  (lambda (word)
    (if (string? word)
      (set! word (string->list word)))
    (equal? word (reverser word))
  )
)

(define (reverser lst)
  (if (string? lst)
    (set! lst (string->list lst)))
  (reverser-helper lst '()))

(define (reverser-helper lst emp)
  (if (null? lst)
      emp
      (reverser-helper (cdr lst) (cons (car lst) emp))))
