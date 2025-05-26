;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Script Name : PSD_WHITELIST.lsp
;; Version     : v1
;; Author      : zhengqiao.sun@hsbcad.com
;; Date        : 23.05.2025
;; Description : Remove all Property-Set-Definitions (PSD) except whitelist
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Based on PSDDEDUP v9.lsp (German). This variant deletes
;; all PSDs whose base name is NOT in the whitelist below.
(vl-load-com)

;— Base name extraction ——————————————————————————————
(defun _base (s / p) (if (setq p (vl-string-search " (" s))
                         (vl-string-trim " " (substr s 1 p)) s))

;— String join utility ————————————————————————————
(defun _join (lst sep / r)
  (setq r "")
  (foreach i lst (setq r (strcat r (if (= r "") "" sep) i))) r)

;— Obtain PSD dictionary and names ———————————————————
(defun _dict ()
  (vl-catch-all-apply
    '(lambda ()
       (vla-item
         (vlax-ename->vla-object (namedobjdict))
         "AEC_PROPERTY_SET_DEFS"))))

(defun _names (/ d lst) (if (setq d (_dict))
  (vlax-for x d (setq lst (cons (vla-get-name x) lst)))) lst)

;— Confirmation prompt ———————————————————————————
(defun _confirm (msg / input)
  (princ (strcat "\n" msg " [Y/N] <N>: "))
  (setq input (getstring T))
  (cond
    ((or (null input) (= input "")) nil)
    ((wcmatch (strcase input) "Y,*") T)
    (T nil)))

;— Delete one PSD ———————————————————————————————
(defun _zap (nm / d o)
  (vl-cmdf "_.PROPERTYSETCLEAN" nm "")     ;remove object data
  (if (setq d (_dict))
    (vl-catch-all-apply
      '(lambda () (setq o (vla-item d nm)) (vla-delete o)))))

;— Whitelist of base names to keep ———————————————————
(setq *psdWhitelist*
  '("2dBlock" "AecPolygonStil" "Dachelementstil" "Decke"
    "Deckenelemente" "Deckenstil" "Dichte" "Fassadenstil"
    "Fenster" "Fensterstil" "Gel\u00e4nderstil" "hsbPlatte"
    "hsbResponsibilitySet" "hsbStab" "Multiwand" "RaumRubner"
    "Raumstil" "RubnerPolylinien" "Tragwerkstil" "Treppe"
    "Treppenstil" "T\u00fcren" "T\u00fcrstil" "Wand" "Wandstil"))

;— Main command ——————————————————————————————
(defun c:PSDDEDUP (/ all delList)
  (setq all (_names))
  (if (null all)
    (princ "\n=> Keine Property-Set-Definitions in dieser Zeichnung.")
    (progn
      (setq delList (vl-remove-if
                      '(lambda (n) (member (_base n) *psdWhitelist*))
                      all))
      (if (null delList)
        (princ "\n=> Keine zu l\u00f6schenden PSDs gefunden.")
        (progn
          (if (_confirm (strcat "L\u00f6sche " (_join delList ", ")))
            (progn
              (foreach n delList (_zap n))
              (princ "\n✔ Entfernt; bitte anschlie\u00dfend PURGE manuell ausf\u00fchren."))
            (princ "\n— Abbruch —")))))
  )
  (princ)
)

(princ "\nPSD_WHITELIST geladen – Befehl PSDDEDUP eingeben.\n")
(princ)
