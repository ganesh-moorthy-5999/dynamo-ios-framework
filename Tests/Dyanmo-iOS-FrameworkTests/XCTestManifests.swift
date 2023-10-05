import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(Dyanmo_iOS_FrameworkTests.allTests),
    ]
}
#endif
