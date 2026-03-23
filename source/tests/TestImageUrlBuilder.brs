' ******************************************************
' TestImageUrlBuilder.brs
' Comprehensive tests for ImageUrlBuilder
' Ticket: FG-012
' ******************************************************

function TestImageUrlBuilderSuite() as Boolean
    print ""
    print "================================================"
    print "TESTING IMAGE URL BUILDER SUITE"
    print "================================================"
    
    TestImageUrlBuilder_Basic()
    TestImageUrlBuilder_AllSizes()
    TestImageUrlBuilder_Validation()
    TestImageUrlBuilder_Fallback()
    TestImageUrlBuilder_Multiple()
    TestImageUrlBuilder_Extraction()
    TestImageUrlBuilder_Dimensions()
    TestImageUrlBuilder_EdgeCases()
    
    print "================================================"
    print "IMAGE URL BUILDER TESTS COMPLETE"
    print "================================================"
    print ""
    
    return true
end function


' ******************************************************
' Test 1: Basic URL Building
' ******************************************************
function TestImageUrlBuilder_Basic() as Boolean
    print ""
    print "--- Testing Basic URL Building ---"
    
    builder = ImageUrlBuilder()
    
    photo = {
        server: "65535"
        id: "52849736921"
        secret: "abc123def456"
    }
    
    ' Test thumbnail
    url = builder.build(photo, "q")
    expected = "https://live.staticflickr.com/65535/52849736921_abc123def456_q.jpg"
    print "Thumbnail URL:", url
    print "Matches expected:", (url = expected)
    
    ' Test medium
    url = builder.build(photo, "z")
    expected = "https://live.staticflickr.com/65535/52849736921_abc123def456_z.jpg"
    print "Medium URL:", url
    print "Matches expected:", (url = expected)
    
    print ""
    return true
end function


' ******************************************************
' Test 2: All Size Suffixes
' ******************************************************
function TestImageUrlBuilder_AllSizes() as Boolean
    print ""
    print "--- Testing All Size Suffixes ---"
    
    builder = ImageUrlBuilder()
    config = GetImageConfig()
    
    photo = {
        server: "65535"
        id: "52849736921"
        secret: "abc123def456"
    }
    
    print "Thumbnail (q - 150x150):", builder.build(photo, config.SIZES.THUMBNAIL)
    print "Small (n - 320px):", builder.build(photo, config.SIZES.SMALL)
    print "Medium (z - 640px):", builder.build(photo, config.SIZES.MEDIUM)
    print "Large (b - 1024px):", builder.build(photo, config.SIZES.LARGE)
    print "Extra Large (h - 1600px):", builder.build(photo, config.SIZES.EXTRA_LARGE)
    
    ' Verify format
    url = builder.build(photo, "z")
    print "URL contains .jpg:", (url.Instr(".jpg") > 0)
    print "URL starts with https://:", (url.Left(8) = "https://")
    
    print ""
    return true
end function


' ******************************************************
' Test 3: Validation
' ******************************************************
function TestImageUrlBuilder_Validation() as Boolean
    print ""
    print "--- Testing Validation ---"
    
    builder = ImageUrlBuilder()
    
    ' Valid photo
    validPhoto = {
        server: "65535"
        id: "52849736921"
        secret: "abc123def456"
    }
    print "Valid photo:", builder.validate(validPhoto)
    
    ' Missing server
    invalidPhoto1 = {
        id: "52849736921"
        secret: "abc123def456"
    }
    print "Missing server:", builder.validate(invalidPhoto1)
    url1 = builder.build(invalidPhoto1, "z")
    print "Missing server URL empty:", (url1 = "")
    
    ' Missing id
    invalidPhoto2 = {
        server: "65535"
        secret: "abc123def456"
    }
    print "Missing id:", builder.validate(invalidPhoto2)
    url2 = builder.build(invalidPhoto2, "z")
    print "Missing id URL empty:", (url2 = "")
    
    ' Missing secret
    invalidPhoto3 = {
        server: "65535"
        id: "52849736921"
    }
    print "Missing secret:", builder.validate(invalidPhoto3)
    url3 = builder.build(invalidPhoto3, "z")
    print "Missing secret URL empty:", (url3 = "")
    
    ' Null object
    print "Null object:", builder.validate(invalid)
    
    ' Empty object
    emptyPhoto = {}
    print "Empty object:", builder.validate(emptyPhoto)
    
    print ""
    return true
end function


' ******************************************************
' Test 4: Fallback Mechanism
' ******************************************************
function TestImageUrlBuilder_Fallback() as Boolean
    print ""
    print "--- Testing Fallback Mechanism ---"
    
    builder = ImageUrlBuilder()
    
    photo = {
        server: "65535"
        id: "52849736921"
        secret: "abc123def456"
    }
    
    ' Valid preferred size
    url = builder.buildWithFallback(photo, "b", "z")
    print "Preferred size (b) URL:", url
    print "Contains '_b.jpg':", (url.Instr("_b.jpg") > 0)
    
    ' Invalid preferred size, use fallback
    url = builder.buildWithFallback(photo, "invalid_size", "z")
    print "Invalid preferred, fallback (z) URL:", url
    print "Contains '_z.jpg':", (url.Instr("_z.jpg") > 0)
    
    ' Both invalid, should use default
    url = builder.buildWithFallback(photo, "invalid1", "invalid2")
    print "Both invalid URL:", url
    print "Has valid URL:", (url <> "")
    
    print ""
    return true
