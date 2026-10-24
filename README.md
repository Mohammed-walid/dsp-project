

# DSP Project

A comprehensive Digital Signal Processing toolkit designed in MATLAB to analyze, filter, and manipulate digital signals. This repository contains the fundamental algorithms and processing pipelines required to handle raw signal data, extract spectral characteristics, and apply mathematical transformations.

## Team Members
* **Omar Tarek Saied Soudan**
* **Mohamed Walid**

## Features
* **Spectral Analysis:** Fast Fourier Transform (FFT) capabilities to seamlessly convert time-series data into the frequency domain.
* **Signal Filtering:** Implementations of Finite Impulse Response (FIR) and Infinite Impulse Response (IIR) filters for noise reduction and frequency band isolation.
* **Waveform Manipulation:** Tools for modulation, convolution, and signal shaping.
* **Data Visualization:** Built-in MATLAB plotting functions for time-domain waveforms, magnitude spectrums, and phase responses.

## Prerequisites
To run this project, ensure you have the following installed:
* MATLAB (R2020a or newer recommended)
* MATLAB Signal Processing Toolbox (recommended for advanced filter design functions)

## Installation
Clone the repository to your local machine and navigate into the project directory:

```bash
git clone https://github.com/Mohammed-walid/dsp-project.git
cd dsp-project
```

## Usage
1. Open **MATLAB**.
2. Navigate to the cloned `dsp-project` folder in the MATLAB Current Folder browser.
3. Open and run the main `.m` script (e.g., `main.m` or your specific project script) to begin the analysis.

*(Note: If you have specific raw data files like `.mat`, `.csv`, or `.wav`, ensure they are placed in the correct directory as referenced by your scripts before running.)*

## Repository Structure
* **Scripts:** Contains the core `.m` files for signal processing algorithms, filter designs, and mathematical models.
* **Data:** Recommended folder to store your raw input files and generated output `.mat` workspaces (make sure to add large data files to your `.gitignore`).

## License
Distributed under the MIT License. See `LICENSE` for more information.
