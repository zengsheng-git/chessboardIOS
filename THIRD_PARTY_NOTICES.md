# Third-Party Notices

This project is licensed under the **GNU General Public License v3.0** (see [LICENSE](LICENSE)),
as required by the third-party GPLv3 components it incorporates (and will incorporate as the
port from the Android version progresses).

## Pikafish

- Source: https://github.com/official-pikafish/Pikafish
- License: GNU GPLv3
- Used for: Xiangqi (Chinese Chess) move search/analysis engine (planned for M4;
  the Android repo builds it from `app/src/main/cpp/Pikafish-Pikafish-2026-01-02/`
  and ships `app/src/main/assets/pikafish.nnue`, both of which this iOS port reuses).
- Pikafish is itself derived from Stockfish (GNU GPLv3).

## VinXiangQi

- Source: https://github.com/Vincentzyx/VinXiangQi
- License: GNU GPLv3
- Used for: `middle.onnx`, a YOLOv5-based board/piece detection model used for
  recognizing the chessboard from screenshots (integrated from the Android repo
  in M5).

## public-Xiangqi (TCHESS)

- Project: TCHESS
- Source: https://github.com/sojourners/public-Xiangqi
- License: GNU GPLv3
- Used for: `yolov11.onnx`, an alternative YOLOv11-based (anchor-free, DFL head)
  detection model, and output-decoding logic ported in the Android version's
  `YoloV11Detector` (may be integrated as an alternative detector path).

## ONNX Runtime

- Source: https://github.com/microsoft/onnxruntime
- License: MIT License
- Used for: running the `.onnx` board-detection models on iOS (planned for M5;
  distributed via the official `onnxruntime-objc` / SwiftPM package).

---

If you redistribute this project, you must comply with the GNU GPLv3 for the
project as a whole, and retain the copyright and license notices of the
above components.
