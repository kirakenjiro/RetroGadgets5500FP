# Contributing to 5500FP Setun 24 Hardware Studio

Thank you for your interest in contributing to the **5500FP Setun 24** project! We welcome contributions to the Lua kernel, web companion bridge, B-ASM microcode library, and documentation.

---

## 🛠️ Development Setup

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/kirakenjiro/retroGadgets5500Fp
   cd retroGadgets5500Fp
   ```

2. **Run the Bridge Server**:
   ```bash
   npm start
   ```
   Open `http://localhost:8080` in your browser to access the 5500FP Setun 24 Hardware Studio.

3. **In-Game Testing (Retro Gadgets)**:
   - Copy `earth_os_kernel.lua` into your in-game gadget's `CPU0.lua`.
   - Ensure "Network Access" is enabled in Multitool permissions.
   - Power on the gadget. The link indicator LED (`Led24` / Channel 10) will illuminate cyan when connected.

---

## 📐 Coding Guidelines

### Lua Kernel (`earth_os_kernel.lua`)
- Target: Retro Gadgets Lua 5.3 / 5.4 environment.
- Keep bracket balancing strict (`(`, `{`, `[`).
- Maintain concise visual separators (`-- ====================`).
- Test all physical interrupt channels (0..15) and verify LED animations before submitting.

### Web Studio & Bridge (`bridge/`)
- Pure zero-dependency Node.js HTTP server.
- Modern vanilla JavaScript and CSS (Notion design system).
- Keep math formulas rendered with KaTeX.

---

## 📜 Pull Request Process

1. Create a feature branch (`git checkout -b feature/awesome-addition`).
2. Verify all syntax checks pass (`npm test`).
3. Commit your changes with descriptive messages.
4. Push to your branch and open a Pull Request.

---

## ⚖️ License
By contributing to 5500FP Setun 24, you agree that your contributions will be licensed under the project's [MIT License](LICENSE).
