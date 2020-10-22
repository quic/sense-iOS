import Foundation

extension Array where Element: Comparable {
    func argmax() -> Index? {
        return indices.max(by: { self[$0] < self[$1] })
    }
    
    func argmin() -> Index? {
        return indices.min(by: { self[$0] < self[$1] })
    }
}
