' ******************************************************
' TestImageUrlBuilder.brs
' Comprehensive tests for ImageUrlBuilder
' Ticket: FG-012
' ******************************************************

function TestImageUrlBuilderSuite() as Boolean
TestImageUrlBuilder_Basic()
    TestImageUrlBuilder_AllSizes()
    TestImageUrlBuilder_Validation()
    TestImageUrlBuilder_Fallback()
    TestImageUrlBuilder_Multiple()
    TestImageUrlBuilder_Extraction()
    TestImageUrlBuilder_Dimensions()
    TestImageUrlBuilder_EdgeCases()
return true
end function


' ******************************************************
' Test 1: Basic URL Building
' ******************************************************
function TestImageUrlBuilder_Basic() as Boolean
builder = ImageUrlBuilder()
    
    photo = {
        server: "65535"
        id: "52849736921"
        secret: "abc123def456"
    }
    
    ' Test thumbnail
    url = builder.build(photo, "q")
    expected = "https://live.staticflickr.com/65535/52849736921_abc123def456_q.jpg"

    
    ' Test medium
    url = builder.build(photo, "z")
    expected = "https://live.staticflickr.com/65535/52849736921_abc123def456_z.jpg"

return true
end function


' ******************************************************
' Test 2: All Size Suffixes
' ******************************************************
function TestImageUrlBuilder_AllSizes() as Boolean
builder = ImageUrlBuilder()
    config = GetImageConfig()
    
    photo = {
        server: "65535"
        id: "52849736921"
        secret: "abc123def456"
    }

    
    ' Verify format
    url = builder.build(photo, "z")

return true
end function


' ******************************************************
' Test 3: Validation
' ******************************************************
function TestImageUrlBuilder_Validation() as Boolean
builder = ImageUrlBuilder()
    
    ' Valid photo
    validPhoto = {
        server: "65535"
        id: "52849736921"
        secret: "abc123def456"
    }

    
    ' Missing server
    invalidPhoto1 = {
        id: "52849736921"
        secret: "abc123def456"
    }

    url1 = builder.build(invalidPhoto1, "z")


    ' Missing id
    invalidPhoto2 = {
        server: "65535"
        secret: "abc123def456"
    }

    url2 = builder.build(invalidPhoto2, "z")

    
    ' Missing secret
    invalidPhoto3 = {
        server: "65535"
        id: "52849736921"
    }

    url3 = builder.build(invalidPhoto3, "z")

    
    ' Null object

    
    ' Empty object
    emptyPhoto = {}

return true
end function


' ******************************************************
' Test 4: Fallback Mechanism
' ******************************************************
function TestImageUrlBuilder_Fallback() as Boolean
builder = ImageUrlBuilder()
    
    photo = {
        server: "65535"
        id: "52849736921"
        secret: "abc123def456"
    }
    
    ' Valid preferred size
    url = builder.buildWithFallback(photo, "b", "z")

    
    ' Invalid preferred size, use fallback
    url = builder.buildWithFallback(photo, "invalid_size", "z")

    
    ' Both invalid, should use default
    url = builder.buildWithFallback(photo, "invalid1", "invalid2")

return true
end function


' ******************************************************
' Test 5: Multiple URLs
' ******************************************************
function TestImageUrlBuilder_Multiple() as Boolean
builder = ImageUrlBuilder()
    
    photo = {
        server: "65535"
        id: "52849736921"
        secret: "abc123def456"
    }
    
    ' Generate multiple sizes
    sizes = ["q", "n", "z", "b"]
    urls = builder.buildMultiple(photo, sizes)

return true
end function


' ******************************************************
' Test 6: Size Extraction from URL
' ******************************************************
function TestImageUrlBuilder_Extraction() as Boolean
builder = ImageUrlBuilder()
    
    ' URL with size
    urlWithSize = "https://live.staticflickr.com/65535/52849736921_abc123def456_z.jpg"
    extractedSize = builder.extractSize(urlWithSize)

    
    ' Another size
    urlWithSize2 = "https://live.staticflickr.com/65535/52849736921_abc123def456_b.jpg"
    extractedSize2 = builder.extractSize(urlWithSize2)

    
    ' URL without size (original)
    urlNoSize = "https://live.staticflickr.com/65535/52849736921_abc123def456.jpg"
    extractedSize3 = builder.extractSize(urlNoSize)

return true
end function


' ******************************************************
' Test 7: Get Dimensions
' ******************************************************
function TestImageUrlBuilder_Dimensions() as Boolean
builder = ImageUrlBuilder()
    
    ' Thumbnail - square
    dims = builder.getDimensions("q")

    
    ' Medium - longest side
    dims = builder.getDimensions("z")

    
    ' Large
    dims = builder.getDimensions("b")

    
    ' Extra Large
    dims = builder.getDimensions("h")

return true
end function


' ******************************************************
' Test 8: Edge Cases
' ******************************************************
function TestImageUrlBuilder_EdgeCases() as Boolean
builder = ImageUrlBuilder()
    
    ' Photo with extra fields (should be ignored)
    photoWithExtras = {
        server: "65535"
        id: "52849736921"
        secret: "abc123def456"
        title: "Test Photo"
        owner: "12345@N01"
        farm: 5
        tags: "nature landscape"
    }
    url = builder.build(photoWithExtras, "z")

    
    ' Case insensitive size
    url1 = builder.build(photoWithExtras, "Z")
    url2 = builder.build(photoWithExtras, "z")

    
    ' Size with whitespace
    url = builder.build(photoWithExtras, " b ")

    
    ' Invalid size uses default
    config = GetImageConfig()
    url = builder.build(photoWithExtras, "invalid_size")
    defaultSize = config.DEFAULTS.GRID_VIEW

    
    ' Empty size array
    urls = builder.buildMultiple(photoWithExtras, [])

    
    ' Invalid size array
    urls = builder.buildMultiple(photoWithExtras, invalid)

return true
end function