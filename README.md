# An End-to-End L-Band PolInSAR Architecture for Glacier Facies Segmentation and Temporal Mass Loss (Δ SWE) Quantification using U-Net Deep Learning

**Team:** Group 6  
**Institution:** Vellore Institute of Technology (VIT)  
**Primary Language:** MATLAB  

---

## 📖 Project Overview
Continuous monitoring of the cryosphere is critical for tracking climate-driven mass loss. This project presents a novel, automated computational architecture that fuses **Polarimetric Interferometric SAR (PolInSAR)** physics with **self-supervised spatial Deep Learning**. 

Using L-band ALOS PALSAR Level 1.1 Single Look Complex (SLC) data, this pipeline:
1. Inverts the Random Volume over Ground (RVoG) model to extract 3D macroscopic snow penetration depth.
2. Mathematically co-registers multi-temporal orbital epochs to quantify seasonal mass loss via Change in Snow Water Equivalent (Δ SWE).
3. Utilizes deterministic physical thresholds to autonomously generate pseudo-labels, training a medical-grade **U-Net Convolutional Neural Network** to segment complex glacier facies (meltwater, crevasses, snow volume) while overcoming inherent radar speckle.

---

## 🗂️ Repository Structure
```text
├── read_alos_slc.m             # Phase I: PolInSAR Physics & 3D RVoG Inversion
├── phase2_change_detection.m   # Phase II: Spatial Co-Registration & Δ SWE
├── phase3_unet_spatial.m       # Phase III: U-Net Semantic Segmentation
├── .gitignore                  # Prevents massive L1.1 datasets from uploading
└── README.md                   # Project documentation

(Note: Output figures and PDF reports are generated locally upon execution and are not tracked in this repository to maintain a lightweight codebase).
📡 Dataset Acquisition (Required to Run)

Due to GitHub's 100 MB file limit, the massive Level 1.1 SAR datasets are not included in this repository. To execute the code, you must download the raw binary data directly from NASA's Alaska Satellite Facility (ASF).

Required Datasets (ALOS PALSAR Level 1.1 SLC - Frame 0990):

    Epoch 1 (Winter Baseline): ALPSRP233170990-H1.1__A

    Epoch 2 (Summer Melt): ALPSRP252570990-H1.1__A

Download Instructions:

    Create a free research account at NASA Earthdata.

    Navigate to the ASF DAAC Vertex Search Portal.

    In the search filters, set the dataset to ALOS PALSAR.

    Set the File Type to L1.1 (SLC) and Beam Mode to FBD (Fine Beam Dual).

    Search for the specific orbit numbers: 23317 and 25257.

    Download the resulting .zip files and extract them directly into the root directory of this repository.

⚙️ Installation & Prerequisites

This pipeline was engineered natively in MATLAB. No external Python dependencies or conda environments are required.

Required Software:

    MATLAB (R2023a or newer recommended for updated unetLayers support)

Required MATLAB Toolboxes:

    Image Processing Toolbox

    Computer Vision Toolbox

    Deep Learning Toolbox

🚀 Usage & Execution

To replicate the study, execute the scripts sequentially.

Important Path Configuration: Before running the scripts, open each .m file and update the base_dir / dir_cycle1 variables at the top of the code to match the absolute path where you extracted your downloaded NASA datasets.
Phase 1: Physical Feature Extraction

Run read_alos_slc.m

    Ingests the raw complex binary files.

    Generates the Dual-Pol Pseudo-Pauli scattering composite.

    Executes RVoG volumetric inversion to calculate 3D snow depth.

    Note: Do not clear the workspace after running. Phase 3 depends on the variables generated here.

Phase 2: Climate Metrics

Run phase2_change_detection.m

    Loads both the Winter and Summer epochs.

    Executes phase-correlation co-registration (imregtform).

    Calculates absolute mass loss (Δ SWE).

Phase 3: Spatial Deep Learning

Run phase3_unet_spatial.m

    Constructs a hybrid Memory-Disk pixelLabelDatastore to bypass MATLAB RAM limitations.

    Trains a U-Net architecture on 128x128 spatial patches.

    Executes spatial inference to generate the final, high-resolution Glacier Facies Classification map.

📊 Core Results

By executing the pipeline, the system will autonomously generate:

    Subsurface Tomographic Profiles: "X-Ray" cross-sections of the glacier down to 15 meters.

    Δ SWE Climate Maps: Divergent color mapping highlighting zones of severe summer hydrologic runoff.

    Journal-Grade AI Segmentation: A 3000x3000 resolution mapping of continuous physical geometries (crevasses, meltwater channels) previously obscured by radar speckle.

Developed by Group 6 for Advanced Radar Remote Sensing and Polar Ice Monitoring.


***

### **A Quick Note on Your Code Paths**
Before your professor runs your code from GitHub, they will need to change the folder paths. In your code, you currently have:
`base_dir = 'C:\Users\harsh\Harsh\VIT\sem6\radar\ALPSRP233170990-H1.1__A';`

The README instructs them to change this to their own computer's path, so you are totally covered. 

Your GitHub repository is now completely ready to be viewed by professionals, recruiters, and profe
