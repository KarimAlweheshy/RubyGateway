//
//  TestVM.swift
//  RubyBridgeTests
//
//  Distributed under the MIT license, see LICENSE
//

import XCTest
import CRuby
@testable import RubyBridge

class TestVM: XCTestCase {
    /// Check we can bring up Ruby.
    func testInit() {
        do {
            try Ruby.setup()
        } catch {
            XCTFail("Ruby init failed, \(error)")
        }
    }

    /// Check whole thing is broadly functional
    func testEndToEnd() {
        do {
            let rc = try Ruby.require(filename: Helpers.fixturePath("backwards.rb"))
            XCTAssertTrue(rc)

            let string = "natural"
            var stringArg = rb_str_new_cstr(string)
            var result = rb_funcallv(0, rb_intern("backwards"), 1, &(stringArg))
            let str = rb_string_value_cstr(&(result))

            XCTAssertEqual(String(string.reversed()), String(cString: str!))
        } catch {
            XCTFail("Unexpected exception, \(error)")
        }
    }

    /// Second init failure
    func testSecondInit() {
        testInit()

        let vm2 = RbVM()
        do {
            try vm2.setup()
            XCTFail("Unexpected pass of second init")
        } catch RbError.setup(_) {
            // OK
        } catch {
            XCTFail("Unexpected error type")
        }
    }

    /// 'require' works, path set up OK
    func testRequire() {
        do {
            let rc1 = try Ruby.require(filename: "pp") // Internal
            XCTAssertTrue(rc1)

            let rc2 = try Ruby.require(filename: "pp") // Internal, repeat
            XCTAssertFalse(rc2)

            let rc3 = try Ruby.require(filename: "rouge") // Gem
            XCTAssertTrue(rc3)

            let rc4 = try Ruby.require(filename: "not-ruby") // fail
            XCTFail("vm.require unexpectedly passed, rc=\(rc4)")
        } catch {
            print("Got expected exception: \(error)")
        }
    }

    /// debug flag
    func testDebug() {
        do {
            XCTAssertFalse(Ruby.debug)
            let debugVal1 = try Ruby.eval(ruby: "$DEBUG")
            XCTAssertTrue(!RB_TEST(debugVal1))

            Ruby.debug = true
            XCTAssertTrue(Ruby.debug)
            let debugVal2 = try Ruby.eval(ruby: "$DEBUG")
            XCTAssertTrue(RB_TEST(debugVal2))

            Ruby.debug = false
            XCTAssertFalse(Ruby.debug)
        } catch {
            XCTFail("Unexpected exception: \(error)")
        }
    }

    /// verbose flag
    func testVerbose() {
        do {
            XCTAssertEqual(.medium, Ruby.verbose)
            let verboseVal1 = try Ruby.eval(ruby: "$VERBOSE")
            XCTAssertEqual(Qfalse, verboseVal1)

            Ruby.verbose = .full
            XCTAssertEqual(.full, Ruby.verbose)
            let verboseVal2 = try Ruby.eval(ruby: "$VERBOSE")
            XCTAssertEqual(Qtrue, verboseVal2)

            Ruby.verbose = .none
            XCTAssertEqual(.none, Ruby.verbose)
            let verboseVal3 = try Ruby.eval(ruby: "$VERBOSE")
            XCTAssertEqual(Qnil, verboseVal3)

            Ruby.verbose = .medium
            XCTAssertEqual(.medium, Ruby.verbose)
        } catch {
            XCTFail("Unexpected exception: \(error)")
        }
    }

    /// Script name
    func testScriptName() {
        let testTitle = "My title"
        Ruby.scriptName = testTitle

        // XXX fix me
        // XCTAssertEqual(testTitle, vm.scriptName)
    }

    /// Version
    func testVersion() {
        let version = Ruby.version
        let description = Ruby.versionDescription

        XCTAssertTrue(description.contains(version))
    }

    static var allTests = [
        ("testInit", testInit),
        ("testEndToEnd", testEndToEnd),
        ("testSecondInit", testSecondInit),
        ("testRequire", testRequire),
        ("testDebug", testDebug),
        ("testVerbose", testVerbose),
        ("testScriptName", testScriptName),
        ("testVersion", testVersion)
    ]
}
