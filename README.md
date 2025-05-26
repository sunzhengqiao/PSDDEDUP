# PSDDEDUP

AutoLISP scripts to identify and remove duplicate Property Set Definitions (PSDs) in AutoCAD Architecture drawings.

## Files

- `PSDDEDUP v8.lsp` – Chinese user interface.
- `PSDDEDUP_EN.lsp` – English user interface.
- `PSD_WHITELIST.lsp` – delete PSDs not in a built-in whitelist (German prompts).
- `需求文档.txt` – project requirements (Chinese).
- `PSD_WHITELIST_CLEAN.lsp` – German script to remove all Property Set
  Definitions not in the internal whitelist.

Load the script you need with `APPLOAD` then run its command (e.g. `PSDDEDUP`).

## Usage
Detailed instructions are available in:

- [USAGE-DE.md](USAGE-DE.md) – German user guide.
- [USAGE-EN.md](USAGE-EN.md) – English user guide.
