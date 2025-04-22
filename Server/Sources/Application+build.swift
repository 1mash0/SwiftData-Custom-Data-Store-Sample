import FluentSQLiteDriver
import Foundation
import Hummingbird
import HummingbirdFluent

func buildApplication() async throws -> some ApplicationProtocol {
    let logger = Logger(label: "items-fluent")
    let fluent = Fluent(logger: logger)
    
    fluent.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
//    fluent.databases.use(.sqlite(.memory), as: .sqlite)
    
    await fluent.migrations.add(CreateItems())
    try await fluent.migrate()
    
    let fluentPersist = await FluentPersistDriver(fluent: fluent)
    
    //    let router = Router(context: MyRequestContext.self)
    let router = Router()
    
    router.middlewares.add(LogRequestsMiddleware(.info))
    router.middlewares.add(FileMiddleware())
    router.middlewares.add(
        CORSMiddleware(
            allowOrigin: .originBased,
            allowHeaders: [.contentType],
            allowMethods: [.get, .post, .patch]
        )
    )
    
    router.get("/health") { _, _ -> HTTPResponse.Status in
            .ok
    }
    
    ItemController(fluent: fluent).addRoutes(to: router.group("items"))
    
    var app = Application(
        router: router,
        configuration: .init(address: .hostname("localhost", port: 8080))
    )
    
    app.addServices(fluent, fluentPersist)
    
    return app
}
