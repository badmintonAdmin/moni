import CIOHID
import CoreFoundation
import Foundation

/// Reads on-die temperature sensors on Apple Silicon via the private
/// IOHIDEventSystem API (no root required). Averages the CPU-cluster sensors.
final class TempSampler {
    private let client: IOHIDEventSystemClientRef?

    init() {
        let c = IOHIDEventSystemClientCreate(kCFAllocatorDefault)
        if let c {
            // Match temperature sensors only: PrimaryUsagePage = AppleVendor, PrimaryUsage = Temperature.
            let matching: [String: Int] = [
                "PrimaryUsagePage": Int(CIOHID_PAGE_APPLE_VENDOR),
                "PrimaryUsage": Int(CIOHID_USAGE_TEMPERATURE),
            ]
            IOHIDEventSystemClientSetMatching(c, matching as CFDictionary)
        }
        self.client = c
    }

    /// Returns the average CPU temperature in °C, or nil if no usable sensor.
    func sample() -> Double? {
        // NB: the services array bridges to `[AnyObject]`, NOT `[IOHIDServiceClientRef]`
        // (which is an OpaquePointer) — casting to the latter silently yields nil.
        guard let client,
              let services = IOHIDEventSystemClientCopyServices(client) as? [AnyObject]
        else { return nil }

        var cpuTemps: [Double] = []    // sensors that clearly belong to the CPU/SoC die
        var allTemps: [Double] = []    // any non-excluded thermal sensor (fallback)

        for object in services {
            let service = unsafeBitCast(object, to: IOHIDServiceClientRef.self)
            guard let name = IOHIDServiceClientCopyProperty(service, "Product" as CFString) as? String,
                  let event = IOHIDServiceClientCopyEvent(service, Int64(CIOHID_EVENT_TYPE_TEMPERATURE), 0, 0)
            else { continue }

            let value = IOHIDEventGetFloatValue(event, Int32(CIOHID_EVENT_FIELD_TEMPERATURE))
            guard value > 0, value < 120 else { continue }   // discard obviously bogus readings

            let lower = name.lowercased()
            // Sensor naming varies by chip; exclude things that are clearly NOT the CPU.
            if lower.contains("battery") || lower.contains("gas gauge")
                || lower.contains("charger") || lower.contains("gpu")
                || lower.contains("tcal") {            // tcal = calibration reference, not a die temp
                continue
            }

            allTemps.append(value)

            // CPU/SoC die temperatures across known Apple Silicon naming schemes:
            //   M1/M2:  "Tp.." (P-cores), "Te.." (E-cores), "Tc.." (complex)
            //   newer:  "PMU tdie.." (per-die), or names containing "cpu"/"soc".
            if name.hasPrefix("Tp") || name.hasPrefix("Te") || name.hasPrefix("Tc")
                || lower.contains("tdie") || lower.contains("cpu") || lower.contains("soc") {
                cpuTemps.append(value)
            }
        }

        let pool = cpuTemps.isEmpty ? allTemps : cpuTemps
        guard !pool.isEmpty else { return nil }
        return pool.reduce(0, +) / Double(pool.count)
    }
}
