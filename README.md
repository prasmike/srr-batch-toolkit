# pyReScene SRR Batch Toolkit

A Windows batch automation tool for **SRR-based reconstruction, sample rebuilding, and CRC verification**.

Optimized primarily for:

* TV series batches
* repetitive scene-style releases
* large-scale `.srr` processing workflows

---

## 📌 Purpose

This tool automates:

* SRR reconstruction using `srr.exe`
* support for both stored and compressed RAR releases
* optional sample reconstruction (`.srs`) via `srs.exe` (`-rs`)
* automatic cleanup of successfully rebuilt sample files
* CRC verification using `.sfv`
* structured final reporting:

  * CRC status per release
  * sample rebuild status summary

---

# 🚨 IMPORTANT BEFORE USE

This script REQUIRES manual configuration before first use.

You MUST edit the tool paths inside `rec.bat`:

- `PYRESCENE_DIR`
- `RAR_DIR`
- `CFV_EXE`

The configuration section is documented below.

The script MUST be executed from the directory containing:

- `.srr` files
- original media files used for reconstruction

This tool does NOT support:

- custom input directory parameters
- separate `.srr` source locations

For convenience, adding the script directory to the Windows PATH is highly recommended.

---

## ⚙️ Required Configuration

Before using the script, edit the configuration section inside `rec.bat`.

Example:

```bat
set "PYRESCENE_DIR=C:\Tools\pyrescene"
set "RAR_DIR=C:\Tools\rar"
set "CFV_EXE=C:\Tools\cfv-1.18.3\cfv.exe"
```

Variables of required tools

|**Variable**|**Description**|
| ------------ | -------------------------------------------------------------------------------------- |
|PYRESCENE_DIR | pyReScene directory containing srr.exe and srs.exe                                     |
|RAR_DIR       | Directory containing the RAR executables required for compressed archive reconstruction|
|CFV_EXE       | Full path to cfv.exe (CFV Command-line File Verify Tool)                               |

The script will NOT function correctly until these paths are configured.

---

## ⚙️ External Dependencies

The script requires the following tools:

### 🔧 pyReScene

https://github.com/srrDB/pyrescene

Used for:

* `.srr` extraction
* `.srs` sample reconstruction

---

### 📦 RAR CLI

https://www.rarlab.com/

Used for:

* compressed archive reconstruction support

---

### ✔ CFV (CRC verification)

https://cfv.sourceforge.net/

Used for:

* `.sfv` integrity checks
* CRC validation

---

## 📁 Input Structure (IMPORTANT)

All `.srr` files and media files must be placed in the same directory.

Example:

```
WorkFolder/
│
├── MovieOrEpisode1.mkv
├── MovieOrEpisode1.srr
├── MovieOrEpisode2.avi
├── MovieOrEpisode2.srr
├── MovieOrEpisode3.mkv
├── MovieOrEpisode3.srr
```

### ✔ Key concept:

* NO predefined “release folders”
* NO manual sorting required
* The script automatically:

  * reconstructs each SRR
  * creates release-specific output folders
  * handles internal structure automatically

The script scans ONLY the current working directory.

You must launch `rec.bat` from the folder containing the `.srr` and media files.

---

## 🚀 Usage

Run the script in the folder containing `.srr` and media files:

```
rec.bat
```

Enable sample reconstruction:

```
rec.bat -rs
```

---

## 🔧 Command Line Options

| Flag       | Description                           |
| ---------- | ------------------------------------- |
| `-rs`      | Enable sample (`.srs`) reconstruction |
| `-o <dir>` | Output directory                      |
| `-t <dir>` | Temporary directory                   |
| `-h`       | Show help                             |

---

## 📊 Output Summary

At the end of execution, the tool prints:

### ✔ CRC Summary

* per-release CRC verification
* overall OK / BAD status

### ✔ Sample Rebuild Summary (if `-rs`)

* successful / failed sample rebuilds
* automatic `.srs` deletion on success

---

## 🔄 Processing Flow

1. Scan all `.srr` files in working directory
2. Reconstruct each release
3. Extract embedded `.srs` (if present)
4. Rebuild samples (if `-rs`)
5. Run CRC verification
6. Print final summaries

---

## 🧠 Design Philosophy

* No manual sorting required
* Fully batch-oriented workflow
* Optimized for repetitive TV series processing
* Minimal user interaction
* Deterministic output structure

---

## 🪟 Windows PATH Integration (Recommended)

Using Windows PATH integration is strongly recommended because the script must be launched directly from reconstruction directories.

To run `rec.bat` from anywhere:

### 1. Move script to a permanent location

Example:

```
C:\Tools\SRRToolkit\
```

### 2. Add to system PATH

#### Windows 10 / 11 steps:

1. Open **Start Menu**
2. Search:

   ```
   Environment Variables
   ```
3. Open:

   ```
   Edit the system environment variables
   ```
4. Click:

   ```
   Environment Variables
   ```
5. Under **User variables** or **System variables**:

   * Select `Path`
   * Click **Edit**
6. Click **New**
7. Add folder path:

   ```
   C:\Tools\SRRToolkit\
   ```
8. Click OK → OK → OK

### 3. Test

Open CMD:

```bat
rec.bat -rs
```

---

## ⚠️ Notes

* `.srs` files are only processed if `-rs` is enabled
* Successful `.srs` rebuilds are automatically deleted
* Output is grouped per reconstructed release
* Designed for Windows batch environments only

---

## ⚠️ Current Limitations

The script currently does NOT support:

- specifying an input directory via command line
- specifying a separate `.srr` source directory
- recursive scanning
- network-safe parallel execution

The working directory is always treated as the reconstruction source location.

---

## 📌 Disclaimer

This software is provided "as is", without warranty of any kind.

The author assumes no responsibility for:

- data loss
- corrupted reconstructions
- damaged archives
- failed CRC validation
- accidental file overwrites
- misuse of the tool

Always test the script on non-critical data first.

Use entirely at your own risk.

