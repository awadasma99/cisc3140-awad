; division by zero

(define divide
  (lambda (dividend divisor)
    (if (= divisor 0)
      (catch 'div-by-zero-error
        (lambda () (throw 'div-by-zero-error))
        (lambda e (display "error: division by zero! please try another divisor\n"))
      )
      (/ dividend divisor)
    )
  )
)
