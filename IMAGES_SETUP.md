# Image Files Setup Guide

## Overview

This document explains how to add the waveform and block diagram images to the project. The images you provided need to be placed in the `waveforms/` directory.

## Images to Add

### 1. ModelSim Waveform Screenshot
**File Name**: `async_fifo_waveform_simulation.png`
**Location**: `/workspaces/VERILOG-ASYNCRONUS-FIFO/waveforms/async_fifo_waveform_simulation.png`
**Description**: Screenshot from ModelSim showing the complete 500ns simulation with all signals

**This image shows:**
- Write and read clocks running at different frequencies
- Write data (0x00-0x07) being written to FIFO
- Read data matching written data with CDC delay
- Full and empty flags assertion/deassertion
- Internal pointers and synchronization signals
- Time markers from 0-500ns

**How the image is referenced in README:**
```markdown
![Async FIFO Waveform - Complete 500ns Simulation](waveforms/async_fifo_waveform_simulation.png)
```

### 2. Block Diagram / Schematic
**File Name**: `async_fifo_block_diagram.png`
**Location**: `/workspaces/VERILOG-ASYNCRONUS-FIFO/waveforms/async_fifo_block_diagram.png`
**Description**: Block diagram showing module hierarchy and signal interconnections

**This image shows:**
- Module blocks: sync_wr, sync_rd, status, status1, fifo_mem
- Signal connections between modules
- Clock domain boundaries
- CDC (Clock Domain Crossing) paths
- Input/output interfaces

**How the image is referenced in README:**
```markdown
![Async FIFO Block Diagram](waveforms/async_fifo_block_diagram.png)
```

## Step-by-Step Instructions to Add Images

### Option A: Using Command Line (Linux/Mac)
```bash
# Navigate to project directory
cd /workspaces/VERILOG-ASYNCRONUS-FIFO

# Copy waveform image
cp ~/path/to/waveform_screenshot.png waveforms/async_fifo_waveform_simulation.png

# Copy block diagram image
cp ~/path/to/block_diagram.png waveforms/async_fifo_block_diagram.png

# Verify files are in place
ls -la waveforms/
```

### Option B: Using VS Code File Explorer
1. Open VS Code file explorer
2. Navigate to `waveforms/` folder
3. Right-click → "Reveal in File Explorer"
4. Paste/drag the PNG images into the folder
5. Files should appear immediately

### Option C: Using Git
```bash
# If images are in your repository
git add waveforms/async_fifo_waveform_simulation.png
git add waveforms/async_fifo_block_diagram.png
git commit -m "Add simulation waveforms and block diagram"
git push
```

## File Naming Convention

The images must be named exactly as follows (case-sensitive on Linux):
- ✅ `async_fifo_waveform_simulation.png`
- ✅ `async_fifo_block_diagram.png`

Not:
- ❌ `waveform.png` (wrong name)
- ❌ `ASYNC_FIFO_WAVEFORM.PNG` (wrong case)
- ❌ `async_fifo_waveform.jpg` (wrong extension - must be .png)

## Verification

After adding the images, verify they are correctly placed:

```bash
# Check file exists and is readable
ls -la waveforms/async_fifo_waveform_simulation.png
ls -la waveforms/async_fifo_block_diagram.png

# Check file size (should be > 0 bytes)
du -h waveforms/*.png
```

## Expected Display in GitHub

Once images are committed to the repository:

1. Open README.md on GitHub
2. Scroll to **Architecture** section
3. Block diagram image should display
4. Scroll to **Waveform Analysis** section
5. Waveform screenshot should display

## Troubleshooting

### Images don't display on GitHub
**Cause**: File path incorrect or file not in repository
**Solution**:
```bash
# Make sure files are tracked by git
git add waveforms/async_fifo_waveform_simulation.png
git status  # Should show "Changes to be committed"
git commit -m "Add waveform images"
```

### Images don't display in VS Code Preview
**Cause**: Relative path issue
**Solution**: 
- Check that files are in `/workspaces/VERILOG-ASYNCRONUS-FIFO/waveforms/`
- Verify file names match exactly
- Use forward slashes `/` in markdown (not backslashes)

### Preview shows broken image icon
**Cause**: File is corrupted or wrong format
**Solution**:
- Verify PNG file is valid: `file waveforms/*.png` should show "PNG image data"
- Re-export from simulator
- Check file size is reasonable (> 10KB typically)

## Current Status

✅ **Project Structure**: Ready  
✅ **README Updated**: References added  
✅ **Documentation**: Complete in waveforms/README.md  
⏳ **Images**: Awaiting addition to waveforms/ folder  

## What's Already in Place

The project already has:
- ✅ All 5 Verilog source files
- ✅ Complete testbench
- ✅ Detailed README with module descriptions
- ✅ ASCII waveform documentation (waveforms/async_fifo_waveform.txt)
- ✅ Waveform guide (waveforms/README.md)
- ✅ References to images in README (just waiting for images)

## Next Steps

1. **Add the PNG images** to `waveforms/` folder using one of the methods above
2. **Commit to Git**:
   ```bash
   git add waveforms/async_fifo_waveform_simulation.png
   git add waveforms/async_fifo_block_diagram.png
   git commit -m "Add ModelSim waveform and block diagram"
   git push
   ```
3. **Verify on GitHub**: Check that images display in README
4. **Done!**: Your project is complete

## Image Quality Requirements

For best results on GitHub:
- **Format**: PNG (lossless)
- **Minimum Width**: 800 pixels
- **Recommended Width**: 1200-1400 pixels
- **File Size**: 50KB - 500KB (reasonable size)
- **Aspect Ratio**: 16:9 or similar (readable at various sizes)

---

**Created**: 2026-08-13  
**Status**: Ready for image integration  
**Questions?**: Check waveforms/README.md for detailed signal descriptions
