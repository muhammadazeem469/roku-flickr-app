' ******************************************************
' ImageMapper.brs
' Maps Flickr API JSON to ImageModel
' ******************************************************

function ImageMapper() as Object
    return {
        fromFlickrJSON: ImageMapper_fromFlickrJSON
        mapImageUrls:   ImageMapper_mapImageUrls
        mapMetadata:    ImageMapper_mapMetadata
        mapStats:       ImageMapper_mapStats
        validate:       ImageMapper_validate
    }
end function


' Convert Flickr JSON to ImageModel
function ImageMapper_fromFlickrJSON(json as Object) as Object
    if not m.validate(json) then
        return invalid
    end if

    model = CreateImageModel()

    model.id    = json.id
    model.title = json.title
    if model.title = invalid or model.title = "" then
        model.title = "Untitled"
    end if

    model = m.mapImageUrls(model, json)
    model = m.mapMetadata(model, json)
    model = m.mapStats(model, json)

    return model
end function


' Select the best URL for a given size.
' Uses the direct URL from the API extras field when present,
' otherwise falls back to building it via ImageUrlBuilder.
' @param json  - Flickr photo JSON object
' @param field - extras field name (e.g. "url_q")
' @param size  - size suffix for the builder (e.g. "q")
' @return String URL
function ImageMapper_selectUrl(json as Object, field as String, size as String) as String
    value = json[field]
    if value <> invalid and value <> "" then return value
    urlBuilder = ImageUrlBuilder()
    return urlBuilder.build(json, size)
end function


' Map image URLs — prefer direct API extras, fall back to builder
function ImageMapper_mapImageUrls(model as Object, json as Object) as Object
    s = GetImageConfig().SIZES
    model.url_thumbnail = ImageMapper_selectUrl(json, "url_" + s.THUMBNAIL, s.THUMBNAIL)
    model.url_small     = ImageMapper_selectUrl(json, "url_" + s.SMALL,     s.SMALL)
    model.url_medium    = ImageMapper_selectUrl(json, "url_" + s.MEDIUM,    s.MEDIUM)
    model.url_large     = ImageMapper_selectUrl(json, "url_" + s.LARGE,     s.LARGE)
    return model
end function


' Map metadata fields
function ImageMapper_mapMetadata(model as Object, json as Object) as Object
    model.ownerId    = GetField(json, "owner",      "")
    model.owner      = GetField(json, "ownername",  "")
    model.datePosted = GetField(json, "dateupload", "")

    ' Description — may be a nested assocarray or a plain string
    if json.description <> invalid then
        if Type(json.description) = "roAssociativeArray" and json.description._content <> invalid then
            model.description = json.description._content
        else
            model.description = SafeToStr(json.description)
        end if
    end if

    ' Tags — can be a string or an array
    if json.tags <> invalid then
        if Type(json.tags) = "roArray" then
            model.tags = ""
            for each tag in json.tags
                if model.tags <> "" then model.tags = model.tags + ","
                model.tags = model.tags + tag
            end for
        else
            model.tags = SafeToStr(json.tags)
        end if
    end if

    return model
end function


' Map statistics
function ImageMapper_mapStats(model as Object, json as Object) as Object
    if json.views <> invalid then
        model.views = SafeToInt(json.views)
    end if

    ' Dimensions — prefer largest size (b), fall back to medium (z)
    if json.width_b <> invalid then model.width  = SafeToInt(json.width_b)
    if json.height_b <> invalid then model.height = SafeToInt(json.height_b)
    if model.width = 0 and json.width_z <> invalid then model.width  = SafeToInt(json.width_z)
    if model.height = 0 and json.height_z <> invalid then model.height = SafeToInt(json.height_z)

    return model
end function


' Validate required fields
function ImageMapper_validate(json as Object) as Boolean
    if json = invalid then return false
    if json.id = invalid or json.id = "" then return false
    return true
end function
