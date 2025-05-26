;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Script Name : PSD_WHITELIST_CLEAN.lsp
;; Version     : v1
;; Author      : zhengqiao.sun@hsbcad.com
;; Date        : 23.05.2025
;; Description : Entfernt alle Property-Set-Definitions, die nicht in der
;;               Whitelist enthalten sind.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; PSD_WHITELIST_CLEAN.lsp  ——  清理白名单之外的 Property-Set-Definitions（德语界面）
(vl-load-com)

;— 取得 PSD 字典 & 列表 ————————————————————
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

;— 清理一个 PSD —————————————————————————
(defun _zap (nm / d o)
  (vl-cmdf "_.PROPERTYSETCLEAN" nm "")     ;删对象数据
  (if (setq d (_dict))
    (vl-catch-all-apply
      '(lambda () (setq o (vla-item d nm)) (vla-delete o)))))

;— 主命令 ——————————————————————————————
(defun c:WLREIN (/ all keepList)
  (setq keepList
    '("2dBlock" "AecPolygonStil" "Dachelementstil" "Decke" "Deckenelemente"
      "Deckenstil" "Dichte" "Fassadenstil" "Fenster" "Fensterstil"
      "Geländerstil" "hsbPlatte" "hsbResponsibilitySet" "hsbStab"
      "Multiwand" "RaumRubner" "Raumstil" "RubnerPolylinien"
      "Tragwerkstil" "Treppe" "Treppenstil" "Türen" "Türstil"
      "Wand" "Wandstil"))
  (setq all (_names))
  (if (null all)
    (princ "\n=> Keine Property-Set-Definitionen in dieser Zeichnung.")
    (progn
      (foreach nm all
        (if (not (member nm keepList))
          (_zap nm)))
      (princ "\n✔ Bereinigung abgeschlossen.")))
  (princ))

(princ "\nWLREIN geladen – Befehl WLREIN eingeben.\n")
(princ)
