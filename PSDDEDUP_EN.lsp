;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Script Name : PSD_DEDUP.lsp
;; Version     : v1
;; Author      : zhengqiao.sun@hsbcad.com
;; Date        : 23.05.2025
;; Description : Removes duplicate Property-Set-Definitions (PSD) in AutoCAD
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; PSD_DEDUP_v1.lsp  ——  清理重复 Property-Set-Definitions（德语界面）
(vl-load-com)

;— 基名提取 ————————————————————————————————
(defun _base (s / p) (if (setq p (vl-string-search " (" s))
                         (vl-string-trim " " (substr s 1 p)) s))

;— 字符串工具：拼接 & 拆分 ————————————————————
(defun _join (lst sep / r)
  (setq r "")
  (foreach i lst (setq r (strcat r (if (= r "") "" sep) i))) r)

(defun _split (str deli / p s res)
  (setq s 1)
  (while (setq p (vl-string-search deli str s))
    (setq res (cons (substr str s (- p s)) res)  s (+ p (strlen deli))))
  (reverse (cons (substr str s) res)))

;— 取得 PSD 字典 & 列表 ————————————————————
(defun _dict ()
  (vl-catch-all-apply
    '(lambda ()
       (vla-item
         (vlax-ename->vla-object (namedobjdict))
         "AEC_PROPERTY_SET_DEFS"))))

(defun _names (/ d lst) (if (setq d (_dict))
  (vlax-for x d (setq lst (cons (vla-get-name x) lst)))) lst)

;— 分组找重复 ——————————————————————————
(defun _dups (lst / g out)
  (foreach n lst
    (if (setq g (assoc (_base n) out))
      (setq out (subst (append g (list n)) g out))
      (setq out (cons (list (_base n) n) out))))
  (vl-remove-if '(lambda (e) (< (length e) 3)) out))

(defun _baseMatch (b f) (or (null f)
  (vl-some '(lambda (p) (wcmatch (strcase b) (strcase p))) f)))

;— 从组中算出需删除的名称（保留一个基名） ————————
(defun _dupList (base lst / keep del)
  (foreach n lst
    (if (= n base)
      (if keep
        (setq del (cons n del))
        (setq keep T))
      (setq del (cons n del))))
  (reverse del))

;— Y/N 简易确认 ——————————————————————————
(defun _confirm (msg / input)
  (princ (strcat "\n" msg " [Y/N] <N>: "))
  (setq input (getstring T))
  (cond
    ((or (null input) (= input "")) nil)
    ((wcmatch (strcase input) "Y,*") T)
    (T nil)))

;— 清理一个 PSD —————————————————————————
(defun _zap (nm / d o)
  (vl-cmdf "_.PROPERTYSETCLEAN" nm "")     ;删对象数据
  (if (setq d (_dict))
    (vl-catch-all-apply
      '(lambda () (setq o (vla-item d nm)) (vla-delete o)))))

;— 主命令 ——————————————————————————————
(defun c:PSDDEDUP (/ all filtStr filters groups i sel g delList)
  (setq all (_names))
  (if (null all) (princ "\n=> No property-set definitions in this drawing.")
    (progn
      (setq filtStr (getstring T
        "\nEnter base-name filter (comma,* ?) <All>: "))
      (if (> (strlen filtStr) 0)
        (setq filters (_split filtStr ",")))

      (setq groups (_dups all)
            groups (vl-remove-if
                     '(lambda (x) (not (_baseMatch (car x) filters)))
                     groups))

      (if (null groups)
        (princ "\n=> No duplicate groups found.")
        (progn
          (princ "\n=== Duplicate groups ===")
          (setq i 0)
          (foreach g groups
            (setq i (1+ i))
            (princ (strcat "\n" (itoa i) ") "
                   (car g) " → " (_join (cdr g) ", "))))
          (setq sel (getint
            (strcat "\n\nNumber [1-" (itoa i) ",0=Cancel]<0>: ")))
          (if (and sel (> sel 0) (<= sel i))
            (progn
              (setq g (nth (1- sel) groups))
              (setq delList (_dupList (car g) (cdr g)))
              (if (_confirm (strcat "Delete " (_join delList ", ")))
                (progn
                  (foreach n delList (_zap n))
                  (princ "\n✔ Removed; please run PURGE manually afterwards."))
                (princ "\n— Cancelled —"))))))
    )
  )
  (princ)
)

(princ "\nPSDDEDUP v1 loaded – type PSDDEDUP to run.\n")
(princ)
