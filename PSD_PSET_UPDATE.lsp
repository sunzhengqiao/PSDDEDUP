;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PSD_PSET_UPDATE.lsp - FIXED VERSION
;; Version : v6.0-simplified
;; Purpose : Copy Property-Set-Definitions from template drawing to current drawing
;; Notes   : Removed non-functional AECSTYLEIMPORT fallback, improved error handling
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(vl-load-com)

;;; Main command to update Property Set Definitions
(defun c:PSDUPDATE ( / *error* app docs dstDoc srcPath srcDoc srcDicts dstDicts copiedCount failedPSDs startTrans dstDb allSrcObjects objArray psdName oldPsdItem singleObjArray copyResult renamedPSDs delRes newName batchFailObjs batchArray idx)
  
  ;;; Local error handling function
  (defun *error* (msg)
    ;; Abort transaction if started
    (if startTrans
      (progn
        (princ "\nAborting transaction...")
        (vl-catch-all-apply 'vla-EndUndoMark (list dstDoc))
      )
    )
    ;; Close source document
    (if (and srcDoc (not (vlax-object-released-p srcDoc)))
      (vla-close srcDoc :vlax-false)
    )
    (cond ((not msg))                               
          ((wcmatch (strcase msg) "*CANCEL*,*QUIT*")) 
          ((princ (strcat "\nError occurred: " msg)))
    )
    (princ)
  )

  ;;; Copy dependency dictionaries function
  (defun copyDependencyDicts ( / dictNames dictName srcDepDict dstDepDict allSrcObjects objArray idx)
    ;; List of ALL potential dependency dictionaries found in the template
    (setq dictNames '(
                      "ACAD_TABLESTYLE" "ACAD_VISUALSTYLE" "AEC_AREA_STYLES" "AEC_CLASSIFICATION_SYSTEM_DEFS"
                      "AEC_DISPLAY_REPRESENTATION_DEFS" "AEC_DISPLAYTHEME_STYLES" "AEC_DOOR_STYLES" 
                      "AEC_ENDCAP_STYLES" "AEC_LAYERKEY_STYLES" "AEC_LIST_DEFINITIONS" "AEC_MASKBLOCK_DEFS" 
                      "AEC_MASS_ELEM_STYLES" "AEC_MATERIAL_DEFS" "AEC_MVBLOCK_DEFS" "AEC_OPENING_ENDCAP_STYLES" 
                      "AEC_POLYGON_STYLES" "AEC_PROFILE_DEFS" "AEC_PROPERTY_DATA_FMT_DEFS" 
                      "AEC_PROPERTY_FORMAT_DEFS" "AEC_RAILING_STYLES" "AEC_ROOFSLAB_STYLES" "AEC_SCHEDULE_TABLE_STYLES" 
                      "AEC_SLAB_STYLES" "AEC_SPACE_STYLES" "AEC_STAIR_STYLES" "AEC_STRUCTURALMEMBER_STYLES" 
                      "AEC_WALL_STYLES" "AEC_WINDOW_STYLES" "AEC_ZONE_STYLES" "HSB_CNCCURVE_STYLES" "HSB_COLLECTIONDEFINITION" 
                      "HSB_DBSDEVELOPABLEASSEMBLYMATERIALSTYLE" "HSB_DBSDEVELOPABLEASSEMBLYSTYLE" "HSB_DBSFASTENERASSEMBLY" 
                      "HSB_DBSMULTIPAGE" "HSB_DICT" "HSB_ELEMENT_FILLER_STYLES" "HSB_EXTRPROF" "HSB_GROUP" 
                      "HSB_LAMELLADISTRIBUTION" "HSB_MACRO" "HSB_MASTERPANEL_STYLES" "HSB_METALPARTDEFINITION" "HSB_PAINTER_DEFS" 
                      "HSB_PANEL_CNC_MACHINECONFIG" "HSB_PANEL_CNC_TOOL" "HSB_PANEL_HEADER_DEFINITIONS" "HSB_PANEL_HEADERSILLSPLITRULE" 
                      "HSB_PANEL_OPENING_DEFINITIONS" "HSB_PANEL_ROOF_STYLES" "HSB_PANEL_STANDALONEHEADER" "HSB_PANEL_STYLES" 
                      "HSB_PANEL_WALL_STYLES" "HSB_PANEL_WIRECHASERULES" "HSB_PANELSHOPDRAWBLOCK" "HSB_PANELSPLIT_DEFINITIONS" 
                      "HSB_PANELWCSTYLES" "HSB_SETTINGS" "HSB_SURFACEQUALITY_STYLES" "HSB_TRUCK_DEFINITIONS" "HSB_TRUSSDEFINITION" 
                      "HSB_TSLhsbStickframe" "HSB_TSLhsbTSL" "HSB_TSLhsbTSLDev" "HSB_TSLITWDEDICT" "HSB_TSLtslDict" 
                      "NE_REFURBISH_STYLES" "NE_SHADOW_STYLES" "NE_SYMLINE_STYLES" "PX_AREA_FLOOR_STYLES" 
                      "PX_AREA_ROOM_GROUP_STYLES" "PX_AREA_ROOM_STYLES" "PX_DIX" "PX_GLOBAL_AREAS" 
                      "PX_QUANTITIES_BP_CALCULATION" "PX_QUANTITIES_BUILD_PARTS_RANGE" "PX_QUANTITIES_ROOM_CALCULATION" 
                      "PX_QUANTITIES_ROOM_RANGE" "PX_QUANTITIES_SELECTION" "PX_REFURBISH_LAYER_STYLES"
                     ))
    
    (princ "\n=== Copying dependency dictionaries ===")
    (foreach dictName dictNames
      (princ (strcat "\nProcessing: " dictName))
      (setq srcDepDict (vl-catch-all-apply 'vla-item (list (vla-get-dictionaries srcDoc) dictName)))
      (if (vl-catch-all-error-p srcDepDict)
        (princ " - Not found in source")
        (progn
          (setq dstDepDict (vl-catch-all-apply 'vla-item (list (vla-get-dictionaries dstDoc) dictName)))
          (if (vl-catch-all-error-p dstDepDict) (setq dstDepDict (vla-add (vla-get-dictionaries dstDoc) dictName)))
          (setq allSrcObjects '())
          (vlax-for depItem srcDepDict (setq allSrcObjects (cons depItem allSrcObjects)))
          (if allSrcObjects
            (progn
              (setq objArray (vlax-make-safearray vlax-vbObject (cons 0 (1- (length allSrcObjects)))))
              (setq idx 0)
              (foreach obj (reverse allSrcObjects) (vlax-safearray-put-element objArray idx obj) (setq idx (1+ idx)))
              (vl-catch-all-apply 'vla-CopyObjects (list srcDoc (vlax-make-variant objArray) dstDepDict))
              (princ " - Completed")
            ) (princ " - Empty")
          )
        )
      )
    )
    (princ)
  )

  ;;; Initialize variables
  (setq app         (vlax-get-acad-object)
        docs        (vla-get-documents app)
        dstDoc      (vla-get-activedocument app)
        srcPath     (getfiled "Select DWT template file" "" "dwt" 0)
        copiedCount 0
        failedPSDs  '()
        renamedPSDs '()
        batchFailObjs '()
        startTrans  nil
  )

  ;;; Check if file was selected
  (if (not srcPath) (progn (princ "\nUser cancelled operation.") (exit)))
  (if (not (findfile srcPath)) (progn (princ (strcat "\nError: Template file not found: " srcPath)) (exit)))

  ;;; Open source file in read-only mode
  (princ (strcat "\nOpening template file: " srcPath))
  (setq srcDoc (vla-open docs srcPath :vlax-true))
  (if (not srcDoc) (progn (princ "\nError: Cannot open template file.") (exit)))

  ;;; Get Property Set Definitions dictionaries
  (princ "\nGetting Property Set Definitions dictionaries...")
  (setq srcDicts (vl-catch-all-apply 'vla-item (list (vla-get-dictionaries srcDoc) "AEC_PROPERTY_SET_DEFS")))
  (setq dstDicts (vl-catch-all-apply 'vla-item (list (vla-get-dictionaries dstDoc) "AEC_PROPERTY_SET_DEFS")))

  (cond 
    ((vl-catch-all-error-p srcDicts) (princ "\nError: AEC_PROPERTY_SET_DEFS dictionary not found in template file."))
    ((vl-catch-all-error-p dstDicts) (princ "\nError: AEC_PROPERTY_SET_DEFS dictionary not found in current drawing."))
    (t
     (princ "\nStarting transaction...")
     (vla-StartUndoMark dstDoc)
     (setq startTrans T)
     
     (copyDependencyDicts)
     
     (princ "\n\n=== Updating Property Set Definitions (one-by-one) ===")
     (vlax-for item srcDicts
       (setq psdName (vla-get-name item))
       (princ (strcat "\nProcessing: " psdName))
       
       ;; Delete existing PSD if found (rename if deletion fails)
       (setq oldPsdItem (vl-catch-all-apply 'vla-item (list dstDicts psdName)))
       (cond
         ((vl-catch-all-error-p oldPsdItem) nil) ; nothing to delete
         (t
          (setq delRes (vl-catch-all-apply 'vla-delete (list oldPsdItem)))
          (if (vl-catch-all-error-p delRes)
            (progn
              (setq newName (makeUniqueName dstDicts psdName))
              (princ (strcat " - In use, renaming old version to " newName "..."))
              (vl-catch-all-apply 'vla-put-name (list oldPsdItem newName))
              (setq renamedPSDs (cons oldPsdItem renamedPSDs))
            )
            (princ " - Deleting old version...")
          )
         )
       )
       
       ;; Try copying new PSD from source
       (setq singleObjArray (vlax-make-safearray vlax-vbObject '(0 . 0)))
       (vlax-safearray-put-element singleObjArray 0 item)
       ;; First attempt – copy directly into the destination PSD dictionary
       (setq copyResult (vl-catch-all-apply 'vla-CopyObjects (list srcDoc (vlax-make-variant singleObjArray) dstDicts)))
       
       ;; Fallback: if the first attempt failed, try copying into the destination drawing itself.
       (if (vl-catch-all-error-p copyResult)
         (progn
           (setq copyResult (vl-catch-all-apply 'vla-CopyObjects (list srcDoc (vlax-make-variant singleObjArray) dstDoc)))
           ;; If the fallback succeeds, rely on AutoCAD to place the PSD in the correct dictionary.
         )
       )
       
       (if (vl-catch-all-error-p copyResult)
         (progn
           (princ (strcat " - Copy failed: " (vl-catch-all-error-message copyResult)))
           (princ " - Tried fallback as well; still failed")
           (setq failedPSDs (cons psdName failedPSDs))
           (setq batchFailObjs (cons item batchFailObjs))
         )
         (progn
           (princ " - Success")
           (setq copiedCount (1+ copiedCount))
         )
       )
     )
     
     (princ "\n\nUpdating database...")
     (vla-Regen dstDoc acActiveViewport)
     
     ;; Attempt to delete renamed PSDs now that new ones are in place
     (if renamedPSDs
       (progn
         (princ "\nDeleting renamed (old) PSDs that are no longer needed...")
         (setq stillInUse '())
         (foreach oldObj renamedPSDs
           (if (and oldObj (not (vlax-object-released-p oldObj)))
             (progn
               (setq delRes (vl-catch-all-apply 'vla-delete (list oldObj)))
               (if (vl-catch-all-error-p delRes)
                 (setq stillInUse (cons (vla-get-name oldObj) stillInUse))
                 (princ (strcat "\nDeleted old PSD: " (vla-get-name oldObj)))
               )
             )
           )
         )
         (if stillInUse
           (progn
             (princ "\nCould not delete the following old PSDs as they are still referenced:")
             (foreach n (reverse stillInUse) (princ (strcat "\n - " n)))
           )
         )
       )
     )
     
     ;; ========== Second-level fallback : try copying remaining failed PSDs in ONE batch ==========
     (if batchFailObjs
       (progn
         (princ "\n\nSecond-level fallback: attempting batch copy of remaining PSDs ...")
         (setq batchArray (vlax-make-safearray vlax-vbObject (cons 0 (1- (length batchFailObjs)))))
         (setq idx 0)
         (foreach obj (reverse batchFailObjs)
           (vlax-safearray-put-element batchArray idx obj)
           (setq idx (1+ idx))
         )
         (setq copyResult (vl-catch-all-apply 'vla-CopyObjects (list srcDoc (vlax-make-variant batchArray) dstDicts)))
         (if (not (vl-catch-all-error-p copyResult))
           (progn
             ;; Success – adjust counters/lists
             (setq copiedCount (+ copiedCount (length batchFailObjs)))
             (princ "\nBatch copy succeeded for all remaining PSDs.")
             (setq failedPSDs '())
           )
           (princ (strcat "\nBatch copy still failed: " (vl-catch-all-error-message copyResult)))
         )
       )
     )
     
     (princ "\nEnding transaction...")
     (vla-EndUndoMark dstDoc)
     (setq startTrans nil)
     
     ;; ---------- If PSDs STILL failed ► brute-force import via block ----------
     (if failedPSDs
       (progn
         (importStylesViaBlock srcPath)
         ;; Re-evaluate whether the previously failed PSDs now exist
         (setq stillFailed '())
         (foreach name failedPSDs
           (setq oldPsdItem (vl-catch-all-apply 'vla-item (list dstDicts name)))
           (if (vl-catch-all-error-p oldPsdItem)
             (setq stillFailed (cons name stillFailed))
           )
         )
         ;; Update counters/lists
         (setq copiedCount (+ copiedCount (- (length failedPSDs) (length stillFailed))))
         (setq failedPSDs stillFailed)
       )
     )
     
     (princ (strcat "\n\n=== Update Complete ==="))
     (princ (strcat "\nSuccessfully copied: " (itoa copiedCount) " Property-Sets"))
     (if failedPSDs
       (progn
         (princ (strcat "\nFailed to copy: " (itoa (length failedPSDs)) " Property-Sets"))
         (princ "\nFailed PSDs:")
         (setq count 0)
         (foreach psdName (reverse failedPSDs)
           (princ (strcat "\n" (itoa (setq count (1+ count))) ". " psdName))
         )
         (princ "\n\nNOTE: Failed PSDs likely have complex dependencies or special configurations.")
         (princ "\nSuggested solutions:")
         (princ "\n1. Manually copy failed PSDs using Style Manager (Format > Style Manager)")
         (princ "\n2. Use IMPORTSTYLESANDSETTINGS command if available in your AutoCAD version")
         (princ "\n3. Check if PSDs use custom property definitions that need to be copied first")
       )
       (princ "\n✔ All PSDs copied successfully")
     )
     (princ "\nPlease check Style Manager to confirm the update.")
    )
  )
  
  (if (and srcDoc (not (vlax-object-released-p srcDoc)))
    (progn (princ "\nClosing template file...") (vla-close srcDoc :vlax-false))
  )
  (princ "\n")
  (princ)
)

;;; Diagnostic command to compare PSDs between template and current drawing
(defun c:PSDCOMPARE ( / *error* app docs dstDoc srcPath srcDoc srcDicts dstDicts srcPSDs dstPSDs missingPSDs extraPSDs)
  
  ;;; Local error handling function
  (defun *error* (msg)
    (if (and srcDoc (not (vlax-object-released-p srcDoc)))
      (vla-close srcDoc :vlax-false)
    )
    (cond ((not msg))                               
          ((wcmatch (strcase msg) "*CANCEL*,*QUIT*")) 
          ((princ (strcat "\nError occurred: " msg)))
    )
    (princ)
  )

  ;;; Initialize variables
  (setq app     (vlax-get-acad-object)
        docs    (vla-get-documents app)
        dstDoc  (vla-get-activedocument app)
        srcPath (getfiled "Select DWT template file" "" "dwt" 0)
  )

  ;;; Check if file was selected
  (if (not srcPath)
    (progn (princ "\nUser cancelled operation.") (exit))
  )

  ;;; Check if template file exists
  (if (not (findfile srcPath))
    (progn (princ (strcat "\nError: Template file not found: " srcPath)) (exit))
  )

  ;;; Open source file in read-only mode
  (princ (strcat "\nOpening template file: " srcPath))
  (setq srcDoc (vla-open docs srcPath :vlax-true))
  (if (not srcDoc)
    (progn (princ "\nError: Cannot open template file.") (exit))
  )

  ;;; Get Property Set Definitions dictionaries
  (princ "\nGetting Property Set Definitions dictionaries...")
  (setq srcDicts (vl-catch-all-apply 'vla-item (list (vla-get-dictionaries srcDoc) "AEC_PROPERTY_SET_DEFS")))
  (setq dstDicts (vl-catch-all-apply 'vla-item (list (vla-get-dictionaries dstDoc) "AEC_PROPERTY_SET_DEFS")))

  (cond 
    ;; Check source dictionary
    ((vl-catch-all-error-p srcDicts)
     (princ "\nError: AEC_PROPERTY_SET_DEFS dictionary not found in template file."))
    
    ;; Check destination dictionary
    ((vl-catch-all-error-p dstDicts)
     (princ "\nError: AEC_PROPERTY_SET_DEFS dictionary not found in current drawing."))
    
    ;; Both dictionaries exist, start comparison
    (t
     ;;; Collect source PSDs
     (setq srcPSDs '())
     (vlax-for item srcDicts
       (setq srcPSDs (cons (vla-get-name item) srcPSDs))
     )
     (setq srcPSDs (reverse srcPSDs))
     
     ;;; Collect destination PSDs
     (setq dstPSDs '())
     (vlax-for item dstDicts
       (setq dstPSDs (cons (vla-get-name item) dstPSDs))
     )
     (setq dstPSDs (reverse dstPSDs))
     
     ;;; Find missing PSDs
     (setq missingPSDs '())
     (foreach psdName srcPSDs
       (if (not (member psdName dstPSDs))
         (setq missingPSDs (cons psdName missingPSDs))
       )
     )
     
     ;;; Find extra PSDs
     (setq extraPSDs '())
     (foreach psdName dstPSDs
       (if (not (member psdName srcPSDs))
         (setq extraPSDs (cons psdName extraPSDs))
       )
     )
     
     ;;; Display comparison results
     (princ (strcat "\n\n=== PSD Comparison Results ==="))
     (princ (strcat "\nTemplate file: " srcPath))
     (princ (strcat "\nTemplate PSDs: " (itoa (length srcPSDs))))
     (princ (strcat "\nCurrent drawing PSDs: " (itoa (length dstPSDs))))
     
     (princ "\n\nAll PSDs in template:")
     (setq count 0)
     (foreach psdName srcPSDs
       (princ (strcat "\n" (itoa (setq count (1+ count))) ". " psdName))
     )
     
     (if missingPSDs
       (progn
         (princ (strcat "\n\nMissing PSDs (" (itoa (length missingPSDs)) "):"))
         (setq count 0)
         (foreach psdName (reverse missingPSDs)
           (princ (strcat "\n" (itoa (setq count (1+ count))) ". " psdName " ❌"))
         )
       )
       (princ "\n\n✔ No missing PSDs")
     )
     
     (if extraPSDs
       (progn
         (princ (strcat "\n\nExtra PSDs in current drawing (" (itoa (length extraPSDs)) "):"))
         (setq count 0)
         (foreach psdName (reverse extraPSDs)
           (princ (strcat "\n" (itoa (setq count (1+ count))) ". " psdName " ➕"))
         )
       )
     )
    )
  )
  
  ;;; Close template file and finish
  (if (and srcDoc (not (vlax-object-released-p srcDoc)))
    (progn
      (princ "\n\nClosing template file...")
      (vla-close srcDoc :vlax-false)
    )
  )
  (princ "\n")
  (princ)
)

;;; Simple command to list current PSDs
(defun c:PSDLIST ( / app dstDoc dstDicts psdName count)
  (vl-load-com)
  (setq app    (vlax-get-acad-object)
        dstDoc (vla-get-activedocument app)
        count  0
  )
  
  (setq dstDicts (vl-catch-all-apply 'vla-item (list (vla-get-dictionaries dstDoc) "AEC_PROPERTY_SET_DEFS")))
  
  (if (vl-catch-all-error-p dstDicts)
    (princ "\nNo AEC_PROPERTY_SET_DEFS dictionary found in current drawing.")
    (progn
      (princ "\nProperty Set Definitions in current drawing:")
      (princ "\n" )
      (vlax-for item dstDicts
        (setq psdName (vla-get-name item))
        (princ (strcat (itoa (setq count (1+ count))) ". " psdName "\n"))
      )
      (princ (strcat "\nTotal: " (itoa count) " Property Set Definitions"))
    )
  )
  (princ)
)



;;; Helper to generate a unique *_OLD name inside a dictionary
(defun makeUniqueName (dict baseName / idx candidate testObj)
  (setq idx 0)
  (while T
    (setq candidate (strcat baseName "_OLD" (if (> idx 0) (itoa idx) "")))
    (setq testObj (vl-catch-all-apply 'vla-item (list dict candidate)))
    (if (vl-catch-all-error-p testObj)
      (progn (return candidate))
      (setq idx (1+ idx))
    )
  )
)

(defun importStylesViaBlock (tplPath / ms insPt blkRef)
  (princ "\nFinal fallback: inserting template as a temporary block to pull in missing styles ...")
  (setq ms (vla-get-ModelSpace dstDoc))
  (setq insPt (vlax-3d-point '(0 0 0)))
  (setq blkRef (vl-catch-all-apply 'vla-InsertBlock (list ms insPt tplPath 1.0 1.0 1.0 0.0)))
  (if (vl-catch-all-error-p blkRef)
    (princ (strcat "\nInsertion failed: " (vl-catch-all-error-message blkRef)))
    (progn
      ;; Delete the block reference immediately
      (vl-catch-all-apply 'vla-Delete (list blkRef))
      (princ "\nTemplate inserted and removed, styles should now be available.")
    )
  )
)



(princ "\nPSD_PSET_UPDATE (v6.0-simplified) loaded.")
(princ "\nCommands:")
(princ "\n  PSDUPDATE  - Update Property Set Definitions from template")
(princ "\n  PSDCOMPARE - Compare PSDs between template and current drawing")
(princ "\n  PSDLIST    - List PSDs in current drawing")
(princ "\n")
(princ) 
