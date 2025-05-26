# PSDDEDUP

AutoLISP scripts to identify and remove duplicate Property Set Definitions (PSDs) in AutoCAD Architecture drawings.

## Files

- `PSDDEDUP v8.lsp` – Chinese user interface.
- `PSDDEDUP_EN.lsp` – English user interface.
- `需求文档.txt` – project requirements (Chinese).
- `PSD_WHITELIST_CLEAN.lsp` – German script to remove all Property Set
  Definitions not in the internal whitelist.

Load the duplicate-removal scripts with `APPLOAD` then run `PSDDEDUP` or
`PSDDEDUP_EN`. Lade `PSD_WHITELIST_CLEAN.lsp` und f\u00fchre `PSDBEREINIG`
aus, um Property Set Definitions au\u00dferhalb der Whitelist zu entfernen.

## Usage
Detailed instructions are available in:

- [USAGE-DE.md](USAGE-DE.md) – German user guide.
- [USAGE-EN.md](USAGE-EN.md) – English user guide.
