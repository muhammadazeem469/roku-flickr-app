' ImageMapper.brs
' Maps Flickr API JSON responses to ImageModel

function ImageMapper_fromFlickrJSON(jsonObject as Object) as Object
    model = CreateImageModel()
    
    if jsonObject = invalid then
        print "[ImageMapper] Invalid JSON object received"
        return model
    end if
    
    ' Map required fields
    model = m.mapCoreFields(model, jsonObject)
    model = m.mapOwnerFields(model, jsonObject)
    model = m.mapDimensions(model, jsonObject)
    model = m.mapMetadata(model, jsonObject)
    model = m.mapImageUrls(model, jsonObject)
    
    return model
end function


' Map core fields (id, title, description)
function ImageMapper_mapCoreFields(model as Object, json as Object) as Object
    if json.id <> invalid then model.id = json.id
    if json.title <> invalid then model.title = json.title
    
    ' Description can be nested
    if json.description <> invalid then
        if Type(json.description) = "roAssociativeArray" and json.description._content <> invalid then
            model.description = json.description._content
        else if Type(json.description) = "roString" then
            model.description = json.description
        end if
    end if
    
    return model
end function


' Map owner information
function ImageMapper_mapOwnerFields(model as Object, json as Object) as Object
    if json.owner <> invalid then model.ownerId = json.owner
    if json.ownername <> invalid then model.owner = json.ownername
    
    return model
end function


' Map image dimensions
function ImageMapper_mapDimensions(model as Object, json as Object) as Object
    ' Try original dimensions first, fallback to large
    if json.width_o <> invalid then
        model.width = m.safeParseInt(json.width_o)
    else if json.width_l <> invalid then
        model.width = m.safeParseInt(json.width_l)
    end if
    
    if json.height_o <> invalid then
        model.height = m.safeParseInt(json.height_o)
    else if json.height_l <> invalid then
        model.height = m.safeParseInt(json.height_l)
    end if
    
    return model
end function


' Map metadata (tags, date, views)
function ImageMapper_mapMetadata(model as Object, json as Object) as Object
    ' Parse tags (can be string or array)
    if json.tags <> invalid then
        if Type(json.tags) = "roString" then
            model.tags = json.tags.Split(" ")
        else if Type(json.tags) = "roArray" then
            model.tags = json.tags
        end if
    end if
    
    if json.dateupload <> invalid then model.datePosted = json.dateupload
    if json.views <> invalid then model.views = m.safeParseInt(json.views)
    
    return model
end function


' Map image URLs using ImageUrlBuilder
function ImageMapper_mapImageUrls(model as Object, json as Object) as Object
    urlBuilder = ImageUrlBuilder()
    
    model.url_thumbnail = urlBuilder.build(json, "q")
    model.url_small = urlBuilder.build(json, "n")
    model.url_medium = urlBuilder.build(json, "z")
    model.url_large = urlBuilder.build(json, "b")
    
    return model
end function


' Safe integer parsing helper
function ImageMapper_safeParseInt(value as Dynamic) as Integer
    if value = invalid then return 0
    
    if Type(value) = "roInt" or Type(value) = "roInteger" then
        return value
    else if Type(value) = "roString" then
        return Val(value.ToStr())
    end if
    
    return 0
end function


' Factory function
function ImageMapper() as Object
    return {
        fromFlickrJSON: ImageMapper_fromFlickrJSON
        mapCoreFields: ImageMapper_mapCoreFields
        mapOwnerFields: ImageMapper_mapOwnerFields
        mapDimensions: ImageMapper_mapDimensions
        mapMetadata: ImageMapper_mapMetadata
        mapImageUrls: ImageMapper_mapImageUrls
        safeParseInt: ImageMapper_safeParseInt
    }
end function