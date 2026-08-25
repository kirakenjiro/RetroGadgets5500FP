<div align="center">

# ⚛️ 5500FP Setun 24 Hardware Studio
### EARTH OS v2.5 &middot; Universal 24-Trit Balanced Ternary Quantum Computer

[![Platform](https://img.shields.io/badge/Platform-Retro%20Gadgets-blue.svg)](https://store.steampowered.com/app/1730260/Retro_Gadgets/)
[![Language](https://img.shields.io/badge/Language-Lua%205.4%20%7C%20Node.js-green.svg)](#)
[![Quantum](https://img.shields.io/badge/Quantum-SU(3)%20Qutrit-purple.svg)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

*An authentic balanced ternary computing architecture, dynamic wave synthesizer, SU(3) quantum engine, topological microcode virtual machine, and real-time hardware telemetry bridge for **Retro Gadgets**.*

[Quickstart](#-quickstart) &bull;
[Hardware Pinouts](#-hardware-pinout--peripheral-map) &bull;
[Subsystems](#-core-subsystems) &bull;
[Desk & Multitool APIs](#-workbench--desk-environment-integration) &bull;
[B-ASM Microcode](#-b-asm-microcode-instruction-set) &bull;
[25 Physics Theorems](#-25-fundamental-earth-theorems) &bull;
[Benchmarks & Trade-offs](BENCHMARKS_AND_ANALYSIS.md) &bull;
[Documentation](#-interactive-web-companion--documentation)

</div>

---

## 🌟 Highlights & Features

- **⚖️ 24-Trit Balanced Ternary Bus**: Signed radix-3 arithmetic ($t_i \in \{-1, 0, +1\}$) spanning $-141.2\text{ Billion}$ to $+141.2\text{ Billion}$ with zero sign bits and instant bitwise negation.
- **🧬 Live 3-Strand Braid Ribbon**: Real-time SVG cubic bezier braid visualizer dynamically weaving strands based on the 24-trit accumulator.
- **⚛️ Quantum Qutrit Engine ($SU(3)$)**: Full 3-state superposition ($|\psi\rangle = c_{-1}|-1\rangle + c_0|0\rangle + c_{+1}|+1\rangle$), phase precession, purity gauge, and quantum gates (`GATE H`, `GATE X`, `GATE Z`, `GATE S`, `MEASURE`, `ENTANGLE`, `DECOHERE`).
- **〰️ Dynamic Wave Synthesizer & Live Analog Scope**: 6 waveform generators simulating Sine-Gordon Solitons, Dual Kink Collisions, 3-Node Standing Waves, Schumann EEG Harmonics ($7.83\text{ Hz}$), Chirp Sweeps, and Heisenberg Quantum Wave Packets.
- **💎 Quasicrystal & Aperiodic Visualizer**: 5D-to-2D Penrose Golden Star Rosette projection, 10-fold Bragg electron diffraction reciprocal lattice, and Fibonacci spiral inflation.
- **💻 B-ASM Microcode Virtual Machine**: Fast 32-instruction topological assembly language with conditional jumps (`JZ`, `JP`, `JN`), memory registers, and flash backup.
- **🔐 TPM Cryptography & PUF Attestation**: Derives physical unclonable hardware entropy and generates cryptographic signatures using Berry phase topological invariants.
- **💾 Triple-Rail Flash Memory**: Split across 3 hardware rails (`FlashMemory0, 1, 2`) with an instant **Physical Memory Peek** feature on the 24 LEDs.
- **🧲 Modular Magnetic Docking Connector**: Channel 11 expansion port with automatic mechanical snap chimes and status detection.
- **💡 Workbench Desk & Multitool Integration**: ANSI-color Multitool debug logging, Minitool pager notifications, and atmospheric Desk Lamp color synchronization.
- **🛣️ Dual-Highway Bidirectional HTTP Telemetry**: In-game gadget posts live state over `Wifi0:WebPostData` to keep the Web Studio bus in real-time sync with physical hardware.

---

## 🚀 Quickstart

### 1. In Retro Gadgets
1. Open the **Multitool** &gt; **Gadget View** &gt; **Permissions** &gt; Check **"Network Access"**.
2. Copy the contents of [`earth_os_kernel.lua`](earth_os_kernel.lua) into your gadget's **`CPU0.lua`**.
3. Power on your gadget.

### 2. Start the Web Companion Bridge
```bash
# Clone the repository
git clone https://github.com/kirakenjiro/retroGadgets5500Fp
cd retroGadgets5500Fp

# Start the bridge server
npm start
```
Open **`http://localhost:8080`** in your browser. When connected, the gadget's **`Led24`** link indicator will light up cyan.

---

## 🔌 Hardware Pinout & Peripheral Map

The **5500FP Setun 24** synchronizes 35 physical components across a unified 60 Hz interrupt loop:

| Component | Lua Binding | Channel / Type | Role & Function |
| :--- | :--- | :--- | :--- |
| **Video Display** | `gdt.VideoChip0` | Direct Raster | Compact 50x40 px CRT Monitor with 4 switchable screen engines (`TERM`, `OSC`, `QUTRIT`, `QC`). |
| **Keyboard Chip** | `gdt.KeyboardChip0` | Channel 1 | Alphanumeric terminal input, `Tab` mode cycling, and Up/Down history. |
| **WiFi Receiver** | `gdt.Wifi0` | Channel 2 | Asynchronous WebGet polling to `http://127.0.0.1:8080/api/poll` & telemetry POSTs. |
| **3 Center Macro Keys** | `LedButton0, 1, 2` | Ch 3, 4, 5 | Red (`-1`), White (`0`), Green (`+1`) instant bus shift insertion. |
| **4 Left Side Buttons** | `LedButton6, 5, 4, 3` | Ch 9, 8, 7, 6 | Cyan (`SIMP`), Yellow (`INV`), Magenta (`VIEW MEM / PEEK`), Blue (`SYNC`). |
| **Link Indicator LED** | `gdt.Led24` | Channel 10 | Cyan connection status indicator. |
| **Magnetic Connector** | `gdt.MagneticConnector0` | Channel 11 | Modular dock with mechanical snap chime and eject event handling. |
| **24 Bus LEDs** | `Led0 .. Led23` | Direct Matrix | Real-time physical display of the 24-Trit accumulator. |
| **Triple-Rail Flash** | `FlashMemory0, 1, 2` | Direct ROM/RAM | 256-word ternary memory (Rail 0: Minus, Rail 1: Zero, Rail 2: Plus). |
| **Audio Synthesizer** | `AudioChip0, Speaker0` | Audio Engine | Dual-tone harmonic synthesizer with frequency scaling ($f/440\text{ Hz}$). |

---

## 🪑 Workbench & Desk Environment Integration

The **5500FP Setun 24** interfaces natively with the player's workbench environment:

- **📟 Multitool Debug Terminal**: Formats high-speed diagnostic execution traces in full ANSI color:
  - Cyan `[36]`: Startup banner, CRT reflections, and magnetic dock events.
  - Green `[32]`: Successful command executions and B-ASM script step completions.
  - Yellow `[33]`: System warnings and topological boundary crossings.
  - Magenta `[35]`: Quantum $SU(3)$ state evolutions, purity measurements, and TPM signatures.
  - Red `[31]`: Error reports and chirality inversion warnings.
- **📟 Desk Minitool Status Pager**: Pushes transient notifications directly to the workbench Minitool screen (`desk.ShowMessage`, `desk.ShowWarning`).
- **💡 Atmospheric Desk Lamp Synchronizer**: Automatically alters desk lighting to match the gadget's active computing state:
  - **Quantum Mode**: Atmospheric Electric Cyan glow.
  - **Soliton & Wave Synthesis**: Warm Golden Amber pulse.
  - **Error & Detach**: Red flash.
  - Controlled directly via `LAMP ON`, `LAMP OFF`, `LAMP CYAN`, `LAMP GOLD`, `LAMP SYNC`.

---

## 🔬 Core Subsystems

### 1. 24-Trit Balanced Ternary Mathematics
Integer values are represented analytically via symmetric signed digits:
$$\text{Value} = \sum_{i=1}^{24} t_i \times 3^{i-1}, \quad t_i \in \{-1, 0, +1\}$$
- **Total Span**: $-141,214,768,240$ to $+141,214,768,240$ ($\approx 282.4\text{ Billion integers}$).
- **Zero-Cost Sign Flip**: $(-\text{Value}) = \sum (-t_i) \times 3^{i-1}$.

### 2. Quantum Qutrit Engine ($SU(3)$)
Maintains an unbroken 3-state superposition evolving under continuous Hamiltonian precession:
- `GATE H` &mdash; Ternary Hadamard gate (equalizes probabilities to $p_i = 1/3$).
- `GATE X` &mdash; Cyclic permutation ($|-1\rangle \to |0\rangle \to |+1\rangle \to |-1\rangle$).
- `GATE Z` &mdash; Advances complex quantum phase by golden angle $\phi^{-1} \approx 0.618\text{ rad}$.
- `GATE S` &mdash; Golden amplitude scaling.
- `MEASURE` &mdash; Wavefunction collapse via Born probabilities ($P(i) = |c_i|^2$), writes outcome to LED 1.
- `ENTANGLE` &mdash; Prepares maximally entangled state $\frac{1}{\sqrt{3}}(|--\rangle + |00\rangle + |++\rangle)$.
- `DECOHERE` &mdash; Damps amplitudes toward classical ground state $|0\rangle$.

### 3. Multi-Mode Wave Synthesizer
- `WAVE SOLITON` &mdash; Relativistic Sine-Gordon travelling kink pulse.
- `WAVE COLLIDE` &mdash; Dual kink/anti-kink collision with non-dissipative phase shift.
- `WAVE STAND` &mdash; Resonant 3-node acoustic standing wave ($A \sin(kx) \cos(\omega t)$).
- `WAVE EEG` &mdash; Superposition of $7.83\text{ Hz}$ (Schumann), $4.84\text{ Hz}$ ($\theta$), and $12.67\text{ Hz}$ ($\alpha$).
- `WAVE CHIRP` &mdash; Polyphonic frequency sweep.
- `WAVE GAUSS` &mdash; Dispersing Heisenberg quantum wave packet ($\Delta x(t) = \sqrt{\sigma^2 + (\hbar t / m\sigma)^2}$).

---

## 💻 B-ASM Microcode Instruction Set

| Opcode | Arguments | Action | Example |
| :--- | :--- | :--- | :--- |
| `SET` | `<word>` | Loads a 24-trit word directly into the accumulator. | `SET +++---000+++---000` |
| `SIMP` | *none* | Annihilates adjacent $(+1, -1)$ crossing pairs. | `SIMP` |
| `SHFT` | `<steps>` | Shifts accumulator right ($+$) or left ($-$). | `SHFT 2` |
| `ROT` | `<steps>` | Circularly rotates accumulator trits. | `ROT -1` |
| `INV` | *none* | Inverts chirality of all 24 trits ($+1 \leftrightarrow -1$). | `INV` |
| `LOAD` | `<addr>` | Loads word from triple-rail flash memory (0..255). | `LOAD 0` |
| `SAVE` | `<addr>` | Saves accumulator into triple-rail flash memory (0..255). | `SAVE 1` |
| `JMP` | `<line>` | Unconditional jump to instruction index. | `JMP 1` |
| `JZ` | `<line>` | Jump if net chirality $\sum \text{ACC} = 0$. | `JZ 8` |
| `JP` | `<line>` | Jump if net chirality $\sum \text{ACC} > 0$. | `JP 12` |
| `JN` | `<line>` | Jump if net chirality $\sum \text{ACC} < 0$. | `JN 14` |
| `HALT` | *none* | Halts microcode execution and rings TPM chime. | `HALT` |

---

## 🌌 25 Fundamental EARTH Theorems

Built-in analytical calculation engines based on Elastic Aether $R(3)$ Twist Hydrodynamics:

| Theorem | Command | Relation & Analytic Expression |
| :--- | :--- | :--- |
| **1. Ginzburg-Landau** | `THEORY` | $\mathcal{L} = -\frac{\lambda_0}{4}(\psi^2 - 1)^2$, $E_{\text{proton}} = 938.272\text{ MeV}$ |
| **2. Gauge Bosons** | `BOSON <type>` | Vortex link topology ($\gamma$, $W^\pm$, $Z^0$, $g$) |
| **3. Unified 4 Forces** | `FORCE_CALC` | Forces scaled by golden hierarchy ($\phi^{18}$, $\phi^{62}$) |
| **4. Intrinsic Curvature** | `CURV` | $\kappa_{\text{eff}} = \sqrt{6} \times \phi^{-2} = 0.9355\text{ fm}^{-1}$ |
| **5. Fermion Topology** | `FERMION <type>` | 3-Strand braid knot invariants ($e, \mu, \tau$) |
| **6. Aperiodic Morphism** | `SIGMA <depth>` | Substitution $\sigma: 1 \to 12, 2 \to 13, 3 \to 21$ |
| **7. Cosmic Growth** | `GROWTH <n>` | Scale hierarchy $r_n = \xi_0 \times \phi^n$ ($n=1..44$) |
| **8. Cosmological Lambda** | `COSMO <1-3>` | $\Lambda = 1.19 \times 10^{-52}\text{ m}^{-2}$, CMB peaks ($220, 356, 576$) |
| **9. Non-EM Density** | `NONEM <rho>` | Nuclear coherence $\xi(\rho) = \xi_0 (\rho_{\text{nuc}}/\rho)^{1/3}$ |
| **10. Helical Phase Flow** | `PHASE` | Angle $\theta(s, t) = (s - ct)/\xi_0$ |
| **11. Golden Stability** | `PHI` | $\phi = 1.6180339887$, KAM Torus non-resonance theorem |
| **12. Algebraic Pi** | `PI` | $\pi_{\text{EARTH}} = \sqrt{30 - 6\sqrt{5}}/2 \approx 3.14159265$ |
| **13. Reduced Planck** | `HBAR` | $\hbar$ derived from circulation action |
| **14. Quantum Superposition** | `QUT` | Qutrit ternary state in braid crossings |
| **15. Quantum Gravity** | `QG` | Metric perturbation $g_{00} = -(1 + 2\Phi/c^2)$ |
| **16. Quasicrystal Projection** | `QC` | 5D $\to$ 2D Penrose golden cut |
| **17. Spinor Parity** | `R3` | $720^\circ$ rotation invariance in $R(3)$ |
| **18. Berry Phase Flux** | `FLUX` | Strand sharing Berry phase $\Phi_B = 2\pi/3\text{ rad}$ |
| **19. Axon Conduction** | `AXON` | $d/D = 0.618$, conduction velocity $120\text{ m/s}$ |
| **20. Kink Soliton** | `SOLITON` | Relativistic Sine-Gordon kink propagation |
| **21. Brainwave Harmonics** | `EEG` | 7 Golden Schumann modes ($7.83\text{ Hz}$ to $33.17\text{ Hz}$) |
| **22. Decoherence Times** | `DIS <key>` | Timescales for Alzheimer's, Parkinson's, ALS |
| **23. Theory-Zero Axioms** | `TH0` | Morphological core topology axioms |
| **24. Vortex Tube Radius** | `TUBE` | Constant tube radius $r_t = \xi_0 \times \phi^{-2} = 0.05716\text{ fm}$ |
| **25. Master Unification** | `UNIFY` | Full analytic closure proof across all 25 relations |

---

## ⌨️ Keyboard Shortcuts & Ergonomics

| Context | Shortcut / Command | Action |
| :--- | :--- | :--- |
| **Web Studio** | <kbd>Ctrl</kbd> + <kbd>Enter</kbd> | Upload and Run current B-ASM microcode script. |
| **Web Studio** | <kbd>Ctrl</kbd> + <kbd>K</kbd> or <kbd>/</kbd> | Focus the Command Dispatcher input. |
| **Web Studio** | <kbd>1</kbd> / <kbd>0</kbd> / <kbd>-</kbd> | Paint trits under the mouse cursor. |
| **Web Studio** | <kbd>Esc</kbd> | Close Documentation portal. |
| **In-Game Gadget** | <kbd>&uarr;</kbd> / <kbd>&darr;</kbd> | Cycle through terminal command history. |
| **In-Game Gadget** | <kbd>Tab</kbd> | Cycle CRT screen (`TERM` &rarr; `OSC` &rarr; `QUTRIT` &rarr; `QC`). |
| **In-Game Gadget** | `CLEAR` or `CLS` | Clear the CRT terminal buffer. |
| **In-Game Gadget** | `AUDIO OFF` / `ON` | Mute or unmute speaker audio clicks. |
| **In-Game Gadget** | `DOCK` / `MAG` | Inspect modular magnetic port status. |
| **In-Game Gadget** | `LAMP ON` / `OFF` | Toggle workbench desk lamp. |
| **In-Game Gadget** | `LAMP CYAN` / `GOLD` | Set ambient desk lighting color. |

---

## 📁 Repository Structure

```
├── earth_os_kernel.lua         # Complete in-game Retro Gadgets CPU kernel (Lua 5.4)
├── bridge/
│   ├── bridge_server.js        # Lightweight Node.js HTTP bridge server (port 8080)
│   └── public/
│       ├── index.html          # Web Studio UI & KaTeX Documentation Portal
│       ├── style.css           # Notion-style CSS design system
│       └── app.js              # Client state, SVG braid ribbon, and ScrollSpy engine
├── RETRO_SETUN_24_SPEC.md      # Detailed hardware architecture specification
├── BENCHMARKS_AND_ANALYSIS.md  # Latencies, radix economy, historical comparisons & trade-offs
├── theorem_summary.txt         # Theoretical reference for all 25 EARTH theorems
├── all_theorems.json           # Raw publication theorems dataset
├── audio_test.lua              # Diagnostic audio frequency calibration script
├── 5500fp_faceplate_design.png # Visual 1:1 drawing guide for in-game painting
├── 5500fp_sticker_mask.png     # Binary pixel mask for custom graphic artists
├── package.json                # Project metadata & npm scripts
├── CONTRIBUTING.md             # Contribution guidelines
├── LICENSE                     # MIT License
└── README.md                   # Repository documentation
```

---

## 📄 License

This project is licensed under the **MIT License** &mdash; see the [LICENSE](LICENSE) file for details.
