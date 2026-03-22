' ******************************************************
' TestImageModel.brs
' Test the ImageModel, ImageMapper, and utilities
' ******************************************************

function TestImageModelSuite() as Boolean
    print ""
    print "================================================"
    print "TESTING IMAGE MODEL SUITE"
    print "================================================"
    
    TestImageModel_Mapper()
    TestImageModel_UrlBuilder()
    TestImageModel_Validator()
    TestImageModel_ContentNodeConverter()  ' ← RENAMED
    
    print "================================================"
    print "IMAGE MODEL TESTS COMPLETE"
    print "================================================"
    print ""
    
    return true
end function


function TestImageModel_Mapper() as Boolean
    print ""
    print "--- Testing ImageMapper ---"
    
    ' Sample Flickr JSON (from actual API response format)
    sampleFlickrJson = {
        id: "53791234567"
        title: "Golden Gate Bridge at Sunset"
        description: {
            _content: "Beautiful sunset view of the Golden Gate Bridge"
        }
        owner: "12345678@N01"
        ownername: "JohnPhotographer"
        server: "65535"
        secret: "abc123def456"
        width_o: "4032"
        height_o: "3024"
        tags: "sunset bridge sanfrancisco goldengate"
        dateupload: "1710000000"
        views: "2547"
    }
    
    ' Create mapper and convert
    mapper = ImageMapper()
    imageModel = mapper.fromFlickrJSON(sampleFlickrJson)
    
    ' Verify mapping
    print "Image ID:", imageModel.id
    print "Title:", imageModel.title
    print "Description:", imageModel.description
    print "Owner:", imageModel.owner
    print "Width x Height:", imageModel.width, "x", imageModel.height
    print "Tags:", imageModel.tags.Count(), "tags"
    print "Views:", imageModel.views
    print "Thumbnail URL:", imageModel.url_thumbnail
    print "Medium URL:", imageModel.url_medium
    print ""
    
    return true
end function


function TestImageModel_UrlBuilder() as Boolean
    print "--- Testing ImageUrlBuilder ---"
    
    photoObj = {
        server: "65535"
        id: "53791234567"
        secret: "abc123def456"
    }
    
    builder = ImageUrlBuilder()
    
    thumbnailUrl = builder.build(photoObj, "q")
    mediumUrl = builder.build(photoObj, "z")
    largeUrl = builder.build(photoObj, "b")
    
    print "Thumbnail:", thumbnailUrl
    print "Medium:", mediumUrl
    print "Large:", largeUrl
    
    ' Test validation
    invalidPhoto = { id: "123" } ' Missing server and secret
    invalidUrl = builder.build(invalidPhoto, "q")
    print "Invalid photo URL (should be empty):", invalidUrl
    print ""
    
    return true
end function


function TestImageModel_Validator() as Boolean
    print "--- Testing ImageValidator ---"
    
    ' Valid image
    validImage = CreateImageModel()
    validImage.id = "123"
    validImage.title = "Test Image"
    validImage.url_medium = "https://example.com/image.jpg"
    
    ' Invalid image (missing URL)
    invalidImage = CreateImageModel()
    invalidImage.id = "456"
    invalidImage.title = "No URL Image"
    
    validator = ImageValidator()
    
    print "Valid image is valid:", validator.isValid(validImage)
    print "Invalid image is valid:", validator.isValid(invalidImage)
    print ""
    
    return true
end function


function TestImageModel_ContentNodeConverter() as Boolean  ' ← RENAMED
    print "--- Testing ContentNodeConverter (ImageModel) ---"
    
    ' Create a sample ImageModel
    imageModel = CreateImageModel()
    imageModel.id = "789"
    imageModel.title = "Test ContentNode"
    imageModel.description = "Testing conversion"
    imageModel.url_large = "https://example.com/large.jpg"
    imageModel.url_medium = "https://example.com/medium.jpg"
    imageModel.width = 1920
    imageModel.height = 1080
    
    ' Convert to ContentNode
    converter = ContentNodeConverter()
    contentNode = converter.fromImageModel(imageModel)
    
    print "ContentNode title:", contentNode.title
    print "ContentNode description:", contentNode.description
    print "ContentNode HDPosterUrl:", contentNode.HDPosterUrl
    print "ContentNode imageWidth:", contentNode.imageWidth
    print "ContentNode imageHeight:", contentNode.imageHeight
    print ""
    
    return true
end function