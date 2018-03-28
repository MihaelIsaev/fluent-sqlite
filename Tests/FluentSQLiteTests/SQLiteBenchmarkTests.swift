import Async
import Fluent
import FluentBenchmark
import FluentSQLite
import SQLite
import XCTest

final class SQLiteBenchmarkTests: XCTestCase {
    var benchmarker: Benchmarker<SQLiteDatabase>!
    var database: SQLiteDatabase!

    override func setUp() {
        database = try! SQLiteDatabase(storage: .memory)
        let group = MultiThreadedEventLoopGroup(numThreads: 1)
        benchmarker = Benchmarker(database, on: group, onFail: XCTFail)
    }

    func testSchema() throws {
        try benchmarker.benchmarkSchema()
    }

    func testModels() throws {
        try benchmarker.benchmarkModels_withSchema()
    }

    func testRelations() throws {
        try benchmarker.benchmarkRelations_withSchema()
    }

    func testTimestampable() throws {
        try benchmarker.benchmarkTimestampable_withSchema()
    }

    func testTransactions() throws {
        try benchmarker.benchmarkTransactions_withSchema()
    }

    func testChunking() throws {
        try benchmarker.benchmarkChunking_withSchema()
    }

    func testAutoincrement() throws {
        try benchmarker.benchmarkAutoincrement_withSchema()
    }

    func testCache() throws {
        try benchmarker.benchmarkCache_withSchema()
    }

    func testJoins() throws {
        try benchmarker.benchmarkJoins_withSchema()
    }

    func testSoftDeletable() throws {
        try benchmarker.benchmarkSoftDeletable_withSchema()
    }

    func testReferentialActions() throws {
        try benchmarker.benchmarkReferentialActions_withSchema()
    }

    func testMinimumViableModelDeclaration() throws {
        /// NOTE: these must never fail to build
        struct Foo: SQLiteModel {
            var id: Int?
            var name: String
        }
        final class Bar: SQLiteModel {
            var id: Int?
            var name: String
        }
        struct Baz: SQLiteUUIDModel {
            var id: UUID?
            var name: String
        }
        final class Qux: SQLiteUUIDModel {
            var id: UUID?
            var name: String
        }
        final class Uh: SQLiteStringModel {
            var id: String?
            var name: String
        }
    }
  
    func testIndexSupporting() throws {
        try benchmarker.benchmarkIndexSupporting_withSchema()
    }

    func testContains() throws {
        try benchmarker.benchmarkContains_withSchema()
    }

    func testSQLiteEnums() throws {
        enum PetType: Int, SQLiteEnumType {
            case cat, dog
        }

        enum NumLegs: Int, SQLiteEnumType {
            case four = 4
            case two = 2

            static func reflectDecoded() -> (NumLegs, NumLegs) {
                return (.four, .two)
            }
        }

        enum FavoriteTreat: String, SQLiteEnumType {
            case bone = "b"
            case tuna = "t"

            static func reflectDecoded() -> (FavoriteTreat, FavoriteTreat) {
                return (.bone, .tuna)
            }
        }

        struct Pet: SQLiteModel, Migration {
            var id: Int?
            var name: String
            var type: PetType
            var numLegs: NumLegs
            var treat: FavoriteTreat
        }

        database.enableLogging(using: .print)
        let conn = try benchmarker.pool.requestConnection().wait()
        defer { benchmarker.pool.releaseConnection(conn) }

        defer { try? Pet.revert(on: conn).wait() }
        try Pet.prepare(on: conn).wait()

        let cat = try Pet(id: nil, name: "Ziz", type: .cat, numLegs: .two, treat: .tuna).save(on: conn).wait()
        let dog = try Pet(id: nil, name: "Spud", type: .dog, numLegs: .four, treat: .bone).save(on: conn).wait()
        let fetchedCat = try Pet.find(cat.requireID(), on: conn).wait()
        XCTAssertEqual(dog.type, .dog)
        XCTAssertEqual(cat.id, fetchedCat?.id)
    }

    func testSQLiteJSON() throws {
        enum PetType: Int, Codable {
            case cat, dog
        }

        struct Pet: SQLiteJSONType {
            var name: String
            var type: PetType
        }

        struct User: SQLiteModel, Migration {
            var id: Int?
            var pet: Pet
        }

        database.enableLogging(using: .print)
        let conn = try benchmarker.pool.requestConnection().wait()
        defer { benchmarker.pool.releaseConnection(conn) }

        defer { try? User.revert(on: conn).wait() }
        try User.prepare(on: conn).wait()

        let cat = Pet(name: "Ziz", type: .cat)
        let tanner = try User(id: nil, pet: cat).save(on: conn).wait()
        let fetched = try User.find(tanner.requireID(), on: conn).wait()
        XCTAssertEqual(tanner.id, fetched?.id)
        XCTAssertEqual(fetched?.pet.name, "Ziz")
    }

    static let allTests = [
        ("testSchema", testSchema),
        ("testModels", testModels),
        ("testRelations", testRelations),
        ("testTimestampable", testTimestampable),
        ("testTransactions", testTransactions),
        ("testChunking", testChunking),
        ("testAutoincrement", testAutoincrement),
        ("testCache", testCache),
        ("testJoins", testJoins),
        ("testSoftDeletable", testSoftDeletable),
        ("testReferentialActions", testReferentialActions),
        ("testMinimumViableModelDeclaration", testMinimumViableModelDeclaration),
        ("testIndexSupporting", testIndexSupporting),
        ("testSQLiteEnums", testSQLiteEnums),
        ("testSQLiteJSON", testSQLiteJSON),
    ]
}
