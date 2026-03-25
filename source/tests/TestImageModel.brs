' ******************************************************
' TestImageModel.brs
' Test the ImageModel, ImageMapper, and utilities
' ******************************************************

function TestImageModelSuite() as Boolean
TestImageModel_Mapper()
    TestImageModel_UrlBuilder()
    TestImageModel_Validator()
    TestImageModel_ContentNodeConverter()  ' ← RENAMED
return true
end function


function TestImageModel_Mapper() as Boolean
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
return true
end function


function TestImageModel_UrlBuilder() as Boolean
photoObj = {
        server: "65535"
        id: "53791234567"
        secret: "abc123def456"
    }
    
    builder = ImageUrlBuilder()
    
    thumbnailUrl = builder.build(photoObj, "q")
    mediumUrl = builder.build(photoObj, "z")
    largeUrl = builder.build(photoObj, "b")

    
    ' Test validation
    invalidPhoto = { id: "123" } ' Missing server and secret
    invalidUrl = builder.build(invalidPhoto, "q")

return true
end function


function TestImageModel_Validator() as Boolean
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

return true
end function


function TestImageModel_ContentNodeConverter() as Boolean  ' ← RENAMED
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
return true
end function