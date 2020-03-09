; summing up a list of numbers

(define sum
  (lambda (nums)
    (if
      (null? nums)
        0
      (+ (car nums)(sum (cdr nums)))
    )
  )
)

; combine with a map so as to add lists of numbers and return a list of their sum?

(define sum2
  (lambda (nums1 nums2)
    (map + nums1 nums2)
  )
)
