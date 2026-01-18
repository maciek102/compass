import { Controller } from "@hotwired/stimulus"
import { BrowserMultiFormatReader } from "@zxing/browser"
import { BarcodeFormat, DecodeHintType, NotFoundException } from "@zxing/library"

export default class extends Controller {
  static targets = [
    "input",
    "result",
    "error",
    "status",
    "videoContainer",
    "video",
    "canvas",
  ]

  connect() {
    console.info("barcode-scanner: connect")
    this.reader = new BrowserMultiFormatReader(this.buildHints())
    this.mediaStream = null
    this.isScanning = false
    this.lastScanTime = 0
    this.scanInterval = 250 // ms między próbami skanowania
    this.resetUi()
  }

  disconnect() {
    this.stopCamera()
  }

  async startCamera() {
    // Jeśli już skanujemy, zatrzymaj i zacznij od nowa
    if (this.isScanning) {
      this.stopCamera()
    }

    this.clearMessages()
    this.showStatus("Skanowanie… skieruj kamerę na kod")

    try {
      this.mediaStream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: "environment" },
      })

      this.videoTarget.srcObject = this.mediaStream
      await this.videoTarget.play()

      this.videoContainerTarget.classList.remove("d-none")
      this.isScanning = true

      // LIVE DECODING Z THROTTLINGIEM
      this.reader.decodeFromVideoElement(
        this.videoTarget,
        (result, err) => {
          if (!this.isScanning) return

          const now = Date.now()
          if (now - this.lastScanTime < this.scanInterval) {
            return // Pomiń tę ramkę - throttling
          }
          this.lastScanTime = now

          if (result) {
            this.showResult(result.getText(), result.getBarcodeFormat())
            this.stopCamera()
          }
        }
      )
    } catch (error) {
      console.error("barcode-scanner: camera error", error)
      this.showError("Nie można uruchomić kamery.")
      this.isScanning = false
    }
  }

  stopCamera() {
    this.isScanning = false

    if (this.hasVideoTarget) {
      this.videoTarget.pause()
      this.videoTarget.srcObject = null
    }

    if (this.mediaStream) {
      this.mediaStream.getTracks().forEach((t) => t.stop())
      this.mediaStream = null
    }

    if (this.hasVideoContainerTarget) {
      this.videoContainerTarget.classList.add("d-none")
    }
  }

  async decodeFromFile() {
    this.clearMessages()
    this.showStatus("Odczytywanie obrazu…")

    const file = this.inputTarget.files?.[0]
    if (!file) {
      this.showError("Brak pliku.")
      return
    }

    const url = URL.createObjectURL(file)

    try {
      const result = await this.reader.decodeFromImageUrl(url)
      this.showResult(result.getText(), result.getBarcodeFormat())
    } catch (error) {
      if (error instanceof NotFoundException) {
        this.showError("Nie znaleziono kodu na obrazie.")
      } else {
        console.error(error)
        this.showError("Błąd odczytu obrazu.")
      }
    } finally {
      URL.revokeObjectURL(url)
    }
  }

  buildHints() {
    const hints = new Map()
    hints.set(DecodeHintType.TRY_HARDER, true)
    hints.set(DecodeHintType.ALSO_INVERTED, true)

    hints.set(DecodeHintType.POSSIBLE_FORMATS, [
      BarcodeFormat.EAN_13,
      BarcodeFormat.EAN_8,
      BarcodeFormat.UPC_A,
      BarcodeFormat.UPC_E,
      BarcodeFormat.CODE_128,
      BarcodeFormat.QR_CODE,
    ])

    return hints
  }

  resetUi() {
    this.clearMessages()
    if (this.hasInputTarget) this.inputTarget.value = ""
  }

  clearMessages() {
    this.resultTarget.textContent = ""
    this.errorTarget.textContent = ""
    this.statusTarget.textContent = ""
  }

  async showResult(text, format) {
    this.resultTarget.textContent = text
    this.statusTarget.textContent = "Odczyt zakończony powodzeniem ✔"
    
    await this.submitBarcodeResult(text, format)
  }

  async submitBarcodeResult(barcode, format) {
    try {
      const url = new URL(this.getFormAction(), window.location.origin)
      url.searchParams.append("format", "js")
      
      const response = await fetch(url.toString(), {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.getCsrfToken(),
          "Accept": "application/javascript",
        },
        body: JSON.stringify({
          barcode: barcode,
          format: format,
        }),
      })

      if (!response.ok) {
        console.error("scanner-result: server error", response.status)
        this.showError("Błąd podczas wysyłania danych.")
        return
      }

      const js = await response.text()
      eval(js)
    } catch (error) {
      console.error("scanner-result: fetch error", error)
      this.showError("Błąd połączenia z serwerem.")
    }
  }

  getFormAction() {
    return this.element.dataset.scannerResultPath || "/variants/scanner_result"
  }

  getCsrfToken() {
    const token = document.querySelector('meta[name="csrf-token"]')
    return token ? token.getAttribute("content") : ""
  }

  showError(message) {
    this.errorTarget.textContent = message
    this.statusTarget.textContent = ""
  }

  showStatus(message) {
    this.statusTarget.textContent = message
  }
}
