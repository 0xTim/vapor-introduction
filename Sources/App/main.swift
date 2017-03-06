import Vapor
import VaporMemory
import HTTP
import Auth

let drop = Droplet()

try drop.addProvider(VaporMemory.Provider.self)

drop.preparations.append(MyUser.self)

let authMiddleware = AuthMiddleware(user: MyUser.self)
drop.middleware.append(authMiddleware)

drop.get { req in
    return "Hello World!"
}

drop.get("hi") { req in
    return "Hi World!"
}

drop.get("hi", String.self) { req, name in
    return try drop.view.make("hi", ["name": name.makeNode()])
}

drop.post("hi") { request in
    guard let name = request.data["name"]?.string else {
        throw Abort.badRequest
    }
    
    return "Hi \(name)"
}

drop.post("users") { request in
    guard let name = request.data["name"]?.string, let password = request.data["password"]?.string else {
        throw Abort.badRequest
    }
    
    
    let credentials = NamePassword(name: name, password: password)
    var newUser = try MyUser(credentials: credentials)
    try newUser.save()
    
    return try newUser.makeJSON()
}

drop.get("users") { request in
    return try MyUser.all().makeJSON()
}

drop.get("login") { request in
    return try drop.view.make("login")
}

drop.post("login") { request in
    guard let name = request.data["name"]?.string, let password = request.data["password"]?.string else {
        throw Abort.badRequest
    }
    
    let credentials = NamePassword(name: name, password: password)
    
    do {
        try request.auth.login(credentials)
        
        guard let _ = try request.auth.user() as? MyUser else {
            request.storage.removeValue(forKey: "remember_me")
            throw Abort.badRequest
        }
        return Response(redirect: "/protected")
    }
    catch {
        print(error)
        return try drop.view.make("login")
    }
}

let protected = Auth.LoginRedirectMiddleware(loginRoute: "login")

drop.grouped(protected).get("protected") { request in
    guard let user = try request.auth.user() as? MyUser else {
        throw Abort.custom(status: .forbidden, message: "You must be logged in")
    }
    
    return "Hello \(user.name)"
}

drop.run()
