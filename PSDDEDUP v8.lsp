;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PSD_DEDUP_v8.lsp  ——  扫描并删除重复 Property-Set-Definitions
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

;— 清理一个 PSD —————————————————————————
(defun _zap (nm / d o)
  (vl-cmdf "_.PROPERTYSETCLEAN" nm "")     ;删对象数据
  (if (setq d (_dict))
    (vl-catch-all-apply
      '(lambda () (setq o (vla-item d nm)) (vla-delete o)))))

;— 主命令 ——————————————————————————————
(defun c:PSDDEDUP (/ all filtStr filters groups i sel g ok)
  (setq all (_names))
  (if (null all) (princ "\n=> 此图无 Property Set Definitions。")
    (progn
      (setq filtStr (getstring T
        "\n输入基名过滤(逗号,* ?) <全部>: "))
      (if (> (strlen filtStr) 0)
        (setq filters (_split filtStr ",")))

      (setq groups (_dups all)
            groups (vl-remove-if
                     '(lambda (x) (not (_baseMatch (car x) filters)))
                     groups))

      (if (null groups)
        (princ "\n=> 未检出重复组。")
        (progn
          (princ "\n=== 重复组 ===")
          (setq i 0)
          (foreach g groups
            (setq i (1+ i))
            (princ (strcat "\n" (itoa i) ") "
                   (car g) " → " (_join (cdr g) ", "))))
          (setq sel (getint
            (strcat "\n\n编号 [1-" (itoa i) ",0=退出]<0>: ")))
          (if (and sel (> sel 0) (<= sel i))
            (setq g (nth (1- sel) groups)
                  ok (getkword
                       (strcat "\n清理 "
                               (_join (cdr g) ", ")
                               " ? [Yes/No] <No>: ")))
          )
          (if (= ok "Yes")
            (progn (foreach n (cdr g) (_zap n))
                   (princ "\n✔ 已删除；请再手动 PURGE 空壳。"))
            (princ "\n— 取消 —"))))))
  (princ))

(princ "\nPSDDEDUP v8 已加载 —— 输入 PSDDEDUP 运行。\n")
(princ)
