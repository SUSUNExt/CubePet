import AppKit
import SwiftUI

/// Observes scroll-wheel events inside its bounds without taking hit testing
/// away from the SwiftUI drag gesture layered over the same decoration.
struct DecorationScrollWheelReader: NSViewRepresentable {
    let onScroll: (Double) -> Void

    func makeNSView(context: Context) -> DecorationScrollWheelView {
        let view = DecorationScrollWheelView()
        view.onScroll = onScroll
        return view
    }

    func updateNSView(_ nsView: DecorationScrollWheelView, context: Context) {
        nsView.onScroll = onScroll
    }
}

final class DecorationScrollWheelView: NSView {
    var onScroll: ((Double) -> Void)?

    private var eventMonitor: Any?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        stopMonitoring()

        guard window != nil else { return }
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            guard
                let self,
                self.window === event.window,
                self.bounds.contains(self.convert(event.locationInWindow, from: nil))
            else { return event }

            self.onScroll?(event.scrollingDeltaY)
            return event
        }
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    deinit {
        stopMonitoring()
    }

    private func stopMonitoring() {
        guard let eventMonitor else { return }
        NSEvent.removeMonitor(eventMonitor)
        self.eventMonitor = nil
    }
}
