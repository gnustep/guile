
(display "\nLoading 'greg' framework...\n\n")
(use-modules (ice-9 greg))
(display "\nLoading 'gstep-guile' utilities...\n\n")
(use-modules (languages gstep-guile))
(display "\nRunning basic tests...\n\n")
(set! greg-tools (list "tests"))
(set! greg-verbose 4)
(set! greg-debug #t)
(greg-test-run)
(display "\nTests complete.\n\n")
(display "\nThere should be a log in 'tests.log'\n")

