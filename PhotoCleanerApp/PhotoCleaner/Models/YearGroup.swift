import Foundation

struct YearGroup: Identifiable, Hashable {
    let year: Int
    let yearOffset: Int
    let items: [MediaItem]

    var id: Int { year }

    func hash(into hasher: inout Hasher) {
        hasher.combine(year)
    }

    static func == (lhs: YearGroup, rhs: YearGroup) -> Bool {
        lhs.year == rhs.year
    }

    var label: String {
        switch yearOffset {
        case 1:  return "Last Year (\(year))"
        case 2:  return "2 Years Ago (\(year))"
        default: return "\(yearOffset) Years Ago (\(year))"
        }
    }
}
