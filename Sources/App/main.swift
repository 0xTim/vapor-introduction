import Vapor

let drop = Droplet()

drop.get { req in
    return "Hello World!"
}

drop.get("hi") { req in
    return "Hi World!"
}

drop.get("hi", String.self) { req, name in
    return "Hi \(name)"
}

drop.run()
