;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PSD_DEDUP_EN.lsp  --  Scan and remove duplicate Property Set Definitions
(vl-load-com)

;; -- Base name extraction -------------------------------------------------------
(defun _base (s / p)
  (if (setq p (vl-string-search " (" s))
    (vl-string-trim " " (substr s 1 p))
    s))

;; -- String helpers ------------------------------------------------------------
(defun _join (lst sep / r)
  (setq r "")
  (foreach i lst
    (setq r (strcat r (if (= r "") "" sep) i)))
  r)

(defun _split (str deli / p s res)
  (setq s 1)
  (while (setq p (vl-string-search deli str s))
    (setq res (cons (substr str s (- p s)) res)
          s (+ p (strlen deli))))
  (reverse (cons (substr str s) res)))

;; -- Access PSD dictionary and names ------------------------------------------
(defun _dict ()
  (vl-catch-all-apply
    '(lambda ()
       (vla-item
         (vlax-ename->vla-object (namedobjdict))
         "AEC_PROPERTY_SET_DEFS"))))

(defun _names (/ d lst)
  (if (setq d (_dict))
    (vlax-for x d (setq lst (cons (vla-get-name x) lst))))
  lst)

;; -- Build duplicate groups keeping one base ----------------------------------
(defun _dupList (lst / groups out b g names base dups)
  (foreach n lst
    (setq b (_base n))
    (if (setq g (assoc b groups))
        (setq groups (subst (cons b (cons n (cdr g))) g groups))
        (setq groups (cons (list b n) groups))))
  (foreach g groups
    (setq names (cdr g))
    (setq base (vl-some '(lambda (x) (if (= (_base x) x) x)) names))
    (if base
        (setq dups (vl-remove base names))
        (setq base (car names) dups (cdr names)))
    (when dups
      (setq out (cons (cons base dups) out))))
  (reverse out))

(defun _baseMatch (b f)
  (or (null f)
      (vl-some '(lambda (p) (wcmatch (strcase b) (strcase p))) f)))

;; -- Simple Y/N confirmation ---------------------------------------------------
(defun _confirm (msg / input)
  (princ (strcat "\n" msg " [Y/N] <N>: "))
  (setq input (getstring T))
  (cond
    ((or (null input) (= input "")) nil)
    ((wcmatch (strcase input) "Y,*") T)
    (T nil)))

;; -- Remove one PSD -----------------------------------------------------------
(defun _zap (nm / d o)
  (vl-cmdf "_.PROPERTYSETCLEAN" nm "")
  (if (setq d (_dict))
    (vl-catch-all-apply
      '(lambda () (setq o (vla-item d nm)) (vla-delete o)))))

;; -- Main command -------------------------------------------------------------
(defun c:PSDDEDUP_EN (/ all filtStr filters groups i sel g)
  (setq all (_names))
  (if (null all)
    (princ "\n=> No Property Set Definitions found in this drawing.")
    (progn
      (setq filtStr (getstring T "\nEnter base-name filters (comma,* ?) <All>: "))
      (if (> (strlen filtStr) 0)
        (setq filters (_split filtStr ",")))

      (setq groups (_dupList all)
            groups (vl-remove-if '(lambda (x) (not (_baseMatch (car x) filters))) groups))

      (if (null groups)
        (princ "\n=> No duplicate groups found.")
        (progn
          (princ "\n=== Duplicate Groups ===")
          (setq i 0)
          (foreach g groups
            (setq i (1+ i))
            (princ (strcat "\n" (itoa i) ") " (car g) " -> " (_join (cdr g) ", "))))
          (setq sel (getint (strcat "\n\nNumber [1-" (itoa i) ",0=Exit]<0>: ")))
          (if (and sel (> sel 0) (<= sel i))
            (progn
              (setq g (nth (1- sel) groups))
              (if (_confirm (strcat "Delete " (_join (cdr g) ", ")))
                (progn
                  (foreach n (cdr g) (_zap n))
                  (princ "\n✔ Done. Run PURGE to remove empty shells."))
                (princ "\n— Cancelled —"))))))))
  (princ))

(princ "\nPSDDEDUP_EN loaded - run PSDDEDUP_EN to start.\n")
(princ)
