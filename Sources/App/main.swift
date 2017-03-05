import Vapor
import VaporMemory

let drop = Droplet()

try drop.addProvider(VaporMemory.Provider.self)

drop.preparations.append(MyUser.self)

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
    guard let name = request.data["name"]?.string else {
        throw Abort.badRequest
    }
    
    var newUser = MyUser(name: name)
    try newUser.save()
    
    return try newUser.makeJSON()
}

drop.get("users") { request in
    return try MyUser.all().makeJSON()
}

drop.run()
