import Vapor

let drop = Droplet()

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

drop.run()
