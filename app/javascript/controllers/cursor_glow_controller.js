import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.glow = this.createGlowElement()
    this.element.appendChild(this.glow)
    this.element.addEventListener('mousemove', this.updateGlowPosition.bind(this))
    
    // Pokazujemy łunę od razu
    this.glow.style.opacity = '1'
  }

  disconnect() {
    this.element.removeEventListener('mousemove', this.updateGlowPosition.bind(this))
    if (this.glow) {
      this.glow.remove()
    }
  }

  createGlowElement() {
    const glow = document.createElement('div')
    glow.className = 'cursor-glow'
    return glow
  }

  updateGlowPosition(event) {
    const rect = this.element.getBoundingClientRect()
    const x = event.clientX - rect.left
    const y = event.clientY - rect.top
    
    this.glow.style.left = `${x}px`
    this.glow.style.top = `${y}px`
  }
}