import Fluent
import Vapor
import Auth
import BCrypt

class MyUser: Model {
    var id: Node?
    var exists: Bool = false
    
    var name: String
    var password: String
    
    init(name: String, password: String) {
        self.name = name
        self.password = password
    }
    
    required init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        name = try node.extract("name")
        password = try node.extract("password")
    }
    
    func makeNode(context: Context) throws -> Node {
        var node = try Node(node: [
            "id": id,
            "name": name
            ])
        
        switch context {
        case is DatabaseContext:
            node["password"] = password.makeNode()
        default:
            break
        }
    
        return node
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity) { users in
            users.id()
            users.string("name")
            users.string("password")
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
}

extension MyUser: Auth.User {
    convenience init(credentials: NamePassword) throws {
        try self.init(name: credentials.name, password: BCrypt.digest(password: credentials.password))
    }
    
    static func register(credentials: Credentials) throws -> Auth.User {
        guard let namePassword = credentials as? NamePassword else {
            throw Abort.custom(status: .forbidden, message: "Unsupported credentials type \(type(of: credentials))")
        }
        
        let user = try MyUser(credentials: namePassword)
        return user
    }
    
    static func authenticate(credentials: Credentials) throws -> Auth.User {
        switch credentials {
        case let namePassword as NamePassword:
            guard let user = try MyUser.query().filter("name", namePassword.name).first() else {
                throw Abort.custom(status: .networkAuthenticationRequired, message: "Invalid username or password")
            }
            if try BCrypt.verify(password: namePassword.password, matchesHash: user.password) {
                return user
            }
            else {
                throw Abort.custom(status: .networkAuthenticationRequired, message: "Invalid username or password")
            }
        case let id as Identifier:
            guard let user = try MyUser.find(id.id) else {
                throw Abort.custom(status: .forbidden, message: "Invalid user identifier")
            }
            return user
        default:
            throw Abort.custom(status: .forbidden, message: "Unsupported credentials type \(type(of: credentials))")
        }
    }
}

struct NamePassword: Credentials {
    let name: String
    let password: String
    
    public init(name: String, password: String) {
        self.name = name
        self.password = password
    }
}