end function


' ******************************************************
' Test 5: Multiple URLs
' ******************************************************
function TestImageUrlBuilder_Multiple() as Boolean
    print ""
    print "--- Testing Multiple URL Generation ---"
    
    builder = ImageUrlBuilder()
    
    photo = {
        server: "65535"
        id: "52849736921"
        secret: "abc123def456"
    }
    
    ' Generate multiple sizes
    sizes = ["q", "n", "z", "b"]
    urls = builder.buildMultiple(photo, sizes)
    
    print "Generated URL count:", urls.Count()
    print "Expected count: 4"
    print "Has thumbnail (q):", urls.DoesExist("q")
    print "Has small (n):", urls.DoesExist("n")
    print "Has medium (z):", urls.DoesExist("z")
    print "Has large (b):", urls.DoesExist("b")
    
    ' Show URLs
    for each size in urls
        print "  Size", size, ":", urls[size]
    end for
    
    print ""
    return true
end function


' ******************************************************
' Test 6: Size Extraction from URL
' ******************************************************
function TestImageUrlBuilder_Extraction() as Boolean
    print ""
    print "--- Testing Size Extraction ---"
    
    builder = ImageUrlBuilder()
    
    ' URL with size
    urlWithSize = "https://live.staticflickr.com/65535/52849736921_abc123def456_z.jpg"
    extractedSize = builder.extractSize(urlWithSize)
    print "URL:", urlWithSize
    print "Extracted size:", extractedSize
    print "Expected 'z':", (extractedSize = "z")
    
    ' Another size
    urlWithSize2 = "https://live.staticflickr.com/65535/52849736921_abc123def456_b.jpg"
    extractedSize2 = builder.extractSize(urlWithSize2)
    print "Extracted size (b):", extractedSize2
    print "Expected 'b':", (extractedSize2 = "b")
    
    ' URL without size (original)
    urlNoSize = "https://live.staticflickr.com/65535/52849736921_abc123def456.jpg"
    extractedSize3 = builder.extractSize(urlNoSize)
    print "URL without size, extracted:", extractedSize3
    print "Expected empty:", (extractedSize3 = "")
    
    print ""
    return true
end function


' ******************************************************
' Test 7: Get Dimensions
' ******************************************************
function TestImageUrlBuilder_Dimensions() as Boolean
    print ""
    print "--- Testing Dimension Lookup ---"
    
    builder = ImageUrlBuilder()
    
    ' Thumbnail - square
    dims = builder.getDimensions("q")
    print "Thumbnail (q):"
    print "  Width:", dims.width, "Height:", dims.height
    print "  Expected: 150x150"
    print "  Correct:", (dims.width = 150 and dims.height = 150)
    
    ' Medium - longest side
    dims = builder.getDimensions("z")
    print "Medium (z):"
    print "  Longest side:", dims.longestSide
    print "  Expected: 640"
    print "  Correct:", (dims.longestSide = 640)
    
    ' Large
    dims = builder.getDimensions("b")
    print "Large (b):"
    print "  Longest side:", dims.longestSide
    print "  Expected: 1024"
    print "  Correct:", (dims.longestSide = 1024)
    
    ' Extra Large
    dims = builder.getDimensions("h")
    print "Extra Large (h):"
    print "  Longest side:", dims.longestSide
    print "  Expected: 1600"
    print "  Correct:", (dims.longestSide = 1600)
    
    print ""
    return true
end function


' ******************************************************
' Test 8: Edge Cases
' ******************************************************
function TestImageUrlBuilder_EdgeCases() as Boolean
    print ""
    print "--- Testing Edge Cases ---"
    
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
    print "Photo with extra fields:"
    print "  URL:", url
    print "  Valid URL:", (url <> "")
    print "  Has correct format:", (url.Instr("_z.jpg") > 0)
    
    ' Case insensitive size
    url1 = builder.build(photoWithExtras, "Z")
    url2 = builder.build(photoWithExtras, "z")
    print "Uppercase 'Z' equals lowercase 'z':", (url1 = url2)
    
    ' Size with whitespace
    url = builder.build(photoWithExtras, " b ")
    print "Size with whitespace ' b ':"
    print "  URL:", url
    print "  Has '_b.jpg':", (url.Instr("_b.jpg") > 0)
    
    ' Invalid size uses default
    config = GetImageConfig()
    url = builder.build(photoWithExtras, "invalid_size")
    defaultSize = config.DEFAULTS.GRID_VIEW
    print "Invalid size uses default (" + defaultSize + "):"
    print "  URL:", url
    print "  Has '_" + defaultSize + ".jpg':", (url.Instr("_" + defaultSize + ".jpg") > 0)
    
    ' Empty size array
    urls = builder.buildMultiple(photoWithExtras, [])
    print "Empty size array returns empty AA:", (urls.Count() = 0)
    
    ' Invalid size array
    urls = builder.buildMultiple(photoWithExtras, invalid)
    print "Invalid size array returns empty AA:", (urls.Count() = 0)
    
    print ""
    return true
end function