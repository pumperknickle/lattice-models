import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(lattice_modelsTests.allTests),
    ]
}
#endif
