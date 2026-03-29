# An End-to-End L-Band PolInSAR Architecture for Glacier Facies Segmentation and Temporal Mass Loss (Δ SWE) Quantification using U-Net Deep Learning

**Team:** Group 6  
**Institution:** Vellore Institute of Technology (VIT)  
**Primary Language:** MATLAB

---

## 📖 Project Overview

Continuous monitoring of the cryosphere is critical for tracking climate-driven mass loss. This project presents a novel, automated computational architecture that fuses Polarimetric Interferometric SAR (PolInSAR) physics with self-supervised spatial Deep Learning.

Using L-band ALOS PALSAR Level 1.1 Single Look Complex (SLC) data, this pipeline:

- **Inverts the Random Volume over Ground (RVoG) model** to extract 3D macroscopic snow penetration depth
- **Mathematically co-registers multi-temporal orbital epochs** to quantify seasonal mass loss via Change in Snow Water Equivalent (Δ SWE)
- **Utilizes deterministic physical thresholds** to autonomously generate pseudo-labels, training a medical-grade U-Net Convolutional Neural Network to segment complex glacier facies (meltwater, crevasses, snow volume) while overcoming inherent radar speckle

---

## 🗂️ Repository Structure

```
RADAR/
├── read_alos_slc.m               # Phase I: PolInSAR Physics & 3D RVoG Inversion
├── phase2_change_detection.m     # Phase II: Spatial Co-Registration & Δ SWE
├── phase3_unet_spatial.m         # Phase III: U-Net Semantic Segmentation
├── .gitignore                    # Prevents massive L1.1 datasets from uploading
└── README.md                     # Project documentation
```

**Note:** Output figures and PDF reports are generated locally upon execution and are not tracked in this repository to maintain a lightweight codebase.

---

## 📡 Dataset Acquisition (Required to Run)

Due to GitHub's 100 MB file limit, the massive Level 1.1 SAR datasets are not included in this repository. To execute the code, you must download the raw binary data directly from NASA's Alaska Satellite Facility (ASF).

### Required Datasets (ALOS PALSAR Level 1.1 SLC - Frame 0990)

| Epoch | Description | Dataset ID |
|-------|-------------|-----------|
| Epoch 1 | Winter Baseline | ALPSRP233170990-H1.1__A |
| Epoch 2 | Summer Melt | ALPSRP252570990-H1.1__A |

### Download Instructions

1. Create a free research account at [NASA Earthdata](https://earthdata.nasa.gov/)
2. Navigate to the [ASF DAAC Vertex Search Portal](https://vertex.daac.asf.alaska.edu/)
3. Configure search parameters:
   - **Dataset:** ALOS PALSAR
   - **File Type:** L1.1 (SLC)
   - **Beam Mode:** FBD (Fine Beam Dual)
   - **Search Orbit Numbers:** 23317 and 25257
4. Download and extract datasets into the project root folder

---

## ⚙️ Installation & Prerequisites

This pipeline was engineered natively in MATLAB.

### Required Software

- **MATLAB** R2023a or newer

### Required MATLAB Toolboxes

- Image Processing Toolbox
- Computer Vision Toolbox
- Deep Learning Toolbox

---

## 🚀 Usage & Execution

⚠️ **Important:** Update `base_dir` and `dir_cycle1` paths inside the `.m` files to match your local extraction paths before running.

### Phase 1: Physical Feature Extraction

**File:** `read_alos_slc.m`

Run this script to perform the initial PolInSAR physics-based analysis:

```matlab
read_alos_slc
```

**Operations:**
- Loads raw complex SAR data
- Generates Pauli composite
- Performs RVoG inversion
- Outputs 3D snow depth

---

### Phase 2: Climate Metrics

**File:** `phase2_change_detection.m`

Run this script to quantify temporal changes and mass loss:

```matlab
phase2_change_detection
```

**Operations:**
- Performs image registration (`imregtform`)
- Computes Δ SWE (Change in Snow Water Equivalent)
- Generates temporal change maps

---

### Phase 3: Deep Learning Segmentation

**File:** `phase3_unet_spatial.m`

Run this script to train and apply the U-Net model:

```matlab
phase3_unet_spatial
```

**Operations:**
- Builds `pixelLabelDatastore` with pseudo-labeled training data
- Trains U-Net semantic segmentation model
- Outputs high-resolution facies segmentation map

---

## 📊 Core Results

Execution generates the following outputs:

- **Subsurface glacier tomographic profiles** – 3D visualization of snow penetration and volume structure
- **Δ SWE mass loss climate maps** – Quantitative seasonal mass loss estimates
- **High-resolution spatial facies segmentation** – 3000×3000 pixel glacier facies classification maps distinguishing meltwater, crevasses, and snow volumes

---

## 🔬 Technical Architecture

### Phase I: RVoG Inversion
- Exploits dual-polarization PolInSAR coherence matrices
- Inverts Random Volume over Ground model to extract macroscopic penetration depth
- Fundamental physics enables automated pseudo-label generation

### Phase II: Change Detection
- Multi-temporal co-registration using intensity correlation
- Computes phase-based elevation differences
- Converts elevation change to Δ SWE using snow density models

### Phase III: U-Net Segmentation
- Self-supervised training via deterministic physics thresholds
- Encoder-decoder architecture with skip connections
- Robust to SAR speckle and complex facies transitions

---

## 📝 Citation

If you use this project in your research, please cite:

```
Group 6, VIT. "An End-to-End L-Band PolInSAR Architecture for Glacier Facies 
Segmentation and Temporal Mass Loss Quantification using U-Net Deep Learning." 
Vellore Institute of Technology, 2024.
```

---

## 📧 Support & Contact

For questions regarding dataset acquisition, methodology, or execution issues, please refer to the individual script documentation or contact your course instructor.

---

## 📜 License

This project is provided for educational and research purposes through VIT.

---

**Last Updated:** March 2026  
**Status:** Active Development
