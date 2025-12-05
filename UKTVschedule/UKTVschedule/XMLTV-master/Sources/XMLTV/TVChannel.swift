import Foundation

public struct TVChannel {
 public var id: String
 public var name: String?
 public var icon: String?

    public init(id: String, name: String?, icon: String?) {
     self.id = id
     self.name = name
     self.icon = icon

 }
}
