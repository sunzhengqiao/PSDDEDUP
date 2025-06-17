;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Script Name : PSD_PSET_UPDATE.lsp
;; Version     : v1
;; Author      : Auto-generated
;; Description : Copy all Property Set Definitions from a template drawing into
;;               the current drawing.  Existing definitions are overwritten.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(vl-load-com)

;;--- Utility: obtain the property set definition dictionary of a document -----
(defun _psd-dict (doc / nod)
  (vl-catch-all-apply
    '(lambda ()
       (setq nod (vla-get-NamedObjectsDictionary doc))
       (vla-Item nod "AEC_PROPERTY_SET_DEFS")))
)

;;--- Copy or replace a definition by name ------------------------------------
(defun _copy-psd (srcDict dstDict name / srcObj dstObj newObj)
  (setq srcObj (vla-Item srcDict name))
  ;; delete existing definition in destination if found
  (vl-catch-all-apply
    '(lambda ()
       (setq dstObj (vla-Item dstDict name))
       (vla-Delete dstObj)))
  ;; create new definition and copy contents
  (setq newObj (vla-Add dstDict name))
  (vla-CopyFrom newObj srcObj)
)

;;--- Command PSDUPDATE -------------------------------------------------------
(defun c:PSDUPDATE (/ app docs srcPath srcDoc dstDoc srcDict dstDict)
  (setq srcPath "C:\\CAD-Technik RubnerHaus\\Zeichnungsvorlage\\RubnerHaus Dateivorlage.dwt")
  (setq app  (vlax-get-Acad-object)
        docs (vla-get-Documents app)
        dstDoc (vla-get-ActiveDocument app))
  (if (findfile srcPath)
    (progn
      (setq srcDoc (vla-Open docs srcPath))
      (setq srcDict (_psd-dict srcDoc)
            dstDict (_psd-dict dstDoc))
      (if (and srcDict dstDict)
        (progn
          (vlax-for itm srcDict
            (_copy-psd srcDict dstDict (vla-get-Name itm)))
          (princ "\n✔ Property sets updated.")
        )
        (princ "\n=> Property set dictionary not found."))
      (vla-Close srcDoc)
    )
    (princ "\n=> Template file not found."))
  (princ)
)

(princ "\nPSDUPDATE loaded – type PSDUPDATE to run.\n")
(princ)
