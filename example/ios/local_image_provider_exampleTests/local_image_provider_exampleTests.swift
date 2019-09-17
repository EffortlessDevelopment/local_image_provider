//
//
//

import XCTest
import local_image_provider

class local_image_provider_exampleTests: XCTestCase {
    var plugin: SwiftLocalImageProviderPlugin?;
    var imageProviderExp: XCTestExpectation?
    
    override func setUp() {
        plugin = SwiftLocalImageProviderPlugin();
        imageProviderExp = expectation(description: "local image provider expect")
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testUnknownMethodCallHandled() {
        testExpectedResult( methodName: LocalImageProviderMethods.unknown, arguments: nil, resultType: String.self, assertExpect: {(result)->Void in
            let strResult = result! as! String
            XCTAssertTrue( strResult.contains( "Unrecognized method: \(LocalImageProviderMethods.unknown.rawValue)") )
        })
    }
    
    // Latest images tests
    
    func testLatestImagesWithMissingCountHandled() {
        testExpectedResult( methodName: LocalImageProviderMethods.latest_images, arguments: nil, resultType: String.self, assertExpect: {(result)->Void in
            let strResult = result! as! String
            XCTAssertEqual( "Missing max photos argument.", strResult )
        })
    }

    /// Note that this requires that there be a photo on the simulator, by default there are as of this writing.
    func testLatesetImagesWithLimitOneReturnsOnePhoto() {
        testExpectedResult( methodName: LocalImageProviderMethods.latest_images, arguments: 1, resultType: [String].self , assertExpect: {(result)->Void in
            let arrResult = result! as! [String]
            XCTAssertEqual( 1, arrResult.count )
        })
    }
    
    /// Note that this requires that there be a photo on the simulator, by default there are as of this writing.
    func testLatestImagesWithLimitTwoReturnsTwoPhotos() {
        testExpectedResult( methodName: LocalImageProviderMethods.latest_images, arguments: 2, resultType: [String].self , assertExpect: {(result)->Void in
            let arrResult = result! as! [String]
            XCTAssertEqual( 2, arrResult.count )
        })
    }
    
    // Get photo tests
    
    func testPhotoImageWithMissingArgsHandled() {
        testExpectedResult( methodName: LocalImageProviderMethods.image_bytes, arguments: nil, resultType: String.self, assertExpect: {(result)->Void in
            let strResult = result! as! String
            XCTAssertEqual( "Missing or invalid arguments: \(LocalImageProviderMethods.image_bytes.rawValue)", strResult )
        })
    }

    func testPhotoImageLoadsKnownImage() {
        guard let firstPhotoId = getFirstPhotoId() else { XCTFail(); return }
        let photoArgs = [ "id": firstPhotoId,"pixelWidth":100,"pixelHeight":100] as [String : Any]
        self.testExpectedResult( methodName: LocalImageProviderMethods.image_bytes, arguments: photoArgs, resultType: FlutterStandardTypedData.self, assertExpect: {(result)->Void in
            let byteResult = result! as! FlutterStandardTypedData
            XCTAssertTrue( !byteResult.data.isEmpty )
        })
    }
    
    func testPhotoImageHandlesUnlikelySizes() {
        guard let firstPhotoId = getFirstPhotoId() else { XCTFail(); return }
        let photoArgs = [ "id": firstPhotoId,"pixelWidth":0,"pixelHeight":0] as [String : Any]
        self.testExpectedResult( methodName: LocalImageProviderMethods.image_bytes, arguments: photoArgs, resultType: FlutterStandardTypedData.self, assertExpect: {(result)->Void in
            let byteResult = result! as! FlutterStandardTypedData
            XCTAssertTrue( !byteResult.data.isEmpty )
        })
    }
    
    func testPhotoImageHandlesUnknownImage() {
        let photoArgs = [ "id": "notARealImage","pixelWidth":100,"pixelHeight":100] as [String : Any]
        self.testExpectedResult( methodName: LocalImageProviderMethods.image_bytes, arguments: photoArgs, resultType: String.self, assertExpect: {(result)->Void in
            let strResult = result! as! String
            XCTAssertEqual( "Image not found: notARealImage", strResult )
        })
    }

    private func getFirstPhotoId() -> String? {
        var firstId: String?
        let call = FlutterMethodCall( methodName: LocalImageProviderMethods.latest_images.rawValue, arguments: 1 )
        plugin!.handle( call, result: {(result)->Void in
            guard let arrResult = result as? [String] else { XCTFail(); return }
            XCTAssertEqual( 1, arrResult.count)
            let decoder = JSONDecoder()
            do {
                let localImage = try decoder.decode( LocalImage.self, from: Data(arrResult[0].utf8))
                firstId = localImage.id
            }
            catch let error {
                XCTFail( error.localizedDescription )
            }
        })
        return firstId
    }
    
    /// Call the plugin handler with method name and arguments and then verify the return type and make any assertions required
    private func testExpectedResult<T>( methodName: LocalImageProviderMethods, arguments: Any?, resultType: T.Type, assertExpect: @escaping FlutterResult ) {
        defer {
            waitForExpectations(timeout: 10.0 )  { (error) in
                if let error = error {
                    XCTFail("timeout: \(error)")
                }}
        }
        let call = FlutterMethodCall( methodName: methodName.rawValue, arguments:arguments )
        plugin!.handle( call, result: {(result)->Void in
            defer {
                self.imageProviderExp!.fulfill()
            }
            if result is T
            {
                assertExpect( result )
            }
            else
            {
                XCTFail("Unexpected type expected: \(T.self)")
            }
        })
    }
}
