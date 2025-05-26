# User Guide (English)

🎯 **Purpose of the script**
This AutoLISP script identifies and removes duplicate Property Set Definitions (PSDs) in an AutoCAD Architecture drawing. Only the original base definition (e.g. `Pset_QuantityTakeOff`) is kept while automatically generated copies such as `(2)` or `(3)` are deleted.

📦 **Load the script**
1. Start AutoCAD Architecture.
2. Type `APPLOAD` at the command line.
3. Load the file `PSDDEDUP.lsp`.

After loading you will see:
```
PSDDEDUP v9 loaded – type PSDDEDUP to run.
```
The script is now ready.

▶️ **Run the command**
1. Type `PSDDEDUP` at the command line.
2. You will be prompted:
```
Enter base-name filter (comma,* ?) <All>:
```
You may enter filter patterns, for example:
```
2dBlock,RubnerPolylinien*
```
Press Enter to check all PSDs.

🔎 **Check duplicates**
When PSD duplicates are detected, the script shows:
```
=== Duplicate groups ===
1) Base name → Duplicate1, Duplicate2, ...
```
Then you are asked to choose a number:
```
Number [1-… ,0=Cancel]<0>:
```
Enter a number to clean that duplicate group, or `0` to cancel.

🧹 **Clean and delete**
To confirm you see:
```
Delete Duplicate1, Duplicate2, … [Y/N] <N>:
```
Enter `Y` or `y` to remove the entries.

Press Enter or `N` to abort.

After successful deletion you see:
```
✔ Removed; please run PURGE manually afterwards.
```
Run the `PURGE` command afterwards to remove empty shells.

📋 **Other possible messages**
- If there are no PSDs in the drawing:
```
=> No property-set definitions in this drawing.
```
- If no duplicates were found:
```
=> No duplicate groups found.
```
- If you cancel the process:
```
— Cancelled —
```

⚙️ **How it works**
- The script analyzes the `AEC_PROPERTY_SET_DEFS` structure to collect all Property Set Definitions.
- PSDs with similar base names and appended numbers (such as `(2)` or `(3)`) are grouped.
- Only the base definition remains; all duplicates are removed.
- Any references that prevent deletion are detected – you must resolve those dependencies manually and run the script again.

