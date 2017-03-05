import Vapor

let drop = Droplet()

drop.get { req in
    return "Hello World!"
}

drop.get("hi") { req in
    return "Hi World!"
}

drop.run()
