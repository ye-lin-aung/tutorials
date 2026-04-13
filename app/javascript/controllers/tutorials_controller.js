import { Controller } from "@hotwired/stimulus"
import { driver } from "driver.js"

// Stimulus controller identified as `tutorials`.
//
// Usage in the layout:
//
//   <div data-controller="tutorials"
//        data-tutorials-available-value='["teacher.grade","student.welcome"]'
//        data-tutorials-auto-open-value="student.welcome">
//   </div>
//
// Actions:
//   data-action="click->tutorials#open" data-tutorials-tour-id-param="teacher.grade"
//
// Programmatic invocation (e.g. from command palette):
//   element.dispatchEvent(new CustomEvent("tutorials:open", { detail: { tourId } }))
//
// Events dispatched (Stimulus prefixes with the identifier):
//   tutorials:started  { detail: { tourId } }
//   tutorials:step     { detail: { tourId, stepIndex } }
//   tutorials:done     { detail: { tourId, completed } }
export default class extends Controller {
  static values = {
    available:        Array,
    autoOpen:         String,
    progressUrl:      { type: String, default: "/tutorials/progress" },
    tourUrlTemplate:  { type: String, default: "/tutorials/tours/%s" }
  }

  initialize() {
    this.element.addEventListener("tutorials:open", (event) => {
      this.open({ detail: event.detail })
    })
  }

  connect() {
    if (this.autoOpenValue && this.autoOpenValue.length > 0) {
      this.open({ params: { tourId: this.autoOpenValue } })
    }
  }

  async open(event) {
    const tourId = event?.params?.tourId ?? event?.detail?.tourId
    if (!tourId) {
      console.warn("[tutorials] open called without a tourId")
      return
    }

    const payload = await this.#fetchTour(tourId)
    if (!payload) return

    const driverObj = driver({
      showProgress: true,
      allowClose:   true,
      steps: payload.steps.map((s, idx) => this.#buildDriverStep(s, idx, payload.steps.length)),
      onHighlightStarted: (_el, _step, { state }) => {
        this.dispatch("step", { detail: { tourId, stepIndex: state?.activeIndex ?? 0 } })
      },
      onDestroyStarted: () => {
        const idx = driverObj.getActiveIndex?.() ?? 0
        const isLast = idx >= payload.steps.length - 1
        if (isLast) {
          this.#postProgress({ tour_id: tourId, completed: true, last_step: idx })
          this.dispatch("done", { detail: { tourId, completed: true } })
        } else {
          this.#postProgress({ tour_id: tourId, dismissed: true, last_step: idx })
          this.dispatch("done", { detail: { tourId, completed: false } })
        }
        driverObj.destroy()
      }
    })

    this.dispatch("started", { detail: { tourId } })
    driverObj.drive()
  }

  async #fetchTour(tourId) {
    try {
      const url = this.tourUrlTemplateValue.replace("%s", encodeURIComponent(tourId))
      const response = await fetch(url, {
        headers: { Accept: "application/json" },
        credentials: "same-origin"
      })
      if (!response.ok) {
        console.warn(`[tutorials] failed to fetch tour ${tourId}: ${response.status}`)
        return null
      }
      return await response.json()
    } catch (err) {
      console.warn(`[tutorials] fetch error for ${tourId}:`, err)
      return null
    }
  }

  #buildDriverStep(step, index, total) {
    return {
      element: step.element,
      popover: {
        title:        step.title,
        description:  step.body,
        progressText: `${index + 1} / ${total}`
      },
      onDeselected: () => {
        const el = document.querySelector(step.element)
        if (!el) {
          console.warn(`[tutorials] missing selector ${step.element} at step ${index}; skipping`)
        }
      }
    }
  }

  async #postProgress(body) {
    try {
      const token = document.querySelector("meta[name='csrf-token']")?.content
      await fetch(this.progressUrlValue, {
        method:      "PATCH",
        credentials: "same-origin",
        headers: {
          "Content-Type":  "application/json",
          "Accept":        "application/json",
          "X-CSRF-Token":  token || ""
        },
        body: JSON.stringify(body)
      })
    } catch (err) {
      console.warn("[tutorials] progress post failed:", err)
    }
  }
}
